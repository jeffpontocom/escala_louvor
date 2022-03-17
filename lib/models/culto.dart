import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/models/cantico.dart';
import 'package:escala_louvor/models/instrumento.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Culto {
  late Timestamp dataCulto;
  String? ocasiao;
  User? dirigente;
  User? coordenador;
  Map<Instrumento, User>? equipe;
  Timestamp? dataEnsaio;
  List<Cantico>? canticos;
  String? liturgiaUrl;
  String? observacoes;

  Culto({
    required this.dataCulto,
    this.ocasiao,
    this.dirigente,
    this.coordenador,
    this.equipe,
    this.dataEnsaio,
    this.canticos,
    this.liturgiaUrl,
    this.observacoes,
  });

  Culto.fromJson(Map<String, Object?> json)
      : this(
          dataCulto: (json['dataCulto'] ?? Timestamp.now()) as Timestamp,
          ocasiao: (json['ocasiao'] ?? '') as String,
          dirigente: json['dirigente'] as User,
          coordenador: json['coordenador'] as User,
          equipe: Map<Instrumento, User>.from(
                  (json['equipe'] ?? {}) as Map<dynamic, dynamic>)
              .map((key, value) => MapEntry(key, value)),
          dataEnsaio: json['dataEnsaio'] as Timestamp,
          canticos: List<Cantico>.from(
              ((json['canticos'] ?? []) as List<dynamic>)
                  .map((e) => Cantico.fromJson(e))),
          liturgiaUrl: (json['liturgiaUrl'] ?? '') as String,
          observacoes: (json['observacoes'] ?? '') as String,
        );

  Map<String, Object?> toJson() {
    return {
      'dataCulto': dataCulto,
      'ocasiao': ocasiao ?? '',
      'dirigente': dirigente,
      'coordenador': coordenador,
      'equipe': equipe,
      'dataEnsaio': dataEnsaio,
      'canticos': canticos ?? [],
      'liturgiaUrl': liturgiaUrl ?? '',
      'observacoes': observacoes ?? '',
    };
  }
}
