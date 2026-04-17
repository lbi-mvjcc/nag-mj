import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
	final AudioPlayer _windowsAudioPlayer = AudioPlayer();

	bool _isInitialized = false;
	bool _isWindowsNotifierBootstrapped = false;
	bool _hasBundledWindowsReminderSound = false;
	bool _isWindowsReminderSoundEnabled = true;
	final Map<int, Timer> _windowsNotificationTimers = {};
	static const List<int> _alertOffsetsInMinutes = [10, 5, 3, 0];
	static const Duration _windowsNearDueThreshold = Duration(minutes: 1);

	bool get isWindowsReminderSoundEnabled => _isWindowsReminderSoundEnabled;

	bool get _isNotificationSupported {
		return _isFlutterNotificationSupported || Platform.isWindows;
	}

	bool get _isFlutterNotificationSupported {
		return Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isLinux;
	}

	Future<void> init() async {
		if (_isInitialized) return;
		if (!_isNotificationSupported) {
			_isInitialized = true;
			return;
		}

		if (Platform.isWindows) {
			await _setupWindowsNotifier();
			await _loadWindowsReminderSoundEnabled();
			await _configureWindowsAudioPlayer();
			await _validateBundledWindowsReminderSound();
		}

		if (!_isFlutterNotificationSupported) {
			_isInitialized = true;
			return;
		}

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

	Future<void> setWindowsReminderSoundEnabled(bool enabled) async {
		if (!Platform.isWindows) return;
		_isWindowsReminderSoundEnabled = enabled;
		if (!enabled) {
			await stopWindowsReminderSound();
		}

		final prefs = await SharedPreferences.getInstance();
		await prefs.setBool(
			AppConstants.windowsReminderSoundEnabledKey,
			enabled,
		);
	}

	Future<bool> requestPermissions() async {
		if (Platform.isWindows) return true;
		if (!_isFlutterNotificationSupported) return true;
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
		if (!_isNotificationSupported) return;
		if (!_isInitialized) await init();
		if (task.reminderDateTime == null) return;

		// Cancel existing notification for this task
		await cancelNotification(task);

		final title = 'Task Reminder';
		final body = task.title;

		if (Platform.isWindows) {
			await _scheduleWindowsNotification(task);
			return;
		}

		for (var index = 0; index < _alertOffsetsInMinutes.length; index++) {
			final offset = _alertOffsetsInMinutes[index];
			final notificationId = _notificationIdFor(task.id, index);
			final scheduledDate = task.reminderDateTime!.subtract(
				Duration(minutes: offset),
			);

			if (task.isRecurring && task.recurrenceType != RecurrenceType.none) {
				await _scheduleRecurringNotification(
					task,
					notificationId,
					title,
					body,
					scheduledDate,
					offset,
				);
			} else {
				await _scheduleOneTimeNotification(
					task,
					notificationId,
					title,
					body,
					scheduledDate,
					offset,
				);
			}
		}
	}

	Future<void> _scheduleOneTimeNotification(
		Task task,
		int notificationId,
		String title,
		String body,
		DateTime alertDateTime,
		int offsetMinutes,
	) async {
		final scheduledDate = tz.TZDateTime.from(alertDateTime, tz.local);

		// Don't schedule if the time is in the past
		if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
			print('Skipping notification for past date: $scheduledDate');
			return;
		}

		await _flutterLocalNotificationsPlugin.zonedSchedule(
			notificationId,
			title,
			_withAlertOffsetBody(body, offsetMinutes),
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
			payload: 'task_${task.id}_offset_$offsetMinutes',
		);

		print('Scheduled one-time notification ($offsetMinutes min) for: $scheduledDate');
	}

	Future<void> _scheduleRecurringNotification(
		Task task,
		int notificationId,
		String title,
		String body,
		DateTime alertDateTime,
		int offsetMinutes,
	) async {
		final scheduledDate = tz.TZDateTime.from(alertDateTime, tz.local);

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
					alertDateTime,
					offsetMinutes,
				);
				return;
		}

		await _flutterLocalNotificationsPlugin.zonedSchedule(
			notificationId,
			title,
			_withAlertOffsetBody(body, offsetMinutes),
			scheduledDate,
			notificationDetails,
			androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
			uiLocalNotificationDateInterpretation:
					UILocalNotificationDateInterpretation.absoluteTime,
			matchDateTimeComponents: matchComponents,
			payload: 'task_${task.id}_offset_$offsetMinutes',
		);

		print(
			'Scheduled recurring notification (${task.recurrenceType.name}, $offsetMinutes min) for: $scheduledDate',
		);
	}

	Future<void> cancelNotification(Task task) async {
		_cancelWindowsTimersForTask(task.id);

		if (!_isNotificationSupported) return;
		if (Platform.isWindows) return;

		for (var index = 0; index < _alertOffsetsInMinutes.length; index++) {
			await _flutterLocalNotificationsPlugin.cancel(
				_notificationIdFor(task.id, index),
			);
		}
	}

	Future<void> cancelAllNotifications() async {
		for (final timer in _windowsNotificationTimers.values) {
			timer.cancel();
		}
		_windowsNotificationTimers.clear();

		if (!_isNotificationSupported) return;
		if (Platform.isWindows) return;
		await _flutterLocalNotificationsPlugin.cancelAll();
	}

	Future<void> rescheduleAllNotifications(List<Task> tasks) async {
		if (!_isNotificationSupported) return;
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

	Future<void> _scheduleWindowsNotification(Task task) async {
		final now = DateTime.now();
		final nextTrigger = _getNextTriggerForWindows(task, now);
		if (nextTrigger == null) return;

		_cancelWindowsTimersForTask(task.id);

		for (var index = 0; index < _alertOffsetsInMinutes.length; index++) {
			final offset = _alertOffsetsInMinutes[index];
			final alertTime = nextTrigger.subtract(Duration(minutes: offset));
			final delay = alertTime.difference(now);
			final timerId = _notificationIdFor(task.id, index);

			if (alertTime.isBefore(now.subtract(_windowsNearDueThreshold))) {
				continue;
			}

			if (delay <= _windowsNearDueThreshold) {
				await _showWindowsNotification(task, nextTrigger, offset);
				if (offset == 0 && task.isRecurring && task.recurrenceType != RecurrenceType.none) {
					_scheduleNextRecurringWindowsNotification(task, nextTrigger);
				}
				continue;
			}

			_windowsNotificationTimers[timerId] = Timer(delay, () {
				_windowsNotificationTimers.remove(timerId);
				unawaited(_showWindowsNotification(task, nextTrigger, offset));
				if (offset == 0 && task.isRecurring && task.recurrenceType != RecurrenceType.none) {
					_scheduleNextRecurringWindowsNotification(task, nextTrigger);
				}
			});
		}
	}

	void _cancelWindowsTimersForTask(int taskId) {
		for (var index = 0; index < _alertOffsetsInMinutes.length; index++) {
			final timerId = _notificationIdFor(taskId, index);
			_windowsNotificationTimers.remove(timerId)?.cancel();
		}
	}

	void _scheduleNextRecurringWindowsNotification(Task task, DateTime occurrence) {
		final nextOccurrence = _addRecurrence(
			occurrence,
			task.recurrenceType,
			task.recurrenceInterval,
		);

		if (task.recurrenceEndDate != null) {
			final endOfDay = DateTime(
				task.recurrenceEndDate!.year,
				task.recurrenceEndDate!.month,
				task.recurrenceEndDate!.day,
				23,
				59,
				59,
			);
			if (nextOccurrence.isAfter(endOfDay)) {
				return;
			}
		}

		final tempTask = task.copyWith(reminderDateTime: nextOccurrence);
		unawaited(_scheduleWindowsNotification(tempTask));
	}

	DateTime? _getNextTriggerForWindows(Task task, DateTime now) {
		if (task.reminderDateTime == null) return null;
		var trigger = task.reminderDateTime!;

		if (!task.isRecurring || task.recurrenceType == RecurrenceType.none) {
			return trigger;
		}

		while (trigger.isBefore(now.subtract(_windowsNearDueThreshold))) {
			trigger = _addRecurrence(
				trigger,
				task.recurrenceType,
				task.recurrenceInterval,
			);

			if (task.recurrenceEndDate != null) {
				final endOfDay = DateTime(
					task.recurrenceEndDate!.year,
					task.recurrenceEndDate!.month,
					task.recurrenceEndDate!.day,
					23,
					59,
					59,
				);
				if (trigger.isAfter(endOfDay)) {
					return null;
				}
			}
		}

		return trigger;
	}

	DateTime _addRecurrence(DateTime date, RecurrenceType type, int interval) {
		final safeInterval = interval <= 0 ? 1 : interval;

		switch (type) {
			case RecurrenceType.daily:
				return date.add(Duration(days: safeInterval));
			case RecurrenceType.weekly:
				return date.add(Duration(days: 7 * safeInterval));
			case RecurrenceType.monthly:
				return DateTime(
					date.year,
					date.month + safeInterval,
					date.day,
					date.hour,
					date.minute,
					date.second,
				);
			case RecurrenceType.none:
				return date;
		}
	}

	Future<void> _showWindowsNotification(
		Task task,
		DateTime scheduledFor,
		int offsetMinutes,
	) async {
		if (!Platform.isWindows) return;

		await _setupWindowsNotifier();
		final shouldPlayBundledReminderSound =
				_isWindowsReminderSoundEnabled && _hasBundledWindowsReminderSound;
		final shouldMuteToastSound =
				!_isWindowsReminderSoundEnabled || shouldPlayBundledReminderSound;

		Future<void> showNotification() async {
			final localNotification = LocalNotification(
				title: 'Task Reminder',
				body: '${_withAlertOffsetBody(task.title, offsetMinutes)}\nScheduled: ${scheduledFor.toLocal()}',
				silent: shouldMuteToastSound,
			);
      //para ma off ang sound alarm pag e click ang notification
			localNotification.onClick = () {
				unawaited(stopWindowsReminderSound());
			};
      
			await localNotification.show();
			if (shouldPlayBundledReminderSound) {
				await _playBundledWindowsReminderSound();
			}
		}

		try {
			await showNotification();
		} catch (e) {
			final errorMessage = e.toString();
			if (errorMessage.contains('Not initialized')) {
				// Re-run setup and retry once for hot-restart/late-init cases.
				await _setupWindowsNotifier(force: true);
				try {
					await showNotification();
				} catch (retryError) {
					debugPrint('Windows notification retry failed: $retryError');
				}
				return;
			}
			debugPrint('Windows notification failed: $e');
		}
	}

	Future<void> _setupWindowsNotifier({bool force = false}) async {
		if (!Platform.isWindows) return;
		if (_isWindowsNotifierBootstrapped && !force) return;

		await localNotifier.setup(
			appName: AppConstants.appName,
			shortcutPolicy: ShortcutPolicy.ignore,
		);

		_isWindowsNotifierBootstrapped = true;
	}

	Future<void> _configureWindowsAudioPlayer() async {
		if (!Platform.isWindows) return;
		await _windowsAudioPlayer.setReleaseMode(ReleaseMode.stop);
	}

	Future<void> _loadWindowsReminderSoundEnabled() async {
		if (!Platform.isWindows) return;

		final prefs = await SharedPreferences.getInstance();
		_isWindowsReminderSoundEnabled =
				prefs.getBool(AppConstants.windowsReminderSoundEnabledKey) ?? true;
	}

	Future<void> _validateBundledWindowsReminderSound() async {
		if (!Platform.isWindows) return;

		try {
			await rootBundle.load(
				'assets/${AppConstants.windowsReminderSoundAssetPath}',
			);
			_hasBundledWindowsReminderSound = true;
		} catch (e) {
			_hasBundledWindowsReminderSound = false;
			debugPrint(
				'Bundled reminder sound not found at assets/${AppConstants.windowsReminderSoundAssetPath}: $e',
			);
		}
	}

	Future<void> _playBundledWindowsReminderSound() async {
		if (!Platform.isWindows || !_hasBundledWindowsReminderSound) {
			return;
		}

		try {
			await _windowsAudioPlayer.stop();
			await _windowsAudioPlayer.play(
				AssetSource(AppConstants.windowsReminderSoundAssetPath),
			);
		} catch (e) {
			debugPrint('Bundled Windows reminder sound playback failed: $e');
		}
	}

	Future<void> stopWindowsReminderSound() async {
		if (!Platform.isWindows) return;

		try {
			await _windowsAudioPlayer.stop();
		} catch (e) {
			debugPrint('Bundled Windows reminder sound stop failed: $e');
		}
	}

	int _notificationIdFor(int taskId, int alertIndex) {
		return AppConstants.defaultNotificationIdOffset + (taskId * 10) + alertIndex;
	}

	String _withAlertOffsetBody(String body, int offsetMinutes) {
		if (offsetMinutes == 0) {
			return '$body (Now)';
		}
		return '$body (in $offsetMinutes minutes)';
	}
}
