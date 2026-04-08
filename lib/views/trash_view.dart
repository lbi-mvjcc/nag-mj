import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/task_viewmodel.dart';
import '../models/task.dart';
import '../widgets/task_result_modal.dart';

class TrashView extends ConsumerWidget {
	const TrashView({super.key});

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		final trashTasksAsync = ref.watch(trashTasksProvider);

		return trashTasksAsync.when(
			data: (trashTasks) {
				// Sort by deletion date, newest first
				final sortedTasks = [...trashTasks];
				sortedTasks.sort((a, b) => (b.deletedAt ?? DateTime.now())
					.compareTo(a.deletedAt ?? DateTime.now()));

				if (sortedTasks.isEmpty) {
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

				return ListView.builder(
					padding: const EdgeInsets.all(16),
				itemCount: sortedTasks.length,
				itemBuilder: (context, index) {
					final task = sortedTasks[index];
						final deletedAt = task.deletedAt;
						final daysUntilPermanent = deletedAt != null
							? 10 - DateTime.now().difference(deletedAt).inDays
							: 0;

						return Card(
							margin: const EdgeInsets.only(bottom: 12),
							child: ListTile(
								contentPadding: const EdgeInsets.symmetric(
									horizontal: 16,
									vertical: 12,
								),
								leading: Icon(
									Icons.delete_outline_rounded,
									color: Theme.of(context).colorScheme.error,
								),
								title: Text(
									task.title,
									maxLines: 1,
									overflow: TextOverflow.ellipsis,
									style: TextStyle(
										decoration: TextDecoration.lineThrough,
										color: Theme.of(context).colorScheme.onSurface,
									),
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
								trailing: PopupMenuButton(
									itemBuilder: (context) => [
										PopupMenuItem(
											value: 'restore',
											child: Row(
												children: [
													Icon(
														Icons.restore_outlined,
														size: 20,
														color: Theme.of(context)
															.colorScheme
															.primary,
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
														color: Theme.of(context)
															.colorScheme
															.error,
													),
													const SizedBox(width: 8),
													const Text('Delete Permanently'),
												],
											),
										),
									],
									onSelected: (value) {
										if (value == 'restore') {
											_showRestoreConfirmation(
												context,
												ref,
												task,
											);
										} else if (value == 'delete') {
											_showPermanentDeleteConfirmation(
												context,
												ref,
												task,
											);
										}
									},
								),
							),
						);
					},
				);
			},
			loading: () => const Center(child: CircularProgressIndicator()),
			error: (error, stackTrace) => Center(
				child: Text('Error loading trash: $error'),
			),
		);
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

	void _showRestoreConfirmation(
		BuildContext context,
		WidgetRef ref,
		Task task,
	) {
		showDialog(
			context: context,
			builder: (context) => AlertDialog(
				title: const Text('Restore Task'),
				content: Text('Restore "${task.title}" from trash?'),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(context),
						child: const Text('Cancel'),
					),
					FilledButton(
						onPressed: () async {
							await ref.read(tasksProvider.notifier).restoreTask(task.id);
							ref.invalidate(trashTasksProvider);
							
							if (context.mounted) {
								Navigator.pop(context);
							}

							if (context.mounted) {
								Future.delayed(const Duration(milliseconds: 100), () {
									if (context.mounted) {
										showDialog(
											context: context,
											barrierDismissible: false,
											builder: (context) => const TaskResultModal(
												isSuccess: true,
												message: 'Task restored successfully',
											),
										);
									}
								});
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
			builder: (context) => AlertDialog(
				title: const Text('Permanently Delete'),
				content: Text(
					'This will permanently delete "${task.title}". This cannot be undone.',
				),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(context),
						child: const Text('Cancel'),
					),
					FilledButton(
						onPressed: () async {
							await ref.read(tasksProvider.notifier).permanentlyDeleteTask(task.id);
							ref.invalidate(trashTasksProvider);
							
							if (context.mounted) {
								Navigator.pop(context);
							}

							if (context.mounted) {
								Future.delayed(const Duration(milliseconds: 100), () {
									if (context.mounted) {
										showDialog(
											context: context,
											barrierDismissible: false,
											builder: (context) => const TaskResultModal(
												isSuccess: true,
												message: 'Task permanently deleted',
											),
										);
									}
								});
							}
						},
						style: FilledButton.styleFrom(
							backgroundColor: Theme.of(context).colorScheme.error,
						),
						child: const Text('Delete'),
					),
				],
			),
		);
	}
}
