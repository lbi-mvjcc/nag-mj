import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'services/isar_service.dart';
import 'services/notification_service.dart';
import 'views/main_app_view.dart';

void main() async {
	WidgetsFlutterBinding.ensureInitialized();

	// Initialize desktop window settings
	await _initializeWindow();

	// Initialize services
	final isarService = IsarService();
	final notificationService = NotificationService();

	await isarService.init();
	await notificationService.init();

	// Request notification permissions
	await notificationService.requestPermissions();

	// Rehydrate notifications from database
	await notificationService.rescheduleAllNotifications(
		await isarService.getAllTasks(),
	);

	runApp(
		const ProviderScope(
			child: MyApp(),
		),
	);
}

Future<void> _initializeWindow() async {
	await windowManager.ensureInitialized();

	const windowOptions = WindowOptions(
		size: Size(1200, 800),
		minimumSize: Size(800, 600),
		center: true,
		backgroundColor: Colors.transparent,
		skipTaskbar: false,
		titleBarStyle: TitleBarStyle.normal,
		title: 'NagMJ',
	);

	await windowManager.waitUntilReadyToShow(windowOptions, () async {
		await windowManager.show();
		await windowManager.focus();
	});
}

class MyApp extends ConsumerWidget {
	const MyApp({super.key});

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		return const MainAppView();
	}
}
