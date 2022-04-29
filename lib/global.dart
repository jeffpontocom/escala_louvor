import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'models/igreja.dart';
import 'models/integrante.dart';

class Global {
  // Notificadores
  static DocumentSnapshot<Integrante>? integranteLogado;
  static ValueNotifier<DocumentSnapshot<Igreja>?> igrejaSelecionada =
      ValueNotifier(null);
  static ValueNotifier<int> paginaSelecionada = ValueNotifier(0);
  static PackageInfo? appInfo;

  static carregarAppInfo() async {
    appInfo = await PackageInfo.fromPlatform();
  }
}
