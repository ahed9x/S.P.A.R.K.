import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SparkTheme {
  SparkTheme._();

  // Colour palette
  static const Color bg        = Color(0xFF0D1117);
  static const Color card      = Color(0xFF161B22);
  static const Color surface   = Color(0xFF1C2128);
  static const Color border    = Color(0xFF30363D);
  static const Color text      = Color(0xFFC9D1D9);
  static const Color muted     = Color(0xFF8B949E);
  static const Color accent    = Color(0xFF00FFCC);
  static const Color red       = Color(0xFFF85149);
  static const Color blue      = Color(0xFF58A6FF);
  static const Color green     = Color(0xFF3FB950);
  static const Color yellow    = Color(0xFFD29922);
  static const Color purple    = Color(0xFFBC8CFF);
  static const Color playerA   = Color(0xFFFF4444);
  static const Color playerB   = Color(0xFF4488FF);

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      cardColor: card,
      dividerColor: border,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: blue,
        surface: card,
        error: red,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: text, displayColor: text),
      appBarTheme: AppBarTheme(
        backgroundColor: card,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
          color: accent,
        ),
        iconTheme: const IconThemeData(color: accent),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: bg,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
        hintStyle: const TextStyle(color: muted),
        labelStyle: const TextStyle(color: muted),
      ),
      cardTheme: CardTheme(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
      ),
    );
  }
}
