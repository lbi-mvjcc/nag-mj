import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../viewmodels/task_viewmodel.dart';
import '../widgets/move_to_trash_dialog.dart';
import '../widgets/task_dialog.dart';
import '../widgets/task_result_modal.dart';

class PendingView extends ConsumerWidget {
  const PendingView({super.key});

  Future<void> _markAsCompleted(WidgetRef ref, Task task) async {
    final reviewTaskIds = ref.read(reviewTaskIdsProvider).toSet();
    if (reviewTaskIds.contains(task.id)) {
      await ref.read(reviewTaskIdsProvider.notifier).removeTask(task.id);
    }

    if (!task.isCompleted) {
      await ref
          .read(tasksProvider.notifier)
          .updateTask(task.copyWith(isCompleted: true, updatedAt: DateTime.now()));
    }
  }

  Future<void> _markAsOvertime(WidgetRef ref, Task task) async {
    final reviewTaskIds = ref.read(reviewTaskIdsProvider).toSet();
    if (reviewTaskIds.contains(task.id)) {
      await ref.read(reviewTaskIdsProvider.notifier).removeTask(task.id);
    }

    final now = DateTime.now();
    final overtimeReminder =
        task.reminderDateTime == null || task.reminderDateTime!.isAfter(now)
        ? now.subtract(const Duration(minutes: 1))
        : task.reminderDateTime!;

    await ref
        .read(tasksProvider.notifier)
        .updateTask(
          task.copyWith(
            isCompleted: false,
            updatedAt: now,
            reminderDateTime: overtimeReminder,
          ),
        );
  }

  Future<void> _markAsToReview(WidgetRef ref, Task task) async {
    await ref.read(reviewTaskIdsProvider.notifier).addTask(task.id);
    ref.read(sidebarIndexProvider.notifier).state = 3;
  }

  Future<void> _confirmDeleteTask(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final shouldDelete = await showMoveToTrashDialog(
      context,
      taskTitle: task.title,
    );

    if (!shouldDelete) {
      return;
    }

    try {
      await ref.read(tasksProvider.notifier).deleteTask(task.id);
      await ref.read(reviewTaskIdsProvider.notifier).removeTask(task.id);
      ref.invalidate(trashTasksProvider);

      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const TaskResultModal(
            isSuccess: true,
            message: 'Task moved to trash',
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const TaskResultModal(
            isSuccess: false,
            message: 'Failed to move task to trash',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final reviewTaskIds = ref.watch(reviewTaskIdsProvider).toSet();

    return tasksAsync.when(
      data: (tasks) {
        final now = DateTime.now();
        final pendingTasks = tasks
            .where(
              (task) =>
                  !task.isCompleted &&
                  !reviewTaskIds.contains(task.id) &&
                  (task.reminderDateTime == null ||
                      !task.reminderDateTime!.isBefore(now)),
            )
            .toList();

        if (pendingTasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.pending_actions,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No pending tasks',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tasks waiting to be done will appear here.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pending Tasks',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Chip(
                    avatar: const Icon(Icons.pending_actions, size: 18),
                    label: Text('${pendingTasks.length}'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: pendingTasks.length,
                itemBuilder: (context, index) {
                  final task = pendingTasks[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(
                        Icons.pending_actions,
                        color: Colors.orange,
                      ),
                      title: Text(task.title),
                      subtitle: task.description == null || task.description!.isEmpty
                          ? null
                          : Text(
                              task.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          switch (value) {
                            case 'edit':
                              await showDialog(
                                context: context,
                                builder: (context) => TaskDialog(task: task),
                              );
                              break;
                            case 'complete':
                              await _markAsCompleted(ref, task);
                              break;
                            case 'overtime':
                              await _markAsOvertime(ref, task);
                              break;
                            case 'review':
                              await _markAsToReview(ref, task);
                              break;
                            case 'delete':
                              await _confirmDeleteTask(context, ref, task);
                              break;
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 20),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'complete',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline, size: 20),
                                SizedBox(width: 8),
                                Text('Mark as Completed'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'overtime',
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, size: 20),
                                SizedBox(width: 8),
                                Text('Mark as Overtime'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'review',
                            child: Row(
                              children: [
                                Icon(Icons.rate_review_outlined, size: 20),
                                SizedBox(width: 8),
                                Text('Mark as To Review'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('Error loading pending tasks: $error'),
      ),
    );
  }
}
