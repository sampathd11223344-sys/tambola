import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Light haptic tick used as *private* feedback: the caller feels it in the
/// hand, while the board the room is watching shows nothing at all.
Future<void> selectionHaptic() async {
  try {
    await HapticFeedback.selectionClick();
  } catch (_) {
    // Not available on every device - ignore.
  }
}

/// Haptic pattern for "this number is now queued" (two crisp ticks).
Future<void> queueHaptic() async {
  try {
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 70));
    await HapticFeedback.selectionClick();
  } catch (_) {
    // Not available on every device - ignore.
  }
}

/// Haptic pattern for "queue cancelled" (one soft tick).
Future<void> cancelHaptic() async {
  try {
    await HapticFeedback.lightImpact();
  } catch (_) {
    // Not available on every device - ignore.
  }
}

/// Shows a short bottom snack bar.
void showMessage(
  BuildContext context,
  String message, {
  SnackBarAction? action,
}) {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        action: action,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
}
