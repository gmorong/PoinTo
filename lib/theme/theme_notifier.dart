import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;
  SharedPreferences? prefs;

  ThemeNotifier() {
    _init();
  }
  Future<void> _init() async {
    prefs = await SharedPreferences.getInstance();

    int savedThemeIndex = prefs?.getInt("theme") ?? ThemeMode.light.index;
    themeMode = (savedThemeIndex == ThemeMode.dark.index) ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void toggleTheme(bool isDark) {
    themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    prefs?.setInt("theme", themeMode.index);
  }
}