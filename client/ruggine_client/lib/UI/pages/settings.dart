import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notificationsEnabled = true;
  String _appVersion = '';
  String _userId = '';
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });

    final auth = ref.read(authProvider);
    setState(() {
      _userId = auth?.id ?? 'N/A';
      _username = auth?.username ?? 'N/A';
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark;
    final themeNotifier = ref.read(themeNotifierProvider.notifier);
    final auth = ref.read(authProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text("Impostazioni")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
              "Preferenze",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
          ),
          SwitchListTile(
            title: const Text("Tema scuro"),
            value: isDark,
            onChanged: (val) {
              themeNotifier.toggleTheme(val);
            },
          ),
          SwitchListTile(
            title: const Text("Notifiche"),
            value: _notificationsEnabled,
            onChanged: (val) {
              setState(() {
                _notificationsEnabled = val;
              });
            },
          ),
          const Divider(),
          const SizedBox(height: 12),
          Text("ID Utente: $_userId"),
          const SizedBox(height: 8),
          Text("Username: $_username"),
          const SizedBox(height: 8),
          Text("Versione app: $_appVersion"),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text("Logout"),
            onPressed: () async {
              await auth.logout();
            },
          ),
        ],
      ),
    );
  }
}
