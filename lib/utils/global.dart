import 'dart:developer' as dev;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/firebase_options.dart';
import '/functions/metodos_firebase.dart';
import '/models/igreja.dart';
import '/models/integrante.dart';

/// Classe com métodos e variáveis de interesse Global
class Global {
  /* VARIÁVEIS */
  static PackageInfo? appInfo;
  static DocumentSnapshot<Integrante>? logadoSnapshot;
  static SharedPreferences? preferences;

  /* PREFERÊNCIAS */

  /// ID da Igreja em contexto
  static String? get prefIgrejaId => preferences?.getString('igreja_atual');
  static set prefIgrejaId(String? id) {
    if (id != null && id.isNotEmpty) {
      preferences?.setString('igreja_atual', id);
    } else {
      preferences?.remove('igreja_atual');
    }
  }

  /// Mostrar todos os cultos
  static bool get prefMostrarTodosOsCultos =>
      preferences?.getBool('mostrar_todos_cultos') ?? false;
  static set prefMostrarTodosOsCultos(bool value) {
    preferences?.setBool('mostrar_todos_cultos', value);
    notificarAlteracaoEmIgrejas();
  }

  /// Notificar alteração em igrejas selecionadas
  static void notificarAlteracaoEmIgrejas() {
    meusFiltros.value.igrejas = prefMostrarTodosOsCultos
        ? logado?.igrejas
        : [igrejaSelecionada.value?.reference];
    meusFiltros.notifyListeners();
  }

  /* MÉTODOS  */

  /// Carrega tudo o que for necessário para iniciar o aplicativo.
  static Future<bool> iniciar() async {
    // Carrega o arquivo de chaves (a extensão .txt é para poder ser lida na web)
    await dotenv.load(fileName: 'dotenv.txt');
    // Carrega as informações básicas do aplicativo e da plataforma
    appInfo = await PackageInfo.fromPlatform();
    // Inicializa a aplicação Firebase
    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    } on UnsupportedError catch (e) {
      // Em caso de plataforma não suportada
      dev.log('Main: ${e.toString()}');
      return false;
    } catch (e) {
      // Em caso de erros não previstos
      dev.log('Main: ${e.toString()}');
    }
    if (kIsWeb) {
      FirebaseAuth.instance.setPersistence(Persistence.SESSION);
    }
    // Recupera os dados salvos na seção anterior
    preferences = await SharedPreferences.getInstance();
    // Carrega igreja pré-selecionada
    await _carregarIgrejaPreSelecionada();
    return true;
  }

  static _carregarIgrejaPreSelecionada() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    var value = await MeuFirebase.obterSnapshotIgreja(prefIgrejaId);
    Global.igrejaSelecionada.value = value;
  }

  /// Nome do aplicativo
  static get nomeDoApp =>
      kIsWeb ? 'Escala do Louvor' : appInfo?.appName ?? 'Escala do Louvor';

  /// Dados do integrante logado
  static Integrante? get logado => logadoSnapshot?.data();
  static DocumentReference<Integrante>? get logadoReference =>
      logadoSnapshot?.reference;

  /// Texto: versão do App
  static get versaoDoAppText {
    return Wrap(
      children: [
        const Text(
          'versão do app: ',
          textAlign: TextAlign.center,
        ),
        Text(
          appInfo?.version ?? '...',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // Notificadores
  static ValueNotifier<DocumentSnapshot<Igreja>?> igrejaSelecionada =
      ValueNotifier(null);
  static ValueNotifier<FiltroAgenda> meusFiltros = ValueNotifier(FiltroAgenda(
    dataMinima: DateTime.now().subtract(const Duration(hours: 4)),
    igrejas: prefMostrarTodosOsCultos
        ? Global.logadoSnapshot!.data()!.igrejas
        : [Global.igrejaSelecionada.value?.reference],
  ));
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

class Cache {
  static Map<String, Uint8List> arquivos = {};
}
