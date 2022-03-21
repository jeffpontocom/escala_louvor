import 'package:cloud_firestore/cloud_firestore.dart';

class Igreja {
  late bool ativa;
  late String nome;
  late String sigla;
  String? fotoUrl;
  String? endereco;
  String? responsavel;

  Igreja({
    required this.ativa,
    required this.nome,
    required this.sigla,
    this.fotoUrl,
    this.endereco,
    this.responsavel,
  });

  Igreja.fromJson(Map<String, Object?> json)
      : this(
          ativa: (json['ativa'] ?? true) as bool,
          nome: (json['nome'] ?? '[Nova Igreja]') as String,
          sigla: (json['sigla'] ?? '[NOVA]') as String,
          fotoUrl: (json['fotoUrl'] ?? '') as String,
          endereco: (json['endereco'] ?? '') as String,
          responsavel: (json['responsavel'] ?? '') as String,
        );

  Map<String, Object?> toJson() {
    return {
      'ativa': ativa,
      'nome': nome,
      'sigla': sigla,
      'fotoUrl': fotoUrl,
      'endereco': endereco ?? '',
      'responsavel': responsavel ?? '',
    };
  }
}
