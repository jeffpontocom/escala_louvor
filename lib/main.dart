import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'firebase_options.dart';
import 'global.dart';
import 'navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //bool needsWeb = Platform.isLinux | Platform.isWindows;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Global.escutarLogin();
  runApp(
    ModularApp(
      module: AppNavigation(),
      child: const MyApp(),
      debugMode: !kReleaseMode,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Escala do Louvor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: kIsWeb
            ? VisualDensity.comfortable
            : VisualDensity.adaptivePlatformDensity,
      ),
      scrollBehavior: MyCustomScrollBehavior(),
      // Suporte a lingua português nos elementos globais
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt')],
      locale: const Locale('pt_BR'),
      // Identificador de tipo de Release
      debugShowCheckedModeBanner: !kReleaseMode,
      // Navegação
      routeInformationParser: Modular.routeInformationParser,
      routerDelegate: Modular.routerDelegate,
    );
  }
}

/// Classe para emular as ações de gestos do dedo pelo mouse
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
