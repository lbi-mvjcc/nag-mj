import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/task_viewmodel.dart';
import '../models/task.dart';
import '../widgets/task_result_modal.dart';

class TrashView extends ConsumerStatefulWidget {
	const TrashView({super.key});

	@override
	ConsumerState<TrashView> createState() => _TrashViewState();
}

class _TrashViewState extends ConsumerState<TrashView> {
	final Set<int> _selectedTaskIds = <int>{};
	int _lastSelectAllTrigger = 0;

	@override
	void initState() {
		super.initState();
		_lastSelectAllTrigger = ref.read(trashSelectAllTriggerProvider);
	}

	@override
	Widget build(BuildContext context) {
		final trashTasksAsync = ref.watch(trashTasksProvider);
		final selectAllTrigger = ref.watch(trashSelectAllTriggerProvider);

		return trashTasksAsync.when(
			data: (trashTasks) {
				if (selectAllTrigger != _lastSelectAllTrigger) {
					_lastSelectAllTrigger = selectAllTrigger;
					WidgetsBinding.instance.addPostFrameCallback((_) {
						if (!mounted) {
							return;
						}

						setState(() {
							_selectedTaskIds
								..clear()
								..addAll(trashTasks.map((task) => task.id));
						});
					});
				}

				final sortedTasks = [...trashTasks]
					..sort(
						(a, b) => (b.deletedAt ?? DateTime.now())
								.compareTo(a.deletedAt ?? DateTime.now()),
					);

				final visibleTaskIds = sortedTasks.map((task) => task.id).toSet();
				final selectedVisibleTaskIds =
						_selectedTaskIds.where(visibleTaskIds.contains).toSet();
				final selectedCount = selectedVisibleTaskIds.length;
				final hasSelection = selectedCount > 0;
				final allSelected =
						sortedTasks.isNotEmpty && selectedCount == sortedTasks.length;

				if (sortedTasks.isEmpty) {
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
									Icons.delete_outline_rounded,
									size: 64,
									color: Theme.of(context).colorScheme.outline,
								),
								const SizedBox(height: 16),
								Text(
									'Trash is empty',
									style: Theme.of(context).textTheme.titleMedium,
								),
								const SizedBox(height: 8),
								Text(
									'Deleted tasks appear here for 10 days',
									style: Theme.of(context).textTheme.bodySmall?.copyWith(
												color: Theme.of(context).colorScheme.outline,
											),
								),
							],
						),
					);
				}

				final selectedTasks = sortedTasks
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
										padding: const EdgeInsets.symmetric(
											horizontal: 12,
											vertical: 8,
										),
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
																_toggleSelectAll(sortedTasks, value ?? false);
															},
														),
														Text(
															'Select all',
															style: Theme.of(context).textTheme.bodyMedium,
														),
														const SizedBox(width: 8),
														Text(
															'$selectedCount/${sortedTasks.length} selected',
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
													onPressed: () => _showBulkRestoreConfirmation(
														context,
														ref,
														selectedTasks,
													),
													icon: const Icon(Icons.restore_outlined),
													label: const Text('Restore Selected'),
												),
												FilledButton.icon(
													style: FilledButton.styleFrom(
														backgroundColor: Theme.of(context).colorScheme.error,
														foregroundColor:
															Theme.of(context).colorScheme.onError,
													),
													onPressed: () => _showBulkDeleteConfirmation(
														context,
														ref,
														selectedTasks,
													),
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
								itemCount: sortedTasks.length,
								itemBuilder: (context, index) {
									final task = sortedTasks[index];
									final isSelected = _selectedTaskIds.contains(task.id);
									final deletedAt = task.deletedAt;
									  final daysUntilPermanent = deletedAt != null
										  ? (10 - DateTime.now().difference(deletedAt).inDays)
											  .clamp(0, 10)
											  .toInt()
										  : 0;

									return Card(
										margin: const EdgeInsets.only(bottom: 12),
										child: ListTile(
											contentPadding: const EdgeInsets.symmetric(
												horizontal: 12,
												vertical: 10,
											),
											leading: Checkbox(
												value: isSelected,
												onChanged: (value) =>
														_toggleTaskSelection(task.id, value ?? false),
											),
											title: Row(
												children: [
													Icon(
														Icons.delete_outline_rounded,
														size: 18,
														color: Theme.of(context).colorScheme.error,
													),
													const SizedBox(width: 8),
													Expanded(
														child: Text(
															task.title,
															maxLines: 1,
															overflow: TextOverflow.ellipsis,
															style: TextStyle(
																decoration: TextDecoration.lineThrough,
																color: Theme.of(context).colorScheme.onSurface,
															),
														),
													),
												],
											),
											subtitle: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													const SizedBox(height: 4),
													if (task.description != null)
														Text(
															task.description!,
															maxLines: 1,
															overflow: TextOverflow.ellipsis,
															style: Theme.of(context).textTheme.bodySmall,
														),
													const SizedBox(height: 4),
													Text(
														'Deleted ${_formatDate(deletedAt!)} • '
														'${daysUntilPermanent}d until permanent',
														style: TextStyle(
															fontSize: 12,
															color: daysUntilPermanent <= 1
																	? Theme.of(context).colorScheme.error
																	: Theme.of(context).colorScheme.outline,
														),
													),
												],
											),
											trailing: PopupMenuButton<String>(
												itemBuilder: (context) => [
													PopupMenuItem(
														value: 'restore',
														child: Row(
															children: [
																Icon(
																	Icons.restore_outlined,
																	size: 20,
																	color: Theme.of(context).colorScheme.primary,
																),
																const SizedBox(width: 8),
																const Text('Restore'),
															],
														),
													),
													PopupMenuItem(
														value: 'delete',
														child: Row(
															children: [
																Icon(
																	Icons.delete_forever,
																	size: 20,
																	color: Theme.of(context).colorScheme.error,
																),
																const SizedBox(width: 8),
																const Text('Delete Permanently'),
															],
														),
													),
												],
												onSelected: (value) {
													if (value == 'restore') {
														_showRestoreConfirmation(context, ref, task);
													} else if (value == 'delete') {
														_showPermanentDeleteConfirmation(context, ref, task);
													}
												},
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
				child: Text('Error loading trash: $error'),
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

	String _formatDate(DateTime dateTime) {
		final difference = DateTime.now().difference(dateTime);
		if (difference.inDays == 0) {
			if (difference.inHours == 0) {
				return '${difference.inMinutes}m ago';
			}
			return '${difference.inHours}h ago';
		}
		return '${difference.inDays}d ago';
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

	void _showBulkRestoreConfirmation(
		BuildContext context,
		WidgetRef ref,
		List<Task> tasks,
	) {
		showDialog(
			context: context,
			builder: (dialogContext) => AlertDialog(
				title: const Text('Restore Selected Tasks'),
				content: Text('Restore ${tasks.length} selected task(s) from trash?'),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(dialogContext),
						child: const Text('Cancel'),
					),
					FilledButton(
						onPressed: () async {
							if (dialogContext.mounted) {
								Navigator.pop(dialogContext);
							}

							var restoredCount = 0;
							for (final task in tasks) {
								try {
									await ref.read(tasksProvider.notifier).restoreTask(task.id);
									restoredCount++;
								} catch (_) {}
							}

							ref.invalidate(trashTasksProvider);
							if (mounted) {
								setState(() {
									_selectedTaskIds.removeAll(tasks.map((task) => task.id));
								});
							}

							if (restoredCount == tasks.length) {
								await _showResultModal(
									isSuccess: true,
									message: '$restoredCount task(s) restored successfully',
								);
							} else if (restoredCount > 0) {
								await _showResultModal(
									isSuccess: false,
									message:
											'Restored $restoredCount of ${tasks.length} selected task(s)',
								);
							} else {
								await _showResultModal(
									isSuccess: false,
									message: 'Failed to restore selected tasks',
								);
							}
						},
						child: const Text('Restore'),
					),
				],
			),
		);
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
			builder: (dialogContext) {
				return Dialog(
					insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
					shape: RoundedRectangleBorder(
						borderRadius: BorderRadius.circular(16),
					),
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
										'Permanently Delete Selected',
										style: Theme.of(dialogContext)
												.textTheme
												.titleLarge
												?.copyWith(fontWeight: FontWeight.bold),
										textAlign: TextAlign.center,
									),
									const SizedBox(height: 12),
									Text(
										'Permanently delete ${tasks.length} selected task(s)?\nThis cannot be undone.',
										style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
													color: Theme.of(dialogContext)
															.colorScheme
															.onSurfaceVariant,
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
														backgroundColor:
																Theme.of(dialogContext).colorScheme.error,
													),
													onPressed: () async {
														if (dialogContext.mounted) {
															Navigator.pop(dialogContext);
														}

														var deletedCount = 0;
														for (final task in tasks) {
															try {
																await ref
																		.read(tasksProvider.notifier)
																		.permanentlyDeleteTask(task.id);
																deletedCount++;
															} catch (_) {}
														}

														ref.invalidate(trashTasksProvider);
														if (mounted) {
															setState(() {
																_selectedTaskIds
																		.removeAll(tasks.map((task) => task.id));
															});
														}

														if (deletedCount == tasks.length) {
															await _showResultModal(
																isSuccess: true,
																message: '$deletedCount task(s) permanently deleted',
															);
														} else if (deletedCount > 0) {
															await _showResultModal(
																isSuccess: false,
																message:
																		'Deleted $deletedCount of ${tasks.length} selected task(s)',
															);
														} else {
															await _showResultModal(
																isSuccess: false,
																message: 'Failed to delete selected tasks',
															);
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

	void _showRestoreConfirmation(
		BuildContext context,
		WidgetRef ref,
		Task task,
	) {
		showDialog(
			context: context,
			builder: (dialogContext) => AlertDialog(
				title: const Text('Restore Task'),
				content: Text('Restore "${task.title}" from trash?'),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(dialogContext),
						child: const Text('Cancel'),
					),
					FilledButton(
						onPressed: () async {
							try {
								await ref.read(tasksProvider.notifier).restoreTask(task.id);
								ref.invalidate(trashTasksProvider);

								if (mounted) {
									setState(() {
										_selectedTaskIds.remove(task.id);
									});
								}

								if (dialogContext.mounted) {
									Navigator.pop(dialogContext);
								}

								await _showResultModal(
									isSuccess: true,
									message: 'Task restored successfully',
								);
							} catch (_) {
								if (dialogContext.mounted) {
									Navigator.pop(dialogContext);
								}

								await _showResultModal(
									isSuccess: false,
									message: 'Failed to restore task',
								);
							}
						},
						child: const Text('Restore'),
					),
				],
			),
		);
	}

	void _showPermanentDeleteConfirmation(
		BuildContext context,
		WidgetRef ref,
		Task task,
	) {
		showDialog(
			context: context,
			builder: (dialogContext) => AlertDialog(
				title: const Text('Permanently Delete'),
				content: Text(
					'This will permanently delete "${task.title}". This cannot be undone.',
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
							try {
								await ref
										.read(tasksProvider.notifier)
										.permanentlyDeleteTask(task.id);
								ref.invalidate(trashTasksProvider);

								if (mounted) {
									setState(() {
										_selectedTaskIds.remove(task.id);
									});
								}

								if (dialogContext.mounted) {
									Navigator.pop(dialogContext);
								}

								await _showResultModal(
									isSuccess: true,
									message: 'Task permanently deleted',
								);
							} catch (_) {
								if (dialogContext.mounted) {
									Navigator.pop(dialogContext);
								}

								await _showResultModal(
									isSuccess: false,
									message: 'Failed to permanently delete task',
								);
							}
						},
						child: const Text('Delete'),
					),
				],
			),
		);
	}
}
