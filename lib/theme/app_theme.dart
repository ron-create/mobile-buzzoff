import 'package:flutter/material.dart';

class AppColors {
  // Light theme
  static const Color primary = Color(0xFF6A89A7);
  static const Color secondary = Color(0xFF7AD6B6);
  static const Color error = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFFFC107);
  static const Color success = Color(0xFF4CAF50);
  static const Color info = Color(0xFF2196F3);
  static const Color background = Color(0xFFF5F7FA);
  static const Color text = Color(0xFF333333);
  static const Color navbar = Color(0xFF6A89A7);
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  // Dark theme
  static const Color darkPrimary = Color(0xFF263445);
  static const Color darkSecondary = Color(0xFF3A4A5A);
  static const Color darkError = Color(0xFFFF6B6B);
  static const Color darkWarning = Color(0xFFFFC107);
  static const Color darkSuccess = Color(0xFF4CAF50);
  static const Color darkInfo = Color(0xFF2196F3);
  static const Color darkBackground = Color(0xFF181C20);
  static const Color darkText = Color(0xFFF5F7FA);
  static const Color darkNavbar = Color(0xFF263445);
  
  // Additional colors for infographics
  static const Color accent = Color(0xFF7A9CB6);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  static const Color border = Color(0xFFE0E0E0);
}

class AppTextStyles {
  // Light theme
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
    fontFamily: 'Roboto',
  );
  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
    fontFamily: 'Roboto',
  );
  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.text,
    fontFamily: 'Roboto',
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.text,
    fontFamily: 'Roboto',
  );
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
    fontFamily: 'Roboto',
  );
  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
    fontFamily: 'Roboto',
  );

  // Dark theme
  static const TextStyle darkHeading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText,
    fontFamily: 'Roboto',
  );
  static const TextStyle darkHeading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText,
    fontFamily: 'Roboto',
  );
  static const TextStyle darkBody = TextStyle(
    fontSize: 16,
    color: AppColors.darkText,
    fontFamily: 'Roboto',
  );
  static const TextStyle darkCaption = TextStyle(
    fontSize: 12,
    color: AppColors.darkText,
    fontFamily: 'Roboto',
  );
  static const TextStyle darkButton = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
    fontFamily: 'Roboto',
  );
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
}

final ThemeData appLightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: AppColors.background,
  fontFamily: 'Roboto',
  colorScheme: ColorScheme.light(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    error: AppColors.error,
    background: AppColors.background,
    onPrimary: AppColors.white,
    onSecondary: AppColors.white,
    onError: AppColors.white,
    onBackground: AppColors.text,
    surface: AppColors.white,
    onSurface: AppColors.text,
  ),
  textTheme: const TextTheme(
    titleLarge: AppTextStyles.heading1,
    titleMedium: AppTextStyles.heading2,
    bodyLarge: AppTextStyles.body,
    bodyMedium: AppTextStyles.body,
    labelSmall: AppTextStyles.caption,
    labelLarge: AppTextStyles.button,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.white,
    elevation: 0,
    titleTextStyle: AppTextStyles.heading2,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
      ),
      textStyle: AppTextStyles.button,
    ),
  ),
);

final ThemeData appDarkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: AppColors.darkPrimary,
  scaffoldBackgroundColor: AppColors.darkBackground,
  fontFamily: 'Roboto',
  colorScheme: ColorScheme.dark(
    primary: AppColors.darkPrimary,
    secondary: AppColors.darkSecondary,
    error: AppColors.darkError,
    background: AppColors.darkBackground,
    onPrimary: AppColors.white,
    onSecondary: AppColors.white,
    onError: AppColors.white,
    onBackground: AppColors.darkText,
    surface: AppColors.darkSecondary,
    onSurface: AppColors.darkText,
  ),
  textTheme: const TextTheme(
    titleLarge: AppTextStyles.darkHeading1,
    titleMedium: AppTextStyles.darkHeading2,
    bodyLarge: AppTextStyles.darkBody,
    bodyMedium: AppTextStyles.darkBody,
    labelSmall: AppTextStyles.darkCaption,
    labelLarge: AppTextStyles.darkButton,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.darkPrimary,
    foregroundColor: AppColors.white,
    elevation: 0,
    titleTextStyle: AppTextStyles.darkHeading2,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.darkPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
      ),
      textStyle: AppTextStyles.darkButton,
    ),
  ),
); 