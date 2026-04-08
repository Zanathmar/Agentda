import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';

class C {
  // Backgrounds
  static const bg       = Color(0xFFF5F5F0);
  static const surface  = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF0F0EB);
  static const surface3 = Color(0xFFE8E8E2);

  // Text
  static const textPri  = Color(0xFF1A1A1A);
  static const textSec  = Color(0xFF6B6B6B);
  static const textMuted= Color(0xFFAAAAAA);

  // Accent — soft black
  static const accent   = Color.fromARGB(255, 10, 10, 10);
  static const accentLt = Color(0xFF444444);
  static const accentBg = Color(0xFFEEEEEE);

  // Semantic
  static const success  = Color(0xFF2D9E6B);
  static const warning  = Color(0xFFE5A000);
  static const error    = Color(0xFFD94F4F);
  static const info     = Color(0xFF4A7FD4);

  // Borders
  static const border   = Color(0xFFE5E5E0);
  static const borderLt = Color(0xFFEEEEEA);

  // Priority colors — muted & tasteful
  static const prioHigh   = Color(0xFFD94F4F);
  static const prioMedium = Color(0xFFE5A000);
  static const prioLow    = Color(0xFF2D9E6B);

  static Color priority(Priority p) => switch (p) {
    Priority.high   => prioHigh,
    Priority.medium => prioMedium,
    Priority.low    => prioLow,
  };
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3:            true,
    brightness:              Brightness.light,
    scaffoldBackgroundColor: C.bg,
    colorScheme: const ColorScheme.light(
      primary:   C.accent,
      surface:   C.surface,
      error:     C.error,
    ),
    textTheme: GoogleFonts.dmSansTextTheme(ThemeData.light().textTheme).apply(
      bodyColor:    C.textPri,
      displayColor: C.textPri,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor:        C.bg,
      elevation:              0,
      scrolledUnderElevation: 0,
      systemOverlayStyle:     SystemUiOverlayStyle.dark,
      centerTitle:            true,
      titleTextStyle: GoogleFonts.dmSans(
        fontSize: 17, fontWeight: FontWeight.w600, color: C.textPri,
      ),
      iconTheme: const IconThemeData(color: C.textPri),
    ),
    cardTheme: CardThemeData(
      color:     C.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: C.border),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: C.accent,
        foregroundColor: Colors.white,
        minimumSize:     const Size(double.infinity, 52),
        elevation:       0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: C.accentLt),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled:        true,
      fillColor:     C.surface,
      hintStyle:     const TextStyle(color: C.textMuted),
      border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.accent, width: 1.5)),
      errorBorder:   OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.error)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.error, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor:  C.surface,
      indicatorColor:   Colors.transparent,
      shadowColor:      Colors.transparent,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? C.textPri : C.textMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return const IconThemeData(color: C.textPri, size: 22);
        return const IconThemeData(color: C.textMuted, size: 22);
      }),
    ),
    dividerTheme:   const DividerThemeData(color: C.border, space: 1, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: C.textPri,
      contentTextStyle: GoogleFonts.dmSans(color: Colors.white, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: C.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor:  C.surface,
      modalBarrierColor: Colors.black38,
    ),
  );
}