import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Color _chatWallpaperColor = Colors.transparent;
  Color _bubbleColor = AppColors.primary;
  double _fontSizeDelta = 0.0; // -2.0 small, 0.0 medium, +2.0 large

  ThemeMode get themeMode => _themeMode;
  Color get chatWallpaperColor => _chatWallpaperColor;
  Color get bubbleColor => _bubbleColor;
  double get fontSizeDelta => _fontSizeDelta;

  ThemeProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Theme Mode
    final themeStr = prefs.getString(AppConstants.prefKeyThemeMode);
    if (themeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (themeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }

    // Wallpaper
    final wallColorVal = prefs.getInt(AppConstants.prefKeyChatWallpaper);
    if (wallColorVal != null) {
      _chatWallpaperColor = Color(wallColorVal);
    }

    // Bubble Color
    final bubbleColorVal = prefs.getInt(AppConstants.prefKeyBubbleColor);
    if (bubbleColorVal != null) {
      _bubbleColor = Color(bubbleColorVal);
    }

    // Font Size
    final fontDelta = prefs.getDouble(AppConstants.prefKeyFontSize);
    if (fontDelta != null) {
      _fontSizeDelta = fontDelta;
    }

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    String val = 'system';
    if (mode == ThemeMode.dark) val = 'dark';
    if (mode == ThemeMode.light) val = 'light';
    await prefs.setString(AppConstants.prefKeyThemeMode, val);
  }

  Future<void> setChatWallpaper(Color color) async {
    _chatWallpaperColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefKeyChatWallpaper, color.value);
  }

  Future<void> setBubbleColor(Color color) async {
    _bubbleColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefKeyBubbleColor, color.value);
  }

  Future<void> setFontSizeDelta(double delta) async {
    _fontSizeDelta = delta;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.prefKeyFontSize, delta);
  }
}
