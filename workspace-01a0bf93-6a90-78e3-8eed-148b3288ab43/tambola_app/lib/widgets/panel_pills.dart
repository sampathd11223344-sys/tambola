import 'package:flutter/material.dart';

import '../models/voice_language.dart';
import '../theme/app_theme.dart';

/// Rounded pill that opens a list of options (used for Voice language and
/// Speed). Mirrors the "Voice English ⌄" / "Speed 3s" controls in the design.
class OptionsPill<T> extends StatelessWidget {
  const OptionsPill({
    super.key,
    required this.label,
    required this.items,
    required this.labelOf,
    required this.value,
    required this.onSelected,
    this.fontSize = 13,
    this.trailing,
  });

  final String label;
  final List<T> items;
  final String Function(T value) labelOf;
  final T value;
  final ValueChanged<T> onSelected;
  final double fontSize;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return _PillShell(
      borderRadius: 10,
      borderColor: AppColors.accent.withOpacity(0.55),
      fill: AppColors.chipSurface,
      onTap: () => _openMenu(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 4),
            trailing!,
          ],
        ],
      ),
    );
  }

  Future<void> _openMenu(BuildContext context) async {
    final RenderBox button = context.findRenderObject()! as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final Offset topLeft = button.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        topLeft,
        topLeft + Offset(button.size.width, button.size.height),
      ),
      Offset.zero & overlay.size,
    );

    final T? selected = await showMenu<T>(
      context: context,
      position: position,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: items
          .map(
            (T item) => PopupMenuItem<T>(
              value: item,
              height: 40,
              child: Row(
                children: <Widget>[
                  Icon(
                    item == value
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 16,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      labelOf(item),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );

    if (selected != null) onSelected(selected);
  }
}

/// "Voice English ⌄" selector.
class VoiceLanguagePill extends StatelessWidget {
  const VoiceLanguagePill({
    super.key,
    required this.value,
    required this.onSelected,
    this.fontSize = 13,
  });

  final VoiceLanguage value;
  final ValueChanged<VoiceLanguage> onSelected;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return OptionsPill<VoiceLanguage>(
      label: 'Voice ${value.label}',
      items: VoiceLanguage.values,
      labelOf: (VoiceLanguage language) => language.label,
      value: value,
      onSelected: onSelected,
      fontSize: fontSize,
      trailing: const Icon(
        Icons.expand_more,
        size: 16,
        color: AppColors.accent,
      ),
    );
  }
}

/// Toggle style pill ("Auto"), with an on/off look.
class TogglePill extends StatelessWidget {
  const TogglePill({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.fontSize = 13,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return _PillShell(
      borderRadius: 10,
      borderColor: active
          ? AppColors.accent
          : AppColors.accent.withOpacity(0.55),
      fill: active ? AppColors.button : AppColors.chipSurface,
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            active ? Icons.play_circle_fill : Icons.pause_circle_outline,
            size: fontSize + 3,
            color: AppColors.accent,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mute / unmute switch shown in the header.
class SoundToggle extends StatelessWidget {
  const SoundToggle({
    super.key,
    required this.muted,
    required this.onChanged,
    this.compact = false,
  });

  final bool muted;
  final ValueChanged<bool> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: muted ? 'Voice muted - tap to unmute' : 'Voice on - tap to mute',
      child: SizedBox(
        width: compact ? 54 : 66,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                size: 18,
                color: AppColors.ink,
              ),
              const SizedBox(width: 2),
              Transform.scale(
                scale: 0.78,
                child: Switch.adaptive(
                  value: !muted,
                  activeColor: const Color(0xFF0F9B8E),
                  activeTrackColor: const Color(0xFF2E7D32),
                  inactiveThumbColor: const Color(0xFFF5F5F5),
                  inactiveTrackColor: const Color(0xFFBDBDBD),
                  onChanged: (bool value) => onChanged(!value),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Square icon button (share) used in the header.
class PanelIconButton extends StatelessWidget {
  const PanelIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: AspectRatio(
        aspectRatio: 1,
        child: Material(
          color: AppColors.chipSurface,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(10),
            child: Icon(icon, size: 18),
          ),
        ),
      ),
    );
  }
}

/// Shared rounded container used by every pill.
class _PillShell extends StatelessWidget {
  const _PillShell({
    required this.child,
    required this.onTap,
    required this.fill,
    required this.borderColor,
    required this.borderRadius,
  });

  final Widget child;
  final VoidCallback onTap;
  final Color fill;
  final Color borderColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
