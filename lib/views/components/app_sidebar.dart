import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

class AppSidebar extends ConsumerWidget {
  const AppSidebar({
    required this.isCollapsed,
    required this.selectedIndex,
    required this.onNavItemChanged,
    required this.onToggleSidebar,
    required this.onImport,
    required this.onExport,
    required this.onToggleTheme,
    required this.isDark,
    required this.appName,
    required this.logoPath,
    required this.sidebarBaseColor,
    super.key,
  });

  final bool isCollapsed;
  final int selectedIndex;
  final Function(int) onNavItemChanged;
  final VoidCallback onToggleSidebar;
  final VoidCallback onImport;
  final VoidCallback onExport;
  final VoidCallback onToggleTheme;
  final bool isDark;
  final String appName;
  final String? logoPath;
  final Color sidebarBaseColor;

  static const double _headerHeight = 76;
  static const double _collapsedWidth = 96.0;
  static const double _expandedWidth = 250.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseColor = sidebarBaseColor;
    double sidebarWidth = isCollapsed ? _collapsedWidth : _expandedWidth;
    double logoSize = isCollapsed ? 24.0 : 32.0;
    final colorScheme = Theme.of(context).colorScheme;
    final sidebarColor = isDark
        ? Color.alphaBlend(baseColor.withOpacity(0.24), colorScheme.surface)
        : Color.alphaBlend(baseColor.withOpacity(0.07), colorScheme.surface);

    final navItems = const [
      'All Tasks',
      'Completed',
      'Pending',
      'To Review',
      'Overtime',
      'With Reminders',
      'Recurring',
      'Trash',
      'Settings',
    ];

    final navIcons = [
      Icons.list_alt,
      Icons.check_circle_outline,
      Icons.pending_actions,
      Icons.rate_review_outlined,
      Icons.warning_amber_rounded,
      Icons.notifications_outlined,
      Icons.repeat_outlined,
      Icons.delete_outline,
      Icons.settings_outlined,
    ];

    final hasCustomLogo =
        logoPath != null &&
        logoPath!.isNotEmpty &&
        File(logoPath!).existsSync();
    final logoImageProvider = hasCustomLogo
        ? FileImage(File(logoPath!)) as ImageProvider
        : const AssetImage('assets/images/app_icon.png');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: sidebarColor,
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
            child: isCollapsed
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: Image(
                            image: logoImageProvider,
                            width: logoSize,
                            height: logoSize,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Tooltip(
                            message: 'Expand sidebar',
                            child: IconButton(
                              onPressed: onToggleSidebar,
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
                        Image(
                          image: logoImageProvider,
                          width: logoSize,
                          height: logoSize,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            appName,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? colorScheme.onPrimaryContainer
                                      : baseColor,
                                ),
                          ),
                        ),
                        Tooltip(
                          message: 'Collapse sidebar',
                          child: IconButton(
                            onPressed: onToggleSidebar,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 28,
                              height: 28,
                            ),
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.keyboard_double_arrow_left),
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
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final isSelected = selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: SidebarNavItem(
                    icon: navIcons[index],
                    label: navItems[index],
                    selected: isSelected,
                    collapsed: isCollapsed,
                    onTap: () => onNavItemChanged(index),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: _SidebarLiveDateTime(collapsed: isCollapsed),
          ),
          const SizedBox(height: 8),
          // Import/Export buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: isCollapsed
                ? Column(
                    children: [
                      SidebarActionButton(
                        icon: Icons.file_download_outlined,
                        label: 'Import',
                        collapsed: true,
                        onTap: onImport,
                      ),
                      const SizedBox(height: 8),
                      SidebarActionButton(
                        icon: Icons.file_upload_outlined,
                        label: 'Export',
                        collapsed: true,
                        onTap: onExport,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: SidebarActionButton(
                          icon: Icons.file_download_outlined,
                          label: 'Import',
                          onTap: onImport,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SidebarActionButton(
                          icon: Icons.file_upload_outlined,
                          label: 'Export',
                          onTap: onExport,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          // Theme toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: SidebarActionButton(
              icon: isDark ? Icons.dark_mode : Icons.light_mode,
              label: isDark ? 'Dark Mode' : 'Light Mode',
              collapsed: isCollapsed,
              onTap: onToggleTheme,
            ),
          ),
        ],
      ),
    );
  }
}

class SidebarNavItem extends StatefulWidget {
  const SidebarNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.selected,
    required this.collapsed,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool collapsed;

  @override
  State<SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFF06402B);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showHoverStyle = _isHovered;
    final showSelectedStyle = widget.selected;
    final selectedColor = isDark ? colorScheme.onPrimaryContainer : baseColor;

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
                width: (showHoverStyle || showSelectedStyle) ? 1.2 : 1,
                color: showSelectedStyle
                    ? baseColor.withOpacity(isDark ? 0.85 : 0.55)
                    : showHoverStyle
                    ? baseColor.withOpacity(0.35)
                    : Colors.transparent,
              ),
              color: showSelectedStyle
                  ? baseColor.withOpacity(isDark ? 0.30 : 0.16)
                  : showHoverStyle
                  ? baseColor.withOpacity(isDark ? 0.20 : 0.10)
                  : Colors.transparent,
              boxShadow: (showHoverStyle || showSelectedStyle)
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
                        color: widget.selected ? selectedColor : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: widget.selected ? selectedColor : null,
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

class SidebarActionButton extends StatefulWidget {
  const SidebarActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.collapsed = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool collapsed;

  @override
  State<SidebarActionButton> createState() => _SidebarActionButtonState();
}

class _SidebarLiveDateTime extends StatelessWidget {
  const _SidebarLiveDateTime({required this.collapsed});

  final bool collapsed;

  static const List<String> _weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute:$second $period';
  }

  String _formatDate(DateTime dateTime) {
    final weekday = _weekdayNames[dateTime.weekday - 1];
    final month = _monthNames[dateTime.month - 1];
    return '$weekday, $month ${dateTime.day}, ${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<DateTime>(
      stream: Stream<DateTime>.periodic(
        const Duration(seconds: 1),
        (_) => DateTime.now(),
      ),
      initialData: DateTime.now(),
      builder: (context, snapshot) {
        final now = snapshot.data ?? DateTime.now();

        if (collapsed) {
          return Tooltip(
            message: '${_formatDate(now)}\n${_formatTime(now)}',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
                color: colorScheme.surface.withOpacity(0.3),
              ),
              child: Icon(Icons.schedule_outlined, color: colorScheme.primary),
            ),
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant),
            color: colorScheme.surface.withOpacity(0.35),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.schedule_outlined, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Time and Date',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _formatTime(now),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDate(now),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SidebarActionButtonState extends State<SidebarActionButton> {
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
