import 'package:flutter/material.dart';

/// Classe para estilos do app
class Estilo {
  /// Título da AppBar
  static TextStyle appBarTitulo = const TextStyle(
    fontFamily: 'Offside',
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );

  /// Títulos de Seção
  static TextStyle secaoTitulo = const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  /// Destaques
  static TextStyle destaque = const TextStyle(
    color: Colors.red,
    fontWeight: FontWeight.bold,
  );

  /// Legendas
  static TextStyle legenda = const TextStyle(
    color: Colors.grey,
    fontSize: 11,
  );

  static InputDecoration mInputDecoration = const InputDecoration(
    floatingLabelBehavior: FloatingLabelBehavior.always,
    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    disabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
  );
}
