import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

import 'functions/metodos_firebase.dart';
import 'functions/notificacoes.dart';
import 'models/igreja.dart';
import 'models/integrante.dart';
import 'screens/home/tela_home.dart';
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
      child: StreamBuilder<DocumentSnapshot<Integrante>?>(
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
              return ValueListenableBuilder<DocumentSnapshot<Igreja>?>(
                  valueListenable: Global.igrejaSelecionada,
                  builder: (context, igreja, _) {
                    return Home(key: Key(igreja?.id ?? ''));
                  });
            }

            // CARREGAMENTO DA INTERFACE
            return const TelaCarregamento();
          }),
    );
  }
}
