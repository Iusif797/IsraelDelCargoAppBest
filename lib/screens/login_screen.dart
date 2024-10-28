// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../database_helper.dart';
import 'home_screen.dart';
import '../theme_extensions.dart'; // Импортируем GradientThemeExtension

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
      
  @override
  _LoginScreenState createState() => _LoginScreenState();
}
    
class _LoginScreenState extends State<LoginScreen> {
  String email = '';
  String password = '';
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>(); // Для валидации формы
      
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Card(
              color: isDark ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.85),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              elevation: 8.0,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey, // Привязываем форму к ключу
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.lock_outline,
                        size: 100.0,
                        color: Color(0xFF0F2027),
                      ),
                      const SizedBox(height: 24.0),
                      TextFormField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email),
                          labelText: 'Email',
                          labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.white.withOpacity(0.2) : Colors.white,
                        ),
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        onChanged: (value) {
                          email = value;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Пожалуйста, введите email';
                          }
                          // Простая проверка формата email
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Введите корректный email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock),
                          labelText: 'Пароль',
                          labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.white.withOpacity(0.2) : Colors.white,
                        ),
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        obscureText: true,
                        onChanged: (value) {
                          password = value;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Пожалуйста, введите пароль';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24.0),
                      isLoading
                          ? const CircularProgressIndicator()
                          : CustomButton(
                              text: 'Войти',
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  setState(() {
                                    isLoading = true;
                                  });
                                  var user = await DatabaseHelper()
                                      .getUser(email.trim(), password.trim());
                                  if (user != null) {
                                    // Переход на главный экран после успешного входа
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            HomeScreen(userName: user['name'], email: user['email']),
                                      ),
                                    );
                                  } else {
                                    setState(() {
                                      isLoading = false;
                                    });
                                    // Показать сообщение об ошибке
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Неверный email или пароль')),
                                    );
                                  }
                                }
                              },
                            ),
                      const SizedBox(height: 16.0),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/registration');
                        },
                        child: const Text(
                          'Нет аккаунта? Зарегистрироваться',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
