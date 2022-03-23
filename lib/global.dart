import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/preferencias.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as dev;

import 'models/igreja.dart';
import 'models/integrante.dart';

class Global {
  // App Data
  static String appName = 'Escala do Louvor';
  static String appVersion = '0.1.0';

  // Services
  static FirebaseAuth auth = FirebaseAuth.instance;
  static DocumentSnapshot<Integrante>? integranteLogado;
  static DocumentSnapshot<Igreja>? igrejaLogado;

  // Helper Methods
  static escutarLogin() {
    auth.idTokenChanges().listen((event) {
      if (event == null) {
        integranteLogado = null;
        dev.log(
            'ALTERAÇÃO Integrante logado: ${integranteLogado?.data()?.nome ?? ''}');
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
          integranteLogado = event;
          dev.log(
              'ALTERAÇÃO Integrante logado: ${integranteLogado?.data()?.nome ?? ''}');
        });
      }
    });
  }

  // Helper Methods
  static escutarIgreja() {
    if (Preferencias.igrejaAtual != null) {
      FirebaseFirestore.instance
          .collection(Igreja.collection)
          .doc(Preferencias.igrejaAtual)
          .withConverter<Igreja>(
              fromFirestore: (snapshot, _) => Igreja.fromJson(snapshot.data()!),
              toFirestore: (pacote, _) => pacote.toJson())
          .get()
          .asStream()
          .listen((event) {
        igrejaLogado = event;
        dev.log('ALTERAÇÃO Igreja logado: ${igrejaLogado?.data()?.nome ?? ''}');
      });
    } else {
      igrejaLogado = null;
      dev.log('ALTERAÇÃO Igreja logado: ${igrejaLogado?.data()?.nome ?? ''}');
    }
  }
}
