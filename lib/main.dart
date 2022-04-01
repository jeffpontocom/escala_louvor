import 'dart:developer' as dev;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:url_strategy/url_strategy.dart';

import 'firebase_options.dart';
import 'functions/metodos_firebase.dart';
import 'global.dart';
import 'preferencias.dart';
import 'rotas.dart';

void main() async {
  setPathUrlStrategy(); // remove o hash '#' das URLs
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Preferencias.carregarInstancia();
  runApp(
    ModularApp(
      module: AppRotas(),
      child: const MyApp(),
      debugMode: !kReleaseMode,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.userChanges(),
        builder: (_, snapshotUser) {
          dev.log(
              'FirebaseAuth alterado - usuário ${snapshotUser.data?.email ?? 'não logado!'}');
          if (snapshotUser.hasData && snapshotUser.data != null) {
            MeuFirebase.escutarIntegranteLogado(snapshotUser.data!.uid);
          } else {
            Global.integranteLogado.value == null;
          }
          return MaterialApp.router(
            title: 'Escala do Louvor',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              colorScheme: ColorScheme.light(
                primary: Colors.blue,
                secondary: Colors.blue.shade600,
              ),
              materialTapTargetSize:
                  kIsWeb ? MaterialTapTargetSize.padded : null,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.blue,
              colorScheme: ColorScheme.dark(
                primary: Colors.blue,
                secondary: Colors.blue.shade400,
              ),
              materialTapTargetSize:
                  kIsWeb ? MaterialTapTargetSize.padded : null,
            ),
            scrollBehavior: MyCustomScrollBehavior(),
            // Suporte a lingua português nos elementos globais
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('pt')],
            locale: const Locale('pt_BR'),
            // Navegação
            routeInformationParser: Modular.routeInformationParser,
            routerDelegate: Modular.routerDelegate,
          );
        });
  }
}

/// Classe para emular as ações de gestos do dedo pelo mouse
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
