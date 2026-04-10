import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReadOnlyDropdownMenu<T> extends StatefulWidget {
  const ReadOnlyDropdownMenu({super.key, 
    required this.width,
    required this.label,
    required this.value,
    required this.inputDecorationTheme,
    required this.dropdownMenuEntries,
    required this.onSelected,
  });

  final double width;
  final Widget label;
  final T value;
  final InputDecorationTheme inputDecorationTheme;
  final List<DropdownMenuEntry<T>> dropdownMenuEntries;
  final Function(T?) onSelected;

  @override
  State<ReadOnlyDropdownMenu<T>> createState() =>
      _ReadOnlyDropdownMenuState<T>();
}

class _ReadOnlyDropdownMenuState<T> extends State<ReadOnlyDropdownMenu<T>> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _getLabelForValue(widget.value),
    );
    _focusNode = FocusNode();
    // Prevent focus on the text field to block keyboard input
    _focusNode.onKey = (node, event) {
      return KeyEventResult.handled;
    };
  }

  @override
  void didUpdateWidget(ReadOnlyDropdownMenu<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = _getLabelForValue(widget.value);
    }
  }

  String _getLabelForValue(T value) {
    return widget.dropdownMenuEntries
        .firstWhere(
          (entry) => entry.value == value,
          orElse: () => widget.dropdownMenuEntries.first,
        )
        .label;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<T>(
      width: widget.width,
      controller: _controller,
      focusNode: _focusNode,
      label: widget.label,
      initialSelection: widget.value,
      inputDecorationTheme: widget.inputDecorationTheme,
      dropdownMenuEntries: widget.dropdownMenuEntries,
      enableFilter: false,
      enableSearch: false,
      textStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp('.')),
      ],
      onSelected: (value) {
        widget.onSelected(value);
        if (value != null) {
          _controller.text = _getLabelForValue(value);
        }
      },
    );
  }
}
