import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'models/igreja.dart';
import 'models/integrante.dart';
import 'preferencias.dart';

class Global {
  // Notificadores
  static DocumentSnapshot<Integrante>? integranteLogado;
  static ValueNotifier<DocumentSnapshot<Igreja>?> igrejaSelecionada =
      ValueNotifier(null);
  static ValueNotifier<int> paginaSelecionada = ValueNotifier(0);
  static ValueNotifier<FiltroAgenda> meusFiltros = ValueNotifier(FiltroAgenda(
    dataMinima: DateTime.now().subtract(const Duration(hours: 4)),
    igrejas: Preferencias.mostrarTodosOsCultos
        ? Global.integranteLogado!.data()!.igrejas
        : [Global.igrejaSelecionada.value?.reference],
  ));
  static PackageInfo? appInfo;

  static carregarAppInfo() async {
    appInfo = await PackageInfo.fromPlatform();
  }

  /// Versão do App
  static get versaoDoAppText {
    return Wrap(
      children: [
        const Text(
          'versão do app: ',
          textAlign: TextAlign.center,
          //style: TextStyle(color: Colors.grey),
        ),
        Text(
          Global.appInfo?.version ?? '...',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            //color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

class FiltroAgenda {
  DateTime? dataMinima;
  DateTime? dataMaxima;
  List<DocumentReference?>? igrejas;

  FiltroAgenda({this.dataMinima, this.dataMaxima, this.igrejas});

  Timestamp? get timeStampMin =>
      dataMinima == null ? null : Timestamp.fromDate(dataMinima!);
  Timestamp? get timeStampMax =>
      dataMaxima == null ? null : Timestamp.fromDate(dataMaxima!);
}
