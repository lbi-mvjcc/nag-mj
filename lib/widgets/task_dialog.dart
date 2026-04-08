import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../viewmodels/task_viewmodel.dart';
import '../core/enums.dart';
import '../core/extensions.dart';
import 'task_result_modal.dart';

class TaskDialog extends ConsumerStatefulWidget {
  final Task? task;

  const TaskDialog({super.key, this.task});

  @override
  ConsumerState<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends ConsumerState<TaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  bool _hasReminder = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isRecurring = false;
  RecurrenceType _recurrenceType = RecurrenceType.daily;
  int _recurrenceInterval = 1;
  DateTime? _recurrenceEndDate;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );

    if (widget.task != null) {
      final task = widget.task!;
      _hasReminder = task.reminderDateTime != null;
      if (task.reminderDateTime != null) {
        _selectedDate = DateTime(
          task.reminderDateTime!.year,
          task.reminderDateTime!.month,
          task.reminderDateTime!.day,
        );
        _selectedTime = TimeOfDay(
          hour: task.reminderDateTime!.hour,
          minute: task.reminderDateTime!.minute,
        );
      }

      _isRecurring = task.isRecurring;
      _recurrenceType = task.recurrenceType;
      _recurrenceInterval = task.recurrenceInterval;
      _recurrenceEndDate = task.recurrenceEndDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _recurrenceEndDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );

    if (picked != null) {
      setState(() {
        _recurrenceEndDate = picked;
      });
    }
  }

  void _saveTask() {
    if (!_formKey.currentState!.validate()) return;

    if (_hasReminder && (_selectedDate == null || _selectedTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both date and time for reminder'),
        ),
      );
      return;
    }

    DateTime? reminderDateTime;
    if (_hasReminder && _selectedDate != null && _selectedTime != null) {
      reminderDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Validate that reminder is not in the past (for new tasks)
      if (!_isEditing && reminderDateTime.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reminder date/time cannot be in the past'),
          ),
        );
        return;
      }
    }

    final task =
        widget.task?.copyWith(
                title: _titleController.text.trim(),
                description: _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
                reminderDateTime: reminderDateTime,
                isRecurring: _isRecurring,
                recurrenceType: _isRecurring
                    ? _recurrenceType
                    : RecurrenceType.none,
                recurrenceInterval: _isRecurring ? _recurrenceInterval : 1,
                recurrenceEndDate: _isRecurring ? _recurrenceEndDate : null,
              ) ??
              Task()
          ..title = _titleController.text.trim()
          ..description = _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim()
          ..reminderDateTime = reminderDateTime
          ..isRecurring = _isRecurring
          ..recurrenceType = _isRecurring
              ? _recurrenceType
              : RecurrenceType.none
          ..recurrenceInterval = _isRecurring ? _recurrenceInterval : 1
          ..recurrenceEndDate = _isRecurring ? _recurrenceEndDate : null;

    if (_isEditing) {
      ref.read(tasksProvider.notifier).updateTask(task);
    } else {
      ref.read(tasksProvider.notifier).createTask(task);
    }

    // Close the dialog and show result modal
    Navigator.pop(context);

    // Show result modal after dialog closes
    Future.delayed(const Duration(milliseconds: 100), () {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => TaskResultModal(
          isSuccess: true,
          message: _isEditing
              ? 'Task updated successfully'
              : 'Task created successfully',
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final recurrenceDropdownValue = _recurrenceType == RecurrenceType.none
        ? RecurrenceType.daily
        : _recurrenceType;

    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 10000),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(
                      _isEditing ? 'Edit Task' : 'Create Task',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Form
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title field
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          hintText: 'Enter task title',
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Description field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (optional)',
                          hintText: 'Enter task description',
                          alignLabelWithHint: true,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 4,
                      ),

                      const SizedBox(height: 24),

                      // Reminder toggle
                      SwitchListTile(
                        title: const Text('Set Reminder'),
                        subtitle: Text(
                          _hasReminder
                              ? 'Reminder is enabled'
                              : 'Enable to set a reminder',
                        ),
                        value: _hasReminder,
                        onChanged: (value) {
                          setState(() {
                            _hasReminder = value;
                            if (!value) {
                              _selectedDate = null;
                              _selectedTime = null;
                            }
                          });
                        },
                      ),

                      // Reminder date/time pickers
                      if (_hasReminder) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Date picker
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _selectDate,
                                icon: const Icon(Icons.calendar_today),
                                label: Text(
                                  _selectedDate != null
                                      ? _selectedDate!.formatDate(context)
                                      : 'Select Date',
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Time picker
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _selectTime,
                                icon: const Icon(Icons.access_time),
                                label: Text(
                                  _selectedTime != null
                                      ? _selectedTime!.format(context)
                                      : 'Select Time',
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Recurring toggle
                      SwitchListTile(
                        title: const Text('Recurring Reminder'),
                        subtitle: Text(
                          _isRecurring
                              ? 'Recurring is enabled'
                              : 'Enable for recurring reminders',
                        ),
                        value: _isRecurring,
                        onChanged: (value) {
                          setState(() {
                            _isRecurring = value;
                          });
                        },
                      ),

                      // Recurring settings
                      if (_isRecurring) ...[
                        const SizedBox(height: 12),
                        // Recurrence type dropdown
                        DropdownButtonFormField<RecurrenceType>(
                          initialValue: recurrenceDropdownValue,
                          decoration: const InputDecoration(
                            labelText: 'Repeat',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: RecurrenceType.daily,
                              child: Text('Daily'),
                            ),
                            DropdownMenuItem(
                              value: RecurrenceType.weekly,
                              child: Text('Weekly'),
                            ),
                            DropdownMenuItem(
                              value: RecurrenceType.monthly,
                              child: Text('Monthly'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _recurrenceType = value;
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 12),

                        // Interval
                        Row(
                          children: [
                            const Text('Every'),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 80,
                              child: TextFormField(
                                initialValue: _recurrenceInterval.toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                onChanged: (value) {
                                  final interval = int.tryParse(value);
                                  if (interval != null && interval > 0) {
                                    setState(() {
                                      _recurrenceInterval = interval;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(_getIntervalLabel()),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // End date
                        Row(
                          children: [
                            const Text('Ends'),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _selectEndDate,
                                icon: const Icon(Icons.event),
                                label: Text(
                                  _recurrenceEndDate != null
                                      ? _recurrenceEndDate!.formatDate(context)
                                      : 'Never',
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const Divider(height: 1),

              // Actions
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _saveTask,
                      child: Text(_isEditing ? 'Save Changes' : 'Create Task'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getIntervalLabel() {
    switch (_recurrenceType) {
      case RecurrenceType.daily:
        return _recurrenceInterval == 1 ? 'day' : 'days';
      case RecurrenceType.weekly:
        return _recurrenceInterval == 1 ? 'week' : 'weeks';
      case RecurrenceType.monthly:
        return _recurrenceInterval == 1 ? 'month' : 'months';
      default:
        return '';
    }
  }
}
