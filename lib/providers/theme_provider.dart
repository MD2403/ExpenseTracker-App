import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CardStyle { rounded, sharp, glassmorphism }
enum FontSize { small, medium, large }
enum AppBackground { solid, gradient, mesh }

class ThemeProvider extends ChangeNotifier {
  static final ThemeProvider instance = ThemeProvider._internal();
  ThemeProvider._internal();

  // Defaults
  ThemeMode _themeMode       = ThemeMode.system;
  Color _accentColor         = const Color(0xFF7C3AED);
  CardStyle _cardStyle       = CardStyle.rounded;
  FontSize _fontSize         = FontSize.medium;
  AppBackground _background  = AppBackground.solid;

  // Getters
  ThemeMode get themeMode      => _themeMode;
  Color get accentColor        => _accentColor;
  CardStyle get cardStyle      => _cardStyle;
  FontSize get fontSize        => _fontSize;
  AppBackground get background => _background;

  // Preset accent colors
  static const List<Color> presetColors = [
    Color(0xFF7C3AED), // Purple (default)
    Color(0xFF2563EB), // Blue
    Color(0xFF059669), // Green
    Color(0xFFDC2626), // Red
    Color(0xFFD97706), // Amber
    Color(0xFFDB2777), // Pink
    Color(0xFF0891B2), // Cyan
    Color(0xFF7C3AED), // Violet
    Color(0xFF000000), // Black
  ];

  // Font scale
  double get fontScale {
    switch (_fontSize) {
      case FontSize.small:  return 0.85;
      case FontSize.medium: return 1.0;
      case FontSize.large:  return 1.2;
    }
  }

  // Card border radius
  double get cardRadius {
    switch (_cardStyle) {
      case CardStyle.rounded:        return 20;
      case CardStyle.sharp:          return 4;
      case CardStyle.glassmorphism:  return 20;
    }
  }

  // Is glassmorphism
  bool get isGlass => _cardStyle == CardStyle.glassmorphism;

  // Load from SharedPreferences
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = ThemeMode.values[
        prefs.getInt('themeMode') ?? ThemeMode.system.index];
    _accentColor = Color(
        prefs.getInt('accentColor') ?? const Color(0xFF7C3AED).value);
    _cardStyle = CardStyle.values[
        prefs.getInt('cardStyle') ?? CardStyle.rounded.index];
    _fontSize = FontSize.values[
        prefs.getInt('fontSize') ?? FontSize.medium.index];
    _background = AppBackground.values[
        prefs.getInt('background') ?? AppBackground.solid.index];
    notifyListeners();
  }

  // Save helpers
  Future<void> _save(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  // Setters
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _save('themeMode', mode.index);
    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    await _save('accentColor', color.value);
    notifyListeners();
  }

  Future<void> setCardStyle(CardStyle style) async {
    _cardStyle = style;
    await _save('cardStyle', style.index);
    notifyListeners();
  }

  Future<void> setFontSize(FontSize size) async {
    _fontSize = size;
    await _save('fontSize', size.index);
    notifyListeners();
  }

  Future<void> setBackground(AppBackground bg) async {
    _background = bg;
    await _save('background', bg.index);
    notifyListeners();
  }

  // Build ThemeData from current settings
  ThemeData buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _accentColor,
        brightness: brightness,
      ),
      textTheme: _buildTextTheme(isDark),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        color: isDark
            ? const Color(0xFF111120)
            : const Color(0xFFF5F5F5),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: isDark
            ? const Color(0xFF0A0A0F)
            : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0A0A0F)
          : const Color(0xFFFAFAFA),
    );
  }

  TextTheme _buildTextTheme(bool isDark) {
    final baseColor = isDark ? Colors.white : Colors.black;
    return TextTheme(
      displayLarge: TextStyle(
          fontSize: 32 * fontScale,
          fontWeight: FontWeight.w800,
          color: baseColor),
      headlineMedium: TextStyle(
          fontSize: 22 * fontScale,
          fontWeight: FontWeight.w700,
          color: baseColor),
      titleLarge: TextStyle(
          fontSize: 18 * fontScale,
          fontWeight: FontWeight.w600,
          color: baseColor),
      titleMedium: TextStyle(
          fontSize: 15 * fontScale,
          fontWeight: FontWeight.w600,
          color: baseColor),
      bodyLarge: TextStyle(
          fontSize: 15 * fontScale,
          color: baseColor),
      bodyMedium: TextStyle(
          fontSize: 13 * fontScale,
          color: baseColor.withOpacity(0.7)),
      labelSmall: TextStyle(
          fontSize: 11 * fontScale,
          color: baseColor.withOpacity(0.5)),
    );
  }
}