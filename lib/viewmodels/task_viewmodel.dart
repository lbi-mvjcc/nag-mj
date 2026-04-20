import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../services/isar_service.dart';
import '../services/notification_service.dart';
import '../core/constants.dart';
import '../core/enums.dart';

// Providers
final isarServiceProvider = Provider<IsarService>((ref) {
  return IsarService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final tasksProvider =
    StateNotifierProvider<TaskViewModel, AsyncValue<List<Task>>>((ref) {
      return TaskViewModel(ref);
    });

final trashTasksProvider = FutureProvider<List<Task>>((ref) {
  final isarService = IsarService();
  return isarService.getTrashTasks();
});

final trashSelectAllTriggerProvider = StateProvider<int>((ref) => 0);
final taskSelectAllTriggerProvider = StateProvider<int>((ref) => 0);

final sidebarIndexProvider = StateProvider<int>((ref) => 0);

final filterProvider = StateProvider<TaskFilter>((ref) => TaskFilter.all);
final sortProvider = StateProvider<TaskSortOption>(
  (ref) => TaskSortOption.createdAt,
);
final searchQueryProvider = StateProvider<String>((ref) => '');
final showOnlyWithRemindersProvider = StateProvider<bool>((ref) => false);
final showOnlyRecurringProvider = StateProvider<bool>((ref) => false);

final reviewTaskIdsProvider =
    StateNotifierProvider<ReviewTaskIdsNotifier, List<int>>((ref) {
      return ReviewTaskIdsNotifier();
    });

class TaskViewModel extends StateNotifier<AsyncValue<List<Task>>> {
  final Ref _ref;
  final IsarService _isarService;
  final NotificationService _notificationService;
  List<int> _manualOrderIds = [];

  TaskViewModel(this._ref)
    : _isarService = IsarService(),
      _notificationService = NotificationService(),
      super(const AsyncValue.loading()) {
    _loadManualOrder();
    loadTasks();
  }

  Future<void> _loadManualOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved =
          prefs.getStringList(AppConstants.taskManualOrderIdsKey) ??
          const <String>[];
      _manualOrderIds = saved
          .map(int.tryParse)
          .whereType<int>()
          .toList(growable: true);
    } catch (_) {
      _manualOrderIds = <int>[];
    }
  }

  Future<void> _saveManualOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        AppConstants.taskManualOrderIdsKey,
        _manualOrderIds.map((id) => id.toString()).toList(),
      );
    } catch (_) {}
  }

  void _normalizeManualOrder(List<Task> tasks) {
    final allIds = tasks.map((t) => t.id).toSet();
    final normalized = _manualOrderIds
        .where(allIds.contains)
        .toList(growable: true);

    for (final task in tasks) {
      if (!normalized.contains(task.id)) {
        normalized.add(task.id);
      }
    }

    _manualOrderIds = normalized;
  }

  Future<void> loadTasks() async {
    try {
      state = const AsyncValue.loading();
      final tasks = await _isarService.getAllTasks();
      _normalizeManualOrder(tasks);
      await _saveManualOrder();
      state = AsyncValue.data(tasks);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> reorderVisibleTasks(List<int> orderedVisibleIds) async {
    final currentTasks = state.value;
    if (currentTasks == null || orderedVisibleIds.isEmpty) return;

    _normalizeManualOrder(currentTasks);

    final visibleSet = orderedVisibleIds.toSet();
    final positions = <int>[];

    for (var i = 0; i < _manualOrderIds.length; i++) {
      if (visibleSet.contains(_manualOrderIds[i])) {
        positions.add(i);
      }
    }

    for (var i = 0; i < positions.length && i < orderedVisibleIds.length; i++) {
      _manualOrderIds[positions[i]] = orderedVisibleIds[i];
    }

    for (final id in orderedVisibleIds) {
      if (!_manualOrderIds.contains(id)) {
        _manualOrderIds.add(id);
      }
    }

    await _saveManualOrder();
    state = AsyncValue.data(List<Task>.from(currentTasks));
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

  Future<void> restoreTask(int id) async {
    try {
      final task = await _isarService.getTask(id);
      if (task != null) {
        // Reschedule notification if it had one
        if (task.reminderDateTime != null && !task.isCompleted) {
          await _notificationService.scheduleNotification(task);
        }
        await _isarService.restoreTask(id);
        await loadTasks();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> permanentlyDeleteTask(int id) async {
    try {
      final task = await _isarService.getTask(id);
      if (task != null) {
        // Cancel notification if it exists
        await _notificationService.cancelNotification(task);
        await _isarService.permanentlyDeleteTask(id);
        await loadTasks();
      }
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
    final now = DateTime.now();

    var filtered = tasksValue.where((task) {
      final isOvertime =
          task.reminderDateTime != null &&
          task.reminderDateTime!.isBefore(now) &&
          !task.isCompleted;

      // Apply status filter
      switch (filter) {
        case TaskFilter.completed:
          if (!task.isCompleted) return false;
          break;
        case TaskFilter.pending:
          if (task.isCompleted || isOvertime) return false;
          break;
        case TaskFilter.overtime:
          if (!isOvertime) return false;
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
        final descMatch =
            task.description?.toLowerCase().contains(searchQuery) ?? false;
        if (!titleMatch && !descMatch) return false;
      }

      return true;
    }).toList();

    // Apply sorting
    switch (sortOption) {
      case TaskSortOption.createdAt:
        _normalizeManualOrder(tasksValue);
        final orderMap = <int, int>{
          for (var i = 0; i < _manualOrderIds.length; i++)
            _manualOrderIds[i]: i,
        };
        filtered.sort((a, b) {
          final indexA = orderMap[a.id] ?? 1 << 30;
          final indexB = orderMap[b.id] ?? 1 << 30;
          if (indexA == indexB) {
            return b.createdAt.compareTo(a.createdAt);
          }
          return indexA.compareTo(indexB);
        });
        break;
      case TaskSortOption.reminderDate:
        filtered.sort((a, b) {
          if (a.reminderDateTime == null && b.reminderDateTime == null) {
            return 0;
          }
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

class ReviewTaskIdsNotifier extends StateNotifier<List<int>> {
  ReviewTaskIdsNotifier() : super(const <int>[]) {
    _loadReviewTaskIds();
  }

  Future<void> _loadReviewTaskIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(AppConstants.taskReviewIdsKey) ??
          const <String>[];
      state = saved.map(int.tryParse).whereType<int>().toList(growable: false);
    } catch (_) {
      state = const <int>[];
    }
  }

  Future<void> _saveReviewTaskIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        AppConstants.taskReviewIdsKey,
        state.map((id) => id.toString()).toList(),
      );
    } catch (_) {}
  }

  Future<void> addTask(int taskId) async {
    if (state.contains(taskId)) return;
    state = [...state, taskId];
    await _saveReviewTaskIds();
  }

  Future<void> removeTask(int taskId) async {
    if (!state.contains(taskId)) return;
    state = state.where((id) => id != taskId).toList(growable: false);
    await _saveReviewTaskIds();
  }

  Future<void> clearAll() async {
    state = const <int>[];
    await _saveReviewTaskIds();
  }
}
