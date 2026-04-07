# TaskMate - Task/Note Manager with Recurring Reminders

A lightweight, offline-first desktop task/note manager built with Flutter for Windows and macOS. Features local persistence, one-time and recurring reminders, and a clean, modern UI.

## Features

### Core Features
- ✅ **Create & Manage Tasks**: Add title, description, and organize your tasks
- ✅ **One-Time Reminders**: Set specific date/time for task reminders
- ✅ **Recurring Reminders**: Daily, weekly, or monthly repeating reminders with custom intervals
- ✅ **Local Persistence**: All data stored locally using Isar database
- ✅ **Search & Filter**: Quick search by title/description, filter by status, reminders, or recurring
- ✅ **Sort Options**: Sort by creation date, reminder date, or title
- ✅ **Dark Mode**: Toggle between light and dark themes
- ✅ **Import/Export**: Backup and restore tasks as JSON files
- ✅ **Keyboard Shortcuts**: Quick actions with keyboard shortcuts

### Task Management
- Mark tasks as complete/incomplete
- Edit all task properties
- Delete tasks with confirmation
- Visual indicators for recurring tasks and upcoming reminders
- Strike-through for completed tasks

## Tech Stack

- **Flutter**: Latest stable version (cross-platform framework)
- **Isar**: Fast, offline-local database
- **flutter_local_notifications**: System notifications
- **Riverpod**: State management
- **window_manager**: Desktop window management
- **shared_preferences**: Theme persistence
- **file_picker**: Import/export functionality

## Architecture

The app follows **MVVM (Model-View-ViewModel)** pattern with clean separation:

```
lib/
├── core/              # Utilities, constants, extensions, enums
│   ├── constants.dart
│   ├── theme.dart
│   ├── extensions.dart
│   └── enums.dart
├── models/            # Isar schemas & data models
│   ├── task.dart
│   └── task_export.dart
├── services/          # Database & notification logic
│   ├── isar_service.dart
│   ├── notification_service.dart
│   └── import_export_service.dart
├── viewmodels/        # Business logic & state management
│   ├── task_viewmodel.dart
│   └── theme_viewmodel.dart
├── views/             # UI screens
│   ├── main_app_view.dart
│   └── task_list_view.dart
└── widgets/           # Reusable UI components
    ├── task_dialog.dart
    └── app_shortcuts.dart
```

## Prerequisites

- **Flutter SDK**: Latest stable version (3.11.4+)
- **macOS**: Xcode installed
- **Windows**: Visual Studio with C++ desktop development workload
- **Dart SDK**: Included with Flutter

## Installation

1. **Clone or navigate to the project directory**:
   ```bash
   cd /path/to/nag_mj
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate Isar files** (if needed):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

## Running the App

### macOS
```bash
flutter run -d macos
```

Or build a release version:
```bash
flutter build macos --release
```

The built app will be at: `build/macos/Build/Products/Release/nag_mj.app`

### Windows
```bash
flutter run -d windows
```

Or build a release version:
```bash
flutter build windows --release
```

The built app will be at: `build\windows\runner\Release\nag_mj.exe`

## How Reminders Work

### One-Time Reminders
1. When creating/editing a task, toggle "Set Reminder"
2. Select date and time
3. The app schedules a single system notification using `flutter_local_notifications`
4. Notification fires at the specified date/time
5. If the task is marked complete, the notification is cancelled

### Recurring Reminders
1. Toggle "Recurring Reminder" after enabling reminders
2. Choose recurrence type: Daily, Weekly, or Monthly
3. Set interval (e.g., every 2 days, every 3 weeks)
4. Optionally set an end date
5. The app schedules repeating notifications based on your settings:
   - **Daily**: Fires at the same time every day (or every X days)
   - **Weekly**: Fires on the same day of week and time (or every X weeks)
   - **Monthly**: Fires on the same day of month and time (or every X months)

### Notification Rehydration
On app startup:
1. Isar database is initialized
2. All tasks are loaded
3. All pending notifications are rescheduled from the database
4. This ensures notifications persist across app restarts

### Avoiding Duplicate Notifications
- Before scheduling a new notification, the old one is cancelled
- When editing a task, the notification is cancelled and rescheduled
- Completed tasks have their notifications cancelled
- Deleted tasks have their notifications cancelled

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl/Cmd + N` | Create new task |
| `Ctrl/Cmd + F` | Focus search field |
| `Ctrl/Cmd + E` | Export tasks |
| `Ctrl/Cmd + I` | Import tasks |
| `Ctrl/Cmd + D` | Toggle dark mode |

## Import/Export

### Export Tasks
1. Click the "Export" button in the sidebar
2. Choose a save location
3. A JSON file is created with all your tasks

### Import Tasks
1. Click the "Import" button in the sidebar
2. Select a previously exported JSON file
3. Tasks are added to your database

## Data Model

### Task Entity
```dart
class Task {
  Id id;                      // Auto-generated by Isar
  String title;               // Required
  String? description;        // Optional
  DateTime createdAt;
  DateTime updatedAt;
  bool isCompleted;
  DateTime? reminderDateTime; // Nullable
  bool isRecurring;
  RecurrenceType recurrenceType; // none, daily, weekly, monthly
  int recurrenceInterval;     // e.g., every 2 days
  DateTime? recurrenceEndDate;
  int notificationId;         // For tracking notifications
}
```

## Error Handling

The app handles various edge cases:
- **Invalid dates**: Validation prevents past dates for new reminders
- **Notification permissions**: Requests permissions on startup
- **Duplicate scheduling**: Cancels old notifications before scheduling new ones
- **Database safety**: All writes use transactions
- **Null safety**: Fully null-safe codebase

## Project Structure Details

### Core Layer
- **constants.dart**: App-wide constants and configuration
- **theme.dart**: Light and dark Material 3 themes
- **extensions.dart**: DateTime and String helper methods
- **enums.dart**: RecurrenceType, TaskFilter, TaskSortOption

### Services Layer
- **isar_service.dart**: Singleton database service with CRUD operations
- **notification_service.dart**: Singleton notification scheduler
- **import_export_service.dart**: JSON import/export functionality

### ViewModels Layer
- **task_viewmodel.dart**: Task business logic and state
- **theme_viewmodel.dart**: Theme state management

### Views Layer
- **main_app_view.dart**: Main layout with sidebar and navigation
- **task_list_view.dart**: Task list with filtering and sorting

### Widgets Layer
- **task_dialog.dart**: Create/edit task dialog
- **app_shortcuts.dart**: Keyboard shortcut definitions

## Customization

### Changing the Theme Color
Edit `lib/core/theme.dart` and change the `seedColor`:
```dart
seedColor: const Color(0xFF6366F1), // Change this color
```

### Adding New Recurrence Types
1. Add to `RecurrenceType` enum in `lib/core/enums.dart`
2. Update notification scheduling logic in `notification_service.dart`
3. Add UI option in `task_dialog.dart`

## Troubleshooting

### Notifications Not Showing
- Ensure notification permissions are granted (macOS: System Preferences > Notifications)
- Check that the reminder date/time is in the future
- Restart the app to rehydrate notifications

### Build Errors
- Run `flutter clean` and `flutter pub get`
- Regenerate Isar files: `dart run build_runner build --delete-conflicting-outputs`
- Ensure Flutter SDK is up to date

### Database Issues
- Database files are stored in the application documents directory
- Delete the database by removing the `taskmate_db` files from the app data folder

## Future Enhancements

Potential improvements:
- [ ] System tray integration
- [ ] Task categories/tags
- [ ] Priority levels
- [ ] Due dates (separate from reminders)
- [ ] Task dependencies
- [ ] Calendar view
- [ ] Snooze functionality
- [ ] Custom recurrence patterns
- [ ] Task templates
- [ ] Backup to cloud storage

## License

This project is for educational and personal use.

## Support

For issues or questions, please check:
- Flutter documentation: https://flutter.dev/docs
- Isar documentation: https://isar.dev
- Riverpod documentation: https://riverpod.dev
- flutter_local_notifications: https://pub.dev/packages/flutter_local_notifications

---

**Built with ❤️ using Flutter**
