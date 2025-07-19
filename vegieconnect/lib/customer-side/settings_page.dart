import 'package:vegieconnect/theme.dart'; // For AppColors
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: Text('Settings', style: AppTextStyles.headline.copyWith(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Neumorphic(
          style: AppNeumorphic.card,
          child: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.notifications, color: Colors.black54),
                title: Text('Notifications', style: AppTextStyles.body),
                trailing: Switch(value: true, onChanged: (v) {}),
              ),
              ListTile(
                leading: const Icon(Icons.brightness_6, color: Colors.black54),
                title: Text('Theme', style: AppTextStyles.body),
                trailing: DropdownButton<String>(
                  value: 'Light',
                  items: const [DropdownMenuItem(value: 'Light', child: Text('Light')), DropdownMenuItem(value: 'Dark', child: Text('Dark'))],
                  onChanged: (v) {},
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.black54),
                title: Text('About', style: AppTextStyles.body),
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
        ),
      ),
    );
  }
} 