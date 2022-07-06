//import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'modulos.dart';
import 'resources/behaviors/app_scroll_behavior.dart';
import 'resources/temas.dart';
import 'utils/global.dart';
import 'views/scaffold_falha.dart';
import '/widgets/raw_loading.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ModularApp(module: AppModule(), child: const AppWidget()));
}

class AppWidget extends StatelessWidget {
  const AppWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool?>(
        future: Global.iniciar(),
        builder: (context, snapshot) {
          // ERRO AO CARREGAR APP
          if (snapshot.hasData && snapshot.data == false) {
            return MaterialApp(
                title: Global.nomeDoApp,
                theme: Temas.claro(),
                darkTheme: Temas.escuro(),
                home: const ViewFalha(
                    mensagem:
                        'Não é possível abrir o aplicativo nesta plataforma.'));
          }

          // CARREGAMENTO COMPLETO
          if (snapshot.hasData && snapshot.data == true) {
            return MaterialApp.router(
              title: Global.nomeDoApp,
              // Temas
              theme: Temas.claro(),
              darkTheme: Temas.escuro(),
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
          }

          // SPLASH SCREEN
          return const RawLoading(mensagem: 'Acessando base de dados...');
        });
  }
}
