import 'package:cloud_firestore/cloud_firestore.dart';

class Igreja {
  late bool ativa;
  late String nome;
  late String alias;
  String? endereco;
  String? responsavel;
  List<DocumentReference>? cultos;

  Igreja({
    required this.ativa,
    required this.nome,
    required this.alias,
    this.endereco,
    this.responsavel,
    this.cultos,
  });

  Igreja.fromJson(Map<String, Object?> json)
      : this(
          ativa: (json['ativa'] ?? true) as bool,
          nome: (json['nome'] ?? '[nova igreja]') as String,
          alias: (json['alias'] ?? '[alias]') as String,
          endereco: (json['endereco'] ?? '') as String,
          responsavel: (json['responsavel'] ?? '') as String,
          cultos:
              List<DocumentReference>.from(((json['cultos']) as List<dynamic>)),
        );

  Map<String, Object?> toJson() {
    return {
      'ativa': ativa,
      'nome': nome,
      'alias': alias,
      'endereco': endereco ?? '',
      'responsavel': responsavel ?? '',
      'cultos': cultos ?? [],
    };
  }
}
