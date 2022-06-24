import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../functions/metodos_firebase.dart';
import '../models/integrante.dart';
import '../utils/utils.dart';

class ViewUserInativo extends StatelessWidget {
  const ViewUserInativo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icone de erro
              Flexible(
                child: Image.asset(
                  'assets/images/login.png',
                  width: 160,
                  height: 160,
                  color: Theme.of(context).colorScheme.secondary,
                  colorBlendMode: BlendMode.modulate,
                ),
              ),
              const SizedBox(height: 24),
              // Texto de carregamento
              const Text(
                'Seu cadastro está inativo!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              const Text(
                'Fale com o administrador do sistema para solucionar o problema.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FutureBuilder<QuerySnapshot<Integrante>>(
                  future: MeuFirebase.obterListaDeAdministradores(),
                  builder: (context, snap) {
                    var whats = snap.data?.docs.first.data().telefone;
                    return ElevatedButton.icon(
                      label: const Text('Chamar no whats'),
                      icon: const Icon(Icons.whatsapp),
                      style: ElevatedButton.styleFrom(primary: Colors.green),
                      onPressed: whats == null
                          ? null
                          : () => MyActions.openWhatsApp(whats),
                    );
                  }),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                label: const Text('Sair'),
                icon: const Icon(Icons.logout),
                style: ElevatedButton.styleFrom(primary: Colors.red),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
