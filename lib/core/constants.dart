class AppConstants {
	AppConstants._();

	static const String appName = 'NagMJ';
	static const String databaseName = 'nagmj_db';
	
	// Notification channels
	static const String notificationChannelId = 'nagmj_reminders';
	static const String notificationChannelName = 'Task Reminders';
	static const String notificationChannelDescription = 'Notifications for task reminders';
	
	// Storage keys
	static const String themeModeKey = 'theme_mode_key';
	static const String isFirstLaunchKey = 'is_first_launch';
	static const String windowsAutoStartEnabledKey = 'windows_auto_start_enabled';
	static const String windowsReminderSoundEnabledKey = 'windows_reminder_sound_enabled';
	static const String appNameKey = 'app_name';
	static const String appLogoPathKey = 'app_logo_path';
	static const String isTaskGridViewKey = 'is_task_grid_view';
	static const String sidebarColorValueKey = 'sidebar_color_value';
	static const String darkThemeSeedColorValueKey = 'dark_theme_seed_color_value';
	static const String taskManualOrderIdsKey = 'task_manual_order_ids';
	static const String taskReviewIdsKey = 'task_review_ids';

	// Asset paths
	static const String windowsReminderSoundAssetPath = 'sounds/reminder.mp3';
	static const String windowsAlarmSoundAssetPath = 'sounds/alarm.mp3';
	
	// Default values
	static const int defaultNotificationIdOffset = 1000;
	static const String dateFormat = 'MMM dd, yyyy';
	static const String timeFormat = 'hh:mm a';
	static const String dateTimeFormat = 'MMM dd, yyyy hh:mm a';
}
