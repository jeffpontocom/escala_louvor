import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/screens/user/tela_login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

import 'functions/metodos_firebase.dart';
import 'functions/notificacoes.dart';
import 'models/igreja.dart';
import 'models/integrante.dart';
import 'screens/home/tela_home.dart';
import 'screens/secondaries/tela_selecao.dart';
import 'widgets/tela_carregamento.dart';
import 'views/scaffold_falha.dart';
import 'views/scaffold_user_inativo.dart';
import 'utils/global.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
        upgrader: Upgrader(
          //debugDisplayOnce: true,
          //debugLogging: true,
          canDismissDialog: true,
          shouldPopScope: () => true,
        ),

        // Ouvinte para integrante logado
        // se houver alguma alteração nos dados do integrante logado
        // o app é recarregado.
        child: StreamBuilder<User?>(
          initialData: FirebaseAuth.instance.currentUser,
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            // USUARIO LOGADO
            if (snapshot.hasData && snapshot.data != null) {
              return StreamBuilder<DocumentSnapshot<Integrante>?>(
                  initialData: Global.logadoSnapshot,
                  stream: MeuFirebase.escutarIntegranteLogado(),
                  builder: (context, logado) {
                    // Log
                    if (logado.connectionState == ConnectionState.active) {
                      dev.log(
                          'Integrante: ${logado.data?.data()?.nome ?? 'não logado!'}',
                          name: 'log:App');
                    }

                    // FALHA AO CARREGAR COM DADOS DO INTEGRANTE
                    if (logado.hasError) {
                      dev.log(logado.error.toString());
                      return const ViewFalha(
                          mensagem:
                              'Falha ao carregar dados do integrante.\nFeche o aplicativo e tente novamente.');
                    }

                    // DADOS DO INTEGRANTE CARREGADOS
                    if (logado.hasData) {
                      // Atualizar snapshot
                      Global.logadoSnapshot = logado.data;
                      // Verifica se está ativo
                      if (!(logado.data?.data()?.ativo ?? true) &&
                          !(logado.data?.data()?.adm ?? true)) {
                        // Caso inativo devolve tela que impede acesso ao app
                        return const ViewUserInativo();
                      }
                      // Caso ativo devolve a tela principal (home)
                      // e ativa o sistema de notificações
                      Notificacoes.carregarInstancia();
                      // Ouvinte para igreja selecionada
                      // se houver alguma alteração nos dados essa tela é recarregada
                      return ValueListenableBuilder<DocumentSnapshot<Igreja>?>(
                          valueListenable: Global.igrejaSelecionada,
                          builder: (context, igreja, _) {
                            print(
                                igreja?.reference ?? 'Sem igreja selecionada');
                            // Verifica se usuário logado está inscrito na igreja selecionada
                            bool inscrito = logado.data
                                    ?.data()
                                    ?.igrejas
                                    ?.map((e) => e.toString())
                                    .contains(igreja?.reference.toString()) ??
                                false;
                            if (!inscrito) {
                              return const TelaContexto();
                            }
                            return Home(key: Key(igreja?.id ?? ''));
                          });
                    }

                    // CARREGAMENTO DA INTERFACE
                    return const TelaCarregamento();
                  });
            }
            // NÃO LOGADO
            if (snapshot.hasData && snapshot.data == null) {
              return const TelaLogin();
            }
            // CARREGAMENTO DA INTERFACE
            return const TelaCarregamento();
          },
        ));
  }
}
