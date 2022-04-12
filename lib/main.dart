import 'dart:developer' as dev;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:url_strategy/url_strategy.dart';

import 'firebase_options.dart';
import 'functions/notificacoes.dart';
import 'preferencias.dart';
import 'rotas.dart';
import 'screens/home.dart';

void main() async {
  setPathUrlStrategy(); // remove o hash '#' das URLs
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'dotenv.txt');
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
    // Rota inicial
    Modular.setInitialRoute('/${Paginas.values[0].name}');
    // Escuta alterações no usuário autenticado
    // pelas configurações de rota os usuários não logados são
    // direcionados a tela de login
    return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.userChanges(),
        builder: (_, snapshotUser) {
          dev.log('MyApp: ${snapshotUser.connectionState.name}');
          if (snapshotUser.connectionState == ConnectionState.active) {
            dev.log(
                'Firebase Auth: ${snapshotUser.data?.email ?? 'não logado!'}');
          }
          if (snapshotUser.data?.email != null) {
            // Carrega sistema de notificações
            // Esse carregamento deve ser feito sempre após runApp() para evitar erros
            Notificacoes.carregarInstancia();
          }
          // APP
          return MaterialApp.router(
            title: 'Escala do Louvor',
            // Tema claro
            theme: ThemeData(
              primarySwatch: Colors.blue,
              colorScheme: ColorScheme.light(
                primary: Colors.blue,
                secondary: Colors.blue.shade600,
              ),
              materialTapTargetSize:
                  kIsWeb ? MaterialTapTargetSize.padded : null,
              dividerTheme: const DividerThemeData(space: 4),
            ),
            // Tema Escuro
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.blue,
              colorScheme: ColorScheme.dark(
                primary: Colors.blue,
                secondary: Colors.blue.shade400,
              ),
              materialTapTargetSize:
                  kIsWeb ? MaterialTapTargetSize.padded : null,
              dividerTheme: const DividerThemeData(space: 4),
            ),
            // Behaviors
            scrollBehavior: MyCustomScrollBehavior(),
            // Suporte a lingua português nos elementos globais
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('pt')],
            locale: const Locale('pt_BR'),
            // Navegação Modular
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
