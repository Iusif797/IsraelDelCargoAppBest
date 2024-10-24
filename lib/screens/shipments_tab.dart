import 'package:flutter/material.dart';

class ShipmentsTab extends StatelessWidget {
  const ShipmentsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Здесь будет экран оформления отправлений
    return Center(
      child: Text(
        'Оформить отправление',
        style: TextStyle(fontSize: 18.0),
      ),
    );
  }
}
