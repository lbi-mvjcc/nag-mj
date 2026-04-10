import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/task_viewmodel.dart';
import '../models/task.dart';
import '../core/enums.dart';
import '../core/extensions.dart';
import '../widgets/task_dialog.dart';
import '../widgets/task_result_modal.dart';

class TaskListView extends ConsumerStatefulWidget {
  const TaskListView({super.key});

  @override
  ConsumerState<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends ConsumerState<TaskListView> {
  final Set<int> _selectedTaskIds = <int>{};
  int _lastSelectAllTrigger = 0;

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);
    ref.watch(filterProvider);
    ref.watch(sortProvider);
    ref.watch(searchQueryProvider);
    ref.watch(showOnlyWithRemindersProvider);
    ref.watch(showOnlyRecurringProvider);
    final selectAllTrigger = ref.watch(taskSelectAllTriggerProvider);
    final viewModel = ref.read(tasksProvider.notifier);

    return tasksAsync.when(
      data: (tasks) {
        final filteredTasks = viewModel.getFilteredAndSortedTasks(tasks);

        if (selectAllTrigger != _lastSelectAllTrigger) {
          _lastSelectAllTrigger = selectAllTrigger;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _selectedTaskIds
                ..clear()
                ..addAll(filteredTasks.map((task) => task.id));
            });
          });
        }

        if (filteredTasks.isEmpty) {
          if (_selectedTaskIds.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(_selectedTaskIds.clear);
              }
            });
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.task_alt,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No tasks found',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a new task to get started',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          );
        }

        final visibleTaskIds = filteredTasks.map((task) => task.id).toSet();
        final selectedVisibleTaskIds =
            _selectedTaskIds.where(visibleTaskIds.contains).toSet();
        final selectedCount = selectedVisibleTaskIds.length;
        final hasSelection = selectedCount > 0;
        final allSelected =
            filteredTasks.isNotEmpty && selectedCount == filteredTasks.length;
        final selectedTasks = filteredTasks
            .where((task) => selectedVisibleTaskIds.contains(task.id))
            .toList();

        return Column(
          children: [
            if (hasSelection)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: allSelected,
                              onChanged: (value) {
                                _toggleSelectAll(filteredTasks, value ?? false);
                              },
                            ),
                            Text(
                              'Select all',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$selectedCount/${filteredTasks.length} selected',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                            ),
                          ],
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => _updateStatusForTasks(ref, selectedTasks),
                          icon: const Icon(Icons.sync_alt_rounded),
                          label: const Text('Update Status'),
                        ),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.error,
                            foregroundColor:
                                Theme.of(context).colorScheme.onError,
                          ),
                          onPressed: () =>
                              _showBulkDeleteConfirmation(context, ref, selectedTasks),
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('Delete Selected'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(16, hasSelection ? 8 : 16, 16, 16),
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];
                  return TaskCard(
                    task: task,
                    isSelected: _selectedTaskIds.contains(task.id),
                    onSelectionChanged: (isSelected) {
                      _toggleTaskSelection(task.id, isSelected);
                    },
                    onEdit: () {
                      showDialog(
                        context: context,
                        builder: (context) => TaskDialog(task: task),
                      );
                    },
                    onUpdateStatus: () {
                      _updateStatusForTasks(ref, [task]);
                    },
                    onDelete: () {
                      _showDeleteConfirmation(context, ref, task);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading tasks: $error'),
          ],
        ),
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

  Future<void> _showResultModal({
    required bool isSuccess,
    required String message,
  }) async {
    if (!mounted) {
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => TaskResultModal(
        isSuccess: isSuccess,
        message: message,
      ),
    );
  }

  Future<void> _updateStatusForTasks(WidgetRef ref, List<Task> tasks) async {
    if (tasks.isEmpty) {
      return;
    }

    var updatedCount = 0;
    for (final task in tasks) {
      try {
        await ref.read(tasksProvider.notifier).toggleTaskCompletion(task.id);
        updatedCount++;
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _selectedTaskIds.removeAll(tasks.map((task) => task.id));
      });
    }

    if (updatedCount == tasks.length) {
      if (tasks.length == 1) {
        await _showResultModal(
          isSuccess: true,
          message: tasks.first.isCompleted
              ? 'Task marked as ${_getReopenStatusLabel(tasks.first).toLowerCase()}'
              : 'Task marked as completed',
        );
      } else {
        await _showResultModal(
          isSuccess: true,
          message: 'Updated status for $updatedCount task(s)',
        );
      }
    } else if (updatedCount > 0) {
      await _showResultModal(
        isSuccess: false,
        message: 'Updated $updatedCount of ${tasks.length} selected task(s)',
      );
    } else {
      await _showResultModal(
        isSuccess: false,
        message: 'Failed to update selected task status',
      );
    }
  }

  String _getReopenStatusLabel(Task task) {
    final reminder = task.reminderDateTime;
    if (reminder != null && reminder.isBefore(DateTime.now())) {
      return 'Overtime';
    }
    return 'Pending';
  }

  void _showBulkDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    List<Task> tasks,
  ) {
    if (tasks.isEmpty) {
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Selected Tasks'),
        content: Text(
          'Delete ${tasks.length} selected task(s)? They will be moved to trash.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () async {
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }

              var deletedCount = 0;
              for (final task in tasks) {
                try {
                  await ref.read(tasksProvider.notifier).deleteTask(task.id);
                  deletedCount++;
                } catch (_) {}
              }

              ref.invalidate(trashTasksProvider);
              if (mounted) {
                setState(() {
                  _selectedTaskIds.removeAll(tasks.map((task) => task.id));
                });
              }

              if (deletedCount == tasks.length) {
                await _showResultModal(
                  isSuccess: true,
                  message: '$deletedCount task(s) moved to trash',
                );
              } else if (deletedCount > 0) {
                await _showResultModal(
                  isSuccess: false,
                  message: 'Moved $deletedCount of ${tasks.length} task(s) to trash',
                );
              } else {
                await _showResultModal(
                  isSuccess: false,
                  message: 'Failed to move selected tasks to trash',
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, Task task) {
    final pageContext = context;
    showDialog(
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
                    style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Are you sure you want to delete "${task.title}"?\nIt will be moved to trash.',
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
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(dialogContext).colorScheme.error,
                          ),
                          onPressed: () async {
                            try {
                              await ref.read(tasksProvider.notifier).deleteTask(task.id);
                              ref.invalidate(trashTasksProvider);

                              if (mounted) {
                                setState(() {
                                  _selectedTaskIds.remove(task.id);
                                });
                              }

                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }

                              if (pageContext.mounted) {
                                await showDialog(
                                  context: pageContext,
                                  barrierDismissible: false,
                                  builder: (context) => const TaskResultModal(
                                    isSuccess: true,
                                    message: 'Task moved to trash',
                                  ),
                                );
                              }
                            } catch (_) {
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }

                              if (pageContext.mounted) {
                                await showDialog(
                                  context: pageContext,
                                  barrierDismissible: false,
                                  builder: (context) => const TaskResultModal(
                                    isSuccess: false,
                                    message: 'Failed to move task to trash',
                                  ),
                                );
                              }
                            }
                          },
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
  }
}

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onEdit,
    required this.onUpdateStatus,
    required this.onDelete,
  });

  final Task task;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final VoidCallback onEdit;
  final VoidCallback onUpdateStatus;
  final VoidCallback onDelete;

  _TaskStatus _getTaskStatus(Task task) {
    if (task.isCompleted) {
      return _TaskStatus.completed;
    }

    final reminder = task.reminderDateTime;
    if (reminder == null) {
      return _TaskStatus.pending;
    }

    final now = DateTime.now();
    if (reminder.isBefore(now)) {
      return _TaskStatus.overtime;
    }

    return _TaskStatus.pending;
  }

  String _statusLabel(_TaskStatus status) {
    switch (status) {
      case _TaskStatus.pending:
        return 'Pending';
      case _TaskStatus.completed:
        return 'Completed';
      case _TaskStatus.overtime:
        return 'Overtime';
    }
  }

  Color _statusBackgroundColor(BuildContext context, _TaskStatus status) {
    switch (status) {
      case _TaskStatus.pending:
        return Theme.of(context).colorScheme.surfaceContainerHighest;
      case _TaskStatus.completed:
        return Colors.green.withOpacity(0.15);
      case _TaskStatus.overtime:
        return Colors.red.withOpacity(0.15);
    }
  }

  Color _statusTextColor(BuildContext context, _TaskStatus status) {
    switch (status) {
      case _TaskStatus.pending:
        return Theme.of(context).colorScheme.onSurfaceVariant;
      case _TaskStatus.completed:
        return Colors.green.shade700;
      case _TaskStatus.overtime:
        return Colors.red.shade700;
    }
  }

  Widget _buildStatusBadge(BuildContext context, _TaskStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _statusBackgroundColor(context, status),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: _statusTextColor(context, status),
            ),
      ),
    );
  }

  String _getRecurrenceLabel(Task task) {
    if (task.recurrenceInterval > 1) {
      switch (task.recurrenceType) {
        case RecurrenceType.daily:
          return 'Every ${task.recurrenceInterval} days';
        case RecurrenceType.weekly:
          return 'Every ${task.recurrenceInterval} weeks';
        case RecurrenceType.monthly:
          return 'Every ${task.recurrenceInterval} months';
        default:
          return '';
      }
    }

    switch (task.recurrenceType) {
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
      default:
        return '';
    }
  }

  String _getReopenStatusLabel(Task task) {
    final reminder = task.reminderDateTime;
    if (reminder != null && reminder.isBefore(DateTime.now())) {
      return 'Overtime';
    }
    return 'Pending';
  }

  @override
  Widget build(BuildContext context) {
    final status = _getTaskStatus(task);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (value) => onSelectionChanged(value ?? false),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style:
                                Theme.of(context).textTheme.titleMedium?.copyWith(
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: task.isCompleted
                                          ? Theme.of(context).colorScheme.outline
                                          : null,
                                    ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(context, status),
                      ],
                    ),
                    if (task.description != null && task.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          task.description!.truncate(100),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          if (task.reminderDateTime != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.notifications_outlined,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  task.reminderDateTime!.formatDateTime(context),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                ),
                              ],
                            ),
                          if (task.isRecurring)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.repeat,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getRecurrenceLabel(task),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                ),
                              ],
                            ),
                          if (task.isRecurring && task.recurrenceEndDate != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.event_outlined,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Until ${task.recurrenceEndDate!.formatDate(context)}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.tertiary,
                                      ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'status':
                      onUpdateStatus();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
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
                    value: 'status',
                    child: Row(
                      children: [
                        const Icon(Icons.sync_alt_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          task.isCompleted
                              ? 'Mark as ${_getReopenStatusLabel(task)}'
                              : 'Mark as Completed',
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
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
            ],
          ),
        ),
      ),
    );
  }
}

enum _TaskStatus { pending, completed, overtime }
