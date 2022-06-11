//import 'dart:developer' as dev;

import 'package:escala_louvor/screens/home/tela_home.dart';
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
    //Modular.setNavigatorKey(myNavigatorKey);
    //Modular.setObservers([myObserver]);
    return FutureBuilder<bool>(
        future: Global.iniciar(),
        builder: (context, snapshot) {
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
          // FALHA AO CARREGAR APP
          else if (snapshot.data == false) {
            return MaterialApp(
                title: Global.nomeDoApp,
                theme: Temas.claro(),
                darkTheme: Temas.escuro(),
                home: const ViewFalha(
                    mensagem:
                        'Não é possível abrir o aplicativo nesta plataforma.'));
          }
          // SPLASH SCREEN
          return const TelaCarregamento();
        });
  }
}

/* class SplashPage extends StatelessWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      upgrader: Upgrader(
        //debugDisplayOnce: true,
        //debugLogging: true,
        canDismissDialog: true,
        shouldPopScope: () => true,
      ),
      child: FutureBuilder<bool>(
          future: Global.iniciar(),
          builder: (context, snapshot) {
            // CARREGAMENTO COMPLETO
            if (snapshot.data == true) {
              Modular.to.navigate('${AppModule.HOME}/${Paginas.agenda.name}');
            }
            // FALHA AO CARREGAR APP
            else if (snapshot.data == false) {
              return const ViewFalha(
                  mensagem:
                      'Não é possível abrir o aplicativo nesta plataforma.');
            }
            // SPLASH SCREEN
            return const TelaCarregamento();
          }),
    );
  }
} */

// LEVAR PARA HOME
                  // Notificacoes.carregarInstancia();

/////
/* class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: Global.iniciar(),
        builder: (context, snapshot) {
          // CARREGAMENTO DO APP
          dev.log('(${snapshot.connectionState.name})', name: 'log:Load');
          if (snapshot.data == null &&
              snapshot.connectionState == ConnectionState.waiting) {
            //return const TelaCarregamento();
            return MaterialApp(
              theme: Temas.claro(),
              darkTheme: Temas.escuro(),
              home: const TelaCarregamento(),
            );
          }
          // FALHA AO CARREGAR
          if (snapshot.data == false) {
            return MaterialApp(
                title: Global.nomeDoApp,
                theme: Temas.claro(),
                darkTheme: Temas.escuro(),
                home: const ViewFalha(
                    mensagem:
                        'Não é possível abrir o aplicativo nesta plataforma.'));
          }
          // APP CARREGADO
          // Escuta alterações no usuário autenticado
          // pelas configurações de rota os usuários não logados são
          // direcionados a tela de login

          // Rota inicial
          return ModularApp(
              module: AppRotas(),
              child:
                  //return
                  StreamBuilder<User?>(
                      initialData: FirebaseAuth.instance.currentUser,
                      stream: FirebaseAuth.instance.userChanges(),
                      builder: (_, snapshotUser) {
                        // Log: FirebaseUser logado
                        dev.log(
                            'Firebase Auth: ${snapshotUser.data?.email ?? 'não logado!'} (${snapshotUser.connectionState.name})',
                            name: 'log:Load');

                        if (snapshotUser.data == null &&
                            snapshotUser.connectionState ==
                                ConnectionState.waiting) {
                          //return const TelaCarregamento();
                        }
                        // Carrega sistema de notificações
                        // Esse carregamento deve ser feito sempre após runApp() para evitar erros
                        // e para o melhor uso do app apenas quando o usuário estiver logado.
                        if (snapshotUser.data?.email != null) {
                          //Notificacoes.carregarInstancia();
                        }
                        if (Modular.to.path.endsWith(AppRotas.LOGIN) &&
                            snapshotUser.data?.email != null) {
                          Modular.to.navigate(AppRotas.HOME);
                        }
                        // APP
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
                          routeInformationParser:
                              Modular.routeInformationParser,
                          routerDelegate: Modular.routerDelegate,
                        );
                      })
              //test
              );
        });
  }
} */
