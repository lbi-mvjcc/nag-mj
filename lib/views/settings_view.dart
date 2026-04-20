import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/settings_viewmodel.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  late final TextEditingController _appNameController;

  static const List<Color> _sidebarColorOptions = [
    Color(0xFF06402B),
    Color(0xFF0B3954),
    Color(0xFF1F2937),
    Color(0xFF7C2D12),
    Color(0xFF14532D),
    Color(0xFF4A044E),
  ];

  static const List<Color> _darkThemeColorOptions = [
    Color(0xFF06402B),
    Color(0xFF1D4ED8),
    Color(0xFF0F766E),
    Color(0xFFB45309),
    Color(0xFFBE123C),
    Color(0xFF7E22CE),
  ];

  @override
  void initState() {
    super.initState();
    _appNameController = TextEditingController();
  }

  @override
  void dispose() {
    _appNameController.dispose();
    super.dispose();
  }

  Future<void> _pickLogoFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'bmp', 'ico'],
      withData: false,
    );

    if (result == null || result.files.single.path == null) {
      return;
    }

    await ref
        .read(appSettingsProvider.notifier)
        .setLogoPath(result.files.single.path);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    if (_appNameController.text != settings.appName) {
      _appNameController.text = settings.appName;
      _appNameController.selection = TextSelection.fromPosition(
        TextPosition(offset: _appNameController.text.length),
      );
    }

    final logoPath = settings.logoPath;
    final hasLogo = settings.hasCustomLogoPath;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Settings',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Customize app identity, layout, and colors.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App Identity',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _appNameController,
                  decoration: const InputDecoration(
                    labelText: 'App Name',
                    hintText: 'Enter your app name',
                  ),
                  onSubmitted: (value) async {
                    await ref
                        .read(appSettingsProvider.notifier)
                        .setAppName(value);
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      backgroundImage: hasLogo && logoPath != null
                          ? FileImage(File(logoPath))
                          : const AssetImage('assets/images/app_icon.png')
                                as ImageProvider,
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _pickLogoFile,
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Change Logo'),
                    ),
                    if (hasLogo)
                      TextButton.icon(
                        onPressed: () async {
                          await ref
                              .read(appSettingsProvider.notifier)
                              .setLogoPath(null);
                        },
                        icon: const Icon(Icons.restore),
                        label: const Text('Reset Logo'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keyboard Shortcuts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Use these hotkeys anywhere in the app.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 10),
                const _ShortcutItem(keys: 'Ctrl + A', description: 'Select All'),
                const _ShortcutItem(keys: 'Ctrl + D', description: 'Toggle Theme'),
                const _ShortcutItem(keys: 'Ctrl + E', description: 'Export Tasks'),
                const _ShortcutItem(keys: 'Ctrl + F', description: 'Focus Search'),
                const _ShortcutItem(keys: 'Ctrl + G', description: 'Toggle Task Grid'),
                const _ShortcutItem(keys: 'Ctrl + I', description: 'Import Tasks'),
                const _ShortcutItem(keys: 'Ctrl + N', description: 'New Task'),
                const _ShortcutItem(keys: 'Ctrl + R', description: 'Refresh View'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task List Layout',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Use Grid View'),
                  subtitle: const Text(
                    'Turn off to use the standard list view.',
                  ),
                  value: settings.isTaskGridView,
                  onChanged: (value) async {
                    await ref
                        .read(appSettingsProvider.notifier)
                        .setTaskGridView(value);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sidebar Color',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _sidebarColorOptions
                      .map(
                        (color) => _ColorSwatchOption(
                          color: color,
                          selected:
                              settings.sidebarColorValue == color.toARGB32(),
                          onTap: () async {
                            await ref
                                .read(appSettingsProvider.notifier)
                                .setSidebarColor(color);
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                _RgbColorEditor(
                  title: 'Custom RGB (Sidebar)',
                  initialColor: Color(settings.sidebarColorValue),
                  onChanged: (color) async {
                    await ref
                        .read(appSettingsProvider.notifier)
                        .setSidebarColor(color, persist: false);
                  },
                  onChangeEnd: (color) async {
                    await ref
                        .read(appSettingsProvider.notifier)
                        .setSidebarColor(color);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dark Mode Accent Color',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _darkThemeColorOptions
                      .map(
                        (color) => _ColorSwatchOption(
                          color: color,
                          selected:
                              settings.darkThemeSeedColorValue ==
                              color.toARGB32(),
                          onTap: () async {
                            await ref
                                .read(appSettingsProvider.notifier)
                                .setDarkThemeSeedColor(color);
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                _RgbColorEditor(
                  title: 'Custom RGB (Dark Mode)',
                  initialColor: Color(settings.darkThemeSeedColorValue),
                  onChanged: (color) async {
                    await ref
                        .read(appSettingsProvider.notifier)
                        .setDarkThemeSeedColor(color, persist: false);
                  },
                  onChangeEnd: (color) async {
                    await ref
                        .read(appSettingsProvider.notifier)
                        .setDarkThemeSeedColor(color);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ColorSwatchOption extends StatelessWidget {
  const _ColorSwatchOption({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.transparent,
              width: selected ? 2 : 0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: selected
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : null,
        ),
      ),
    );
  }
}

class _RgbColorEditor extends StatefulWidget {
  const _RgbColorEditor({
    required this.title,
    required this.initialColor,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final String title;
  final Color initialColor;
  final Future<void> Function(Color color) onChanged;
  final Future<void> Function(Color color) onChangeEnd;

  @override
  State<_RgbColorEditor> createState() => _RgbColorEditorState();
}

class _RgbColorEditorState extends State<_RgbColorEditor> {
  double _red = 0;
  double _green = 0;
  double _blue = 0;

  @override
  void initState() {
    super.initState();
    _syncFromColor(widget.initialColor, notify: false);
  }

  @override
  void didUpdateWidget(covariant _RgbColorEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialColor.toARGB32() != widget.initialColor.toARGB32()) {
      _syncFromColor(widget.initialColor);
    }
  }

  void _syncFromColor(Color color, {bool notify = true}) {
    _red = _channelToPercent(color.red);
    _green = _channelToPercent(color.green);
    _blue = _channelToPercent(color.blue);
    if (notify && mounted) {
      setState(() {});
    }
  }

  Color _previewColor() {
    final r = _percentToChannel(_red);
    final g = _percentToChannel(_green);
    final b = _percentToChannel(_blue);
    return Color.fromARGB(255, r, g, b);
  }

  double _channelToPercent(int channel) {
    return (channel / 255) * 100;
  }

  int _percentToChannel(double percent) {
    return ((percent.clamp(0, 100) / 100) * 255).round().clamp(0, 255);
  }

  Future<void> _handleColorChanged() async {
    await widget.onChanged(_previewColor());
  }

  Future<void> _handleColorChangeEnd() async {
    await widget.onChangeEnd(_previewColor());
  }

  @override
  Widget build(BuildContext context) {
    final preview = _previewColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Drag sliders from 0% to 100%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: preview,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _RgbSlider(
          label: 'R',
          value: _red,
          activeColor: Colors.redAccent,
          onChanged: (value) async {
            setState(() => _red = value);
            await _handleColorChanged();
          },
          onChangeEnd: (_) async {
            await _handleColorChangeEnd();
          },
        ),
        _RgbSlider(
          label: 'G',
          value: _green,
          activeColor: Colors.green,
          onChanged: (value) async {
            setState(() => _green = value);
            await _handleColorChanged();
          },
          onChangeEnd: (_) async {
            await _handleColorChangeEnd();
          },
        ),
        _RgbSlider(
          label: 'B',
          value: _blue,
          activeColor: Colors.blue,
          onChanged: (value) async {
            setState(() => _blue = value);
            await _handleColorChanged();
          },
          onChangeEnd: (_) async {
            await _handleColorChangeEnd();
          },
        ),
        const SizedBox(height: 4),
        Text(
          'RGB(${_percentToChannel(_red)}, ${_percentToChannel(_green)}, ${_percentToChannel(_blue)})',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

class _RgbSlider extends StatelessWidget {
  const _RgbSlider({
    required this.label,
    required this.value,
    required this.activeColor,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final String label;
  final double value;
  final Color activeColor;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 100,
            divisions: 100,
            activeColor: activeColor,
            label: '${value.round()}%',
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '${value.round()}%',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _ShortcutItem extends StatelessWidget {
  const _ShortcutItem({required this.keys, required this.description});

  final String keys;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
              ),
              child: Text(
                keys,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: colorScheme.onPrimaryContainer,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(
              description,
              style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
