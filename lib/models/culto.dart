import 'package:cloud_firestore/cloud_firestore.dart';

import 'cantico.dart';
import 'igreja.dart';
import 'instrumento.dart';
import 'integrante.dart';

class Culto {
  static const String collection = 'cultos';

  late Timestamp dataCulto;
  late Igreja igreja;
  String? ocasiao;
  List<DocumentReference>? disponiveis;
  Integrante? dirigente;
  Integrante? coordenador;
  Map<Instrumento, Integrante>? equipe;
  Timestamp? dataEnsaio;
  List<Cantico>? canticos;
  String? liturgiaUrl;
  String? obs;

  Culto({
    required this.dataCulto,
    required this.igreja,
    this.ocasiao,
    this.disponiveis,
    this.dirigente,
    this.coordenador,
    this.equipe,
    this.dataEnsaio,
    this.canticos,
    this.liturgiaUrl,
    this.obs,
  });

  Culto.fromJson(Map<String, Object?> json)
      : this(
          dataCulto: (json['dataCulto'] ?? Timestamp.now()) as Timestamp,
          igreja: json['igreja'] as Igreja,
          ocasiao: (json['ocasiao'] ?? '') as String,
          disponiveis: (json['disponiveis'] ?? []) as List<DocumentReference>,
          dirigente: json['dirigente'] as Integrante,
          coordenador: json['coordenador'] as Integrante,
          equipe: Map<Instrumento, Integrante>.from(
                  (json['equipe'] ?? {}) as Map<dynamic, dynamic>)
              .map((key, value) => MapEntry(key, value)),
          dataEnsaio: json['dataEnsaio'] as Timestamp,
          canticos: List<Cantico>.from(
              ((json['canticos'] ?? []) as List<dynamic>)
                  .map((e) => Cantico.fromJson(e))),
          liturgiaUrl: (json['liturgiaUrl'] ?? '') as String,
          obs: (json['obs'] ?? '') as String,
        );

  Map<String, Object?> toJson() {
    return {
      'dataCulto': dataCulto,
      'igreja': igreja,
      'ocasiao': ocasiao ?? '',
      'disponiveis': disponiveis ?? [],
      'dirigente': dirigente,
      'coordenador': coordenador,
      'equipe': equipe,
      'dataEnsaio': dataEnsaio,
      'canticos': canticos ?? [],
      'liturgiaUrl': liturgiaUrl ?? '',
      'obs': obs ?? '',
    };
  }
}
