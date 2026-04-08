import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/task.dart';
import '../core/enums.dart';

class IsarService {
	static final IsarService _instance = IsarService._internal();
	factory IsarService() => _instance;
	IsarService._internal();

	late Isar _isar;

	Isar get isar => _isar;

	Future<void> init() async {
		final dir = await getApplicationDocumentsDirectory();
		_isar = await Isar.open(
			[TaskSchema],
			directory: dir.path,
			name: 'taskmate_db',
		);
	}

	Future<void> close() async {
		if (_isar.isOpen) {
			await _isar.close();
		}
	}

	// CRUD Operations
	
	Future<List<Task>> getAllTasks() async {
		// Exclude deleted tasks and clean up old deleted tasks
		await _cleanupExpiredDeletedTasks();
		return await _isar.tasks
			.where()
			.filter()
			.deletedAtIsNull()
			.sortByCreatedAtDesc()
			.findAll();
	}

	Future<Task?> getTask(int id) async {
		return await _isar.tasks.get(id);
	}

	Future<List<Task>> getPendingTasks() async {
		return await _isar.tasks
				.where()
				.filter()
				.isCompletedEqualTo(false)
				.build()
				.findAll();
	}

	Future<List<Task>> getTasksWithReminders() async {
		final allTasks = await getAllTasks();
		return allTasks.where((task) => task.reminderDateTime != null).toList();
	}

	Future<List<Task>> getRecurringTasks() async {
		final allTasks = await getAllTasks();
		return allTasks.where((task) => task.isRecurring).toList();
	}

	Future<List<Task>> searchTasks(String query) async {
		final allTasks = await getAllTasks();
		final lowerQuery = query.toLowerCase();
		return allTasks.where((task) {
			final titleMatch = task.title.toLowerCase().contains(lowerQuery);
			final descMatch = task.description?.toLowerCase().contains(lowerQuery) ?? false;
			return titleMatch || descMatch;
		}).toList();
	}

	Future<int> createTask(Task task) async {
		return await _isar.writeTxn(() async {
			return await _isar.tasks.put(task);
		});
	}

	Future<bool> updateTask(Task task) async {
		return await _isar.writeTxn(() async {
			task.updatedAt = DateTime.now();
			final id = await _isar.tasks.put(task);
			return id > 0;
		});
	}

	Future<bool> deleteTask(int id) async {
		return await _isar.writeTxn(() async {
			final task = await _isar.tasks.get(id);
			if (task == null) return false;
			task.deletedAt = DateTime.now();
			task.updatedAt = DateTime.now();
			await _isar.tasks.put(task);
			return true;
		});
	}

	// Trash operations
	Future<List<Task>> getTrashTasks() async {
		await _cleanupExpiredDeletedTasks();
		return await _isar.tasks
			.where()
			.filter()
			.deletedAtIsNotNull()
			.sortByDeletedAtDesc()
			.findAll();
	}

	Future<bool> restoreTask(int id) async {
		return await _isar.writeTxn(() async {
			final task = await _isar.tasks.get(id);
			if (task == null) return false;
			task.deletedAt = null;
			task.updatedAt = DateTime.now();
			await _isar.tasks.put(task);
			return true;
		});
	}

	Future<bool> permanentlyDeleteTask(int id) async {
		return await _isar.writeTxn(() async {
			return await _isar.tasks.delete(id);
		});
	}

	Future<void> _cleanupExpiredDeletedTasks() async {
		final tenDaysAgo = DateTime.now().subtract(const Duration(days: 10));
		final expiredTasks = await _isar.tasks
			.where()
			.filter()
			.deletedAtIsNotNull()
			.and()
			.deletedAtLessThan(tenDaysAgo)
			.findAll();

		if (expiredTasks.isNotEmpty) {
			await _isar.writeTxn(() async {
				final ids = expiredTasks.map((task) => task.id).toList();
				await _isar.tasks.deleteAll(ids);
			});
		}
	}

	Future<bool> toggleTaskCompletion(int id) async {
		return await _isar.writeTxn(() async {
			final task = await _isar.tasks.get(id);
			if (task == null) return false;
			task.isCompleted = !task.isCompleted;
			task.updatedAt = DateTime.now();
			await _isar.tasks.put(task);
			return true;
		});
	}

	Future<void> clearCompletedTasks() async {
		await _isar.writeTxn(() async {
			final completedTasks = await _isar.tasks
				.where()
				.filter()
				.isCompletedEqualTo(true)
				.and()
				.deletedAtIsNull()
				.findAll();
			final now = DateTime.now();
			for (final task in completedTasks) {
				task.deletedAt = now;
				task.updatedAt = now;
				await _isar.tasks.put(task);
			}
		});
	}

	// Export all tasks
	Future<List<Map<String, dynamic>>> exportTasks() async {
		final tasks = await getAllTasks();
		return tasks.map((task) => _taskToMap(task)).toList();
	}

	// Import tasks
	Future<void> importTasks(List<Map<String, dynamic>> taskMaps) async {
		await _isar.writeTxn(() async {
			for (final taskMap in taskMaps) {
				final task = _mapToTask(taskMap);
				await _isar.tasks.put(task);
			}
		});
	}

	Map<String, dynamic> _taskToMap(Task task) {
		return {
			'title': task.title,
			'description': task.description,
			'createdAt': task.createdAt.toIso8601String(),
			'updatedAt': task.updatedAt.toIso8601String(),
			'isCompleted': task.isCompleted,
			'reminderDateTime': task.reminderDateTime?.toIso8601String(),
			'isRecurring': task.isRecurring,
			'recurrenceType': task.recurrenceType.name,
			'recurrenceInterval': task.recurrenceInterval,
			'recurrenceEndDate': task.recurrenceEndDate?.toIso8601String(),
		};
	}

	Task _mapToTask(Map<String, dynamic> map) {
		final task = Task()
			..title = map['title'] as String
			..description = map['description'] as String?
			..createdAt = DateTime.parse(map['createdAt'] as String)
			..updatedAt = DateTime.parse(map['updatedAt'] as String)
			..isCompleted = map['isCompleted'] as bool? ?? false
			..isRecurring = map['isRecurring'] as bool? ?? false
			..recurrenceInterval = map['recurrenceInterval'] as int? ?? 1;

		if (map['reminderDateTime'] != null) {
			task.reminderDateTime = DateTime.parse(map['reminderDateTime'] as String);
		}

		if (map['recurrenceType'] != null) {
			task.recurrenceType = _parseRecurrenceType(map['recurrenceType'] as String);
		}

		if (map['recurrenceEndDate'] != null) {
			task.recurrenceEndDate = DateTime.parse(map['recurrenceEndDate'] as String);
		}

		return task;
	}

	RecurrenceType _parseRecurrenceType(String type) {
		switch (type.toLowerCase()) {
			case 'daily':
				return RecurrenceType.daily;
			case 'weekly':
				return RecurrenceType.weekly;
			case 'monthly':
				return RecurrenceType.monthly;
			default:
				return RecurrenceType.none;
		}
	}
}
