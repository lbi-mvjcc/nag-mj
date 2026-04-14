import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

import '../core/constants.dart';

class DesktopLifecycleService with WindowListener {
	DesktopLifecycleService._internal();

	static final DesktopLifecycleService _instance =
			DesktopLifecycleService._internal();

	factory DesktopLifecycleService() => _instance;

	final SystemTray _systemTray = SystemTray();
	final Menu _trayMenu = Menu();

	bool _isInitialized = false;
	bool _isQuitting = false;
	bool _isTrayReady = false;

	bool get isTrayReady => _isTrayReady;

	Future<void> init() async {
		if (!Platform.isWindows || _isInitialized) return;

		try {
			await _initSystemTray();
			_isTrayReady = true;
		} catch (e, stackTrace) {
			debugPrint('System tray init failed: $e');
			debugPrint('$stackTrace');
		}

		if (_isTrayReady) {
			await windowManager.setPreventClose(true);
			windowManager.addListener(this);
		}

		_isInitialized = true;
	}

	Future<void> _initSystemTray() async {
		final iconPath = _resolveTrayIconPath();

		await _systemTray.initSystemTray(
			iconPath: iconPath,
			toolTip: AppConstants.appName,
		);

		await _trayMenu.buildFrom([
			MenuItemLabel(
				label: 'Show NagMJ',
				onClicked: (_) {
					unawaited(_showWindow());
				},
			),
			MenuItemLabel(
				label: 'Hide',
				onClicked: (_) {
					unawaited(_hideWindow());
				},
			),
			MenuSeparator(),
			MenuItemLabel(
				label: 'Quit',
				onClicked: (_) {
					unawaited(_quitApplication());
				},
			),
		]);

		await _systemTray.setContextMenu(_trayMenu);

		_systemTray.registerSystemTrayEventHandler((eventName) {
			if (eventName == kSystemTrayEventRightClick) {
				unawaited(_systemTray.popUpContextMenu());
				return;
			}

			if (eventName == kSystemTrayEventClick ||
					eventName == kSystemTrayEventDoubleClick) {
				unawaited(_toggleWindowVisibility());
			}
		});
	}

	String _resolveTrayIconPath() {
		final executableDir = File(Platform.resolvedExecutable).parent.path;
		final candidatePaths = [
			'$executableDir/data/flutter_assets/windows/runner/resources/app_icon.ico',
			'$executableDir/app_icon.ico',
			'windows/runner/resources/app_icon.ico',
		];

		for (final path in candidatePaths) {
			final iconFile = File(path);
			if (iconFile.existsSync()) {
				return iconFile.absolute.path;
			}
		}

		throw StateError('No tray icon file found in expected locations.');
	}

	Future<void> _toggleWindowVisibility() async {
		final isVisible = await windowManager.isVisible();
		if (isVisible) {
			await _hideWindow();
			return;
		}

		await _showWindow();
	}

	Future<void> _showWindow() async {
		await windowManager.setSkipTaskbar(false);
		await windowManager.show();
		await windowManager.focus();
	}

	Future<void> _hideWindow() async {
		await windowManager.setSkipTaskbar(true);
		await windowManager.hide();
	}

	Future<void> _quitApplication() async {
		_isQuitting = true;
		await windowManager.setPreventClose(false);
		await windowManager.destroy();
	}

	@override
	void onWindowClose() {
		if (!Platform.isWindows || _isQuitting || !_isTrayReady) return;
		unawaited(_hideWindow());
	}
}
