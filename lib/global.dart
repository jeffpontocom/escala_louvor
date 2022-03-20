import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'models/integrante.dart';

class Global {
  // App Data
  static String appName = 'Escala do Louvor';
  static String appVersion = '0.1.0';

  // Services
  static FirebaseAuth auth = FirebaseAuth.instance;
  static Integrante? integranteLogado;

  // Helper Methods
  static escutarLogin() {
    auth.idTokenChanges().listen((event) {
      if (event == null) {
        integranteLogado = null;
      } else {
        FirebaseFirestore.instance
            .collection(Integrante.collection)
            .doc(event.uid)
            .withConverter<Integrante>(
                fromFirestore: (snapshot, _) =>
                    Integrante.fromJson(snapshot.data()!),
                toFirestore: (pacote, _) => pacote.toJson())
            .get()
            .asStream()
            .listen((event) {
          integranteLogado = event.data();
        });
      }
    });
  }
}
