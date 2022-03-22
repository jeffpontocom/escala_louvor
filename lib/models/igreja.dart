import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/models/integrante.dart';

class Igreja {
  static const String collection = 'igrejas';

  late String sigla;
  late String nome;
  String? fotoUrl;
  String? endereco;
  DocumentReference<Integrante>? responsavel;
  late bool ativo;

  Igreja({
    required this.sigla,
    required this.nome,
    this.fotoUrl,
    this.endereco,
    this.responsavel,
    this.ativo = true,
  });

  Igreja.fromJson(Map<String, Object?> json)
      : this(
          sigla: (json['sigla'] ?? '[NOVA]') as String,
          nome: (json['nome'] ?? '[Nova Igreja]') as String,
          fotoUrl: (json['fotoUrl']) as String?,
          endereco: (json['endereco']) as String?,
          responsavel: _getResponsavel(json['responsavel']),
          ativo: (json['ativo'] ?? true) as bool,
        );

  Map<String, Object?> toJson() {
    return {
      'sigla': sigla,
      'nome': nome,
      'fotoUrl': fotoUrl,
      'endereco': endereco,
      'responsavel': responsavel,
      'ativo': ativo,
    };
  }

  static DocumentReference<Integrante>? _getResponsavel(var json) {
    if (json == null) return null;
    return (json as DocumentReference).withConverter<Integrante>(
      fromFirestore: (snapshot, _) => Integrante.fromJson(snapshot.data()!),
      toFirestore: (model, _) => model.toJson(),
    );
  }
}
