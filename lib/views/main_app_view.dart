import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/task_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../core/enums.dart';
import '../views/task_list_view.dart';
import '../views/to_review_view.dart';
import '../views/completed_view.dart';
import '../views/overtime_view.dart';
import '../views/pending_view.dart';
import '../views/trash_view.dart';
import '../views/settings_view.dart';
import '../views/components/app_sidebar.dart';
import '../views/components/app_header.dart';
import '../widgets/task_dialog.dart';
import '../widgets/app_shortcuts.dart';
import '../services/import_export_service.dart';

class MainAppView extends ConsumerWidget {
  const MainAppView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final appSettings = ref.watch(appSettingsProvider);

    return MaterialApp(
      title: appSettings.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: appSettings.sidebarColor,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: appSettings.darkThemeSeedColor,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
  static const double _headerHeight = 76;

  bool _isSidebarCollapsed = false;
  final FocusNode _searchFocusNode = FocusNode();

  void _onNavItemChanged(int index) {
    ref.read(sidebarIndexProvider.notifier).state = index;

    // Update filters based on selection
    switch (index) {
      case 0:
        ref.read(filterProvider.notifier).state = TaskFilter.all;
        ref.read(showOnlyWithRemindersProvider.notifier).state = false;
        ref.read(showOnlyRecurringProvider.notifier).state = false;
        break;
      case 5:
        ref.read(filterProvider.notifier).state = TaskFilter.all;
        ref.read(showOnlyWithRemindersProvider.notifier).state = true;
        ref.read(showOnlyRecurringProvider.notifier).state = false;
        break;
      case 6:
        ref.read(filterProvider.notifier).state = TaskFilter.all;
        ref.read(showOnlyWithRemindersProvider.notifier).state = false;
        ref.read(showOnlyRecurringProvider.notifier).state = true;
        break;
      case 1:
        // Completed view - no filter changes needed
        break;
      case 2:
        // Pending view - no filter changes needed
        break;
      case 3:
        // To Review view - no filter changes needed
        break;
      case 4:
        // Overtime view - no filter changes needed
        break;
      case 7:
        // Trash view - no filter changes needed
        break;
      case 8:
        // Settings view - no filter changes needed
        break;
    }
  }

  void _showCreateTaskDialog() {
    showDialog(context: context, builder: (context) => const TaskDialog());
  }

  void _focusSearchField() {
    _searchFocusNode.requestFocus();
  }

  Future<void> _importTasks() async {
    await ImportExportService().importTasks(context, ref);
  }

  Future<void> _exportTasks() async {
    await ImportExportService().exportTasks(context, ref);
  }

  Future<void> _refreshTasks() async {
    try {
      await ref.read(tasksProvider.notifier).loadTasks();
      ref.invalidate(trashTasksProvider);

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Tasks refreshed'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Refresh failed'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _toggleTheme() {
    ref.read(themeModeProvider.notifier).toggleTheme();
  }

  Future<void> _toggleTaskGridView() async {
    final appSettings = ref.read(appSettingsProvider);
    await ref
        .read(appSettingsProvider.notifier)
        .setTaskGridView(!appSettings.isTaskGridView);
  }

  void _openToReviewPage() {
    ref.read(sidebarIndexProvider.notifier).state = 3;
  }

  void _toggleSidebarCollapsed() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
    });
  }

  bool _handleGlobalShortcut(KeyEvent event) {
    final action = AppShortcuts.resolveKeyEvent(event);

    switch (action) {
      case AppShortcutAction.newTask:
        _showCreateTaskDialog();
        return true;
      case AppShortcutAction.focusSearch:
        _focusSearchField();
        return true;
      case AppShortcutAction.exportTasks:
        _exportTasks();
        return true;
      case AppShortcutAction.importTasks:
        _importTasks();
        return true;
      case AppShortcutAction.toggleTaskGrid:
        _toggleTaskGridView();
        return true;
      case AppShortcutAction.refreshTasks:
        _refreshTasks();
        return true;
      case AppShortcutAction.toggleTheme:
        _toggleTheme();
        return true;
      case AppShortcutAction.selectAll:
        final selectedIndex = ref.read(sidebarIndexProvider);
        if (selectedIndex == 7) {
          ref.read(trashSelectAllTriggerProvider.notifier).state++;
          return true;
        }
        if (selectedIndex == 0 || selectedIndex == 5 || selectedIndex == 6) {
          ref.read(taskSelectAllTriggerProvider.notifier).state++;
          return true;
        }
        return false;
      case null:
        return false;
    }
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleGlobalShortcut);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalShortcut);
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final selectedIndex = ref.watch(sidebarIndexProvider);
    final appSettings = ref.watch(appSettingsProvider);
    final isTrashView = selectedIndex == 7;
    final isSettingsView = selectedIndex == 8;
    final isToReviewView = selectedIndex == 3;
    final isCompletedView = selectedIndex == 1;
    final isOvertimeView = selectedIndex == 4;
    final isPendingView = selectedIndex == 2;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AppSidebar(
            isCollapsed: _isSidebarCollapsed,
            selectedIndex: selectedIndex,
            onNavItemChanged: _onNavItemChanged,
            onToggleSidebar: _toggleSidebarCollapsed,
            onImport: _importTasks,
            onExport: _exportTasks,
            onToggleTheme: _toggleTheme,
            isDark: isDark,
            appName: appSettings.appName,
            logoPath: appSettings.logoPath,
            sidebarBaseColor: appSettings.sidebarColor,
          ),
          // Main content
          Expanded(
            child: Column(
              children: [
                AppHeader(
                  headerHeight: _headerHeight,
                  searchFocusNode: _searchFocusNode,
                ),
                // Content View
                Expanded(
                  child: isSettingsView
                      ? const SettingsView()
                      : isTrashView
                          ? const TrashView()
                          : isToReviewView
                              ? const ToReviewView()
                              : isCompletedView
                                  ? const CompletedView()
                                  : isOvertimeView
                                      ? const OvertimeView()
                                      : isPendingView
                                          ? const PendingView()
                              : const TaskListView(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton:
          (!isTrashView &&
              !isSettingsView &&
              !isToReviewView &&
                !isCompletedView &&
                !isOvertimeView &&
                !isPendingView)
          ? FloatingActionButton.extended(
              onPressed: _showCreateTaskDialog,
              icon: const Icon(Icons.add),
              label: const Text('New Task'),
            )
          : null,
    );
  }
}
