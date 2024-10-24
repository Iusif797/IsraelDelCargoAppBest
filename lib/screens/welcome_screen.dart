// lib/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:israeldelcargoapplication/widgets/custom_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Используем градиентный фон для современного вида
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
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
                  gradientColors: [Color(0xFFe96443), Color(0xFF904e95)],
                ),
                const SizedBox(height: 16.0),
                CustomButton(
                  text: 'Регистрация',
                  onPressed: () {
                    Navigator.pushNamed(context, '/registration');
                  },
                  gradientColors: [Colors.white, Colors.white],
                  textColor: const Color(0xFF0D47A1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
