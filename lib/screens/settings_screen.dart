import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _themeMode = _ThemeModeScope.of(context)?.themeMode ?? ThemeMode.light;
  }

  void _changeTheme(ThemeMode? themeMode) {
    if (themeMode != null) {
      _ThemeModeScope.of(context)?.changeTheme(themeMode);
      setState(() {
        _themeMode = themeMode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Тема приложения'),
            subtitle: Text(_themeMode == ThemeMode.light ? 'Светлая' : 'Тёмная'),
            trailing: Switch(
              value: _themeMode == ThemeMode.dark,
              onChanged: (value) {
                _changeTheme(value ? ThemeMode.dark : ThemeMode.light);
              },
            ),
          ),
          // Добавьте другие настройки, если необходимо
        ],
      ),
    );
  }
}

// Добавляем доступ к ThemeModeScope
class _ThemeModeScope extends InheritedWidget {
  final ThemeMode themeMode;
  final Function(ThemeMode) changeTheme;

  const _ThemeModeScope({
    Key? key,
    required this.themeMode,
    required this.changeTheme,
    required Widget child,
  }) : super(key: key, child: child);

  static _ThemeModeScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ThemeModeScope>();
  }

  @override
  bool updateShouldNotify(_ThemeModeScope oldWidget) {
    return oldWidget.themeMode != themeMode;
  }
}
