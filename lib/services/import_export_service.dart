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
			final csvString = '\uFEFF${_buildTasksCsv(taskMaps)}';

			final savePath = await FilePicker.platform.saveFile(
				dialogTitle: 'Export Tasks',
				fileName: 'nagmj_export_${DateTime.now().millisecondsSinceEpoch}.csv',
				type: FileType.custom,
				allowedExtensions: ['csv'],
			);

			if (savePath != null) {
				final normalizedSavePath =
					savePath.toLowerCase().endsWith('.csv') ? savePath : '$savePath.csv';
				final file = File(normalizedSavePath);
				await file.writeAsString(csvString);

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

	String _buildTasksCsv(List<Map<String, dynamic>> taskMaps) {
		const headers = [
			'title',
			'description',
			'createdAt',
			'updatedAt',
			'isCompleted',
			'reminderDateTime',
			'isRecurring',
			'recurrenceType',
			'recurrenceInterval',
			'recurrenceEndDate',
		];

		final buffer = StringBuffer();
		buffer.writeln(headers.join(','));

		for (final task in taskMaps) {
			final row = headers
				.map((header) => _escapeCsvValue(task[header]))
				.join(',');
			buffer.writeln(row);
		}

		return buffer.toString();
	}

	String _escapeCsvValue(dynamic value) {
		if (value == null) {
			return '';
		}

		final text = value.toString();
		final escaped = text.replaceAll('"', '""');
		return '"$escaped"';
	}

	Future<void> importTasks(BuildContext context, WidgetRef ref) async {
		try {
			final result = await FilePicker.platform.pickFiles(
				dialogTitle: 'Import Tasks',
				type: FileType.custom,
				allowedExtensions: ['json', 'csv'],
			);

			if (result != null && result.files.isNotEmpty) {
				final file = File(result.files.single.path!);
				final content = await file.readAsString();
				final extension = result.files.single.extension?.toLowerCase();

				late List<Map<String, dynamic>> taskMaps;
				if (extension == 'csv') {
					taskMaps = _parseCsvTasks(content);
				} else {
					final jsonMap = jsonDecode(content) as Map<String, dynamic>;
					final export = TaskExport.fromJson(jsonMap);
					taskMaps = export.tasks;
				}

				final viewModel = ref.read(tasksProvider.notifier);
				await viewModel.importTasks(taskMaps);

				if (context.mounted) {
					ScaffoldMessenger.of(context).showSnackBar(
						SnackBar(
							content: Text('Imported ${taskMaps.length} tasks!'),
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

	List<Map<String, dynamic>> _parseCsvTasks(String csvContent) {
		final rows = _parseCsvRows(csvContent);
		if (rows.isEmpty) {
			return [];
		}

		final headers = rows.first;
		final tasks = <Map<String, dynamic>>[];

		for (var i = 1; i < rows.length; i++) {
			final row = rows[i];
			if (row.every((value) => value.trim().isEmpty)) {
				continue;
			}

			final task = <String, dynamic>{};
			for (var j = 0; j < headers.length; j++) {
				final header = headers[j];
				final value = j < row.length ? row[j] : '';
				task[header] = _coerceTaskFieldValue(header, value);
			}
			tasks.add(task);
		}

		return tasks;
	}

	List<List<String>> _parseCsvRows(String content) {
		final rows = <List<String>>[];
		var row = <String>[];
		final field = StringBuffer();
		var inQuotes = false;

		for (var i = 0; i < content.length; i++) {
			final char = content[i];

			if (char == '"') {
				if (inQuotes && i + 1 < content.length && content[i + 1] == '"') {
					field.write('"');
					i++;
				} else {
					inQuotes = !inQuotes;
				}
				continue;
			}

			if (!inQuotes && char == ',') {
				row.add(field.toString());
				field.clear();
				continue;
			}

			if (!inQuotes && (char == '\n' || char == '\r')) {
				if (char == '\r' && i + 1 < content.length && content[i + 1] == '\n') {
					i++;
				}

				row.add(field.toString());
				field.clear();
				rows.add(row);
				row = <String>[];
				continue;
			}

			field.write(char);
		}

		if (field.isNotEmpty || row.isNotEmpty) {
			row.add(field.toString());
			rows.add(row);
		}

		return rows;
	}

	dynamic _coerceTaskFieldValue(String field, String rawValue) {
		final value = rawValue.trim();
		if (value.isEmpty) {
			return null;
		}

		switch (field) {
			case 'isCompleted':
			case 'isRecurring':
				return value.toLowerCase() == 'true';
			case 'recurrenceInterval':
				return int.tryParse(value) ?? 1;
			default:
				return value;
		}
	}
}
