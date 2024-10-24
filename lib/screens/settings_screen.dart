// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:israeldelcargoapplication/providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        backgroundColor: const Color(0xFF0F2027),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
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
