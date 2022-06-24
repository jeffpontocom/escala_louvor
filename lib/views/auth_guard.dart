import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'scaffold_falha.dart';
import 'scaffold_user_inativo.dart';
import '/functions/metodos_firebase.dart';
import '/functions/notificacoes.dart';
import '/models/integrante.dart';
import '/screens/user/tela_login.dart';
import '/utils/global.dart';
import '/views/scaffold_404.dart';
import '/widgets/tela_carregamento.dart';

class AuthGuardView extends StatelessWidget {
  final bool adminCheck;
  final Widget scaffoldView;
  const AuthGuardView(
      {Key? key, this.adminCheck = false, required this.scaffoldView})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ouvinte para usuário firebase
    // se houver alguma alteração no status da autenticação
    // o app é recarregado.
    return StreamBuilder<User?>(
        initialData: FirebaseAuth.instance.currentUser,
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          dev.log(
              'FirebaseAuth User: ${snapshot.connectionState.name.toUpperCase()}',
              name: 'AuthGuard');

          // NÃO LOGADO
          if (!snapshot.hasData &&
              snapshot.connectionState == ConnectionState.active) {
            dev.log('Usuário não está logado', name: 'AuthGuard');
            Global.logadoSnapshot = null;
            return const TelaLogin();
          }
          // DADOS DO INTEGRANTE CARREGADOS
          // USUARIO LOGADO
          if (snapshot.hasData) {
            // Ativa o sistema de notificações
            if (snapshot.connectionState == ConnectionState.active &&
                Notificacoes.instancia == null) {
              Notificacoes.carregarInstancia(context);
            }

            // Ouvinte para integrante logado
            // se houver alguma alteração nos dados do integrante logado
            // o app é recarregado.
            return StreamBuilder<DocumentSnapshot<Integrante>>(
                initialData: Global.logadoSnapshot,
                stream: MeuFirebase.ouvinteIntegrante(id: snapshot.data!.uid),
                builder: (context, logado) {
                  dev.log(
                      'Integrante: ${snapshot.connectionState.name.toUpperCase()}',
                      name: 'AuthGuard');

                  // FALHA AO CARREGAR COM DADOS DO INTEGRANTE
                  if (logado.hasError) {
                    dev.log('Falha: ${logado.error}', name: 'AuthGuard');
                    return const ViewFalha(
                        mensagem:
                            'Não foi possível carregar os dados do integrante.\nFeche o aplicativo e tente novamente.');
                  }

                  // DADOS DO INTEGRANTE CARREGADOS
                  if (logado.hasData) {
                    if (logado.connectionState == ConnectionState.active) {
                      dev.log(
                          'Interface carregada para ${logado.data?.data()?.nome ?? 'SEM NOME'}',
                          name: 'AuthGuard');

                      // Atualizar snapshot
                      Global.logadoSnapshot = logado.data;
                    }

                    // Verifica se está ativo
                    // Caso inativo devolve tela que impede acesso ao app
                    if (!(logado.data?.data()?.ativo ?? true) &&
                        !(logado.data?.data()?.adm ?? true)) {
                      dev.log('Usuário está inativo!', name: 'AuthGuard');
                      return const ViewUserInativo();
                    }

                    if (adminCheck && !(logado.data?.data()?.adm ?? true)) {
                      dev.log('Página restrita a administradores!',
                          name: 'AuthGuard');
                      return const View404();
                    }

                    // CASO INTEGRANTE ATIVO DEVOLVE A TELA SOLICITADA
                    return scaffoldView;
                  }

                  // CARREGAMENTO DA INTERFACE
                  dev.log('Carregando interface do integrante...',
                      name: 'AuthGuard');
                  return const TelaCarregamento();
                });
          }

          // CARREGAMENTO DA INTERFACE
          dev.log('Carregando interface do usuário...', name: 'AuthGuard');
          return const TelaCarregamento();
        });
  }
}
