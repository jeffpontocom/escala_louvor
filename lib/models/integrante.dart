import 'package:cloud_firestore/cloud_firestore.dart';

import 'grupo.dart';
import 'igreja.dart';
import 'instrumento.dart';

enum Funcao {
  administrador,
  dirigente,
  integrante,
  leitura,
}

class Integrante {
  static const String collection = 'integrantes';

  late bool ativo;
  late String nome;
  late String email;
  String? foto;
  String? fone;
  List<Funcao>? funcoes;
  List<Igreja>? igrejas;
  List<Grupo>? grupos;
  List<Instrumento>? instrumentos;
  List<DocumentReference>? disponibilidades;

  Integrante({
    required this.ativo,
    required this.nome,
    required this.email,
    this.foto,
    this.fone,
    this.funcoes,
    this.igrejas,
    this.grupos,
    this.instrumentos,
    this.disponibilidades,
  });

  Integrante.fromJson(Map<String, Object?> json)
      : this(
          ativo: (json['ativo'] ?? true) as bool,
          nome: (json['nome'] ?? '') as String,
          email: (json['email'] ?? '') as String,
          foto: (json['foto'] ?? '') as String,
          fone: (json['fone'] ?? '') as String,
          funcoes: List<Funcao>.from(((json['funcoes']) as List<dynamic>)
              .map((code) => _getFuncao(code))),
          igrejas: List<Igreja>.from(((json['igrejas']) as List<dynamic>)
              .map((e) => Igreja.fromJson(e))),
          grupos: List<Grupo>.from(((json['grupos']) as List<dynamic>)
              .map((e) => Grupo.fromJson(e))),
          instrumentos: List<Instrumento>.from(
              ((json['instrumentos']) as List<dynamic>)
                  .map((e) => Instrumento.fromJson(e))),
          disponibilidades: List<DocumentReference>.from(
              ((json['disponibilidades']) as List<dynamic>)),
        );

  Map<String, Object?> toJson() {
    return {
      'ativo': ativo,
      'nome': nome,
      'email': email,
      'foto': foto ?? '',
      'fone': fone ?? '',
      'funcoes': _parseFuncoes(funcoes),
      'igrejas': igrejas ?? [],
      'grupos': grupos ?? [],
      'instrumentos': instrumentos ?? [],
      'disponibilidades': disponibilidades ?? [],
    };
  }

  static Funcao _getFuncao(int code) {
    switch (code) {
      case 0:
        return Funcao.administrador;
      case 1:
        return Funcao.dirigente;
      case 2:
        return Funcao.integrante;
      default:
        return Funcao.leitura;
    }
  }

  static List<int> _parseFuncoes(List<Funcao>? funcoes) {
    if (funcoes == null) return [];
    List<int> parseable = [];
    for (var funcao in funcoes) {
      parseable.add(funcao.index);
    }
    return parseable;
  }
}
