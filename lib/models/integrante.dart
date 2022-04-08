import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'grupo.dart';
import 'igreja.dart';
import 'instrumento.dart';

enum Funcao {
  recrutador,
  dirigente,
  coordenador,
  liturgo,
  membro,
}

String funcaoGetString(Funcao funcao) {
  switch (funcao) {
    case Funcao.recrutador:
      return 'Recrutador';
    case Funcao.dirigente:
      return 'Dirigente';
    case Funcao.coordenador:
      return 'Coord. técnico';
    case Funcao.liturgo:
      return 'Liturgo';
    case Funcao.membro:
      return 'Membro';
  }
}

IconData funcaoGetIcon(Funcao funcao) {
  switch (funcao) {
    case Funcao.recrutador:
      return Icons.paste;
    case Funcao.dirigente:
      return Icons.mic;
    case Funcao.coordenador:
      return Icons.support_agent;
    case Funcao.liturgo:
      return Icons.list_alt;
    case Funcao.membro:
      return Icons.hail;
  }
}

class Integrante {
  static const String collection = 'integrantes';

  late String nome;
  late String email;
  String? fotoUrl;
  String? telefone;
  Timestamp? dataNascimento;
  List<Funcao>? funcoes;
  List<DocumentReference<Igreja>>? igrejas;
  List<DocumentReference<Grupo>>? grupos;
  List<DocumentReference<Instrumento>>? instrumentos;
  String? obs;
  late bool adm;
  late bool ativo;

  Integrante({
    required this.nome,
    required this.email,
    this.fotoUrl,
    this.telefone,
    this.dataNascimento,
    this.funcoes,
    this.igrejas,
    this.grupos,
    this.instrumentos,
    this.obs,
    this.adm = false,
    this.ativo = true,
  });

  Integrante.fromJson(Map<String, Object?>? json)
      : this(
          nome: (json?['nome'] ?? '') as String,
          email: (json?['email'] ?? '') as String,
          fotoUrl: (json?['fotoUrl']) as String?,
          telefone: (json?['telefone']) as String?,
          dataNascimento: (json?['dataNascimento']) as Timestamp?,
          funcoes: _getFuncoes(json?['funcoes']),
          igrejas: _getIgrejas(json?['igrejas']),
          grupos: _getGrupos(json?['grupos']),
          instrumentos: _getInstrumentos(json?['instrumentos']),
          obs: (json?['obs']) as String?,
          adm: (json?['adm'] ?? false) as bool,
          ativo: (json?['ativo'] ?? true) as bool,
        );

  Map<String, Object?> toJson() {
    return {
      'nome': nome,
      'email': email,
      'fotoUrl': fotoUrl,
      'telefone': telefone,
      'dataNascimento': dataNascimento,
      'funcoes': _parseListaFuncao(funcoes),
      'igrejas': igrejas,
      'grupos': grupos,
      'instrumentos': instrumentos,
      'obs': obs,
      'adm': adm,
      'ativo': ativo,
    };
  }

  static List<Funcao>? _getFuncoes(var json) {
    if (json == null) return null;
    return List<Funcao>.from(
        (json as List<dynamic>).map((code) => _getFuncao(code)));
  }

  static Funcao _getFuncao(int code) {
    switch (code) {
      case 0:
        return Funcao.recrutador;
      case 1:
        return Funcao.dirigente;
      case 2:
        return Funcao.coordenador;
      case 3:
        return Funcao.liturgo;
      case 4:
      default:
        return Funcao.membro;
    }
  }

  static List<int>? _parseListaFuncao(List<Funcao>? funcoes) {
    if (funcoes == null) return null;
    List<int> parsable = [];
    for (var funcao in funcoes) {
      parsable.add(funcao.index);
    }
    return parsable;
  }

  static List<DocumentReference<Igreja>>? _getIgrejas(var json) {
    if (json == null) return null;
    return List<DocumentReference<Igreja>>.from(
      (json as List<dynamic>).map(
        (doc) => (doc as DocumentReference).withConverter<Igreja>(
          fromFirestore: (snapshot, _) => Igreja.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        ),
      ),
    );
  }

  static List<DocumentReference<Grupo>>? _getGrupos(var json) {
    if (json == null) return null;
    return List<DocumentReference<Grupo>>.from(
      (json as List<dynamic>).map(
        (doc) => (doc as DocumentReference).withConverter<Grupo>(
          fromFirestore: (snapshot, _) => Grupo.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        ),
      ),
    );
  }

  static List<DocumentReference<Instrumento>>? _getInstrumentos(var json) {
    if (json == null) return null;
    return List<DocumentReference<Instrumento>>.from(
      (json as List<dynamic>).map(
        (doc) => (doc as DocumentReference).withConverter<Instrumento>(
          fromFirestore: (snapshot, _) =>
              Instrumento.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        ),
      ),
    );
  }

  /* BOOLEANS  */
  bool get ehRecrutador {
    return (funcoes?.contains(Funcao.recrutador) ?? false);
  }

  bool get ehDirigente {
    return (funcoes?.contains(Funcao.dirigente) ?? false);
  }

  bool get ehCoordenador {
    return (funcoes?.contains(Funcao.coordenador) ?? false);
  }

  bool get ehLiturgo {
    return (funcoes?.contains(Funcao.liturgo) ?? false);
  }

  bool get ehComponente {
    return (funcoes?.contains(Funcao.membro) ?? false);
  }
}
