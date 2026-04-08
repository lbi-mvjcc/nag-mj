import 'package:isar/isar.dart';
import '../core/enums.dart';

part 'task.g.dart';

@collection
class Task {
	Id id = Isar.autoIncrement;

	@Index(type: IndexType.value)
	late String title;

	String? description;

	late DateTime createdAt;

	late DateTime updatedAt;

	bool isCompleted = false;

	DateTime? reminderDateTime;

	bool isRecurring = false;

	@Enumerated(EnumType.name)
	RecurrenceType recurrenceType = RecurrenceType.none;

	int recurrenceInterval = 1;

	DateTime? recurrenceEndDate;

	int notificationId = 0;

	DateTime? deletedAt;

	Task() {
		createdAt = DateTime.now();
		updatedAt = DateTime.now();
	}

	Task copyWith({
		String? title,
		String? description,
		DateTime? createdAt,
		DateTime? updatedAt,
		bool? isCompleted,
		DateTime? reminderDateTime,
		bool? isRecurring,
		RecurrenceType? recurrenceType,
		int? recurrenceInterval,
		DateTime? recurrenceEndDate,
		int? notificationId,
		DateTime? deletedAt,
	}) {
		return Task()
		..id = id
		..title = title ?? this.title
		..description = description ?? this.description
		..createdAt = createdAt ?? this.createdAt
		..updatedAt = updatedAt ?? this.updatedAt
		..isCompleted = isCompleted ?? this.isCompleted
		..reminderDateTime = reminderDateTime ?? this.reminderDateTime
		..isRecurring = isRecurring ?? this.isRecurring
		..recurrenceType = recurrenceType ?? this.recurrenceType
		..recurrenceInterval = recurrenceInterval ?? this.recurrenceInterval
		..recurrenceEndDate = recurrenceEndDate ?? this.recurrenceEndDate
		..notificationId = notificationId ?? this.notificationId
		..deletedAt = deletedAt ?? this.deletedAt;
	}

	@override
	String toString() {
		return 'Task(id: $id, title: $title, isCompleted: $isCompleted, '
			'reminderDateTime: $reminderDateTime, isRecurring: $isRecurring, '
			'recurrenceType: $recurrenceType)';
	}
}
