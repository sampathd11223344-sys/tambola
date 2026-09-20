import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/cell_visual_state.dart';
import '../models/voice_language.dart';
import '../services/announcer.dart';
import '../services/tts_service.dart';
import '../services/wake_lock_service.dart';

/// Single source of truth for the whole game.
///
/// It is a plain [ChangeNotifier] (no external state-management dependency) so
/// it can be dropped into Provider, Riverpod, GetX or a bare `ListenableBuilder`
/// without modification.
///
/// ---------------------------------------------------------------------------
/// THE DELAYED CALL QUEUE (custom feature)
/// ---------------------------------------------------------------------------
/// Tapping an uncalled number puts it in the queue with `delayCounter = 2`.
/// Every generation:
///   Step A - if a queued number has `delayCounter == 0`, it is called next
///            (oldest-ready first, so the queue is predictable).
///            Otherwise a random uncalled number is picked, excluding queued
///            numbers unless every remaining number is queued.
///   Step B - every number still in the queue loses one tick.
///
/// The queue can run in two display modes:
///   * DISCREET (default) - queued numbers look exactly like uncalled numbers,
///     so nobody watching the board can tell what is coming next. A light
///     haptic tick is the caller's only confirmation.
///   * REVEALED - the amber tile + "IN 2" / "NEXT" badge is drawn
///     (`showQueueHints: true`).
///
/// Worked example with delay = 2 (revealed mode shows "in 2" -> "in 1" -> "NEXT"):
///   tap 54              -> queue {54: 2}
///   Generate            -> random (e.g. 23 is *deferred*, 54 -> 1)
///   Generate            -> random (54 -> 0, tile now says NEXT)
///   Generate            -> 54 is called, guaranteed.
class TambolaController extends ChangeNotifier {
  TambolaController({
    Announcer? announcer,
    WakeLockService? wakeLockService,
    Random? random,
    bool showQueueHints = false,
  })  : _tts = announcer ?? TtsService(),
        _wakeLock = wakeLockService ?? WakeLockService(),
        _random = random ?? Random(),
        _showQueueHints = showQueueHints;

  /// Total numbers on a Housie board.
  static const int totalNumbers = 90;

  /// Number of generations a pre-selected number waits before being called.
  static const int defaultQueueDelay = 2;

  static const Duration defaultSpeed = Duration(seconds: 3);
  static const List<Duration> speedOptions = <Duration>[
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 3),
    Duration(seconds: 5),
  ];

  static const int minNumber = 1;
  static const int maxNumber = totalNumbers;

  final Announcer _tts;
  final WakeLockService _wakeLock;
  final Random _random;

  final Set<int> _called = <int>{};
  final List<int> _history = <int>[];
  final Map<int, int> _queue = <int, int>{}; // number -> delayCounter (ordered)

  int? _current;
  Timer? _autoTimer;
  bool _autoMode = false;
  bool _muted = false;
  Duration _speed = defaultSpeed;
  VoiceLanguage _language = VoiceLanguage.english;
  bool _showQueueHints = false;
  bool _disposed = false;

  // ---------------------------------------------------------------------------
  // Read-only view of the game
  // ---------------------------------------------------------------------------

  /// Most recently called number, or null before the first call.
  int? get currentNumber => _current;

  /// Numbers in the exact order they were called.
  List<int> get history => List<int>.unmodifiable(_history);

  /// The delayed-call queue as `number -> remaining delay`.
  Map<int, int> get queue => Map<int, int>.unmodifiable(_queue);

  int get calledCount => _history.length;

  int get remainingCount => totalNumbers - _history.length;

  bool get isBoardComplete => _history.length >= totalNumbers;

  bool get canGenerate => !isBoardComplete;

  /// Whether queued numbers are painted on the board.
  ///
  /// `false` (the default) keeps the delayed-call queue completely invisible:
  /// queued tiles render like ordinary uncalled tiles, so the upcoming number
  /// is known only to the caller. Flip it to `true` for a transparent board
  /// (handy while developing, or when a second caller shares the screen).
  bool get showQueueHints => _showQueueHints;

  bool get isAutoMode => _autoMode;

  bool get isMuted => _muted;

  Duration get speed => _speed;

  VoiceLanguage get language => _language;

  int get queueLength => _queue.length;

  /// Queued numbers whose counter already reached 0 (they will be called next).
  int get readyQueueLength =>
      _queue.values.where((int counter) => counter <= 0).length;

  /// "14 -> 60 -> 42 -> 23" (empty string when nothing has been called yet).
  String get historyText => _history.map((int n) => n.toString()).join(' -> ');

  bool isNumberCalled(int number) => _called.contains(number);

  bool isNumberQueued(int number) => _queue.containsKey(number);

  /// Remaining delay for a queued number (`null` when it is not queued).
  int? queueDelayOf(int number) => _queue[number];

  /// The one method the board uses to decide how to paint a tile.
  ///
  /// In discreet mode a queued number is reported as [CellVisualState.uncalled]
  /// on purpose - the tile has to look completely untouched.
  CellVisualState stateOf(int number) {
    if (_current == number) return CellVisualState.latest;
    if (_called.contains(number)) return CellVisualState.called;
    final int? delay = _queue[number];
    if (delay != null && _showQueueHints) {
      return delay <= 0 ? CellVisualState.queuedReady : CellVisualState.queued;
    }
    return CellVisualState.uncalled;
  }

  /// Turns the amber queue markers on/off at runtime.
  void setShowQueueHints(bool show) {
    if (show == _showQueueHints) return;
    _showQueueHints = show;
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Prepares TTS. Safe to call more than once.
  Future<void> init() => _tts.init();

  // ---------------------------------------------------------------------------
  // Queue interaction
  // ---------------------------------------------------------------------------

  /// Tapping an uncalled tile toggles it in/out of the delayed-call queue.
  ///
  /// The queue is a private caller tool: in discreet mode nothing is painted on
  /// the board, so the tap is invisible to everybody watching.
  ///
  /// Returns `true` when the number was *added* and `false` when it was
  /// cancelled (or when the tap was ignored because the number is already
  /// called).
  bool toggleQueuedNumber(int number) {
    if (number < minNumber || number > maxNumber) return false;
    if (_called.contains(number)) return false;

    if (_queue.remove(number) != null) {
      _notify();
      return false;
    }

    _queue[number] = defaultQueueDelay;
    _notify();
    return true;
  }

  /// Empties the delayed-call queue without touching the called numbers.
  void clearQueue() {
    if (_queue.isEmpty) return;
    _queue.clear();
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Generating numbers
  // ---------------------------------------------------------------------------

  /// Calls the next number and returns it, or `null` when the board is done.
  int? callNextNumber() {
    if (isBoardComplete) return null;

    final int chosen = _pickNextNumber();

    // Step A - the pick is final: remove it from the queue and mark it called.
    _queue.remove(chosen);
    _current = chosen;
    _called.add(chosen);
    _history.add(chosen);

    // Step B - advance every number that is still waiting.
    for (final int key in _queue.keys.toList(growable: false)) {
      final int remaining = _queue[key]!;
      if (remaining > 0) _queue[key] = remaining - 1;
    }

    if (isBoardComplete) {
      _autoMode = false;
      _stopAutoTimer();
    }

    if (!_muted) {
      // Fire and forget: the announcement must never block the UI.
      unawaited(_tts.announce(chosen));
    }

    _notify();
    return chosen;
  }

  int _pickNextNumber() {
    // Step A: the oldest queued number that has finished waiting.
    for (final MapEntry<int, int> entry in _queue.entries) {
      if (entry.value <= 0) return entry.key;
    }

    // Otherwise: random among uncalled numbers that are *not* queued.
    final List<int> pool = <int>[];
    final List<int> queuedOnlyFallback = <int>[];
    for (int n = minNumber; n <= maxNumber; n++) {
      if (_called.contains(n)) continue;
      if (_queue.containsKey(n)) {
        queuedOnlyFallback.add(n);
      } else {
        pool.add(n);
      }
    }

    // Spec: queued numbers are skipped unless no other uncalled number exists.
    final List<int> source = pool.isNotEmpty ? pool : queuedOnlyFallback;
    return source[_random.nextInt(source.length)];
  }

  // ---------------------------------------------------------------------------
  // Auto play
  // ---------------------------------------------------------------------------

  void toggleAutoMode() {
    if (isBoardComplete) return;
    _autoMode = !_autoMode;
    if (_autoMode) {
      _startAutoTimer();
    } else {
      _stopAutoTimer();
    }
    _notify();
  }

  /// Changes the auto-play interval; restarts the timer when auto is active.
  void setSpeed(Duration speed) {
    if (speed == _speed || speed.inMilliseconds <= 0) return;
    _speed = speed;
    if (_autoMode) _startAutoTimer();
    _notify();
  }

  void _startAutoTimer() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(_speed, (_) => callNextNumber());
    unawaited(_wakeLock.enable());
  }

  void _stopAutoTimer() {
    _autoTimer?.cancel();
    _autoTimer = null;
    unawaited(_wakeLock.disable());
  }

  // ---------------------------------------------------------------------------
  // Voice / sound
  // ---------------------------------------------------------------------------

  Future<void> setLanguage(VoiceLanguage language) async {
    if (language == _language) return;
    _language = language;
    _notify();
    await _tts.setLanguage(language);
  }

  Future<void> toggleMuted() async {
    _muted = !_muted;
    _tts.setMuted(_muted);
    _notify();
    if (!_muted) await _tts.announce(_current ?? 0);
  }

  /// Repeats the last call (handy if the room missed it).
  Future<void> repeatCurrentNumber() async {
    final int? number = _current;
    if (number == null || _muted) return;
    await _tts.announce(number);
  }

  // ---------------------------------------------------------------------------
  // Reset
  // ---------------------------------------------------------------------------

  /// Clears the board, the queue, the history and the current number.
  Future<void> resetGame() async {
    _stopAutoTimer();
    _autoMode = false;
    _called.clear();
    _history.clear();
    _queue.clear();
    _current = null;
    await _tts.stop();
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _autoTimer?.cancel();
    unawaited(_wakeLock.disable());
    unawaited(_tts.dispose());
    super.dispose();
  }
}
