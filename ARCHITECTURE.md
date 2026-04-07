# TaskMate - Technical Architecture

## Overview

TaskMate is a cross-platform desktop application built with Flutter, following MVVM (Model-View-ViewModel) architecture with clean separation of concerns. The app is fully offline-first with local persistence using Isar database.

## Architecture Layers

```
┌─────────────────────────────────────────┐
│           Presentation Layer            │
│         (Views & Widgets)               │
├─────────────────────────────────────────┤
│          ViewModel Layer                │
│      (State Management - Riverpod)      │
├─────────────────────────────────────────┤
│           Service Layer                 │
│    (Business Logic & Data Access)       │
├─────────────────────────────────────────┤
│            Data Layer                   │
│         (Isar Database)                 │
└─────────────────────────────────────────┘
```

## Core Components

### 1. Models (`lib/models/`)

#### Task
Isar collection schema with the following fields:
- `id`: Auto-incrementing primary key
- `title`: Required string (indexed)
- `description`: Optional string
- `createdAt`: DateTime of creation
- `updatedAt`: DateTime of last update
- `isCompleted`: Boolean flag
- `reminderDateTime`: Nullable DateTime for reminder
- `isRecurring`: Boolean flag for recurring tasks
- `recurrenceType`: Enum (none, daily, weekly, monthly)
- `recurrenceInterval`: Integer for custom intervals
- `recurrenceEndDate`: Nullable DateTime for recurring end date
- `notificationId`: Integer for tracking system notifications

#### TaskExport
Data transfer object for import/export:
- `tasks`: List of task JSON objects
- `exportedAt`: Timestamp of export
- `version`: Export format version

### 2. Services (`lib/services/`)

#### IsarService
Singleton database service managing all data operations:

**Initialization:**
```dart
Future<void> init() async {
  final dir = await getApplicationDocumentsDirectory();
  _isar = await Isar.open(
    [TaskSchema],
    directory: dir.path,
    name: 'taskmate_db',
  );
}
```

**Key Methods:**
- `getAllTasks()`: Retrieve all tasks sorted by creation date
- `getPendingTasks()`: Filter incomplete tasks
- `getTasksWithReminders()`: Filter tasks with reminders
- `getRecurringTasks()`: Filter recurring tasks
- `searchTasks(query)`: Full-text search on title/description
- `createTask(task)`: Insert new task
- `updateTask(task)`: Update existing task
- `deleteTask(id)`: Remove task
- `toggleTaskCompletion(id)`: Toggle completed status
- `exportTasks()`: Export all tasks as JSON
- `importTasks(taskMaps)`: Import tasks from JSON

**Design Patterns:**
- Singleton pattern for single database instance
- Transaction-based writes for data safety
- Async/await for non-blocking operations

#### NotificationService
Singleton service managing system notifications:

**Initialization:**
```dart
Future<void> init() async {
  // Initialize timezone data
  tz.initializeTimeZones();
  
  // Configure platform-specific settings
  const initializationSettings = InitializationSettings(
    macOS: DarwinInitializationSettings(...),
  );
  
  await _flutterLocalNotificationsPlugin.initialize(...);
}
```

**Scheduling Logic:**

**One-Time Notifications:**
```dart
Future<void> _scheduleOneTimeNotification(...) async {
  final scheduledDate = tz.TZDateTime.from(
    task.reminderDateTime!,
    tz.local,
  );
  
  // Skip if in the past
  if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
    return;
  }
  
  await _flutterLocalNotificationsPlugin.zonedSchedule(
    notificationId,
    title,
    body,
    scheduledDate,
    NotificationDetails(...),
    matchDateTimeComponents: DateTimeComponents.dateAndTime,
  );
}
```

**Recurring Notifications:**
```dart
Future<void> _scheduleRecurringNotification(...) async {
  switch (task.recurrenceType) {
    case RecurrenceType.daily:
      matchComponents = DateTimeComponents.time;
      break;
    case RecurrenceType.weekly:
      matchComponents = DateTimeComponents.dayOfWeekAndTime;
      break;
    case RecurrenceType.monthly:
      matchComponents = DateTimeComponents.dayOfMonthAndTime;
      break;
  }
  
  await _flutterLocalNotificationsPlugin.zonedSchedule(...);
}
```

**Notification Management:**
- `scheduleNotification(task)`: Schedule or reschedule for a task
- `cancelNotification(task)`: Cancel notification for a task
- `rescheduleAllNotifications(tasks)`: Bulk reschedule on app startup
- Automatic cancellation for completed/deleted tasks

**Duplicate Prevention:**
- Cancel old notification before scheduling new one
- Unique notification IDs based on task IDs
- Validation prevents past dates

#### ImportExportService
Handles JSON import/export:

**Export Process:**
1. Fetch all tasks from Isar
2. Convert to JSON maps
3. Create TaskExport object
4. Save to user-selected location

**Import Process:**
1. User selects JSON file
2. Parse and validate format
3. Convert JSON to Task objects
4. Insert into Isar database

### 3. ViewModels (`lib/viewmodels/`)

#### TaskViewModel
State management for task operations using Riverpod:

**State:**
```dart
final tasksProvider = StateNotifierProvider<TaskViewModel, AsyncValue<List<Task>>>(
  (ref) => TaskViewModel(ref),
);
```

**Key Methods:**
- `loadTasks()`: Fetch and update state
- `createTask(task)`: Add new task + schedule notification
- `updateTask(task)`: Update task + reschedule notification
- `deleteTask(id)`: Remove task + cancel notification
- `toggleTaskCompletion(id)`: Toggle status + manage notification
- `getFilteredAndSortedTasks()`: Apply filters and sorting

**Filtering Logic:**
```dart
List<Task> getFilteredAndSortedTasks() {
  var filtered = tasks.where((task) {
    // Status filter
    switch (filter) {
      case TaskFilter.completed:
        if (!task.isCompleted) return false;
        break;
      case TaskFilter.pending:
        if (task.isCompleted) return false;
        break;
    }
    
    // Reminder filter
    if (showOnlyWithReminders && task.reminderDateTime == null) {
      return false;
    }
    
    // Recurring filter
    if (showOnlyRecurring && !task.isRecurring) {
      return false;
    }
    
    // Search filter
    if (searchQuery.isNotEmpty) {
      final titleMatch = task.title.toLowerCase().contains(searchQuery);
      final descMatch = task.description?.toLowerCase().contains(searchQuery) ?? false;
      if (!titleMatch && !descMatch) return false;
    }
    
    return true;
  }).toList();
  
  // Apply sorting
  switch (sortOption) {
    case TaskSortOption.createdAt:
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      break;
    // ... other sort options
  }
  
  return filtered;
}
```

#### ThemeModeNotifier
State management for theme:

```dart
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(AppConstants.themeModeKey);
    if (modeIndex != null) {
      state = ThemeMode.values[modeIndex];
    }
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.themeModeKey, mode.index);
    state = mode;
  }
}
```

### 4. Views (`lib/views/`)

#### MainAppView
Root widget configuring:
- Material 3 theme (light/dark)
- Theme mode switching
- Main layout

#### MainLayout
Primary app structure:
```
┌──────────────────────────────────────────────┐
│  Sidebar  │  Top Bar (Search, Filters)       │
│           ├──────────────────────────────────┤
│  - Nav    │                                   │
│  - Import │  Task List                        │
│  - Export │                                   │
│  - Theme  │                                   │
└───────────┴───────────────────────────────────┘
```

**Features:**
- Responsive sidebar navigation
- Search field with clear button
- Sort dropdown (Created, Reminder, Title)
- Filter dropdown (All, Pending, Completed)
- Floating action button for new task

#### TaskListView
Displays filtered/sorted tasks:

**TaskCard Widget:**
- Checkbox for completion toggle
- Title with strike-through for completed
- Description preview (truncated)
- Reminder indicator with date/time
- Recurring indicator with pattern
- Popup menu for edit/delete
- Click to open edit dialog

### 5. Widgets (`lib/widgets/`)

#### TaskDialog
Modal dialog for create/edit:

**Form Fields:**
- Title (required, validated)
- Description (optional, multi-line)
- Reminder toggle
- Date picker (if reminder enabled)
- Time picker (if reminder enabled)
- Recurring toggle
- Recurrence type dropdown (if recurring)
- Interval input (if recurring)
- End date picker (if recurring)

**Validation:**
- Title required
- Date/time required if reminder enabled
- Prevents past dates for new tasks

#### AppShortcuts
Keyboard shortcut definitions:
```dart
class AppShortcuts {
  static final Map<LogicalKeySet, Intent> shortcuts = {
    LogicalKeySet(
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.keyN,
    ): const NewTaskIntent(),
    // ... more shortcuts
  };
}
```

## State Management with Riverpod

### Provider Types Used

1. **StateNotifierProvider**: For complex state logic
   ```dart
   final tasksProvider = StateNotifierProvider<TaskViewModel, AsyncValue<List<Task>>>(...);
   ```

2. **StateProvider**: For simple state
   ```dart
   final filterProvider = StateProvider<TaskFilter>((ref) => TaskFilter.all);
   final sortProvider = StateProvider<TaskSortOption>((ref) => TaskSortOption.createdAt);
   final searchQueryProvider = StateProvider<String>((ref) => '');
   ```

3. **Provider**: For singleton services
   ```dart
   final isarServiceProvider = Provider<IsarService>((ref) => IsarService());
   ```

### State Flow

```
User Action → ViewModel Method → Service Call → Database Update
                                              ↓
                                        Notification Update
                                              ↓
                                        Load Tasks → State Update → UI Rebuild
```

## Notification System Architecture

### Scheduling Flow

```
Task Created/Updated
        ↓
Check if reminderDateTime != null
        ↓
Cancel existing notification (if any)
        ↓
Is recurring? ──Yes──→ Schedule recurring notification
        │
       No
        │
        ↓
Schedule one-time notification
        ↓
Store notificationId in task
```

### Rehydration Flow (App Startup)

```
App Start
    ↓
Initialize Isar
    ↓
Initialize Notifications
    ↓
Load all tasks from database
    ↓
Filter tasks with reminderDateTime != null
    ↓
For each pending task:
  - Cancel old notification
  - Reschedule notification
    ↓
App ready
```

### Platform-Specific Handling

**macOS:**
- Uses Darwin notification settings
- Requires permission request
- Supports alerts, badges, sounds

**Windows:**
- Uses Windows notification system
- No additional configuration needed
- Automatic toast notifications

## Data Persistence Strategy

### Isar Database
- **Type**: Embedded, offline-first NoSQL database
- **Storage**: Local file system
- **Performance**: Extremely fast (written in Rust)
- **Features**: ACID transactions, type-safe queries, auto-migrations

### Database Schema
```
Collection: Task
Indexes:
  - id (primary, auto-increment)
  - title (value index for search)
```

### Data Safety
- All writes use transactions
- Auto-increment IDs prevent conflicts
- Schema versioning for future migrations
- Safe null handling throughout

## Error Handling Strategy

### Database Errors
```dart
try {
  final tasks = await _isar.tasks.where().findAll();
  state = AsyncValue.data(tasks);
} catch (e, stackTrace) {
  state = AsyncValue.error(e, stackTrace);
}
```

### Notification Errors
- Graceful degradation if permissions denied
- Skip scheduling for past dates with warning
- Cancel-and-reschedule pattern prevents duplicates

### User Input Errors
- Form validation before submission
- SnackBar messages for feedback
- Prevent invalid date/time selection

## Performance Optimizations

1. **Lazy Loading**: Tasks loaded on-demand
2. **Efficient Queries**: Isar indexes for fast searches
3. **State Caching**: Riverpod caches state
4. **Debounced Search**: (Can be added for large datasets)
5. **Minimal Rebuilds**: Consumer widgets scope rebuilds

## Security Considerations

- **No Network Calls**: Fully offline
- **Local Storage Only**: No data leaves device
- **No Authentication**: No credentials to protect
- **File Permissions**: Import/export uses system file picker

## Testing Strategy (Future)

### Unit Tests
- ViewModel logic
- Service methods
- Model serialization

### Widget Tests
- UI components
- User interactions
- State updates

### Integration Tests
- Full user workflows
- Database operations
- Notification scheduling

## Build Configuration

### Dependencies
```yaml
dependencies:
  flutter_riverpod: ^2.5.1      # State management
  isar: ^3.1.0+1                 # Database
  isar_flutter_libs: ^3.1.0+1    # Database native libs
  flutter_local_notifications: ^17.2.1  # Notifications
  shared_preferences: ^2.3.2     # Settings storage
  file_picker: ^8.1.2            # Import/Export
  path_provider: ^2.1.4          # File paths
  window_manager: ^0.4.2         # Window control
  timezone: ^0.9.4               # Timezone handling

dev_dependencies:
  isar_generator: ^3.1.0+1       # Code generation
  build_runner: ^2.4.12          # Code generation runner
  riverpod_generator: ^2.4.0     # Riverpod code generation
```

### Code Generation
```bash
# Generate Isar schemas
dart run build_runner build --delete-conflicting-outputs

# Watch mode (auto-regenerate on changes)
dart run build_runner watch --delete-conflicting-outputs
```

## Deployment

### macOS
```bash
flutter build macos --release
# Output: build/macos/Build/Products/Release/nag_mj.app
```

### Windows
```bash
flutter build windows --release
# Output: build/windows/runner/Release/nag_mj.exe
```

### Distribution
- macOS: `.app` bundle or `.dmg` installer
- Windows: `.exe` installer or portable `.zip`

## Future Architecture Improvements

1. **Repository Pattern**: Abstract data source
2. **Dependency Injection**: Testable service location
3. **Event Bus**: Decoupled component communication
4. **Caching Layer**: Faster repeated reads
5. **Analytics**: Usage tracking (optional, privacy-focused)
6. **Crash Reporting**: Error logging (local only)

---

**This architecture ensures:**
- ✅ Maintainability
- ✅ Testability
- ✅ Scalability
- ✅ Separation of concerns
- ✅ Offline-first reliability
- ✅ Cross-platform compatibility
