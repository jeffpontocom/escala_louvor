import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'models/integrante.dart';

class IntegrantePage extends StatefulWidget {
  final String id;
  const IntegrantePage({Key? key, required this.id}) : super(key: key);

  @override
  State<IntegrantePage> createState() => _IntegrantePageState();
}

class _IntegrantePageState extends State<IntegrantePage> {
  late Integrante _integrante;
  late DocumentReference _documentReference;

  Future<DocumentSnapshot<Integrante>> get firebaseSnapshot {
    return FirebaseFirestore.instance
        .collection(Integrante.collection)
        .doc(widget.id)
        .withConverter<Integrante>(
            fromFirestore: (snapshot, _) =>
                Integrante.fromJson(snapshot.data()!),
            toFirestore: (pacote, _) => pacote.toJson())
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Modular.to.navigate('/')),
        title: const Text('Integrante'),
        titleSpacing: 0,
      ),
      body: FutureBuilder<DocumentSnapshot<Integrante>>(
          future: firebaseSnapshot,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snap.data!.exists || snap.data!.data() == null) {
              return const Center(child: Text('Erro!'));
            }
            _integrante = snap.data!.data()!;
            _documentReference = snap.data!.reference;
            return Column(
              children: [
                Text(_integrante.nome),
                Text(_integrante.email),
                Text(_integrante.instrumentos.toString()),
              ],
            );
          }),
    );
  }
}
