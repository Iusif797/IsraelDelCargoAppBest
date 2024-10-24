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
            colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
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
                ),
                const SizedBox(height: 16.0),
                CustomButton(
                  text: 'Регистрация',
                  color: Colors.white,
                  textColor: const Color(0xFF0D47A1),
                  onPressed: () {
                    Navigator.pushNamed(context, '/registration');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
