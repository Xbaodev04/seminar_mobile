import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// A small PageTransitionsBuilder that disables the default page transition animations.
class _NoTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child; // No animation, immediate switch
  }
}

const LinearGradient kGrapGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  // Palette adapted from user: soft green -> teal gradient
  colors: [Color(0xFFB7E5CD), Color(0xFF8ABEB9)],
);

ThemeData grapTheme() {
  // Seed: deep teal for modern contrast, accents from provided palette
  final seed = const Color(0xFF305669);
  final scheme = ColorScheme.fromSeed(seedColor: seed).copyWith(
    primary: const Color(0xFF305669), // deep teal
    secondary: const Color(0xFFC1785A), // warm accent
    tertiary: const Color(0xFF8ABEB9), // soft teal
    surfaceVariant: const Color(0xFFF7FBF7), // subtle light background as surface variant
    surface: Colors.white,
  );

  final notoSansTextTheme = GoogleFonts.notoSansTextTheme();

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: Colors.grey.shade50,
    ),
    // Card theme left to default to avoid SDK type mismatches.
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    // Use Google Fonts Noto Sans for better multilingual coverage
    fontFamily: GoogleFonts.notoSans().fontFamily,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: const _NoTransitionsBuilder(),
      TargetPlatform.iOS: const _NoTransitionsBuilder(),
      TargetPlatform.linux: const _NoTransitionsBuilder(),
      TargetPlatform.macOS: const _NoTransitionsBuilder(),
      TargetPlatform.windows: const _NoTransitionsBuilder(),
    }),
    textTheme: const TextTheme().copyWith(
      titleLarge: GoogleFonts.notoSans(fontSize: 20, fontWeight: FontWeight.w600),
      headlineMedium: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold),
      bodyLarge: GoogleFonts.notoSans(fontSize: 14, color: Colors.black87),
    ),
  );
}
