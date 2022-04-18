import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'models/igreja.dart';
import 'models/integrante.dart';

class Global {
  // App Data
  static const String appName = 'Escala do Louvor';
  static const String appVersion = '0.1.6';

  // Notificadores
  static DocumentSnapshot<Integrante>? integranteLogado;
  static ValueNotifier<DocumentSnapshot<Igreja>?> igrejaSelecionada =
      ValueNotifier(null);
  static ValueNotifier<int> paginaSelecionada = ValueNotifier(0);
}
