import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:upgrader/upgrader.dart';

import 'functions/notificacoes.dart';
import 'functions/metodos_firebase.dart';
import 'models/igreja.dart';
import 'models/integrante.dart';
import 'resources/behaviors/app_scroll_behavior.dart';
import 'resources/temas.dart';
import 'rotas.dart';
import 'screens/home/tela_home.dart';
import 'screens/secondaries/tela_selecao.dart';
import 'widgets/tela_carregamento.dart';
import 'views/scaffold_falha.dart';
import 'views/scaffold_user_inativo.dart';
import 'utils/global.dart';

class LoadApp extends StatelessWidget {
  const LoadApp({Key? key}) : super(key: key);

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
              themeMode: ThemeMode.system,
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
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ouvinte para integrante logado
    // se houver alguma alteração nos dados do integrante logado
    // o app é recarregado.
    return UpgradeAlert(
      upgrader: Upgrader(
        //debugDisplayOnce: true,
        //debugLogging: true,
        canDismissDialog: true,
        shouldPopScope: () => true,
      ),
      child: StreamBuilder<DocumentSnapshot<Integrante>?>(
          stream: MeuFirebase.escutarIntegranteLogado(),
          builder: (_, logado) {
            // Log: Integrante logado
            if (logado.connectionState == ConnectionState.active) {
              dev.log(
                  'Firebase Integrante: ${logado.data?.data()?.nome ?? 'não logado!'}',
                  name: 'log:App');
            }
            // CARREGAMENTO DA INTERFACE
            if (logado.data == null &&
                logado.connectionState == ConnectionState.waiting) {
              return const TelaCarregamento();
            }
            // FALHA AO CARREGAR COM DADOS DO INTEGRANTE
            if (logado.hasError && !logado.hasData) {
              return const ViewFalha(
                  mensagem:
                      'Falha ao carregar dados do integrante.\nFeche o aplicativo e tente novamente.');
            }
            // Preenche integrante snapshot global
            Global.logadoSnapshot = logado.data;
            // Verifica se está ativo
            if (!(logado.data?.data()?.ativo ?? true) &&
                !(logado.data?.data()?.adm ?? true)) {
              return const ViewUserInativo();
            }
            // Ouvinte para igreja selecionada
            return ValueListenableBuilder<DocumentSnapshot<Igreja>?>(
                valueListenable: Global.igrejaSelecionada,
                child: const TelaContexto(),
                builder: (context, igreja, child) {
                  dev.log('Igreja: ${igreja?.id}', name: 'log:App');
                  if (igreja == null) {
                    return child!;
                  }
                  // Verifica se usuário logado está inscrito na igreja
                  bool inscrito = logado.data
                          ?.data()
                          ?.igrejas
                          ?.map((e) => e.toString())
                          .contains(igreja.reference.toString()) ??
                      false;
                  if (!inscrito) {
                    return child!;
                  }
                  // Scaffold (utilizar key para forçar atualização da interface)
                  return Home(key: Key(igreja.id));
                });
          }),
    );
  }
}
