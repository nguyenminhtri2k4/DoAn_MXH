import 'package:flutter/material.dart';

/// ==================== APP COLORS (Facebook Style) ====================
class AppColors {
  // ==================== PRIMARY ====================
  static const Color primary = Color(0xFF1877F2);       // Facebook Blue
  static const Color primaryLight = Color(0xFF4B9BFF);
  static const Color primaryDark = Color(0xFF0C5BC1);

  // ==================== BACKGROUND ====================
  static const Color background = Color(0xFFF0F2F5);       // Facebook background
  static const Color backgroundLight = Colors.white;      // Card, surfaces
  static const Color backgroundDark = Color(0xFFE4E6EB);  // Borders, secondary bg

  // ==================== TEXT ====================
  static const Color textPrimary = Color(0xFF050505);      // Main text
  static const Color textSecondary = Color(0xFF65676B);    // Secondary text
  static const Color textDisabled = Color(0xFFBCC0C4);     // Disabled text
  static const Color textWhite = Colors.white;             // White text
  static const Color textLink = primary;                   // Links, active text

  // ==================== BUTTONS ====================
  static const Color buttonPrimary = primary;
  static const Color buttonPrimaryHover = Color(0xFF166FE5);
  static const Color buttonPrimaryPressed = primaryDark;
  static const Color buttonSecondary = backgroundLight;
  static const Color buttonSecondaryText = textPrimary;
  static const Color buttonDanger = Color(0xFFFA383E);     // Error / Danger button

  // ==================== STATUS ====================
  static const Color success = Color(0xFF31A24C);  // Green
  static const Color warning = Color(0xFFFFA726);  // Orange
  static const Color error = Color(0xFFFA383E);    // Red
  static const Color info = primary;

  // ==================== ICONS ====================
  static const Color icon = textSecondary;
  static const Color iconActive = primary;

 // ==================== ASSETS PATHS ====================
  static const String logosybau = 'assets/logosybau.png';

  
  // ==================== DIVIDERS ====================
  static const Color divider = Color(0xFFE4E6EB);  // Light gray line
  static const Color border = Color(0xFFCED0D4);   // Border

  // ==================== GRADIENTS ====================
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient storyGradient = LinearGradient(
    colors: [Color(0xFF1877F2), Color(0xFF8B2CF5), Color(0xFFE95950)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==================== HELPER ====================
  static Color withOpacity(Color color, double opacity) => color.withOpacity(opacity);
}

/// ==================== EXTENSIONS ====================
extension ColorExt on Color {
  Color fade([double opacity = 0.5]) => withOpacity(opacity);
}

/// ==================== RADIUS, SPACING, FONT SIZES, FONT WEIGHTS ====================
/// Giữ nguyên như bạn yêu cầu
class AppRadius {
  static const double small = 4;
  static const double medium = 8;
  static const double large = 12;
  static const double xLarge = 16;
  static const double round = 999;

  static BorderRadius get smallRadius => BorderRadius.circular(small);
  static BorderRadius get mediumRadius => BorderRadius.circular(medium);
  static BorderRadius get largeRadius => BorderRadius.circular(large);
  static BorderRadius get xLargeRadius => BorderRadius.circular(xLarge);
  static BorderRadius get roundRadius => BorderRadius.circular(round);
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppFontSizes {
  static const double xs = 10;
  static const double sm = 12;
  static const double md = 14;
  static const double lg = 16;
  static const double xl = 18;
  static const double xxl = 20;
  static const double huge = 32;
}

class AppFontWeights {
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
}
