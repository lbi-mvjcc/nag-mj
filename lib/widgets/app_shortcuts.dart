import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppShortcuts {
	static final Map<LogicalKeySet, Intent> shortcuts = {
		// Ctrl/Cmd + N: New task
		LogicalKeySet(
			LogicalKeyboardKey.control,
			LogicalKeyboardKey.keyN,
		): const NewTaskIntent(),
		LogicalKeySet(
			LogicalKeyboardKey.meta,
			LogicalKeyboardKey.keyN,
		): const NewTaskIntent(),
	};
}

class NewTaskIntent extends Intent {
	const NewTaskIntent();
}
