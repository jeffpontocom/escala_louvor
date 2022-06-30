import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Temas {
  static ThemeData _base(Brightness brightness) {
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white),
        systemOverlayStyle:
            SystemUiOverlayStyle(statusBarColor: Colors.transparent),
      ),
      // Botões
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.minPositive, 40),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.minPositive, 40),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(double.minPositive, 40),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
      chipTheme: const ChipThemeData(
        labelPadding: EdgeInsets.only(left: 4, right: 8),
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

  static ThemeData claro() {
    return _base(Brightness.light).copyWith(
      colorScheme: ColorScheme.light(
        primary: Colors.blue,
        secondary: Colors.amber.shade700,
      ),
    );
  }

  static ThemeData escuro() {
    return _base(Brightness.dark).copyWith(
      colorScheme: ColorScheme.dark(
        primary: Colors.blue.shade700,
        secondary: Colors.amber.shade800,
      ),
    );
  }
}
