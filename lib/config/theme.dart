import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class EmobiesTheme {
  EmobiesTheme._();

  static const bg = Color(0xFF07080B);
  static const surface = Color(0xFF0C0F14);
  static const card = Color(0xFF111519);
  static const cardLight = Color(0xFF1A1F28);
  static const orange = Color(0xFFFF5500);
  static const orangeLight = Color(0xFFFF7733);
  static const green = Color(0xFF00E676);
  static const greenDim = Color(0xFF00C853);
  static const yellow = Color(0xFFFBBF24);
  static const red = Color(0xFFEF4444);
  static const blue = Color(0xFF3B82F6);
  static const purple = Color(0xFFA855F7);
  static const cyan = Color(0xFF06B6D4);
  static const text = Color(0xFFEEF0F4);
  static const text2 = Color(0xFF8892A4);
  static const muted = Color(0xFF424A58);
  static const border = Color(0xFF1A1F28);
  static const borderLight = Color(0xFF2A3140);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: orange,
      secondary: purple,
      surface: card,
      surfaceContainerHighest: cardLight,
      error: red,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: text,
      onError: Colors.white,
    ),
    textTheme: GoogleFonts.syneTextTheme().apply(
      bodyColor: text,
      displayColor: text,
    ),
    fontFamily: 'Syne',
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.syne(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: text,
      ),
      iconTheme: const IconThemeData(color: text),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: orange,
      unselectedItemColor: muted,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: const BorderSide(color: border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: orange, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: red),
      ),
      hintStyle: const TextStyle(color: muted, fontSize: 13),
      labelStyle: const TextStyle(color: text2, fontSize: 13),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: orange,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        textStyle: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: orange,
        side: const BorderSide(color: orange),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: orange),
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: cardLight,
      contentTextStyle: const TextStyle(color: text),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
  );
}

extension TextStyleExt on TextStyle {
  TextStyle get orangeColor => copyWith(color: EmobiesTheme.orange);
  TextStyle get greenColor => copyWith(color: EmobiesTheme.green);
  TextStyle get redColor => copyWith(color: EmobiesTheme.red);
  TextStyle get mutedColor => copyWith(color: EmobiesTheme.muted);
  TextStyle get text2Color => copyWith(color: EmobiesTheme.text2);
}

class AppGradients {
  static const orangePurple = LinearGradient(
    colors: [EmobiesTheme.orange, EmobiesTheme.purple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const greenCyan = LinearGradient(
    colors: [EmobiesTheme.green, EmobiesTheme.cyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const cardShine = LinearGradient(
    colors: [EmobiesTheme.cardLight, EmobiesTheme.card],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppShadows {
  static const orangeGlow = BoxShadow(
    color: Color(0x40FF5500),
    blurRadius: 20,
    spreadRadius: -5,
  );
  static const cardShadow = BoxShadow(
    color: Color(0x40000000),
    blurRadius: 10,
    offset: Offset(0, 4),
  );
}