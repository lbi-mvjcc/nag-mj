import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/task_viewmodel.dart';
import '../../core/enums.dart';
import 'read_only_dropdown.dart';

class AppHeader extends ConsumerWidget {
  const AppHeader({
    required this.headerHeight,
    required this.searchFocusNode,
    super.key,
  });

  final double headerHeight;
  final FocusNode searchFocusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Container(
      height: headerHeight,
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
              focusNode: searchFocusNode,
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
                  child: ReadOnlyDropdownMenu<TaskSortOption>(
                    width: 160,
                    label: const Text('Sort by'),
                    value: sortOption,
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
                        ref.read(sortProvider.notifier).state = value;
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
