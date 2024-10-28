// lib/screens/delivery_screen.dart
import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../theme_extensions.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({Key? key}) : super(key: key);

  @override
  _DeliveryScreenState createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  final _formKey = GlobalKey<FormState>();
  String trackingNumber = '';
  String origin = '';
  String destination = '';
  String estimatedDelivery = '';
  bool isLoading = false;
  String message = '';

  @override
  Widget build(BuildContext context) {
    final gradientTheme = Theme.of(context).extension<GradientThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Оформить доставку'),
        backgroundColor: const Color(0xFF0F2027),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: gradientTheme.backgroundGradient,
        ),
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Icon(
                Icons.local_shipping,
                size: 100.0,
                color: Colors.white,
              ),
              const SizedBox(height: 24.0),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Номер отправления',
                        labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.2) : Colors.white,
                      ),
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      onChanged: (value) {
                        trackingNumber = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Пожалуйста, введите номер отправления';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Откуда',
                        labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.2) : Colors.white,
                      ),
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      onChanged: (value) {
                        origin = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Пожалуйста, введите место отправления';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Куда',
                        labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.2) : Colors.white,
                      ),
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      onChanged: (value) {
                        destination = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Пожалуйста, введите место назначения';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Ожидаемая доставка',
                        labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.2) : Colors.white,
                      ),
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      onChanged: (value) {
                        estimatedDelivery = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Пожалуйста, введите дату ожидаемой доставки';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24.0),
                    isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  isLoading = true;
                                  message = '';
                                });
                                bool result = await DatabaseHelper().addShipment(
                                  trackingNumber.trim(),
                                  origin.trim(),
                                  destination.trim(),
                                  estimatedDelivery.trim(),
                                );
                                setState(() {
                                  isLoading = false;
                                  message = result ? 'Отправление успешно оформлено!' : 'Ошибка оформления отправления. Возможно, номер уже существует.';
                                });
                                if (result) {
                                  Navigator.pop(context);
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              elevation: 5.0,
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                            child: const Text(
                              'Оформить',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                    const SizedBox(height: 16.0),
                    Text(
                      message,
                      style: TextStyle(
                        color: message.contains('успешно') ? Colors.green : Colors.red,
                        fontSize: 16.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
