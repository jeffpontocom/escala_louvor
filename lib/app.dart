import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

import 'models/igreja.dart';
import 'screens/home/tela_home.dart';
import 'screens/secondaries/tela_selecao.dart';
import 'utils/global.dart';
import 'views/auth_guard.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      upgrader: Upgrader(
        canDismissDialog: true,
        shouldPopScope: () => true,
      ),
      child: AuthGuardView(
        scaffoldView: ValueListenableBuilder<DocumentSnapshot<Igreja>?>(
            valueListenable: Global.igrejaSelecionada,
            builder: (context, igreja, _) {
              dev.log('Escutando igreja selecionada', name: 'MyApp');

              // Verifica se usuário logado está inscrito na igreja selecionada
              bool inscrito = Global.logado?.igrejas
                      ?.map((e) => e.toString())
                      .contains(igreja?.reference.toString()) ??
                  false;

              // Se não está inscrito devolve a tela de seleção de igreja
              if (!inscrito) {
                dev.log('Nenhuma igreja selecionada', name: 'MyApp');
                return const TelaContexto();
              }

              // Se está inscrito devolve a tela inicial
              dev.log(
                  'Inscrito na igreja: ${igreja?.data()?.sigla ?? 'NENHUMA'}',
                  name: 'MyApp');
              return Home(key: Key(igreja?.id ?? ''));
            }),
      ),
    );
  }
}
