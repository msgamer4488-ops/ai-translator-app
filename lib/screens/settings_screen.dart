import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  final ValueChanged<bool> onDarkModeChanged;

  const SettingsScreen({super.key, required this.onDarkModeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = SettingsService();
  bool _darkMode = true;
  int _chunkSize = 4000;
  String _sttLocale = 'en_US';

  final _chunkController = TextEditingController();
  final _sttController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _darkMode = await _settings.getDarkMode();
    _chunkSize = await _settings.getChunkSize();
    _sttLocale = await _settings.getSttLocale();
    _chunkController.text = _chunkSize.toString();
    _sttController.text = _sttLocale;
    setState(() {});
  }

  Future<void> _save() async {
    await _settings.setDarkMode(_darkMode);
    await _settings.setChunkSize(int.tryParse(_chunkController.text) ?? 4000);
    await _settings.setSttLocale(_sttController.text.trim().isEmpty ? 'en_US' : _sttController.text.trim());
    widget.onDarkModeChanged(_darkMode);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved.')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Dark theme'),
            value: _darkMode,
            onChanged: (v) => setState(() => _darkMode = v),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _chunkController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Translation chunk size (characters)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _sttController,
            decoration: const InputDecoration(
              labelText: 'Speech recognition locale (e.g. en_US, hi_IN)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('Save Settings')),
        ],
      ),
    );
  }
}
