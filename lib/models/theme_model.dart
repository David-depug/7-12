import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme model for managing app theme state
class ThemeModel extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  static const String _themePrefKey = 'theme_mode';

  ThemeModel() {
    _loadThemePreference();
  }

  /// Current theme mode
  ThemeMode get themeMode => _themeMode;

  /// Check if currently in dark mode
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Check if currently in light mode
  bool get isLightMode => _themeMode == ThemeMode.light;

  /// Load saved theme preference from SharedPreferences
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themePrefKey);
      
      if (savedTheme != null) {
        switch (savedTheme) {
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          case 'system':
            _themeMode = ThemeMode.system;
            break;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    }
  }

  /// Save theme preference to SharedPreferences
  Future<void> _saveThemePreference(String theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePrefKey, theme);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  /// Set theme to light mode (Bright Mood)
  Future<void> setLightMode() async {
    _themeMode = ThemeMode.light;
    await _saveThemePreference('light');
    notifyListeners();
  }

  /// Set theme to dark mode
  Future<void> setDarkMode() async {
    _themeMode = ThemeMode.dark;
    await _saveThemePreference('dark');
    notifyListeners();
  }

  /// Set theme to system default
  Future<void> setSystemMode() async {
    _themeMode = ThemeMode.system;
    await _saveThemePreference('system');
    notifyListeners();
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setDarkMode();
    } else {
      await setLightMode();
    }
  }
}


