// lib/widgets/custom_button.dart
import 'package:flutter/material.dart';
import '../theme_extensions.dart'; // Импортируем GradientThemeExtension

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? textColor; // Опциональный цвет текста

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Получаем GradientThemeExtension из текущей темы
    final gradientTheme = Theme.of(context).extension<GradientThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        elevation: 5.0, // Добавлена тень для глубины
        backgroundColor: Colors.transparent, // Убираем стандартный цвет
        shadowColor: Colors.transparent,     // Убираем стандартную тень
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: gradientTheme.buttonGradient,
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: Container(
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: textColor ?? Colors.white, // Белый текст по умолчанию
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
