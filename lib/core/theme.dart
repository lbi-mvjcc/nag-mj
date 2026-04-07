import 'package:flutter/material.dart';

class AppTheme {
	AppTheme._();

	static ThemeData get lightTheme {
		return ThemeData(
			useMaterial3: true,
			brightness: Brightness.light,
			colorScheme: ColorScheme.fromSeed(
				seedColor: const Color(0xFF06402B),
				brightness: Brightness.light,
			),
			appBarTheme: const AppBarTheme(
				centerTitle: false,
				elevation: 0,
			),
			cardTheme: CardThemeData(
				elevation: 0,
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.circular(12),
				),
			),
			inputDecorationTheme: InputDecorationTheme(
				border: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
				),
				filled: true,
			),
			floatingActionButtonTheme: const FloatingActionButtonThemeData(
				elevation: 2,
			),
		);
	}

	static ThemeData get darkTheme {
		return ThemeData(
			useMaterial3: true,
			brightness: Brightness.dark,
			colorScheme: ColorScheme.fromSeed(
				seedColor: const Color(0xFF06402B),
				brightness: Brightness.dark,
			),
			appBarTheme: const AppBarTheme(
				centerTitle: false,
				elevation: 0,
			),
			cardTheme: CardThemeData(
				elevation: 0,
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.circular(12),
				),
			),
			inputDecorationTheme: InputDecorationTheme(
				border: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
				),
				filled: true,
			),
			floatingActionButtonTheme: const FloatingActionButtonThemeData(
				elevation: 2,
			),
		);
	}
}
