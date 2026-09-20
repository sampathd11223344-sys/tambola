import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Big circular readout of the number that was just called.
///
/// Tapping it repeats the announcement (useful when the room missed it).
class CurrentNumberDisplay extends StatelessWidget {
  const CurrentNumberDisplay({
    super.key,
    required this.number,
    required this.calledCount,
    required this.remainingCount,
    required this.onRepeat,
    this.compact = false,
  });

  final int? number;
  final int calledCount;
  final int remainingCount;
  final VoidCallback onRepeat;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double diameter = math.min(constraints.maxHeight, constraints.maxWidth);

        return Center(
          child: Tooltip(
            message: 'Tap to repeat the call',
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: number == null ? null : onRepeat,
                child: Ink(
                  width: diameter,
                  height: diameter,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.currentNumberFill,
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.35),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      if (!compact)
                        const Text(
                          'CURRENT',
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w800,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            number?.toString() ?? '--',
                            style: const TextStyle(
                              fontSize: 60,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                      if (!compact)
                        Text(
                          '$calledCount called  •  $remainingCount left',
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
