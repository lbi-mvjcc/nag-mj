import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../viewmodels/task_viewmodel.dart';
import '../widgets/move_to_trash_dialog.dart';
import '../widgets/task_dialog.dart';
import '../widgets/task_result_modal.dart';

class ToReviewView extends ConsumerStatefulWidget {
  const ToReviewView({super.key});

  @override
  ConsumerState<ToReviewView> createState() => _ToReviewViewState();
}

class _ToReviewViewState extends ConsumerState<ToReviewView> {
  final Set<int> _selectedTaskIds = <int>{};

  Future<void> _markAsCompleted(Task task) async {
    await ref.read(reviewTaskIdsProvider.notifier).removeTask(task.id);
    if (!task.isCompleted) {
      await ref
          .read(tasksProvider.notifier)
          .updateTask(task.copyWith(isCompleted: true, updatedAt: DateTime.now()));
    }
  }

  Future<void> _markAsOvertime(Task task) async {
    await ref.read(reviewTaskIdsProvider.notifier).removeTask(task.id);

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

  Future<void> _markAsToReview(Task task) async {
    await ref.read(reviewTaskIdsProvider.notifier).addTask(task.id);
    ref.read(sidebarIndexProvider.notifier).state = 3;
  }

  Future<void> _confirmDeleteTask(Task task) async {
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

      if (mounted) {
        setState(() => _selectedTaskIds.remove(task.id));
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
      if (mounted) {
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
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);
    final reviewTaskIds = ref.watch(reviewTaskIdsProvider);

    return tasksAsync.when(
      data: (tasks) {
        final reviewTasks = tasks.where((task) => reviewTaskIds.contains(task.id)).toList();

        if (reviewTasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No tasks to review',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use the task menu and tap "Mark as To Review" to send tasks here.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final selectedVisibleTaskIds = _selectedTaskIds
            .where(reviewTasks.map((task) => task.id).toSet().contains)
            .toSet();
        final selectedTasks = reviewTasks
            .where((task) => selectedVisibleTaskIds.contains(task.id))
            .toList();
        final selectedCount = selectedVisibleTaskIds.length;
        final hasSelection = selectedCount > 0;
        final allSelected = reviewTasks.isNotEmpty && selectedCount == reviewTasks.length;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'To Review',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  if (hasSelection)
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: allSelected,
                              onChanged: (value) {
                                _toggleSelectAll(reviewTasks, value ?? false);
                              },
                            ),
                            Text('$selectedCount/${reviewTasks.length} selected'),
                            const SizedBox(width: 12),
                            FilledButton.tonalIcon(
                              onPressed: () => _removeSelectedFromReview(selectedTasks),
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Remove from Review'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: reviewTasks.length,
                itemBuilder: (context, index) {
                  final task = reviewTasks[index];
                  final isSelected = _selectedTaskIds.contains(task.id);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          _toggleTaskSelection(task.id, value ?? false);
                        },
                      ),
                      title: Text(task.title),
                      subtitle: task.description == null
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
                              await _markAsCompleted(task);
                              break;
                            case 'overtime':
                              await _markAsOvertime(task);
                              break;
                            case 'review':
                              await _markAsToReview(task);
                              break;
                            case 'remove':
                              await _removeFromReview(task.id);
                              break;
                            case 'delete':
                              await _confirmDeleteTask(task);
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
                            value: 'remove',
                            child: Row(
                              children: [
                                Icon(Icons.rate_review_outlined, size: 20),
                                SizedBox(width: 8),
                                Text('Remove from Review'),
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
        child: Text('Error loading review tasks: $error'),
      ),
    );
  }

  void _toggleTaskSelection(int taskId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedTaskIds.add(taskId);
      } else {
        _selectedTaskIds.remove(taskId);
      }
    });
  }

  void _toggleSelectAll(List<Task> tasks, bool isSelected) {
    final ids = tasks.map((task) => task.id);
    setState(() {
      if (isSelected) {
        _selectedTaskIds.addAll(ids);
      } else {
        _selectedTaskIds.removeAll(ids);
      }
    });
  }

  Future<void> _removeFromReview(int taskId) async {
    await ref.read(reviewTaskIdsProvider.notifier).removeTask(taskId);
    if (mounted) {
      setState(() => _selectedTaskIds.remove(taskId));
    }
  }

  Future<void> _removeSelectedFromReview(List<Task> tasks) async {
    for (final task in tasks) {
      await ref.read(reviewTaskIdsProvider.notifier).removeTask(task.id);
    }

    if (mounted) {
      setState(() {
        _selectedTaskIds.removeAll(tasks.map((task) => task.id));
      });
    }

    if (!mounted) {
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const TaskResultModal(
        isSuccess: true,
        message: 'Removed selected task(s) from review',
      ),
    );
  }
}
