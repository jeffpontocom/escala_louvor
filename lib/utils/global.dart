//import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/firebase_options.dart';
import '/functions/metodos_firebase.dart';
import '/models/igreja.dart';
import '/models/integrante.dart';
import '/modulos.dart';
import '/screens/home/tela_home.dart';

enum FiltroAgenda {
  historico,
  proximos,
  mesAtual,
}

enum FiltroAvisos {
  atuais,
  vencidos,
}

/// Classe com métodos e variáveis de interesse Global
class Global {
  /* VARIÁVEIS */
  static PackageInfo? appInfo;
  static SharedPreferences? preferences;
  static DocumentSnapshot<Integrante>? logadoSnapshot;

  /* MÉTODOS  */

  /// INICIAR
  /// Carrega tudo o que é necessário para utilizar o aplicativo:
  /// - PackageInfo
  /// - Firebase initialize (return false on error)
  ///   -  Persistência da autenticação
  /// - Rota inicial
  /// - Shared Preferences
  ///   - Integrante logado
  ///   - Igreja em contexto
  static Future<bool> iniciar() async {
    print('Carregando dados globais...');

    // Carrega o arquivo de chaves (a extensão .txt é para poder ser lida na web)
    await dotenv.load(fileName: 'dotenv.txt');

    // Carrega as informações básicas do aplicativo e da plataforma
    appInfo = await PackageInfo.fromPlatform();

    // Inicializa a aplicação Firebase
    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    }
    // Em caso de plataforma não suportada
    on UnsupportedError catch (e) {
      print('Erro fatal: ${e.toString()}');
      return false;
    }
    // Em caso falta de plugin
    on MissingPluginException catch (e) {
      print('Erro fatal: ${e.toString()}');
      return false;
    }
    // Em caso de erros não previstos
    catch (e) {
      print('Falha: ${e.toString()}');
    }

    // Prepostos Modular
    Modular.setInitialRoute(rotaInicial);
    //Modular.setNavigatorKey(myNavigatorKey);
    //Modular.setObservers([myObserver]);

    // Recupera os dados salvos na seção anterior
    preferences = await SharedPreferences.getInstance();
    // Carrega igreja pré-selecionada
    igrejaSelecionada.value =
        await MeuFirebase.obterSnapshotIgreja(prefIgrejaId);

    /* final auth = FirebaseAuth.instance;
    // Persistência da autenticação (somente web)
    if (kIsWeb) {
      await auth.setPersistence(Persistence.LOCAL);
    }

    // Dados do usuário logado
    if (auth.currentUser != null) {
      print('Usuário está logado!');
      // Carrega o integrante logado
      var userId = auth.currentUser!.uid;
      logadoSnapshot = await MeuFirebase.obterSnapshotIntegrante(userId);
    } else {
      print('Usuário não está logado!');
    } */

    print('Dados globais carregados com sucesso');
    return true;
  }

  /* PREFERÊNCIAS */

  /// Getter: ID da Igreja em contexto
  static String? get prefIgrejaId => preferences?.getString('igreja_atual');

  /// Setter: ID da Igreja em contexto
  static set prefIgrejaId(String? id) {
    if (id == null || !id.isNotEmpty) {
      preferences?.remove('igreja_atual');
    } else {
      preferences?.setString('igreja_atual', id);
    }
  }

  /// Getter: Mostrar cultos de todas as igrejas inscritas
  static bool get prefMostrarTodosOsCultos =>
      preferences?.getBool('mostrar_todos_cultos') ?? false;

  /// Setter: Mostrar cultos de todas as igrejas inscritas
  static set prefMostrarTodosOsCultos(bool value) {
    preferences?.setBool('mostrar_todos_cultos', value);
  }

  /* GETTERS */

  /// Nome do aplicativo
  static get nomeDoApp =>
      kIsWeb ? 'Escala do Louvor' : appInfo?.appName ?? 'Escala do Louvor';

  /// Rota inicial
  static get rotaInicial => '${AppModule.HOME}/${HomePages.agenda.name}';

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

  /* NOTIFICADORES */

  // Igreja selecionada para o contexto
  static ValueNotifier<DocumentSnapshot<Igreja>?> igrejaSelecionada =
      ValueNotifier(null);

  // Filtros para apresentar apenas uma igreja ou todas as inscritas
  static ValueNotifier<bool> filtroMostrarTodosCultos =
      ValueNotifier(prefMostrarTodosOsCultos);

  // Filtro da pagina agenda
  static ValueNotifier<FiltroAgenda> filtroAgenda =
      ValueNotifier(FiltroAgenda.proximos);

  // Filtro da pagina equipe
  static ValueNotifier<Funcao?> filtroEquipe = ValueNotifier(null);

  // Filtros da pagina avisos
  static ValueNotifier<FiltroAvisos> filtroAvisos =
      ValueNotifier(FiltroAvisos.atuais);

  // Filtros da pagina repertorio
  static ValueNotifier<bool?> filtroHinos = ValueNotifier(null);
}
