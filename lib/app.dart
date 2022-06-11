import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/modulos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:upgrader/upgrader.dart';

import 'functions/metodos_firebase.dart';
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
          builder: (_, logado) {
            // Log: Integrante logado
            if (logado.connectionState == ConnectionState.active) {
              dev.log(
                  'Firebase Integrante: ${logado.data?.data()?.nome ?? 'não logado!'}',
                  name: 'log:App');
            }
            // OK
            if (logado.hasData) {
              // Preenche integrante snapshot global
              Global.logadoSnapshot = logado.data;
              // Verifica se está ativo
              if (!(logado.data?.data()?.ativo ?? true) &&
                  !(logado.data?.data()?.adm ?? true)) {
                return const ViewUserInativo();
              }
              return const Home();
            }
            // FALHA AO CARREGAR COM DADOS DO INTEGRANTE
            if (logado.hasError) {
              dev.log(logado.error.toString());
              return const ViewFalha(
                  mensagem:
                      'Falha ao carregar dados do integrante.\nFeche o aplicativo e tente novamente.');
            }
            // CARREGAMENTO DA INTERFACE
            return const TelaCarregamento();
            // Ouvinte para igreja selecionada
            /* return ValueListenableBuilder<DocumentSnapshot<Igreja>?>(
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
                  if (inscrito) {
                    Modular.to
                        .navigate('${AppModule.HOME}/${Paginas.agenda.name}');
                    return Home(key: Key(igreja.id));
                  }
                  return child!;
                  // Scaffold (utilizar key para forçar atualização da interface)
                  //return Home(key: Key(igreja.id));
                }); */
          }),
    );
  }
}
