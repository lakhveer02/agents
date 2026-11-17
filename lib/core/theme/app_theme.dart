import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Deep Neutral palette (Apple/Vercel inspired)
  static const Color background = Color(0xFF0A0A0B);
  static const Color surface = Color(0xFF161618);
  static const Color card = Color(0xFF1C1C1E);
  
  // Accents & Gradients
  static const Color primary = Color(0xFF007AFF); // Apple Blue
  static const Color secondary = Color(0xFF5856D6); // Apple Indigo
  static const Color accent = Color(0xFF30D158); // Apple Green
  
  static const List<Color> aiGradient = [
    Color(0xFF007AFF),
    Color(0xFF5856D6),
    Color(0xFFFF2D55),
  ];

  static const Color glassBorder = Color(0x1AFFFFFF);
  static const Color glassHighlight = Color(0x0DFFFFFF);
  
  // Glow effects
  static const Color primaryGlow = Color(0x33007AFF);
  static const Color secondaryGlow = Color(0x335856D6);
  static const Color accentGlow = Color(0x3330D158);
}

// Spacing constants
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

// Animation durations
class AppDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration pageTransition = Duration(milliseconds: 300);
}

// Shadow presets
class AppShadows {
  static List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> medium = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> strong = [
    BoxShadow(
      color: Colors.black.withOpacity(0.25),
      blurRadius: 30,
      offset: const Offset(0, 12),
    ),
  ];
  
  static List<BoxShadow> glow(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.3),
      blurRadius: 30,
      spreadRadius: 5,
    ),
  ];
}

// Typography scale
class AppTextStyles {
  static const TextStyle display = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    letterSpacing: -1,
    height: 1.2,
  );
  
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.3,
  );
  
  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );
  
  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );
  
  static const TextStyle code = TextStyle(
    fontFamily: 'monospace',
    fontSize: 14,
    height: 1.6,
  );
}

class AppTheme {
  static ThemeData get dark => FlexThemeData.dark(
    colors: const FlexSchemeColor(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      appBarColor: AppColors.background,
      error: Color(0xFFFF453A),
    ),
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 10,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 20,
      useTextTheme: true,
      useM2StyleDividerInM3: true,
      adaptiveRemoveElevationTint: FlexAdaptive.all(),
      cardRadius: 24,
      inputDecoratorRadius: 16,
      inputDecoratorIsFilled: true,
      inputDecoratorFillColor: AppColors.surface,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    fontFamily: GoogleFonts.inter().fontFamily,
    scaffoldBackground: AppColors.background,
  ).copyWith(
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );

  static ThemeData get light => FlexThemeData.light(
    scheme: FlexScheme.deepBlue,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 7,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 10,
      useTextTheme: true,
      useM2StyleDividerInM3: true,
      cardRadius: 24,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    fontFamily: GoogleFonts.inter().fontFamily,
  );
}
