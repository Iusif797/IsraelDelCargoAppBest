// lib/screens/help_screen.dart
import 'package:flutter/material.dart';
import '../theme_extensions.dart'; // Импортируем GradientThemeExtension

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Получаем GradientThemeExtension из текущей темы
    final gradientTheme = Theme.of(context).extension<GradientThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Помощь'),
        backgroundColor: const Color(0xFF0F2027),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: gradientTheme.backgroundGradient,
        ),
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            'Это экран помощи. Здесь вы можете разместить информацию о том, как пользоваться приложением, ответы на часто задаваемые вопросы и другие полезные сведения.',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 16.0,
            ),
          ),
        ),
      ),
    );
  }
}
