// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../theme_extensions.dart'; // Импортируем GradientThemeExtension

class HomeScreen extends StatelessWidget {
  final String userName;
  final String email;

  const HomeScreen({
    Key? key,
    required this.userName,
    required this.email,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gradientTheme = Theme.of(context).extension<GradientThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // Верхняя синяя секция с логотипом
          Container(
            width: double.infinity,
            color: const Color(0xFF0D47A1), // Чисто синий цвет
            padding: const EdgeInsets.symmetric(vertical: 40.0),
            child: Column(
              children: [
                // Логотип по центру
                Image.asset(
                  'assets/images/logo.png',
                  height: 100.0,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20.0),
                // Круглый поисковый бар
                Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: 50.0,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(25.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10.0,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Поиск...',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Нижняя белая секция с меню и выбором услуг
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.white, // Белый фон
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
              child: Column(
                children: [
                  // Меню с тремя кнопками
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Кнопка "Рассчитать"
                      Expanded(
                        child: CustomButton(
                          text: 'Рассчитать',
                          onPressed: () {
                            // Логика для расчёта
                            Navigator.pushNamed(context, '/calculate');
                          },
                          textColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      // Кнопка "Оформить доставку"
                      Expanded(
                        child: CustomButton(
                          text: 'Оформить доставку',
                          onPressed: () {
                            // Логика для оформления доставки
                            Navigator.pushNamed(context, '/shipment');
                          },
                          textColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      // Кнопка "Отследить посылку"
                      Expanded(
                        child: CustomButton(
                          text: 'Отследить посылку',
                          onPressed: () {
                            // Логика для отслеживания посылки
                            Navigator.pushNamed(context, '/tracking');
                          },
                          textColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30.0),
                  // Раздел "Выбор услуг"
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Выбор услуг',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  // Пример выбора услуг
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20.0,
                      mainAxisSpacing: 20.0,
                      children: [
                        // Услуга 1
                        ServiceCard(
                          icon: Icons.local_shipping,
                          title: 'Доставка',
                          onTap: () {
                            Navigator.pushNamed(context, '/delivery');
                          },
                        ),
                        // Услуга 2
                        ServiceCard(
                          icon: Icons.calculate,
                          title: 'Рассчитать стоимость',
                          onTap: () {
                            Navigator.pushNamed(context, '/calculate');
                          },
                        ),
                        // Услуга 3
                        ServiceCard(
                          icon: Icons.track_changes,
                          title: 'Отслеживание',
                          onTap: () {
                            Navigator.pushNamed(context, '/tracking');
                          },
                        ),
                        // Услуга 4
                        ServiceCard(
                          icon: Icons.support_agent,
                          title: 'Поддержка',
                          onTap: () {
                            Navigator.pushNamed(context, '/support');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Кастомный виджет для карточек услуг
class ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const ServiceCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 10.0,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 50.0,
              color: const Color(0xFF0D47A1),
            ),
            const SizedBox(height: 10.0),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
