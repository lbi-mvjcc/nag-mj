import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppShortcuts {
	static const Map<ShortcutActivator, Intent> shortcuts = {
		SingleActivator(LogicalKeyboardKey.keyN, control: true): NewTaskIntent(),
		SingleActivator(LogicalKeyboardKey.keyN, meta: true): NewTaskIntent(),
		SingleActivator(LogicalKeyboardKey.keyF, control: true): FocusSearchIntent(),
		SingleActivator(LogicalKeyboardKey.keyF, meta: true): FocusSearchIntent(),
		SingleActivator(LogicalKeyboardKey.keyE, control: true): ExportTasksIntent(),
		SingleActivator(LogicalKeyboardKey.keyE, meta: true): ExportTasksIntent(),
		SingleActivator(LogicalKeyboardKey.keyI, control: true): ImportTasksIntent(),
		SingleActivator(LogicalKeyboardKey.keyI, meta: true): ImportTasksIntent(),
		SingleActivator(LogicalKeyboardKey.keyD, control: true): ToggleThemeIntent(),
		SingleActivator(LogicalKeyboardKey.keyD, meta: true): ToggleThemeIntent(),
	};

	static AppShortcutAction? resolveKeyEvent(KeyEvent event) {
		if (event is! KeyDownEvent) return null;

		final isShortcutModifierPressed =
				HardwareKeyboard.instance.isControlPressed ||
				HardwareKeyboard.instance.isMetaPressed;

		if (!isShortcutModifierPressed) return null;

		switch (event.logicalKey) {
			case LogicalKeyboardKey.keyN:
				return AppShortcutAction.newTask;
			case LogicalKeyboardKey.keyF:
				return AppShortcutAction.focusSearch;
			case LogicalKeyboardKey.keyE:
				return AppShortcutAction.exportTasks;
			case LogicalKeyboardKey.keyI:
				return AppShortcutAction.importTasks;
			case LogicalKeyboardKey.keyD:
				return AppShortcutAction.toggleTheme;
			default:
				return null;
		}
	}
}

enum AppShortcutAction {
	newTask,
	focusSearch,
	exportTasks,
	importTasks,
	toggleTheme,
}

class NewTaskIntent extends Intent {
	const NewTaskIntent();
}

class FocusSearchIntent extends Intent {
	const FocusSearchIntent();
}

class ExportTasksIntent extends Intent {
	const ExportTasksIntent();
}

class ImportTasksIntent extends Intent {
	const ImportTasksIntent();
}

class ToggleThemeIntent extends Intent {
	const ToggleThemeIntent();
}
