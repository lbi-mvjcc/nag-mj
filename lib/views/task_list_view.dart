import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/task_viewmodel.dart';
import '../models/task.dart';
import '../core/enums.dart';
import '../core/extensions.dart';
import '../widgets/task_dialog.dart';

class TaskListView extends ConsumerWidget {
	const TaskListView({super.key});

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		final tasksAsync = ref.watch(tasksProvider);
		final viewModel = ref.read(tasksProvider.notifier);

		return tasksAsync.when(
			data: (tasks) {
				final filteredTasks = viewModel.getFilteredAndSortedTasks();

				if (filteredTasks.isEmpty) {
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

				return ListView.builder(
					padding: const EdgeInsets.all(16),
					itemCount: filteredTasks.length,
					itemBuilder: (context, index) {
						final task = filteredTasks[index];
						return TaskCard(task: task);
					},
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
}

class TaskCard extends ConsumerWidget {
	final Task task;

	const TaskCard({
		super.key,
		required this.task,
	});

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		return Card(
			margin: const EdgeInsets.only(bottom: 12),
			child: InkWell(
				onTap: () {
					showDialog(
						context: context,
						builder: (context) => TaskDialog(task: task),
					);
				},
				borderRadius: BorderRadius.circular(12),
				child: Padding(
					padding: const EdgeInsets.all(16.0),
					child: Row(
						children: [
							// Checkbox
							Checkbox(
								value: task.isCompleted,
								onChanged: (value) {
									ref.read(tasksProvider.notifier).toggleTaskCompletion(task.id);
								},
							),

							const SizedBox(width: 12),

							// Task content
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										// Title
										Text(
											task.title,
											style: Theme.of(context).textTheme.titleMedium?.copyWith(
														decoration: task.isCompleted
																? TextDecoration.lineThrough
																: null,
														color: task.isCompleted
																? Theme.of(context).colorScheme.outline
																: null,
													),
										),

										// Description
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

										// Metadata row
										Padding(
											padding: const EdgeInsets.only(top: 8),
											child: Wrap(
												spacing: 12,
												runSpacing: 4,
												children: [
													// Reminder indicator
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
																	style: Theme.of(context)
																			.textTheme
																			.bodySmall
																			?.copyWith(
																				color: Theme.of(context).colorScheme.primary,
																			),
																),
															],
														),

													// Recurring indicator
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
																	style: Theme.of(context)
																			.textTheme
																			.bodySmall
																			?.copyWith(
																				color: Theme.of(context).colorScheme.secondary,
																			),
																),
															],
														),

													// End date for recurring tasks
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
																	style: Theme.of(context)
																			.textTheme
																			.bodySmall
																			?.copyWith(
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

							// Actions
							PopupMenuButton<String>(
								onSelected: (value) {
									switch (value) {
										case 'edit':
											showDialog(
												context: context,
												builder: (context) => TaskDialog(task: task),
											);
											break;
										case 'delete':
											_showDeleteConfirmation(context, ref, task);
											break;
									}
								},
								itemBuilder: (context) => [
									const PopupMenuItem(
										value: 'edit',
										child: Row(
											children: [
												Icon(Icons.edit_outlined, size: 20),
												SizedBox(width: 8),
												Text('Edit'),
											],
										),
									),
									const PopupMenuItem(
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

	void _showDeleteConfirmation(
		BuildContext context,
		WidgetRef ref,
		Task task,
	) {
		showDialog(
			context: context,
			builder: (context) => AlertDialog(
				title: const Text('Delete Task'),
				content: Text('Are you sure you want to delete "${task.title}"?'),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(context),
						child: const Text('Cancel'),
					),
					FilledButton(
						onPressed: () {
							ref.read(tasksProvider.notifier).deleteTask(task.id);
							Navigator.pop(context);
						},
						style: FilledButton.styleFrom(
							backgroundColor: Colors.red,
						),
						child: const Text('Delete'),
					),
				],
			),
		);
	}
}
