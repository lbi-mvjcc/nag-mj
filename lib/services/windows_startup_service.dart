import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

class WindowsStartupService {
	WindowsStartupService._internal();

	static final WindowsStartupService _instance =
			WindowsStartupService._internal();

	factory WindowsStartupService() => _instance;

	bool _isAutoStartEnabled = true;

	bool get isAutoStartEnabled => _isAutoStartEnabled;

	Future<void> init({bool defaultEnabled = true}) async {
		if (!Platform.isWindows) return;

		launchAtStartup.setup(
			appName: AppConstants.appName,
			appPath: Platform.resolvedExecutable,
			args: const ['--startup'],
		);

		final prefs = await SharedPreferences.getInstance();
		final savedEnabled = prefs.getBool(AppConstants.windowsAutoStartEnabledKey);
		final targetEnabled = savedEnabled ?? defaultEnabled;

		await _applyAutoStart(targetEnabled);
		await prefs.setBool(AppConstants.windowsAutoStartEnabledKey, targetEnabled);
	}

	Future<void> setAutoStartEnabled(bool enabled) async {
		if (!Platform.isWindows) return;

		await _applyAutoStart(enabled);

		final prefs = await SharedPreferences.getInstance();
		await prefs.setBool(AppConstants.windowsAutoStartEnabledKey, enabled);
	}

	Future<void> _applyAutoStart(bool enabled) async {
		try {
			final currentlyEnabled = await launchAtStartup.isEnabled();
			if (enabled && !currentlyEnabled) {
				await launchAtStartup.enable();
			}
			if (!enabled && currentlyEnabled) {
				await launchAtStartup.disable();
			}
			_isAutoStartEnabled = enabled;
		} catch (e) {
			debugPrint('Windows auto-start update failed: $e');
		}
	}
}
