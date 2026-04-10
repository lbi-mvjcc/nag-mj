import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  static const double _headerHeight = 76;
  static const double _collapsedWidth = 96.0;
  static const double _expandedWidth = 250.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const baseColor = Color(0xFF06402B);
    double sidebarWidth = isCollapsed ? _collapsedWidth : _expandedWidth;
    double logoSize = isCollapsed ? 24.0 : 32.0;
    final colorScheme = Theme.of(context).colorScheme;
    final sidebarColor = isDark
        ? Color.alphaBlend(baseColor.withOpacity(0.24), colorScheme.surface)
        : Color.alphaBlend(baseColor.withOpacity(0.07), colorScheme.surface);

    final navItems = const [
      'All Tasks',
      'With Reminders',
      'Recurring',
      'Hotkeys',
      'Trash',
    ];

    final navIcons = [
      Icons.list_alt,
      Icons.notifications_outlined,
      Icons.repeat_outlined,
      Icons.keyboard,
      Icons.delete_outline,
    ];

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
