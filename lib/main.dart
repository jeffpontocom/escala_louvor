//import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'modulos.dart';
import 'resources/animations/bouncing.dart';
import 'resources/behaviors/app_scroll_behavior.dart';
import 'resources/temas.dart';
import 'utils/global.dart';
import 'views/scaffold_falha.dart';

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
          return Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            color: MediaQueryData.fromWindow(WidgetsBinding.instance.window)
                        .platformBrightness ==
                    Brightness.dark
                ? const Color(0xFF303030)
                : const Color(0xFF2094f3),
            child: Column(children: [
              const Expanded(child: SizedBox()),
              Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimacaoPulando(
                          objectToAnimate:
                              Image.asset('assets/icons/ic_launcher.png')),
                    ]),
              ),
              Expanded(
                child: Column(children: const [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      'Acessando base e preferências...',
                      style: TextStyle(color: Color(0xFFE0E0E0)),
                    ),
                  ),
                ]),
              ),
            ]),
          );
        });
  }
}
