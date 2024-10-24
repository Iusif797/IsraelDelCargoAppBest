import 'package:flutter/material.dart';
import 'package:israeldelcargoapplication/widgets/custom_button.dart';
import 'package:israeldelcargoapplication/database_helper.dart';
import 'package:israeldelcargoapplication/screens/home_screen.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Вход'),
        backgroundColor: const Color(0xFF0D47A1),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey, // Привязываем форму к ключу
          child: Column(
            children: <Widget>[
              const SizedBox(height: 48.0),
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
                                    HomeScreen(userName: user['name']),
                              ),
                            );
                          } else {
                            setState(() {
                              isLoading = false;
                            });
                            // Показать сообщение об ошибке
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Неверный email или пароль')),
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
