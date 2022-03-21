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

  late String nome;
  late String email;
  String? fotoUrl;
  String? telefone;
  List<Funcao>? funcoes;
  List<Igreja>? igrejas;
  List<Grupo>? grupos;
  List<Instrumento>? instrumentos;
  String? obs;
  late bool ativo;

  Integrante({
    required this.nome,
    required this.email,
    this.fotoUrl,
    this.telefone,
    this.funcoes,
    this.igrejas,
    this.grupos,
    this.instrumentos,
    this.obs,
    this.ativo = true,
  });

  Integrante.fromJson(Map<String, Object?> json)
      : this(
          nome: (json['nome'] ?? '') as String,
          email: (json['email'] ?? '') as String,
          fotoUrl: (json['fotoUrl']) as String?,
          telefone: (json['telefone']) as String?,
          funcoes: List<Funcao>.from(((json['funcoes']) as List<dynamic>)
              .map((code) => _getFuncao(code))),
          igrejas: List<Igreja>.from(((json['igrejas']) as List<dynamic>)
              .map((e) => Igreja.fromJson(e))),
          grupos: List<Grupo>.from(((json['grupos']) as List<dynamic>)
              .map((e) => Grupo.fromJson(e))),
          instrumentos: List<Instrumento>.from(
              ((json['instrumentos']) as List<dynamic>)
                  .map((e) => Instrumento.fromJson(e))),
          obs: (json['obs']) as String?,
          ativo: (json['ativo'] ?? true) as bool,
        );

  Map<String, Object?> toJson() {
    return {
      'nome': nome,
      'email': email,
      'fotoUrl': fotoUrl,
      'telefone': telefone,
      'funcoes': _parseListaFuncao(funcoes),
      'igrejas': igrejas,
      'grupos': grupos,
      'instrumentos': instrumentos,
      'obs': obs,
      'ativo': ativo,
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

  static List<int> _parseListaFuncao(List<Funcao>? funcoes) {
    if (funcoes == null) return [];
    List<int> parsable = [];
    for (var funcao in funcoes) {
      parsable.add(funcao.index);
    }
    return parsable;
  }
}
