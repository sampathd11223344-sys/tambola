import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Large green action button (Reset / Generate / History).
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.fontSize = 16,
    this.icon,
    this.emphasized = false,
  });

  final String label;

  /// `null` disables the button.
  final VoidCallback? onPressed;
  final double fontSize;
  final IconData? icon;

  /// Slightly stronger colour for the primary action (Generate).
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    final Color fill = enabled ? AppColors.button : AppColors.buttonDisabled;

    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(AppMetrics.panelRadius),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppMetrics.panelRadius),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppMetrics.panelRadius),
            border: emphasized
                ? Border.all(color: AppColors.accent.withOpacity(0.6), width: 1.5)
                : null,
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(
                    icon,
                    size: fontSize + 2,
                    color: enabled ? AppColors.ink : AppColors.inkMuted,
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                      color: enabled ? AppColors.ink : AppColors.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
