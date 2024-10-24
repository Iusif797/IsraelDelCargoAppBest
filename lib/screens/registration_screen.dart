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
      appBar: AppBar(
        title: const Text('Регистрация'),
        backgroundColor: const Color(0xFF0D47A1),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey, // Привязываем форму к ключу
          child: Column(
            children: <Widget>[
              const SizedBox(height: 24.0),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Имя',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
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
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                onChanged: (value) {
                  email = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите email';
                  }
                  // Дополнительная проверка формата email может быть добавлена здесь
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Пароль',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
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
                              SnackBar(
                                  content: Text('Ошибка регистрации: ${e.toString()}')),
                            );
                          }
                        }
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
