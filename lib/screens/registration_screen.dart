// lib/screens/registration_screen.dart
import 'package:flutter/material.dart';
import 'package:israeldelcargoapplication/widgets/custom_button.dart';
import 'package:israeldelcargoapplication/database_helper.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);
      
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}
    
class _RegistrationScreenState extends State<RegistrationScreen> {
  String name = '';
  String email = '';
  String password = '';
  bool isLoading = false;

  final _formKey = GlobalKey<FormState>(); // Для валидации формы
      
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Card(
              color: Colors.white.withOpacity(0.85),
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
                        Icons.person_add_alt_1,
                        size: 100.0,
                        color: Color(0xFF0F2027),
                      ),
                      const SizedBox(height: 24.0),
                      TextFormField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person),
                          labelText: 'Имя',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) {
                          name = value;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Пожалуйста, введите имя';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email),
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        obscureText: true,
                        onChanged: (value) {
                          password = value;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Пожалуйста, введите пароль';
                          }
                          if (value.length < 6) {
                            return 'Пароль должен быть не менее 6 символов';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24.0),
                      isLoading
                          ? const CircularProgressIndicator()
                          : CustomButton(
                              text: 'Зарегистрироваться',
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  setState(() {
                                    isLoading = true;
                                  });
                                  try {
                                    int result = await DatabaseHelper().registerUser(
                                        name.trim(), email.trim(), password.trim());
                                    if (result > 0) {
                                      // Регистрация успешна, переходим на экран входа
                                      Navigator.pushReplacementNamed(
                                          context, '/login');
                                    }
                                  } catch (e) {
                                    setState(() {
                                      isLoading = false;
                                    });
                                    // Показать сообщение об ошибке (например, email уже существует)
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Ошибка регистрации: ${e.toString()}')),
                                    );
                                  }
                                }
                              },
                              gradientColors: [Color(0xFFe96443), Color(0xFF904e95)],
                            ),
                      const SizedBox(height: 16.0),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        child: const Text(
                          'Уже есть аккаунт? Войти',
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
