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
	
	// Default values
	static const int defaultNotificationIdOffset = 1000;
	static const String dateFormat = 'MMM dd, yyyy';
	static const String timeFormat = 'hh:mm a';
	static const String dateTimeFormat = 'MMM dd, yyyy hh:mm a';
}
