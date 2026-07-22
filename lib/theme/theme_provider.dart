import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── THEME PROVIDER ───────────────────────────────────────────────────────────

class ThemeProvider extends ChangeNotifier {
  bool _isDark;
  ThemeProvider(this._isDark);

  bool get isDark => _isDark;

  static const Color sidebarBg = Color(0xFF1A1A2E);
  static const Color accent    = Color(0xFFD4456E);

  Color get pageBg          => _isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF5F5F5);
  Color get cardBg          => _isDark ? const Color(0xFF1A1A2E) : Colors.white;
  Color get tableRowEven    => _isDark ? const Color(0xFF16162A) : Colors.white;
  Color get tableRowOdd     => _isDark ? const Color(0xFF1E1E30) : const Color(0xFFFAFAFA);
  Color get borderColor     => _isDark ? const Color(0xFF2A2A40) : Colors.grey.shade200;
  Color get textPrimary     => _isDark ? const Color(0xFFEEEEFF) : const Color(0xFF1A1A2E);
  Color get textSecondary   => _isDark ? const Color(0xFF8888AA) : Colors.grey.shade600;
  Color get inputFill       => _isDark ? const Color(0xFF1E1E30) : Colors.grey.shade50;
  Color get dividerColor    => _isDark ? const Color(0xFF2A2A40) : Colors.grey.shade200;
  Color get billPanelBg     => _isDark ? const Color(0xFF13131F) : Colors.grey.shade50;
  Color get chargeSectionBg => _isDark ? const Color(0xFF1A1A2E) : Colors.white;

  Future<void> toggle() async {
    _isDark = !_isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _isDark);
    notifyListeners();
  }
}
