import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

// Константы для единообразия на всех платформах
class AppConstants {
  static bool get isDesktop =>
      !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  // Единые размеры для всех платформ
  static const double cardElevation = 2.0;
  static const double borderRadius = 8.0;
  static const double listTileHeight = 72.0; // Фиксированная высота для списков
  static const double iconSize = 24.0;
  static const double avatarRadius = 20.0;

  // Единые отступы
  static const EdgeInsets cardMargin =
      EdgeInsets.symmetric(horizontal: 8, vertical: 4);
  static const EdgeInsets cardPadding = EdgeInsets.all(12);
  static const EdgeInsets screenPadding = EdgeInsets.all(16);

  // Единые размеры текста
  static const double bodyFontSize = 16.0;
  static const double titleFontSize = 18.0;
  static const double headlineFontSize = 24.0;
}

final ThemeData customLightTheme = ThemeData.light().copyWith(
  colorScheme: ColorScheme.light(
    primary: Colors.blue,
    secondary: Colors.blue,
    surface: const Color.fromARGB(255, 255, 255, 255),
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onSurface: Colors.black,
    shadow: const Color.fromARGB(255, 132, 200, 255),
    tertiary: const Color.fromARGB(255, 255, 255, 255),
  ),

  scaffoldBackgroundColor: Colors.white,

  // ДОБАВЛЯЕМ: Единообразие для карточек
  cardTheme: CardThemeData(
    elevation: AppConstants.cardElevation,
    margin: AppConstants.cardMargin,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
    ),
  ),

  // ДОБАВЛЯЕМ: Единообразие для ListTile
  listTileTheme: ListTileThemeData(
    contentPadding: AppConstants.cardPadding,
    minVerticalPadding: 8.0,
    horizontalTitleGap: 16.0,
    minLeadingWidth: 40.0,
    // Фиксированная высота для всех ListTile
    visualDensity: VisualDensity.compact,
  ),

  // УЛУЧШАЕМ: Более точные размеры текста
  textTheme: ThemeData.light().textTheme.copyWith(
        headlineLarge: TextStyle(
          fontSize: AppConstants.headlineFontSize,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
        titleMedium: TextStyle(
          fontSize: AppConstants.titleFontSize,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        bodyLarge: TextStyle(
          fontSize: AppConstants.bodyFontSize,
          color: Colors.black87,
        ),
        bodyMedium: TextStyle(
          fontSize: AppConstants.bodyFontSize,
          color: Colors.black87,
        ),
      ),

  appBarTheme: AppBarTheme(
    backgroundColor: Colors.blue,
    elevation: 4,
    iconTheme: IconThemeData(
      color: Colors.white,
      size: AppConstants.iconSize,
    ),
    titleTextStyle: TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      minimumSize: Size(120, 44), // Минимальный размер кнопок
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
    ),
    filled: true,
    fillColor: Colors.grey[100],
    labelStyle: TextStyle(color: Colors.blue),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),

  // ДОБАВЛЯЕМ: Единообразие для иконок
  iconTheme: IconThemeData(
    size: AppConstants.iconSize,
    color: Colors.blue,
  ),

  // ДОБАВЛЯЕМ: Единообразие для чекбоксов
  checkboxTheme: CheckboxThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
    ),
    side: BorderSide(width: 2, color: Colors.blue),
  ),

  // ДОБАВЛЯЕМ: Единообразие для Divider
  dividerTheme: DividerThemeData(
    thickness: 1,
    space: 1,
    color: Colors.grey[300],
  ),
);

final ThemeData customDarkTheme = ThemeData.dark().copyWith(
  colorScheme: ColorScheme.dark(
    primary: Colors.teal,
    secondary: Colors.teal,
    surface: const Color.fromARGB(255, 9, 9, 9),
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onSurface: Colors.white,
    shadow: const Color.fromARGB(255, 29, 29, 29),
    tertiary: const Color.fromARGB(255, 0, 0, 0),
  ),

  scaffoldBackgroundColor: Colors.black,

  // ДОБАВЛЯЕМ: Единообразие для карточек (темная тема)
  cardTheme: CardThemeData(
    elevation: AppConstants.cardElevation,
    margin: AppConstants.cardMargin,
    color: const Color.fromARGB(255, 18, 18, 18),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
    ),
  ),

  // ДОБАВЛЯЕМ: Единообразие для ListTile (темная тема)
  listTileTheme: ListTileThemeData(
    contentPadding: AppConstants.cardPadding,
    minVerticalPadding: 8.0,
    horizontalTitleGap: 16.0,
    minLeadingWidth: 40.0,
    visualDensity: VisualDensity.compact,
  ),

  textTheme: ThemeData.dark().textTheme.copyWith(
        headlineLarge: TextStyle(
          fontSize: AppConstants.headlineFontSize,
          fontWeight: FontWeight.bold,
          color: Colors.tealAccent,
        ),
        titleMedium: TextStyle(
          fontSize: AppConstants.titleFontSize,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
        ),
        bodyLarge: TextStyle(
          fontSize: AppConstants.bodyFontSize,
          color: Colors.white70,
        ),
        bodyMedium: TextStyle(
          fontSize: AppConstants.bodyFontSize,
          color: Colors.white70,
        ),
      ),

  appBarTheme: AppBarTheme(
    backgroundColor: Colors.teal,
    elevation: 4,
    iconTheme: IconThemeData(
      color: Colors.white,
      size: AppConstants.iconSize,
    ),
    titleTextStyle: TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.teal,
      foregroundColor: Colors.white,
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      minimumSize: Size(120, 44),
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
    ),
    filled: true,
    fillColor: Colors.grey[900],
    labelStyle: TextStyle(color: Colors.tealAccent),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),

  iconTheme: IconThemeData(
    size: AppConstants.iconSize,
    color: Colors.teal,
  ),

  checkboxTheme: CheckboxThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
    ),
    side: BorderSide(width: 2, color: Colors.teal),
  ),

  dividerTheme: DividerThemeData(
    thickness: 1,
    space: 1,
    color: Colors.grey[700],
  ),
);
