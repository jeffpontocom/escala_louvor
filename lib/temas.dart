import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

ThemeData _base(Brightness brightness) {
  return ThemeData(
    brightness: brightness,
    fontFamily: 'Ubuntu',
    primarySwatch: Colors.blue,
    materialTapTargetSize: kIsWeb ? MaterialTapTargetSize.padded : null,
    dividerTheme: const DividerThemeData(space: 4),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      titleTextStyle: TextStyle(
          fontFamily: 'Offside',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white),
    ),
    // Botões
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.minPositive, 40),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.minPositive, 40),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(double.minPositive, 40),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    ),
    // Inputs
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide: const BorderSide(style: BorderStyle.none),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide: const BorderSide(style: BorderStyle.none),
      ),
      filled: true,
    ),
  );
}

ThemeData temaClaro() {
  return _base(Brightness.light).copyWith(
    colorScheme: ColorScheme.light(
      primary: Colors.blue,
      secondary: Colors.blue.shade600,
    ),
  );
}

ThemeData temaEscuro() {
  return _base(Brightness.dark).copyWith(
    colorScheme: ColorScheme.dark(
      primary: Colors.blue,
      secondary: Colors.blue.shade400,
    ),
  );
}
