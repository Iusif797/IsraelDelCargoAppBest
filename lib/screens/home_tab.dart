import 'package:flutter/material.dart';

class HomeTab extends StatelessWidget {
  final String userName;

  const HomeTab({Key? key, required this.userName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Здравствуйте, $userName!',
            style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16.0),
          const Text(
            'Добро пожаловать в ISRAELDELCARGO. Мы рады видеть вас!',
            style: TextStyle(fontSize: 16.0),
          ),
          const SizedBox(height: 24.0),
          Card(
            elevation: 4.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: ListTile(
              leading: Icon(Icons.local_shipping, color: Theme.of(context).primaryColor),
              title: const Text('Оформить новое отправление'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Переход на экран оформления отправления
              },
            ),
          ),
          const SizedBox(height: 16.0),
          Card(
            elevation: 4.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: ListTile(
              leading: Icon(Icons.track_changes, color: Theme.of(context).primaryColor),
              title: const Text('Отследить посылку'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Переход на экран отслеживания
              },
            ),
          ),
          const SizedBox(height: 16.0),
          // Добавьте другие карточки или элементы по необходимости
        ],
      ),
    );
  }
}
