import 'package:flutter/material.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Здесь будет экран профиля пользователя
    return Center(
      child: Text(
        'Профиль пользователя',
        style: TextStyle(fontSize: 18.0),
      ),
    );
  }
}
