// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme_extensions.dart'; // Импортируем GradientThemeExtension

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.themeMode == ThemeMode.dark;
    final gradientTheme = Theme.of(context).extension<GradientThemeExtension>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        backgroundColor: const Color(0xFF0F2027),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: gradientTheme.backgroundGradient,
        ),
        child: ListView(
          children: [
            const SizedBox(height: 24.0),
            ListTile(
              leading: const Icon(Icons.color_lens, color: Colors.white),
              title: const Text(
                'Тема приложения',
                style: TextStyle(color: Colors.white, fontSize: 18.0),
              ),
              subtitle: Text(
                isDark ? 'Тёмная' : 'Светлая',
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: Switch(
                value: isDark,
                onChanged: (value) {
                  themeProvider.toggleTheme(value);
                },
                activeColor: const Color(0xFFE100FF),
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.grey.shade700,
              ),
            ),
            const Divider(color: Colors.white70),
            // Добавьте другие настройки, если необходимо
          ],
        ),
      ),
    );
  }
}
