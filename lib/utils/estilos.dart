import 'package:flutter/material.dart';

/// Classe para estilos do app
class Estilo {
  /// Para titulos
  static TextStyle titulo = TextStyle(
      color: Colors.grey.shade800, fontSize: 18, fontWeight: FontWeight.bold);

  /// Para destaques
  static TextStyle destaque =
      const TextStyle(color: Colors.red, fontWeight: FontWeight.bold);

  /// Para legendas
  static TextStyle legenda = const TextStyle(color: Colors.grey, fontSize: 11);

  static InputDecoration mInputDecoration = const InputDecoration(
      floatingLabelBehavior: FloatingLabelBehavior.always,
      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      disabledBorder: OutlineInputBorder(borderSide: BorderSide.none));
}
