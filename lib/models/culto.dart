import 'package:cloud_firestore/cloud_firestore.dart';

import 'cantico.dart';
import 'igreja.dart';
import 'instrumento.dart';
import 'integrante.dart';

class Culto {
  static const String collection = 'cultos';

  late Timestamp dataCulto;
  late DocumentReference<Igreja> igreja;
  String? ocasiao;
  List<DocumentReference<Integrante>>? disponiveis;
  DocumentReference<Integrante>? dirigente;
  DocumentReference<Integrante>? coordenador;
  Map<DocumentReference<Instrumento>, DocumentReference<Integrante>>? equipe;
  Timestamp? dataEnsaio;
  List<DocumentReference<Cantico>>? canticos;
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
          igreja: _getIgreja(json['igreja']),
          ocasiao: json['ocasiao'] as String?,
          disponiveis: _getDisponiveis(json['disponiveis']),
          dirigente: _getIntegrante(json['dirigente']),
          coordenador: _getIntegrante(json['coordenador']),
          equipe: _getEquipe(json['equipe']),
          dataEnsaio: json['dataEnsaio'] as Timestamp?,
          canticos: _getCanticos(json['canticos']),
          liturgiaUrl: json['liturgiaUrl'] as String?,
          obs: json['obs'] as String?,
        );

  Map<String, Object?> toJson() {
    return {
      'dataCulto': dataCulto,
      'igreja': igreja,
      'ocasiao': ocasiao,
      'disponiveis': disponiveis,
      'dirigente': dirigente,
      'coordenador': coordenador,
      'equipe': equipe,
      'dataEnsaio': dataEnsaio,
      'canticos': canticos,
      'liturgiaUrl': liturgiaUrl,
      'obs': obs,
    };
  }

  static List<DocumentReference<Integrante>>? _getDisponiveis(var json) {
    if (json == null) return null;
    return List<DocumentReference<Integrante>>.from(
      (json as List<dynamic>).map(
        (doc) => (doc as DocumentReference)
          ..withConverter<Integrante>(
            fromFirestore: (snapshot, _) =>
                Integrante.fromJson(snapshot.data()!),
            toFirestore: (model, _) => model.toJson(),
          ),
      ),
    );
  }

  static DocumentReference<Igreja> _getIgreja(var json) {
    if (json == null)
      return FirebaseFirestore.instance.collection(Igreja.collection).doc()
          as DocumentReference<Igreja>;
    return (json as DocumentReference).withConverter<Igreja>(
      fromFirestore: (snapshot, _) => Igreja.fromJson(snapshot.data()!),
      toFirestore: (model, _) => model.toJson(),
    );
  }

  static DocumentReference<Integrante>? _getIntegrante(var json) {
    if (json == null) return null;
    return (json as DocumentReference).withConverter<Integrante>(
      fromFirestore: (snapshot, _) => Integrante.fromJson(snapshot.data()!),
      toFirestore: (model, _) => model.toJson(),
    );
  }

  static List<DocumentReference<Cantico>>? _getCanticos(var json) {
    if (json == null) return null;
    return List<DocumentReference<Cantico>>.from(
      (json as List<dynamic>).map(
        (doc) => (doc as DocumentReference)
          ..withConverter<Cantico>(
            fromFirestore: (snapshot, _) => Cantico.fromJson(snapshot.data()!),
            toFirestore: (model, _) => model.toJson(),
          ),
      ),
    );
  }

  static Map<DocumentReference<Instrumento>, DocumentReference<Integrante>>?
      _getEquipe(var json) {
    if (json == null) return null;
    return Map<DocumentReference<Instrumento>,
        DocumentReference<Integrante>>.from(
      (json as Map<dynamic, dynamic>).map((key, value) {
        return MapEntry(
          (key as DocumentReference).withConverter<Instrumento>(
            fromFirestore: (snapshot, _) =>
                Instrumento.fromJson(snapshot.data()!),
            toFirestore: (model, _) => model.toJson(),
          ),
          (value as DocumentReference).withConverter<Integrante>(
            fromFirestore: (snapshot, _) =>
                Integrante.fromJson(snapshot.data()!),
            toFirestore: (model, _) => model.toJson(),
          ),
        );
      }),
    );
  }
}
