import 'package:flutter/material.dart';

Future<bool> showMoveToTrashDialog(
  BuildContext context, {
  required String taskTitle,
}) async {
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(dialogContext).colorScheme.surface,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Theme.of(dialogContext).colorScheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    color: Theme.of(dialogContext).colorScheme.error,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Delete Task',
                  style: Theme.of(
                    dialogContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to delete "$taskTitle"?\nIt will be moved to trash.',
                  style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(dialogContext).colorScheme.error,
                        ),
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  return shouldDelete ?? false;
}