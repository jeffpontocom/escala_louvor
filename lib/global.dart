import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'models/igreja.dart';
import 'models/integrante.dart';

class Global {
  // App Data
  static String appName = 'Escala do Louvor';
  static String appVersion = '0.1.0';

  // Services
  static FirebaseAuth auth = FirebaseAuth.instance;
  static DocumentSnapshot<Integrante>? integranteLogado;
  static DocumentSnapshot<Igreja>? igrejaAtual;
}
