# TaskMate - Quick Start Guide

## 🚀 Getting Started

### Running the App

**For macOS:**
```bash
flutter run -d macos
```

**For Windows:**
```bash
flutter run -d windows
```

**Build Release Version:**
```bash
# macOS
flutter build macos --release

# Windows
flutter build windows --release
```

## 📱 Using the App

### Creating Your First Task

1. **Click the "New Task" button** (floating action button at bottom-right)
2. **Enter a title** (required)
3. **Add a description** (optional)
4. **Click "Create Task"**

### Setting a Reminder

1. **Create or edit a task**
2. **Toggle "Set Reminder"** to enable
3. **Click "Select Date"** to choose a date
4. **Click "Select Time"** to choose a time
5. **Save the task**

### Creating a Recurring Reminder

1. **Enable reminder first** (steps above)
2. **Toggle "Recurring Reminder"**
3. **Choose recurrence type**:
   - Daily
   - Weekly
   - Monthly
4. **Set interval** (e.g., every 2 days, every 3 weeks)
5. **Optionally set an end date**
6. **Save the task**

### Managing Tasks

**View Tasks:**
- **All Tasks**: Shows all tasks
- **With Reminders**: Shows only tasks with reminders
- **Recurring**: Shows only recurring tasks

**Filter Tasks:**
- Use the "Status" dropdown: All, Pending, Completed

**Sort Tasks:**
- Use the "Sort by" dropdown: Created, Reminder, Title

**Search Tasks:**
- Type in the search bar to filter by title or description

**Edit a Task:**
- Click on the task card OR
- Click the menu icon (⋮) → Edit

**Delete a Task:**
- Click the menu icon (⋮) → Delete
- Confirm deletion in the dialog

**Mark Complete:**
- Click the checkbox next to any task

### Import/Export

**Export Tasks:**
1. Click "Export" button in sidebar
2. Choose save location
3. JSON file is created

**Import Tasks:**
1. Click "Import" button in sidebar
2. Select previously exported JSON file
3. Tasks are added to database

### Dark Mode

Toggle dark mode using the switch at the bottom of the sidebar.

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+N` (Windows) / `Cmd+N` (Mac) | New task |
| `Ctrl+F` / `Cmd+F` | Focus search |
| `Ctrl+E` / `Cmd+E` | Export tasks |
| `Ctrl+I` / `Cmd+I` | Import tasks |
| `Ctrl+D` / `Cmd+D` | Toggle dark mode |

## 💡 Tips & Tricks

1. **Visual Indicators**:
   - 🔔 Bell icon = Task has a reminder
   - 🔄 Repeat icon = Task is recurring
   - 📅 Calendar icon = Shows end date for recurring tasks

2. **Completed Tasks**: Appear with strike-through text and dimmed colors

3. **Reminder Times**: Displayed in the task card for quick reference

4. **Recurring Patterns**:
   - "Every 2 days" = fires every other day
   - "Every 3 weeks" = fires every 3 weeks on the same weekday
   - "Every 2 months" = fires every 2 months on the same day

5. **App Restart**: All pending reminders are automatically rescheduled when you restart the app

## 🐛 Troubleshooting

**Notifications not appearing?**
- Check system notification settings
- macOS: System Preferences > Notifications > TaskMate
- Windows: Settings > System > Notifications > TaskMate
- Ensure notifications are enabled

**Can't create tasks?**
- Title is required
- Check that date/time are valid (not in the past for new tasks)

**App won't start?**
- Run `flutter clean`
- Run `flutter pub get`
- Try running again

**Database issues?**
- Database is stored in app documents directory
- Safe to delete and restart app if needed

## 📊 Project Structure

```
lib/
├── main.dart                    # App entry point
├── core/                        # Constants, theme, utilities
├── models/                      # Data models (Isar schemas)
├── services/                    # Business logic services
├── viewmodels/                  # State management
├── views/                       # Main screens
└── widgets/                     # Reusable components
```

## 🎨 Customization

Want to change the accent color?
- Edit `lib/views/main_app_view.dart`
- Find `Color(0xFF6366F1)` and change to your preferred color

## 📝 Notes

- **All data is stored locally** - no cloud sync
- **No authentication required** - works offline
- **Cross-platform** - works on both Windows and macOS
- **Open format** - export files are standard JSON

---

**Enjoy organizing your tasks with TaskMate!** 🎉
