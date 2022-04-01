import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'models/igreja.dart';
import 'models/integrante.dart';

class Global {
  // App Data
  static const String appName = 'Escala do Louvor';
  static const String appVersion = '0.1.0';

  // Notificadores
  static ValueNotifier<DocumentSnapshot<Integrante>?> integranteLogado =
      ValueNotifier(null);
  static ValueNotifier<DocumentSnapshot<Igreja>?> igrejaSelecionada =
      ValueNotifier(null);
}
