import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/task.dart';
import '../core/constants.dart';
import '../core/enums.dart';

class NotificationService {
	static final NotificationService _instance = NotificationService._internal();
	factory NotificationService() => _instance;
	NotificationService._internal();

	final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
			FlutterLocalNotificationsPlugin();

	bool _isInitialized = false;

	Future<void> init() async {
		if (_isInitialized) return;

		// Initialize timezone data
		tz.initializeTimeZones();

		const androidSettings =
				AndroidInitializationSettings('@mipmap/ic_launcher');

		const darwinSettings = DarwinInitializationSettings(
			requestAlertPermission: true,
			requestBadgePermission: true,
			requestSoundPermission: true,
		);

		const initializationSettings = InitializationSettings(
			android: androidSettings,
			macOS: darwinSettings,
		);

		await _flutterLocalNotificationsPlugin.initialize(
			initializationSettings,
			onDidReceiveNotificationResponse: _onNotificationTapped,
		);

		_isInitialized = true;
	}

	Future<bool> requestPermissions() async {
		if (!_isInitialized) await init();

		final result = await _flutterLocalNotificationsPlugin
				.resolvePlatformSpecificImplementation<
						MacOSFlutterLocalNotificationsPlugin>()
				?.requestPermissions(
					alert: true,
					badge: true,
					sound: true,
				);

		return result ?? true;
	}

	static void _onNotificationTapped(NotificationResponse response) {
		// Handle notification tap - can be used to navigate to specific task
		print('Notification tapped: ${response.payload}');
	}

	Future<void> scheduleNotification(Task task) async {
		if (!_isInitialized) await init();
		if (task.reminderDateTime == null) return;

		// Cancel existing notification for this task
		await cancelNotification(task);

		final notificationId =
				AppConstants.defaultNotificationIdOffset + task.id;

		final title = 'Task Reminder';
		final body = task.title;

		if (task.isRecurring && task.recurrenceType != RecurrenceType.none) {
			await _scheduleRecurringNotification(
				task,
				notificationId,
				title,
				body,
			);
		} else {
			await _scheduleOneTimeNotification(
				task,
				notificationId,
				title,
				body,
			);
		}
	}

	Future<void> _scheduleOneTimeNotification(
		Task task,
		int notificationId,
		String title,
		String body,
	) async {
		final scheduledDate = tz.TZDateTime.from(
			task.reminderDateTime!,
			tz.local,
		);

		// Don't schedule if the time is in the past
		if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
			print('Skipping notification for past date: $scheduledDate');
			return;
		}

		await _flutterLocalNotificationsPlugin.zonedSchedule(
			notificationId,
			title,
			body,
			scheduledDate,
			const NotificationDetails(
				macOS: DarwinNotificationDetails(
					presentAlert: true,
					presentBadge: true,
					presentSound: true,
				),
			),
			androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
			uiLocalNotificationDateInterpretation:
					UILocalNotificationDateInterpretation.absoluteTime,
			matchDateTimeComponents: DateTimeComponents.dateAndTime,
			payload: 'task_${task.id}',
		);

		print('Scheduled one-time notification for: $scheduledDate');
	}

	Future<void> _scheduleRecurringNotification(
		Task task,
		int notificationId,
		String title,
		String body,
	) async {
		final scheduledDate = tz.TZDateTime.from(
			task.reminderDateTime!,
			tz.local,
		);

		// Don't schedule if the time is in the past and past end date
		if (task.recurrenceEndDate != null &&
				scheduledDate.isAfter(
					tz.TZDateTime.from(task.recurrenceEndDate!, tz.local),
				)) {
			print('Skipping recurring notification - past end date');
			return;
		}

		NotificationDetails notificationDetails;
		DateTimeComponents matchComponents;

		switch (task.recurrenceType) {
			case RecurrenceType.daily:
				notificationDetails = const NotificationDetails(
					macOS: DarwinNotificationDetails(
						presentAlert: true,
						presentBadge: true,
						presentSound: true,
					),
				);
				matchComponents = DateTimeComponents.time;
				break;

			case RecurrenceType.weekly:
				notificationDetails = const NotificationDetails(
					macOS: DarwinNotificationDetails(
						presentAlert: true,
						presentBadge: true,
						presentSound: true,
					),
				);
				matchComponents = DateTimeComponents.dayOfWeekAndTime;
				break;

			case RecurrenceType.monthly:
				notificationDetails = const NotificationDetails(
					macOS: DarwinNotificationDetails(
						presentAlert: true,
						presentBadge: true,
						presentSound: true,
					),
				);
				matchComponents = DateTimeComponents.dayOfMonthAndTime;
				break;

			default:
				// Fallback to one-time
				await _scheduleOneTimeNotification(
					task,
					notificationId,
					title,
					body,
				);
				return;
		}

		await _flutterLocalNotificationsPlugin.zonedSchedule(
			notificationId,
			title,
			body,
			scheduledDate,
			notificationDetails,
			androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
			uiLocalNotificationDateInterpretation:
					UILocalNotificationDateInterpretation.absoluteTime,
			matchDateTimeComponents: matchComponents,
			payload: 'task_${task.id}',
		);

		print('Scheduled recurring notification (${task.recurrenceType.name}) for: $scheduledDate');
	}

	Future<void> cancelNotification(Task task) async {
		final notificationId =
				AppConstants.defaultNotificationIdOffset + task.id;
		await _flutterLocalNotificationsPlugin.cancel(notificationId);
	}

	Future<void> cancelAllNotifications() async {
		await _flutterLocalNotificationsPlugin.cancelAll();
	}

	Future<void> rescheduleAllNotifications(List<Task> tasks) async {
		final pendingTasks = tasks
				.where(
					(task) =>
							task.reminderDateTime != null && !task.isCompleted,
				)
				.toList();

		for (final task in pendingTasks) {
			await scheduleNotification(task);
		}
	}
}
