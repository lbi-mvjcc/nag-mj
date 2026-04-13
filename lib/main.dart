import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'services/desktop_lifecycle_service.dart';
import 'services/isar_service.dart';
import 'services/notification_service.dart';
import 'services/windows_startup_service.dart';
import 'views/main_app_view.dart';

void main(List<String> args) async {
	WidgetsFlutterBinding.ensureInitialized();
	final isStartupLaunch = args.contains('--startup');

	// Initialize desktop window settings
	await _initializeWindow();

	// Initialize services
	final desktopLifecycleService = DesktopLifecycleService();
	final windowsStartupService = WindowsStartupService();
	final isarService = IsarService();
	final notificationService = NotificationService();

	try {
		await windowsStartupService.init();
	} catch (e) {
		debugPrint('Windows startup service init error: $e');
	}

	try {
		await desktopLifecycleService.init();
	} catch (e) {
		debugPrint('Desktop lifecycle init error: $e');
	}

	if (isStartupLaunch && desktopLifecycleService.isTrayReady) {
		await windowManager.setSkipTaskbar(true);
		await windowManager.hide();
	}

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
