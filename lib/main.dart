//import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:url_strategy/url_strategy.dart';

import 'modulos.dart';
import 'resources/behaviors/app_scroll_behavior.dart';
import 'resources/temas.dart';
import 'utils/global.dart';
import 'views/scaffold_falha.dart';
import 'widgets/tela_carregamento.dart';

void main() async {
  setPathUrlStrategy();
  runApp(ModularApp(module: AppModule(), child: const AppWidget()));
}

class AppWidget extends StatelessWidget {
  const AppWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool?>(
        future: Global.iniciar(),
        builder: (context, snapshot) {
          // FALHA AO CARREGAR APP
          if (snapshot.data == false) {
            return MaterialApp(
                title: Global.nomeDoApp,
                theme: Temas.claro(),
                darkTheme: Temas.escuro(),
                home: const ViewFalha(
                    mensagem:
                        'Não é possível abrir o aplicativo nesta plataforma.'));
          }

          // CARREGAMENTO COMPLETO
          if (snapshot.data == true) {
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
          return const TelaCarregamento();
        });
  }
}
