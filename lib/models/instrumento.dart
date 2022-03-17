import 'package:flutter/material.dart';

class Instrumento {
  late bool ativo;
  late String nome;
  late IconData icone;

  Instrumento({required this.ativo, required this.nome, required this.icone});

  Instrumento.fromJson(Map<String, Object?> json)
      : this(
          ativo: (json['ativo'] ?? true) as bool,
          nome: (json['nome'] ?? '[novo instrumento]') as String,
          icone: IconData((json['icone'] ?? '') as int),
        );

  Map<String, Object?> toJson() {
    return {
      'ativo': ativo,
      'nome': nome,
      'icone': icone.codePoint,
    };
  }
}
