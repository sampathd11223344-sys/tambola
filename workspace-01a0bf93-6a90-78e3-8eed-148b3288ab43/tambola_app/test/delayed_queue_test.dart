import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tambola_board/models/cell_visual_state.dart';
import 'package:tambola_board/models/voice_language.dart';
import 'package:tambola_board/services/announcer.dart';
import 'package:tambola_board/state/tambola_controller.dart';

/// Records everything the controller asks to be spoken.
class FakeAnnouncer implements Announcer {
  final List<String> spoken = <String>[];
  final List<VoiceLanguage> languages = <VoiceLanguage>[];
  bool muted = false;
  bool disposed = false;

  @override
  Future<void> init() async {}

  @override
  Future<void> setLanguage(VoiceLanguage language) async =>
      languages.add(language);

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> announce(int number) => speak('NUMBER $number');

  @override
  void setMuted(bool value) => muted = value;

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async => disposed = true;
}

/// Deterministic Random: always returns the first index.
class _LowestRandom implements Random {
  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => 0;
}

void main() {
  group('TambolaController basics', () {
    late TambolaController controller;
    late FakeAnnouncer announcer;

    setUp(() {
      announcer = FakeAnnouncer();
      controller = TambolaController(announcer: announcer);
    });

    tearDown(() => controller.dispose());

    test('starts empty', () {
      expect(controller.currentNumber, isNull);
      expect(controller.calledCount, 0);
      expect(controller.remainingCount, 90);
      expect(controller.historyText, '');
      expect(controller.queueLength, 0);
    });

    test('generates unique numbers and updates every state', () {
      final Set<int> seen = <int>{};
      for (int i = 0; i < 90; i++) {
        final int? called = controller.callNextNumber();
        expect(called, isNotNull);
        expect(seen.add(called!), isTrue, reason: 'duplicate call: $called');
        expect(controller.stateOf(called), CellVisualState.latest);
        expect(controller.currentNumber, called);
      }
      expect(controller.isBoardComplete, isTrue);
      expect(controller.callNextNumber(), isNull);
      expect(announcer.spoken.length, 90);
    });

    test('history keeps the chronological order', () {
      controller.callNextNumber();
      controller.callNextNumber();
      controller.callNextNumber();
      final List<int> history = controller.history;
      expect(history.length, 3);
      expect(controller.historyText, history.join(' -> '));
    });

    test('reset clears numbers, history, queue and current call', () {
      controller.toggleQueuedNumber(7);
      controller.callNextNumber();
      expect(controller.history, isNotEmpty);

      controller.resetGame();
      expect(controller.currentNumber, isNull);
      expect(controller.history, isEmpty);
      expect(controller.queueLength, 0);
      expect(controller.isAutoMode, isFalse);
      expect(controller.stateOf(7), CellVisualState.uncalled);
    });
  });

  group('Delayed call queue - REVEALED mode (showQueueHints: true)', () {
    late TambolaController controller;

    setUp(() {
      // Deterministic picks make the assertions exact.
      controller = TambolaController(
        announcer: FakeAnnouncer(),
        random: _LowestRandom(),
        showQueueHints: true,
      );
    });

    tearDown(() => controller.dispose());

    test('tapping an uncalled tile queues it with a delay of 2', () {
      expect(controller.toggleQueuedNumber(54), isTrue);
      expect(controller.queueDelayOf(54), 2);
      expect(controller.stateOf(54), CellVisualState.queued);
    });

    test('tapping a queued tile cancels it', () {
      controller.toggleQueuedNumber(54);
      expect(controller.toggleQueuedNumber(54), isFalse);
      expect(controller.queueLength, 0);
      expect(controller.stateOf(54), CellVisualState.uncalled);
    });

    test('a called number can never be queued', () {
      final int called = controller.callNextNumber()!;
      expect(controller.toggleQueuedNumber(called), isFalse);
      expect(controller.queueLength, 0);
    });

    test('queued number is guaranteed to be called after exactly 2 picks', () {
      controller.toggleQueuedNumber(54);

      // 1st generation: 54 is still waiting (2 -> 1) and must NOT be picked.
      final int first = controller.callNextNumber()!;
      expect(first, isNot(54));
      expect(controller.queueDelayOf(54), 1);
      expect(controller.stateOf(54), CellVisualState.queued);

      // 2nd generation: 54 drops to 0 and is now flagged as next.
      final int second = controller.callNextNumber()!;
      expect(second, isNot(54));
      expect(controller.queueDelayOf(54), 0);
      expect(controller.stateOf(54), CellVisualState.queuedReady);

      // 3rd generation: the queue is honoured first.
      expect(controller.callNextNumber(), 54);
      expect(controller.isNumberQueued(54), isFalse);
      expect(controller.stateOf(54), CellVisualState.latest);
    });

    test('queued numbers are excluded from the random pool', () {
      for (int n = 11; n <= 90; n++) {
        controller.toggleQueuedNumber(n);
      }
      // Only 1..10 are free, so the first two random picks must come from there
      // (after two calls the queue starts expiring, which is the next test).
      expect(controller.callNextNumber(), inInclusiveRange(1, 10));
      expect(controller.callNextNumber(), inInclusiveRange(1, 10));
      // 11 is the oldest queued number and its counter is now 0.
      expect(controller.callNextNumber(), 11);
    });

    test('falls back to the queue when every uncalled number is queued', () {
      for (int n = 1; n <= 90; n++) {
        controller.toggleQueuedNumber(n);
      }
      // Nothing else is available -> the game must not deadlock.
      final int first = controller.callNextNumber()!;
      expect(first, 1);
      expect(controller.isNumberQueued(first), isFalse);
    });

    test('multiple queued numbers are called in first-queued order', () {
      controller.toggleQueuedNumber(70);
      controller.toggleQueuedNumber(12);

      controller.callNextNumber(); // 70: 2 -> 1, 12: 2 -> 1
      controller.callNextNumber(); // 70: 1 -> 0, 12: 1 -> 0
      expect(controller.readyQueueLength, 2);

      expect(controller.callNextNumber(), 70);
      expect(controller.callNextNumber(), 12);
    });

    test('clearQueue empties the queue without touching called numbers', () {
      controller.toggleQueuedNumber(5);
      controller.callNextNumber();
      controller.clearQueue();
      expect(controller.queueLength, 0);
      expect(controller.calledCount, 1);
    });
  });

  group('Delayed call queue - DISCREET mode (the default)', () {
    late TambolaController controller;

    setUp(() {
      controller = TambolaController(
        announcer: FakeAnnouncer(),
        random: _LowestRandom(),
      );
    });

    tearDown(() => controller.dispose());

    test('queue hints are off by default', () {
      expect(controller.showQueueHints, isFalse);
    });

    test('a queued number looks exactly like an uncalled number', () {
      expect(controller.toggleQueuedNumber(54), isTrue);

      // The queue works internally...
      expect(controller.queueLength, 1);
      expect(controller.queueDelayOf(54), 2);
      expect(controller.isNumberQueued(54), isTrue);

      // ...but the board reveals nothing: this is what the room sees.
      expect(controller.stateOf(54), CellVisualState.uncalled);
    });

    test('a ready queued number still shows as uncalled (no NEXT marker)', () {
      controller.toggleQueuedNumber(54);
      controller.callNextNumber();
      controller.callNextNumber();
      expect(controller.queueDelayOf(54), 0);
      expect(controller.stateOf(54), CellVisualState.uncalled);
    });

    test('the upcoming number is still honoured after exactly 2 picks', () {
      controller.toggleQueuedNumber(54);

      expect(controller.callNextNumber(), isNot(54));
      expect(controller.callNextNumber(), isNot(54));
      expect(controller.callNextNumber(), 54); // guaranteed, silently
      expect(controller.stateOf(54), CellVisualState.latest);
    });

    test('tapping a queued tile still cancels it invisibly', () {
      controller.toggleQueuedNumber(54);
      expect(controller.toggleQueuedNumber(54), isFalse);
      expect(controller.queueLength, 0);
      expect(controller.stateOf(54), CellVisualState.uncalled);

      // Cancelled -> the 3rd pick is no longer forced to be 54.
      controller.callNextNumber();
      controller.callNextNumber();
      expect(controller.callNextNumber(), isNot(54));
    });

    test('setShowQueueHints can reveal the queue at runtime', () {
      controller.toggleQueuedNumber(54);
      expect(controller.stateOf(54), CellVisualState.uncalled);

      controller.setShowQueueHints(true);
      expect(controller.stateOf(54), CellVisualState.queued);

      controller.setShowQueueHints(false);
      expect(controller.stateOf(54), CellVisualState.uncalled);
    });

    test('called numbers stay visible in discreet mode', () {
      controller.toggleQueuedNumber(54);
      controller.callNextNumber();
      controller.callNextNumber();
      controller.callNextNumber(); // calls 54

      expect(controller.stateOf(54), CellVisualState.latest);
      expect(controller.history.last, 54);
    });
  });

  group('Sound, language and auto mode', () {
    test('muted controller does not announce numbers', () {
      final FakeAnnouncer announcer = FakeAnnouncer();
      final TambolaController controller =
          TambolaController(announcer: announcer);
      addTearDown(controller.dispose);

      expect(controller.isMuted, isFalse);
      controller.toggleMuted();
      expect(controller.isMuted, isTrue);
      controller.callNextNumber();
      expect(announcer.spoken, isEmpty);
    });

    test('language change is forwarded to the announcer', () async {
      final FakeAnnouncer announcer = FakeAnnouncer();
      final TambolaController controller =
          TambolaController(announcer: announcer);
      addTearDown(controller.dispose);

      await controller.setLanguage(VoiceLanguage.hindi);
      expect(controller.language, VoiceLanguage.hindi);
      expect(announcer.languages, <VoiceLanguage>[VoiceLanguage.hindi]);
      expect(VoiceLanguage.hindi.announcement(54), 'नंबर 54');
    });

    test('speed change keeps auto mode running', () {
      final TambolaController controller =
          TambolaController(announcer: FakeAnnouncer());
      addTearDown(controller.dispose);

      controller.setSpeed(const Duration(seconds: 1));
      expect(controller.speed, const Duration(seconds: 1));
      controller.toggleAutoMode();
      expect(controller.isAutoMode, isTrue);
      controller.toggleAutoMode();
      expect(controller.isAutoMode, isFalse);
    });

    test('auto mode generates a number on every tick', () {
      fakeAsync((FakeAsync async) {
        final TambolaController controller =
            TambolaController(announcer: FakeAnnouncer())
              ..setSpeed(const Duration(seconds: 1));

        controller.toggleAutoMode();
        async.elapse(const Duration(seconds: 3, milliseconds: 10));
        expect(controller.calledCount, 3);

        // Switching auto off stops the timer.
        controller.toggleAutoMode();
        async.elapse(const Duration(seconds: 3));
        expect(controller.calledCount, 3);

        controller.dispose();
      });
    });
  });
}
