import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

class AppSettings {
  const AppSettings({
    required this.appName,
    required this.logoPath,
    required this.isTaskGridView,
    required this.sidebarColorValue,
    required this.darkThemeSeedColorValue,
  });

  final String appName;
  final String? logoPath;
  final bool isTaskGridView;
  final int sidebarColorValue;
  final int darkThemeSeedColorValue;

  static const String defaultAppName = 'NagMJ';
  static const int defaultSidebarColorValue = 0xFF06402B;
  static const int defaultDarkSeedColorValue = 0xFF06402B;

  Color get sidebarColor => Color(sidebarColorValue);
  Color get darkThemeSeedColor => Color(darkThemeSeedColorValue);

  bool get hasCustomLogoPath {
    if (logoPath == null || logoPath!.trim().isEmpty) {
      return false;
    }

    return File(logoPath!).existsSync();
  }

  AppSettings copyWith({
    String? appName,
    String? logoPath,
    bool clearLogoPath = false,
    bool? isTaskGridView,
    int? sidebarColorValue,
    int? darkThemeSeedColorValue,
  }) {
    return AppSettings(
      appName: appName ?? this.appName,
      logoPath: clearLogoPath ? null : (logoPath ?? this.logoPath),
      isTaskGridView: isTaskGridView ?? this.isTaskGridView,
      sidebarColorValue: sidebarColorValue ?? this.sidebarColorValue,
      darkThemeSeedColorValue:
          darkThemeSeedColorValue ?? this.darkThemeSeedColorValue,
    );
  }

  static const AppSettings defaults = AppSettings(
    appName: defaultAppName,
    logoPath: null,
    isTaskGridView: false,
    sidebarColorValue: defaultSidebarColorValue,
    darkThemeSeedColorValue: defaultDarkSeedColorValue,
  );
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>(
      (ref) => AppSettingsNotifier(),
    );

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(AppSettings.defaults) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString(AppConstants.appNameKey);
      final savedLogo = prefs.getString(AppConstants.appLogoPathKey);
      final isTaskGridView =
          prefs.getBool(AppConstants.isTaskGridViewKey) ?? false;
      final sidebarColor =
          prefs.getInt(AppConstants.sidebarColorValueKey) ??
          AppSettings.defaultSidebarColorValue;
      final darkSeedColor =
          prefs.getInt(AppConstants.darkThemeSeedColorValueKey) ??
          AppSettings.defaultDarkSeedColorValue;

      state = state.copyWith(
        appName: (savedName == null || savedName.trim().isEmpty)
            ? AppSettings.defaultAppName
            : savedName.trim(),
        logoPath: (savedLogo == null || savedLogo.trim().isEmpty)
            ? null
            : savedLogo.trim(),
        isTaskGridView: isTaskGridView,
        sidebarColorValue: sidebarColor,
        darkThemeSeedColorValue: darkSeedColor,
      );
    } catch (e) {
      debugPrint('Error loading app settings: $e');
    }
  }

  Future<void> setAppName(String name) async {
    final trimmed = name.trim();
    final safeName = trimmed.isEmpty ? AppSettings.defaultAppName : trimmed;

    state = state.copyWith(appName: safeName);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.appNameKey, safeName);
    } catch (e) {
      debugPrint('Error saving app name: $e');
    }
  }

  Future<void> setLogoPath(String? path) async {
    final normalized = path?.trim();

    state = state.copyWith(
      logoPath: normalized,
      clearLogoPath: normalized == null || normalized.isEmpty,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      if (normalized == null || normalized.isEmpty) {
        await prefs.remove(AppConstants.appLogoPathKey);
        return;
      }

      await prefs.setString(AppConstants.appLogoPathKey, normalized);
    } catch (e) {
      debugPrint('Error saving app logo path: $e');
    }
  }

  Future<void> setTaskGridView(bool isGrid) async {
    state = state.copyWith(isTaskGridView: isGrid);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.isTaskGridViewKey, isGrid);
    } catch (e) {
      debugPrint('Error saving task layout setting: $e');
    }
  }

  Future<void> setSidebarColor(Color color, {bool persist = true}) async {
    state = state.copyWith(sidebarColorValue: color.toARGB32());

    if (!persist) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(AppConstants.sidebarColorValueKey, color.toARGB32());
    } catch (e) {
      debugPrint('Error saving sidebar color: $e');
    }
  }

  Future<void> setDarkThemeSeedColor(Color color, {bool persist = true}) async {
    state = state.copyWith(darkThemeSeedColorValue: color.toARGB32());

    if (!persist) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        AppConstants.darkThemeSeedColorValueKey,
        color.toARGB32(),
      );
    } catch (e) {
      debugPrint('Error saving dark mode color: $e');
    }
  }
}
