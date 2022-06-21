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

        // Ouvinte para usuário firebase
        // se houver alguma alteração no status da autenticação
        // o app é recarregado.
        child: StreamBuilder<User?>(
          initialData: FirebaseAuth.instance.currentUser,
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            dev.log('Stream user: ${snapshot.connectionState.name}',
                name: 'MyApp');

            // NÃO LOGADO
            if (!snapshot.hasData &&
                snapshot.connectionState == ConnectionState.active) {
              dev.log('Interface usuário não logado', name: 'MyApp');
              return const TelaLogin();
            }

            // USUARIO LOGADO
            if (snapshot.hasData) {
              dev.log('Interface usuário logado', name: 'MyApp');

              // Ativa o sistema de notificações
              if (snapshot.connectionState == ConnectionState.active) {
                Notificacoes.carregarInstancia(context);
              }

              // Ouvinte para integrante logado
              // se houver alguma alteração nos dados do integrante logado
              // o app é recarregado.
              return StreamBuilder<DocumentSnapshot<Integrante>?>(
                  initialData: Global.logadoSnapshot,
                  stream: MeuFirebase.escutarIntegranteLogado(),
                  builder: (context, logado) {
                    dev.log(
                        'Stream integrante: ${snapshot.connectionState.name}',
                        name: 'MyApp');

                    // FALHA AO CARREGAR COM DADOS DO INTEGRANTE
                    if (logado.hasError) {
                      dev.log(logado.error.toString(), name: 'MyApp');
                      return const ViewFalha(
                          mensagem:
                              'Não foi possível carregar os dados do integrante.\nFeche o aplicativo e tente novamente.');
                    }

                    // DADOS DO INTEGRANTE CARREGADOS
                    if (logado.hasData) {
                      dev.log(
                          'Carregando interface para ${logado.data?.data()?.nome ?? 'SEM NOME'}',
                          name: 'MyApp');

                      // Atualizar snapshot
                      Global.logadoSnapshot = logado.data;

                      // Verifica se está ativo
                      // Caso inativo devolve tela que impede acesso ao app
                      if (!(logado.data?.data()?.ativo ?? true) &&
                          !(logado.data?.data()?.adm ?? true)) {
                        dev.log('Usuário está inativo!', name: 'MyApp');
                        return const ViewUserInativo();
                      }

                      // Caso ativo devolve ouvinte para igreja selecionada
                      // se houver alguma alteração nos dados essa tela é recarregada
                      return ValueListenableBuilder<DocumentSnapshot<Igreja>?>(
                          valueListenable: Global.igrejaSelecionada,
                          builder: (context, igreja, _) {
                            dev.log('Escutando igreja selecionada',
                                name: 'MyApp');

                            // Verifica se usuário logado está inscrito na igreja selecionada
                            bool inscrito = logado.data
                                    ?.data()
                                    ?.igrejas
                                    ?.map((e) => e.toString())
                                    .contains(igreja?.reference.toString()) ??
                                false;

                            // Se não está inscrito devolve a tela de seleção de igreja
                            if (!inscrito) {
                              dev.log('Nenhuma igreja selecionada',
                                  name: 'MyApp');
                              return const TelaContexto();
                            }

                            // Se está inscrito devolve a tela inicial
                            dev.log(
                                'Inscrito na igreja: ${igreja?.data()?.sigla ?? 'NENHUMA'}',
                                name: 'MyApp');
                            return Home(key: Key(igreja?.id ?? ''));
                          });
                    }

                    // CARREGAMENTO DA INTERFACE
                    dev.log('Carregando interface logado...', name: 'MyApp');
                    return const TelaCarregamento();
                  });
            }

            // CARREGAMENTO DA INTERFACE
            dev.log('Carregando interface...', name: 'MyApp');
            return const TelaCarregamento();
          },
        ));
  }
}
