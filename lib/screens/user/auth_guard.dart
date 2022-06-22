import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/screens/user/tela_login.dart';
import 'package:escala_louvor/utils/global.dart';
import 'package:escala_louvor/widgets/tela_carregamento.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../functions/metodos_firebase.dart';
import '../../models/integrante.dart';

class AuthGuardView extends StatelessWidget {
  final Widget scaffold;
  const AuthGuardView({Key? key, required this.scaffold}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
        initialData: FirebaseAuth.instance.currentUser,
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          dev.log('Stream user: ${snapshot.connectionState.name}',
              name: 'AuthGuard');

          // NÃO LOGADO
          if (!snapshot.hasData &&
              snapshot.connectionState == ConnectionState.active) {
            dev.log('Interface usuário não logado', name: 'AuthGuard');
            return const TelaLogin();
          }
          // DADOS DO INTEGRANTE CARREGADOS
          // USUARIO LOGADO
          if (snapshot.hasData) {
            print('Usuário está logado!');
            FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
            var user = snapshot.data!;
            // Carrega o integrante logado

            return FutureBuilder<DocumentSnapshot<Integrante>?>(
                future: MeuFirebase.obterSnapshotIntegrante(user.uid),
                builder: (context, integrante) {
                  if (!integrante.hasData) {
                    return const TelaCarregamento();
                  }
                  Global.logadoSnapshot = integrante.data;
                  return scaffold;
                });
          }

          // CARREGAMENTO DA INTERFACE
          dev.log('Carregando interface...', name: 'AuthGuard');
          return const TelaCarregamento();
        });
  }
}
