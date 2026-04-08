import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/task_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import '../core/enums.dart';
import '../views/task_list_view.dart';
import '../widgets/task_dialog.dart';
import '../widgets/app_shortcuts.dart';
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
          seedColor: const Color(0xFF06402B),
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
          seedColor: const Color(0xFF06402B),
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

  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;
  final FocusNode _searchFocusNode = FocusNode();

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

  void _toggleTheme() {
    ref.read(themeModeProvider.notifier).toggleTheme();
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
      case AppShortcutAction.toggleTheme:
        _toggleTheme();
        return true;
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
    final navIcons = [
      Icons.list_alt,
      Icons.notifications_outlined,
      Icons.repeat_outlined,
    ];
    final sidebarWidth = _isSidebarCollapsed ? 96.0 : 250.0;
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final logoSize = _isSidebarCollapsed ? 24.0 : 32.0;
    final colorScheme = Theme.of(context).colorScheme;
    final searchFillColor =
        Theme.of(context).inputDecorationTheme.fillColor ??
        colorScheme.surfaceContainerHighest.withOpacity(0.40);
    final dropdownRadius = BorderRadius.circular(12);
    final dropdownInputTheme = InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: searchFillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: dropdownRadius,
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: dropdownRadius,
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: dropdownRadius,
        borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.85)),
      ),
    );

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: sidebarWidth,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // App title
                SizedBox(
                  height: _headerHeight,
                  child: _isSidebarCollapsed
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Center(
                                child: Image.asset(
                                  'assets/images/app_icon.png',
                                  width: logoSize,
                                  height: logoSize,
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Tooltip(
                                  message: 'Expand sidebar',
                                  child: IconButton(
                                    onPressed: _toggleSidebarCollapsed,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints.tightFor(
                                      width: 28,
                                      height: 28,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(
                                      Icons.keyboard_double_arrow_right,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(left: 20, right: 8),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/images/app_icon.png',
                                width: logoSize,
                                height: logoSize,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'NagMJ',
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                ),
                              ),
                              Tooltip(
                                message: 'Collapse sidebar',
                                child: IconButton(
                                  onPressed: _toggleSidebarCollapsed,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints.tightFor(
                                    width: 28,
                                    height: 28,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(
                                    Icons.keyboard_double_arrow_left,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                // Navigation items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _navItems.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedIndex == index;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: _SidebarNavItem(
                          icon: navIcons[index],
                          label: _navItems[index],
                          selected: isSelected,
                          collapsed: _isSidebarCollapsed,
                          onTap: () => _onNavItemChanged(index),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // Import/Export buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: _isSidebarCollapsed
                      ? Column(
                          children: [
                            _SidebarActionButton(
                              icon: Icons.file_download_outlined,
                              label: 'Import',
                              collapsed: true,
                              onTap: _importTasks,
                            ),
                            const SizedBox(height: 8),
                            _SidebarActionButton(
                              icon: Icons.file_upload_outlined,
                              label: 'Export',
                              collapsed: true,
                              onTap: _exportTasks,
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _SidebarActionButton(
                                icon: Icons.file_download_outlined,
                                label: 'Import',
                                onTap: _importTasks,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _SidebarActionButton(
                                icon: Icons.file_upload_outlined,
                                label: 'Export',
                                onTap: _exportTasks,
                              ),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 8),

                // Theme toggle
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  child: _SidebarActionButton(
                    icon: isDark ? Icons.dark_mode : Icons.light_mode,
                    label: isDark ? 'Dark Mode' : 'Light Mode',
                    collapsed: _isSidebarCollapsed,
                    onTap: _toggleTheme,
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
                  height: _headerHeight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Search field
                      Flexible(
                        flex: 3,
                        child: TextField(
                          focusNode: _searchFocusNode,
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
                                    ref
                                            .read(searchQueryProvider.notifier)
                                            .state =
                                        '';
                                  },
                                );
                              },
                            ),
                          ),
                          onChanged: (value) {
                            ref.read(searchQueryProvider.notifier).state =
                                value;
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
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: dropdownRadius,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.07),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: DropdownMenu<TaskSortOption>(
                                width: 160,
                                label: const Text('Sort by'),
                                initialSelection: sortOption,
                                inputDecorationTheme: dropdownInputTheme,
                                dropdownMenuEntries: const [
                                  DropdownMenuEntry(
                                    value: TaskSortOption.createdAt,
                                    label: 'Created',
                                  ),
                                  DropdownMenuEntry(
                                    value: TaskSortOption.reminderDate,
                                    label: 'Reminder',
                                  ),
                                  DropdownMenuEntry(
                                    value: TaskSortOption.title,
                                    label: 'Title',
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value != null) {
                                    ref.read(sortProvider.notifier).state =
                                        value;
                                  }
                                },
                              ),
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
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: dropdownRadius,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.07),
                                    blurRadius: 20,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: DropdownMenu<TaskFilter>(
                                width: 160,
                                label: const Text('Status'),
                                initialSelection: filter,
                                inputDecorationTheme: dropdownInputTheme,
                                dropdownMenuEntries: const [
                                  DropdownMenuEntry(
                                    value: TaskFilter.all,
                                    label: 'All',
                                  ),
                                  DropdownMenuEntry(
                                    value: TaskFilter.pending,
                                    label: 'Pending',
                                  ),
                                  DropdownMenuEntry(
                                    value: TaskFilter.completed,
                                    label: 'Completed',
                                  ),
                                  DropdownMenuEntry(
                                    value: TaskFilter.overtime,
                                    label: 'Overtime',
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value != null) {
                                    ref.read(filterProvider.notifier).state =
                                        value;
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Task list
                Expanded(child: const TaskListView()),
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

class _SidebarActionButton extends StatefulWidget {
  const _SidebarActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.collapsed = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool collapsed;

  @override
  State<_SidebarActionButton> createState() => _SidebarActionButtonState();
}

class _SidebarNavItem extends StatefulWidget {
  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.selected,
    required this.collapsed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool collapsed;

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showHoverStyle = _isHovered;

    return Tooltip(
      message: widget.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHover: (isHovering) {
            if (_isHovered != isHovering) {
              setState(() => _isHovered = isHovering);
            }
          },
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(
              horizontal: widget.collapsed ? 12 : 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                width: showHoverStyle ? 1.2 : 1,
                color: showHoverStyle
                    ? colorScheme.primary.withOpacity(0.35)
                    : Colors.transparent,
              ),
              color: showHoverStyle
                  ? colorScheme.primaryContainer.withOpacity(0.14)
                  : Colors.transparent,
              boxShadow: showHoverStyle
                  ? [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : const [],
            ),
            child: widget.collapsed
                ? Center(child: Icon(widget.icon))
                : Row(
                    children: [
                      Icon(
                        widget.icon,
                        color: widget.selected ? colorScheme.primary : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: widget.selected ? colorScheme.primary : null,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _SidebarActionButtonState extends State<_SidebarActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: widget.label,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shouldUseIconOnly =
              widget.collapsed || constraints.maxWidth < 108;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onHover: (isHovering) {
                if (_isHovered != isHovering) {
                  setState(() => _isHovered = isHovering);
                }
              },
              mouseCursor: SystemMouseCursors.click,
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: shouldUseIconOnly ? 10 : 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    width: _isHovered ? 1.4 : 1,
                    color: _isHovered
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                  ),
                  color: _isHovered
                      ? colorScheme.primaryContainer.withOpacity(0.25)
                      : Colors.transparent,
                ),
                child: shouldUseIconOnly
                    ? Icon(widget.icon)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(widget.icon, size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              widget.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
