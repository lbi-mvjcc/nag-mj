import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

// Theme mode provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
	(ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
	ThemeModeNotifier() : super(ThemeMode.system) {
		_loadThemeMode();
	}

	Future<void> _loadThemeMode() async {
		try {
			final prefs = await SharedPreferences.getInstance();
			final modeIndex = prefs.getInt(AppConstants.themeModeKey);
			if (modeIndex != null) {
				state = ThemeMode.values[modeIndex];
			}
		} catch (e) {
			print('Error loading theme mode: $e');
		}
	}

	Future<void> setThemeMode(ThemeMode mode) async {
		try {
			final prefs = await SharedPreferences.getInstance();
			await prefs.setInt(AppConstants.themeModeKey, mode.index);
			state = mode;
		} catch (e) {
			print('Error saving theme mode: $e');
		}
	}

	Future<void> toggleTheme() async {
		final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
		await setThemeMode(newMode);
	}
}
