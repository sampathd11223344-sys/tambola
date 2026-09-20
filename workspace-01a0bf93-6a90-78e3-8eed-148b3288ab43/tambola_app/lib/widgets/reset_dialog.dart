import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// "Start a new game?" confirmation. Resolves to `true` when the user confirms.
Future<bool> confirmReset(
  BuildContext context, {
  required int calledCount,
  required int queueLength,
}) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Start a new game?',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
        ),
        content: Text(
          'This clears $calledCount called number${calledCount == 1 ? '' : 's'}'
          '${queueLength > 0 ? ' and $queueLength queued number${queueLength == 1 ? '' : 's'}' : ''},'
          ' the history and the current call.',
          style: const TextStyle(fontSize: 14.5, height: 1.35),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.inkMuted,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.button,
              foregroundColor: AppColors.ink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Reset',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
