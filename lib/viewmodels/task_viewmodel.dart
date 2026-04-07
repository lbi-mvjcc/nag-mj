import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../services/isar_service.dart';
import '../services/notification_service.dart';
import '../core/enums.dart';

// Providers
final isarServiceProvider = Provider<IsarService>((ref) {
	return IsarService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
	return NotificationService();
});

final tasksProvider = StateNotifierProvider<TaskViewModel, AsyncValue<List<Task>>>((ref) {
	return TaskViewModel(ref);
});

final filterProvider = StateProvider<TaskFilter>((ref) => TaskFilter.all);
final sortProvider = StateProvider<TaskSortOption>((ref) => TaskSortOption.createdAt);
final searchQueryProvider = StateProvider<String>((ref) => '');
final showOnlyWithRemindersProvider = StateProvider<bool>((ref) => false);
final showOnlyRecurringProvider = StateProvider<bool>((ref) => false);

class TaskViewModel extends StateNotifier<AsyncValue<List<Task>>> {
	final Ref _ref;
	final IsarService _isarService;
	final NotificationService _notificationService;

	TaskViewModel(this._ref)
			: _isarService = IsarService(),
				_notificationService = NotificationService(),
				super(const AsyncValue.loading()) {
		loadTasks();
	}

	Future<void> loadTasks() async {
		try {
			state = const AsyncValue.loading();
			final tasks = await _isarService.getAllTasks();
			state = AsyncValue.data(tasks);
		} catch (e, stackTrace) {
			state = AsyncValue.error(e, stackTrace);
		}
	}

	Future<void> createTask(Task task) async {
		try {
			final id = await _isarService.createTask(task);
			task.id = id;

			// Schedule notification if reminder is set
			if (task.reminderDateTime != null) {
				await _notificationService.scheduleNotification(task);
			}

			await loadTasks();
		} catch (e) {
			rethrow;
		}
	}

	Future<void> updateTask(Task updatedTask) async {
		try {
			// Cancel old notification
			await _notificationService.cancelNotification(updatedTask);

			// Update task in database
			await _isarService.updateTask(updatedTask);

			// Schedule new notification if reminder is set
			if (updatedTask.reminderDateTime != null && !updatedTask.isCompleted) {
				await _notificationService.scheduleNotification(updatedTask);
			}

			await loadTasks();
		} catch (e) {
			rethrow;
		}
	}

	Future<void> deleteTask(int id) async {
		try {
			final task = await _isarService.getTask(id);
			if (task != null) {
				// Cancel notification
				await _notificationService.cancelNotification(task);
				// Delete from database
				await _isarService.deleteTask(id);
				await loadTasks();
			}
		} catch (e) {
			rethrow;
		}
	}

	Future<void> toggleTaskCompletion(int id) async {
		try {
			final task = await _isarService.getTask(id);
			if (task != null) {
				task.isCompleted = !task.isCompleted;
				task.updatedAt = DateTime.now();

				await _isarService.updateTask(task);

				// Cancel notification if completed
				if (task.isCompleted) {
					await _notificationService.cancelNotification(task);
				} else if (task.reminderDateTime != null) {
					// Reschedule if marked as pending again
					await _notificationService.scheduleNotification(task);
				}

				await loadTasks();
			}
		} catch (e) {
			rethrow;
		}
	}

	Future<void> clearCompletedTasks() async {
		try {
			final completedTasks = await _isarService.getAllTasks();
			for (final task in completedTasks.where((t) => t.isCompleted)) {
				await _notificationService.cancelNotification(task);
			}

			await _isarService.clearCompletedTasks();
			await loadTasks();
		} catch (e) {
			rethrow;
		}
	}

	Future<void> importTasks(List<Map<String, dynamic>> taskMaps) async {
		try {
			await _isarService.importTasks(taskMaps);
			await loadTasks();
		} catch (e) {
			rethrow;
		}
	}

	Future<List<Map<String, dynamic>>> exportTasks() async {
		try {
			return await _isarService.exportTasks();
		} catch (e) {
			rethrow;
		}
	}

	List<Task> getFilteredAndSortedTasks(List<Task> tasksValue) {

		final filter = _ref.read(filterProvider);
		final sortOption = _ref.read(sortProvider);
		final searchQuery = _ref.read(searchQueryProvider).toLowerCase();
		final showOnlyWithReminders = _ref.read(showOnlyWithRemindersProvider);
		final showOnlyRecurring = _ref.read(showOnlyRecurringProvider);

		var filtered = tasksValue.where((task) {
			// Apply status filter
			switch (filter) {
				case TaskFilter.completed:
					if (!task.isCompleted) return false;
					break;
				case TaskFilter.pending:
					if (task.isCompleted) return false;
					break;
				case TaskFilter.all:
					break;
			}

			// Apply reminder filter
			if (showOnlyWithReminders && task.reminderDateTime == null) {
				return false;
			}

			// Apply recurring filter
			if (showOnlyRecurring && !task.isRecurring) {
				return false;
			}

			// Apply search filter
			if (searchQuery.isNotEmpty) {
				final titleMatch = task.title.toLowerCase().contains(searchQuery);
				final descMatch = task.description?.toLowerCase().contains(searchQuery) ?? false;
				if (!titleMatch && !descMatch) return false;
			}

			return true;
		}).toList();

		// Apply sorting
		switch (sortOption) {
			case TaskSortOption.createdAt:
				filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
				break;
			case TaskSortOption.reminderDate:
				filtered.sort((a, b) {
					if (a.reminderDateTime == null && b.reminderDateTime == null) return 0;
					if (a.reminderDateTime == null) return 1;
					if (b.reminderDateTime == null) return -1;
					return a.reminderDateTime!.compareTo(b.reminderDateTime!);
				});
				break;
			case TaskSortOption.title:
				filtered.sort((a, b) => a.title.compareTo(b.title));
				break;
		}

		return filtered;
	}

	Future<void> rescheduleAllNotifications() async {
		try {
			final tasks = await _isarService.getAllTasks();
			await _notificationService.rescheduleAllNotifications(tasks);
		} catch (e) {
			print('Error rescheduling notifications: $e');
		}
	}
}
