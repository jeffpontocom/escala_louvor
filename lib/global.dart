import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/igreja.dart';
import 'models/integrante.dart';

class Global {
  // App Data
  static const String appName = 'Escala do Louvor';
  static const String appVersion = '0.1.0';

  // Services
  static DocumentSnapshot<Integrante>? integranteLogado;
  static DocumentSnapshot<Igreja>? igrejaAtual;
}
