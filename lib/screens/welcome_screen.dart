// lib/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../theme_extensions.dart'; // Импортируем GradientThemeExtension

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Получаем GradientThemeExtension из текущей темы
    final gradientTheme = Theme.of(context).extension<GradientThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Используем градиентный фон из темы
      body: Container(
        decoration: BoxDecoration(
          gradient: gradientTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              // Выравниваем содержимое по центру
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Иконка вместо логотипа
                const Icon(
                  Icons.local_shipping,
                  size: 100.0,
                  color: Colors.white,
                ),
                const SizedBox(height: 24.0),
                const Text(
                  'Добро пожаловать в',
                  style: TextStyle(
                    fontSize: 28.0,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'ISRAELDELCARGO',
                  style: TextStyle(
                    fontSize: 36.0,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 48.0),
                CustomButton(
                  text: 'Войти',
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  textColor: Colors.white,
                ),
                const SizedBox(height: 16.0),
                CustomButton(
                  text: 'Регистрация',
                  onPressed: () {
                    Navigator.pushNamed(context, '/registration');
                  },
                  textColor: isDark ? Colors.black : Colors.blue, // Цвет текста для контраста
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
