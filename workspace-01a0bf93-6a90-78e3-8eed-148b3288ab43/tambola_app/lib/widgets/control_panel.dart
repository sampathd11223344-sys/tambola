import 'package:flutter/material.dart';

import '../models/voice_language.dart';
import '../state/tambola_controller.dart';
import '../theme/app_theme.dart';
import 'action_button.dart';
import 'current_number_display.dart';
import 'panel_pills.dart';

/// Right-hand control column: header, settings, reset, current number,
/// generate and history.
///
/// The heights are computed from the available space so the column never
/// overflows, on a 5" phone in landscape or a 13" tablet.
class ControlPanel extends StatelessWidget {
  const ControlPanel({
    super.key,
    required this.controller,
    required this.onToggleMute,
    required this.onShare,
    required this.onReset,
    required this.onGenerate,
    required this.onShowHistory,
    required this.onRepeatCurrent,
  });

  final TambolaController controller;
  final ValueChanged<bool> onToggleMute;
  final VoidCallback onShare;
  final VoidCallback onReset;
  final VoidCallback onGenerate;
  final VoidCallback onShowHistory;
  final VoidCallback onRepeatCurrent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double height = constraints.maxHeight;
        final bool compact = height < 430;
        final double gap = (height * 0.017).clamp(5.0, 12.0);
        final double pillFont = (height * 0.026).clamp(11.0, 17.0);
        final double buttonFont = (height * 0.032).clamp(13.0, 21.0);

        // Proportional heights (fractions of the column height).
        final double headerH = height * 0.075;
        final double settingsH = height * 0.075;
        final double resetH = height * 0.085;
        final double generateH = height * 0.115;
        final double historyH = height * 0.115;
        final double displayH = height -
            (headerH +
                settingsH +
                resetH +
                generateH +
                historyH +
                gap * 5);
        return Column(
          children: <Widget>[
            // ---------------------------------------------------------------- //
            // Header: voice language, mute, share
            // ---------------------------------------------------------------- //
            SizedBox(
              height: headerH,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: VoiceLanguagePill(
                      value: controller.language,
                      onSelected: (VoiceLanguage language) =>
                          controller.setLanguage(language),
                      fontSize: pillFont,
                    ),
                  ),
                  SizedBox(width: gap),
                  SoundToggle(
                    muted: controller.isMuted,
                    compact: compact,
                    onChanged: onToggleMute,
                  ),
                  SizedBox(width: gap),
                  PanelIconButton(
                    icon: Icons.ios_share,
                    tooltip: 'Share the called numbers',
                    onPressed: onShare,
                  ),
                ],
              ),
            ),
            SizedBox(height: gap),

            // ---------------------------------------------------------------- //
            // Settings: Auto mode + Speed
            // ---------------------------------------------------------------- //
            SizedBox(
              height: settingsH,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TogglePill(
                      label: 'Auto [Pro]',
                      active: controller.isAutoMode,
                      fontSize: pillFont,
                      onTap: controller.toggleAutoMode,
                    ),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    child: OptionsPill<Duration>(
                      label: 'Speed ${controller.speed.inSeconds}s',
                      items: TambolaController.speedOptions,
                      labelOf: (Duration d) => '${d.inSeconds}s',
                      value: controller.speed,
                      onSelected: controller.setSpeed,
                      fontSize: pillFont,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: gap),

            // ---------------------------------------------------------------- //
            // Reset
            // ---------------------------------------------------------------- //
            SizedBox(
              height: resetH,
              child: ActionButton(
                label: 'Reset',
                icon: Icons.restart_alt_rounded,
                fontSize: buttonFont - 1,
                onPressed: onReset,
              ),
            ),
            SizedBox(height: gap),

            // ---------------------------------------------------------------- //
            // Current number
            // ---------------------------------------------------------------- //
            SizedBox(
              height: displayH < 60 ? 60 : displayH,
              child: CurrentNumberDisplay(
                number: controller.currentNumber,
                calledCount: controller.calledCount,
                remainingCount: controller.remainingCount,
                onRepeat: onRepeatCurrent,
                compact: displayH < 110,
              ),
            ),
            SizedBox(height: gap),

            // ---------------------------------------------------------------- //
            // Generate
            // ---------------------------------------------------------------- //
            SizedBox(
              height: generateH,
              child: ActionButton(
                label: controller.isBoardComplete ? 'Board Full' : 'Generate',
                icon: Icons.campaign_rounded,
                emphasized: true,
                fontSize: buttonFont,
                onPressed: controller.canGenerate ? onGenerate : null,
              ),
            ),
            SizedBox(height: gap),

            // ---------------------------------------------------------------- //
            // History
            // ---------------------------------------------------------------- //
            SizedBox(
              height: historyH,
              child: ActionButton(
                label: 'History',
                icon: Icons.history_rounded,
                fontSize: buttonFont - 1,
                onPressed: onShowHistory,
              ),
            ),
          ],
        );
      },
    );
  }
}
