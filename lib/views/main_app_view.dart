import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/task_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import '../core/enums.dart';
import '../views/task_list_view.dart';
import '../widgets/task_dialog.dart';
import '../services/import_export_service.dart';

class MainAppView extends ConsumerWidget {
	const MainAppView({super.key});

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		final themeMode = ref.watch(themeModeProvider);
		
		return MaterialApp(
			title: 'NagMJ',
			debugShowCheckedModeBanner: false,
			theme: ThemeData(
				useMaterial3: true,
				brightness: Brightness.light,
				colorScheme: ColorScheme.fromSeed(
					seedColor: const Color(0xFF6366F1),
					brightness: Brightness.light,
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
			),
			darkTheme: ThemeData(
				useMaterial3: true,
				brightness: Brightness.dark,
				colorScheme: ColorScheme.fromSeed(
					seedColor: const Color(0xFF6366F1),
					brightness: Brightness.dark,
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
			),
			themeMode: themeMode,
			home: const MainLayout(),
		);
	}
}

class MainLayout extends ConsumerStatefulWidget {
	const MainLayout({super.key});

	@override
	ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
	int _selectedIndex = 0;

	final List<String> _navItems = const [
		'All Tasks',
		'With Reminders',
		'Recurring',
	];

	void _onNavItemChanged(int index) {
		setState(() {
			_selectedIndex = index;
		});

		// Update filters based on selection
		switch (index) {
			case 0:
				ref.read(filterProvider.notifier).state = TaskFilter.all;
				ref.read(showOnlyWithRemindersProvider.notifier).state = false;
				ref.read(showOnlyRecurringProvider.notifier).state = false;
				break;
			case 1:
				ref.read(filterProvider.notifier).state = TaskFilter.all;
				ref.read(showOnlyWithRemindersProvider.notifier).state = true;
				ref.read(showOnlyRecurringProvider.notifier).state = false;
				break;
			case 2:
				ref.read(filterProvider.notifier).state = TaskFilter.all;
				ref.read(showOnlyWithRemindersProvider.notifier).state = false;
				ref.read(showOnlyRecurringProvider.notifier).state = true;
				break;
		}
	}

	void _showCreateTaskDialog() {
		showDialog(
			context: context,
			builder: (context) => const TaskDialog(),
		);
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			body: Row(
				children: [
					// Sidebar
					Container(
						width: 250,
						decoration: BoxDecoration(
							color: Theme.of(context).colorScheme.surfaceContainerLow,
							border: Border(
								right: BorderSide(
									color: Theme.of(context).colorScheme.outlineVariant,
									width: 1,
								),
							),
						),
						child: Column(
							children: [
								// App title
								Padding(
									padding: const EdgeInsets.all(20.0),
									child: Row(
										children: [
											Icon(
												Icons.task_alt,
												size: 28,
												color: Theme.of(context).colorScheme.primary,
											),
											const SizedBox(width: 12),
											Text(
												'NagMJ',
												style: Theme.of(context).textTheme.headlineSmall?.copyWith(
															fontWeight: FontWeight.bold,
															color: Theme.of(context).colorScheme.primary,
														),
											),
										],
									),
								),

								const Divider(),

								// Navigation items
								ListView.builder(
									shrinkWrap: true,
									itemCount: _navItems.length,
									itemBuilder: (context, index) {
										final isSelected = _selectedIndex == index;
										final icons = [
											Icons.list_alt,
											Icons.notifications_outlined,
											Icons.repeat_outlined,
										];

										return ListTile(
											leading: Icon(icons[index]),
											title: Text(_navItems[index]),
											selected: isSelected,
											selectedTileColor: Theme.of(context)
													.colorScheme
													.primaryContainer
													.withOpacity(0.3),
											onTap: () => _onNavItemChanged(index),
										);
									},
								),

								const Spacer(),

								// Import/Export buttons
								Padding(
									padding: const EdgeInsets.symmetric(horizontal: 16.0),
									child: Row(
										children: [
											Expanded(
												child: OutlinedButton.icon(
													onPressed: () {
														ImportExportService().importTasks(
															context,
															ref,
														);
													},
													icon: const Icon(Icons.file_download_outlined),
													label: const Text('Import'),
													style: OutlinedButton.styleFrom(
														padding: const EdgeInsets.symmetric(vertical: 8),
													),
												),
											),
											const SizedBox(width: 8),
											Expanded(
												child: OutlinedButton.icon(
													onPressed: () {
														ImportExportService().exportTasks(
															context,
															ref,
														);
													},
													icon: const Icon(Icons.file_upload_outlined),
													label: const Text('Export'),
													style: OutlinedButton.styleFrom(
														padding: const EdgeInsets.symmetric(vertical: 8),
													),
												),
											),
										],
									),
								),

								const SizedBox(height: 8),

								// Theme toggle
								Padding(
									padding: const EdgeInsets.all(16.0),
									child: Consumer(
										builder: (context, ref, child) {
											final themeMode = ref.watch(themeModeProvider);
											final isDark = themeMode == ThemeMode.dark;
											return ListTile(
												leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
												title: Text(isDark ? 'Dark Mode' : 'Light Mode'),
												trailing: Switch(
													value: isDark,
													onChanged: (value) {
														ref.read(themeModeProvider.notifier).toggleTheme();
													},
												),
												onTap: () {
													ref.read(themeModeProvider.notifier).toggleTheme();
												},
											);
										},
									),
								),
							],
						),
					),

					// Main content
					Expanded(
						child: Column(
							children: [
								// Top bar with search and actions
								Container(
									padding: const EdgeInsets.all(16.0),
									decoration: BoxDecoration(
										color: Theme.of(context).colorScheme.surface,
										border: Border(
											bottom: BorderSide(
												color: Theme.of(context).colorScheme.outlineVariant,
												width: 1,
											),
										),
									),
									child: Row(
										children: [
											// Search field
											Flexible(
												flex: 3,
												child: TextField(
													decoration: InputDecoration(
														hintText: 'Search tasks...',
														prefixIcon: const Icon(Icons.search),
														suffixIcon: Consumer(
															builder: (context, ref, child) {
																final query = ref.watch(searchQueryProvider);
																if (query.isEmpty) {
																	return const SizedBox.shrink();
																}
																return IconButton(
																	icon: const Icon(Icons.clear),
																	onPressed: () {
																		ref.read(searchQueryProvider.notifier).state = '';
																	},
																);
															},
														),
													),
													onChanged: (value) {
														ref.read(searchQueryProvider.notifier).state = value;
													},
												),
											),

											const SizedBox(width: 12),

											// Sort dropdown
											SizedBox(
												width: 160,
												child: Consumer(
													builder: (context, ref, child) {
														final sortOption = ref.watch(sortProvider);
														return DropdownButtonFormField<TaskSortOption>(
															initialValue: sortOption,
															decoration: const InputDecoration(
																labelText: 'Sort by',
																contentPadding: EdgeInsets.symmetric(
																	horizontal: 12,
																	vertical: 8,
																),
															),
															items: const [
																DropdownMenuItem(
																	value: TaskSortOption.createdAt,
																	child: Text('Created'),
																),
																DropdownMenuItem(
																	value: TaskSortOption.reminderDate,
																	child: Text('Reminder'),
																),
																DropdownMenuItem(
																	value: TaskSortOption.title,
																	child: Text('Title'),
																),
															],
															onChanged: (value) {
																if (value != null) {
																	ref.read(sortProvider.notifier).state = value;
																}
															},
														);
													},
												),
											),

											const SizedBox(width: 12),

											// Filter dropdown
											SizedBox(
												width: 160,
												child: Consumer(
													builder: (context, ref, child) {
														final filter = ref.watch(filterProvider);
														return DropdownButtonFormField<TaskFilter>(
															initialValue: filter,
															decoration: const InputDecoration(
																labelText: 'Status',
																contentPadding: EdgeInsets.symmetric(
																	horizontal: 12,
																	vertical: 8,
																),
															),
														items: const [
															DropdownMenuItem(
																value: TaskFilter.all,
																child: Text('All'),
															),
															DropdownMenuItem(
																value: TaskFilter.pending,
																child: Text('Pending'),
															),
															DropdownMenuItem(
																value: TaskFilter.completed,
																child: Text('Completed'),
															),
														],
														onChanged: (value) {
															if (value != null) {
																ref.read(filterProvider.notifier).state = value;
															}
														},
													);
												},
											),
											),
										],
									),
								),

								// Task list
								Expanded(
									child: const TaskListView(),
								),
							],
						),
					),
				],
			),
			floatingActionButton: FloatingActionButton.extended(
				onPressed: _showCreateTaskDialog,
				icon: const Icon(Icons.add),
				label: const Text('New Task'),
			),
		);
	}
}
