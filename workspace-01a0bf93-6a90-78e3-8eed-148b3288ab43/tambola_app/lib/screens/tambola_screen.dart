import 'dart:async';

import 'package:flutter/material.dart';

import '../services/share_service.dart';
import '../state/tambola_controller.dart';
import '../theme/app_theme.dart';
import '../utils/feedback.dart';
import '../widgets/control_panel.dart';
import '../widgets/history_dialog.dart';
import '../widgets/number_grid.dart';
import '../widgets/reset_dialog.dart';

/// Landscape board screen: 9x10 grid on the left, control panel on the right.
class TambolaScreen extends StatefulWidget {
  const TambolaScreen({super.key});

  @override
  State<TambolaScreen> createState() => _TambolaScreenState();
}

class _TambolaScreenState extends State<TambolaScreen> {
  final TambolaController _controller = TambolaController();
  final ShareService _shareService = const ShareService();

  @override
  void initState() {
    super.initState();
    // Warm up the speech engine in the background.
    unawaited(_controller.init());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _onTileTap(int number) {
    if (_controller.isNumberCalled(number)) {
      showMessage(context, 'Number $number was already called.');
      return;
    }
    final bool added = _controller.toggleQueuedNumber(number);

    // Private confirmation: only the hand holding the phone feels the tick, so
    // the pre-selected "upcoming" numbers are never revealed on the board.
    // Queue and cancel get different patterns, so the caller can tell them
    // apart without looking at the screen.
    unawaited(added ? queueHaptic() : cancelHaptic());

    // On-screen feedback exists only in REVEALED mode (showQueueHints: true).
    if (_controller.showQueueHints) {
      showMessage(
        context,
        added
            ? 'Number $number queued - it will be called after '
                '${TambolaController.defaultQueueDelay} more numbers.'
            : 'Number $number removed from the queue.',
      );
    }
  }

  void _onGenerate() {
    final int? called = _controller.callNextNumber();
    if (called == null) return;
    if (_controller.isBoardComplete) {
      showMessage(context, 'Board complete - all 90 numbers have been called!');
    }
  }

  Future<void> _onShowHistory() async {
    await showHistoryDialog(
      context,
      historyText: _controller.historyText,
      calledCount: _controller.calledCount,
      onShare: _shareHistory,
    );
  }

  Future<void> _onReset() async {
    final bool confirmed = await confirmReset(
      context,
      calledCount: _controller.calledCount,
      // In discreet mode the queue is not mentioned, not even in this dialog.
      queueLength: _controller.showQueueHints ? _controller.queueLength : 0,
    );
    if (!confirmed || !mounted) return;
    await _controller.resetGame();
    if (!mounted) return;
    showMessage(context, 'Board reset - ready for a new game.');
  }

  Future<void> _shareHistory() async {
    if (_controller.history.isEmpty) {
      showMessage(context, 'Nothing to share yet - call a few numbers first.');
      return;
    }
    await _shareService.shareText(
      'Tambola / Housie - called numbers (${_controller.calledCount}/90)\n'
      '${_controller.historyText}',
      subject: 'Tambola board history',
    );
  }

  Future<void> _onToggleMute(bool muted) async {
    // `onToggleMute` receives the *desired* muted flag.
    if (muted != _controller.isMuted) {
      await _controller.toggleMuted();
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (BuildContext context, Widget? _) {
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool shortScreen = constraints.maxHeight < 430;
                final double outerGap = shortScreen ? 8 : 14;
                final double panelWidth =
                    (constraints.maxWidth * 0.225).clamp(210.0, 360.0);

                return Padding(
                  padding: EdgeInsets.all(shortScreen ? 6 : 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(
                        child: NumberGrid(
                          controller: _controller,
                          onTileTap: _onTileTap,
                        ),
                      ),
                      SizedBox(width: outerGap),
                      SizedBox(
                        width: panelWidth,
                        child: ControlPanel(
                          controller: _controller,
                          onToggleMute: _onToggleMute,
                          onShare: () => unawaited(_shareHistory()),
                          onReset: () => unawaited(_onReset()),
                          onGenerate: _onGenerate,
                          onShowHistory: () => unawaited(_onShowHistory()),
                          onRepeatCurrent: () =>
                              unawaited(_controller.repeatCurrentNumber()),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
