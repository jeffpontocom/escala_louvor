import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '/utils/global.dart';

class View404 extends StatelessWidget {
  const View404({Key? key}) : super(key: key);

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
                  'assets/images/fail.png',
                  width: 160,
                  height: 160,
                ),
              ),
              const SizedBox(height: 24),
              // Texto de carregamento
              const Text(
                'Nenhuma página encontrada por aqui!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              const Text(
                'Clique no botão abaixo para ser redirecionado a página inicial',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                label: const Text('Home'),
                icon: const Icon(Icons.logout),
                style: ElevatedButton.styleFrom(primary: Colors.red),
                onPressed: () {
                  Modular.to.navigate(Global.rotaInicial);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
