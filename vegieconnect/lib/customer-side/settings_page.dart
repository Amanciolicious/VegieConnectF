import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final green = const Color(0xFFA7C957);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: green,
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFFF6F6F6),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications, color: Colors.black54),
            title: const Text('Notifications'),
            trailing: Switch(value: true, onChanged: (v) {}),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6, color: Colors.black54),
            title: const Text('Theme'),
            trailing: DropdownButton<String>(
              value: 'Light',
              items: const [DropdownMenuItem(value: 'Light', child: Text('Light')), DropdownMenuItem(value: 'Dark', child: Text('Dark'))],
              onChanged: (v) {},
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.black54),
            title: const Text('About'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'VegieConnect',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2024 VegieConnect',
              );
            },
          ),
        ],
      ),
    );
  }
} 