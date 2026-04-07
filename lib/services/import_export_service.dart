import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../viewmodels/task_viewmodel.dart';
import '../models/task_export.dart';

class ImportExportService {
	static final ImportExportService _instance = ImportExportService._internal();
	factory ImportExportService() => _instance;
	ImportExportService._internal();

	Future<void> exportTasks(BuildContext context, WidgetRef ref) async {
		try {
			final viewModel = ref.read(tasksProvider.notifier);
			final taskMaps = await viewModel.exportTasks();

			final export = TaskExport(tasks: taskMaps);
			final jsonString = const JsonEncoder.withIndent('  ').convert(
				export.toJson(),
			);

			final savePath = await FilePicker.platform.saveFile(
				dialogTitle: 'Export Tasks',
				fileName: 'nagmj_export_${DateTime.now().millisecondsSinceEpoch}.json',
				type: FileType.custom,
				allowedExtensions: ['json'],
			);

			if (savePath != null) {
				final file = File(savePath);
				await file.writeAsString(jsonString);

				if (context.mounted) {
					ScaffoldMessenger.of(context).showSnackBar(
						const SnackBar(
							content: Text('Tasks exported successfully!'),
							backgroundColor: Colors.green,
						),
					);
				}
			}
		} catch (e) {
			if (context.mounted) {
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(
						content: Text('Error exporting tasks: $e'),
						backgroundColor: Colors.red,
					),
				);
			}
		}
	}

	Future<void> importTasks(BuildContext context, WidgetRef ref) async {
		try {
			final result = await FilePicker.platform.pickFiles(
				dialogTitle: 'Import Tasks',
				type: FileType.custom,
				allowedExtensions: ['json'],
			);

			if (result != null && result.files.isNotEmpty) {
				final file = File(result.files.single.path!);
				final jsonString = await file.readAsString();
				final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;

				final export = TaskExport.fromJson(jsonMap);

				final viewModel = ref.read(tasksProvider.notifier);
				await viewModel.importTasks(export.tasks);

				if (context.mounted) {
					ScaffoldMessenger.of(context).showSnackBar(
						SnackBar(
							content: Text('Imported ${export.tasks.length} tasks!'),
							backgroundColor: Colors.green,
						),
					);
				}
			}
		} catch (e) {
			if (context.mounted) {
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(
						content: Text('Error importing tasks: $e'),
						backgroundColor: Colors.red,
					),
				);
			}
		}
	}
}
