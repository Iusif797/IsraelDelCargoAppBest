// lib/screens/profile_tab.dart
import 'package:flutter/material.dart';
import 'help_screen.dart'; // Исправленный импорт HelpScreen
import '../theme_extensions.dart'; // Импортируем GradientThemeExtension

class ProfileTab extends StatelessWidget {
  final String userName;
  final String email;
  final VoidCallback onEditProfile;
  final VoidCallback onViewHistory;

  const ProfileTab({
    Key? key,
    required this.userName,
    required this.email,
    required this.onEditProfile,
    required this.onViewHistory,
  }) : super(key: key);

  Widget buildProfileItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      color: Colors.white.withOpacity(0.1),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradientTheme = Theme.of(context).extension<GradientThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: gradientTheme.backgroundGradient,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40.0),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50.0,
                  backgroundColor: Colors.transparent, // Убираем фон аватара
                  child: Icon(
                    Icons.person,
                    size: 80.0,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16.0),
                Text(
                  userName,
                  style: const TextStyle(fontSize: 24.0, color: Colors.white),
                ),
                const SizedBox(height: 8.0),
                Text(
                  email,
                  style: TextStyle(fontSize: 16.0, color: isDark ? Colors.white70 : Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24.0),
          Expanded(
            child: ListView(
              children: [
                buildProfileItem(
                  icon: Icons.edit,
                  title: 'Редактировать профиль',
                  onTap: onEditProfile,
                ),
                buildProfileItem(
                  icon: Icons.history,
                  title: 'История отправлений',
                  onTap: onViewHistory,
                ),
                buildProfileItem(
                  icon: Icons.settings,
                  title: 'Настройки',
                  onTap: () {
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
                buildProfileItem(
                  icon: Icons.help_outline,
                  title: 'Помощь',
                  onTap: () {
                    // Переход на экран помощи
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HelpScreen()),
                    );
                  },
                ),
                buildProfileItem(
                  icon: Icons.exit_to_app,
                  title: 'Выйти',
                  onTap: () {
                    // Действие при нажатии (например, выход из аккаунта)
                    Navigator.pushReplacementNamed(context, '/');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
