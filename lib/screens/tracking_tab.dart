import 'package:flutter/material.dart';

class TrackingTab extends StatelessWidget {
  const TrackingTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Здесь будет экран отслеживания посылок
    return Center(
      child: Text(
        'Отслеживание посылок',
        style: TextStyle(fontSize: 18.0),
      ),
    );
  }
}
