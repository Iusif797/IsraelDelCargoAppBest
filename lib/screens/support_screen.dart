// lib/screens/support_screen.dart
import 'package:flutter/material.dart';
import '../theme_extensions.dart'; // Импортируем GradientThemeExtension

class SupportScreen extends StatelessWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gradientTheme = Theme.of(context).extension<GradientThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Поддержка'),
        backgroundColor: const Color(0xFF0F2027),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: gradientTheme.backgroundGradient,
        ),
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            'Здесь будет информация о поддержке.',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: isDark ? Colors.white : Colors.black,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
