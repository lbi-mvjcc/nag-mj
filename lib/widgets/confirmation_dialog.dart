import 'package:flutter/material.dart';
import '../models/task.dart';

class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    required this.title,
    required this.message,
    required this.onConfirm,
    this.onCancel,
    this.confirmButtonLabel = 'Confirm',
    this.cancelButtonLabel = 'Cancel',
    this.confirmButtonColor,
    this.isDangerous = false,
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final String confirmButtonLabel;
  final String cancelButtonLabel;
  final Color? confirmButtonColor;
  final bool isDangerous;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttonColor = confirmButtonColor ?? colorScheme.primary;
    final isError = isDangerous;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isError
                    ? colorScheme.errorContainer
                    : colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isError ? Icons.warning_rounded : Icons.help_outline_rounded,
                color: isError ? colorScheme.error : colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Message
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      onCancel?.call();
                      Navigator.pop(context);
                    },
                    child: Text(cancelButtonLabel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: buttonColor,
                    ),
                    onPressed: () {
                      onConfirm();
                      Navigator.pop(context);
                    },
                    child: Text(confirmButtonLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DeleteTaskConfirmationDialog extends StatelessWidget {
  const DeleteTaskConfirmationDialog({
    required this.task,
    required this.onConfirm,
    this.onCancel,
    super.key,
  });

  final Task task;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return ConfirmationDialog(
      title: 'Delete Task',
      message: 'Are you sure you want to delete "${task.title}"?\nIt will be moved to trash.',
      confirmButtonLabel: 'Delete',
      confirmButtonColor: Theme.of(context).colorScheme.error,
      isDangerous: true,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }
}
