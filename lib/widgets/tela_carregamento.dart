import 'package:flutter/material.dart';

import '/resources/animations/bouncing.dart';
import '/utils/global.dart';

class TelaCarregamento extends StatelessWidget {
  final String mensagem;
  const TelaCarregamento({Key? key, required this.mensagem}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        // Animação
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 36),
            const Expanded(child: SizedBox()),
            // Icone da aplicação
            Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimacaoPulando(
                        objectToAnimate:
                            Image.asset('assets/icons/ic_launcher.png')),
                  ]),
            ),
            // Mensagem
            Expanded(
              child: Column(children: [
                Text(
                  mensagem,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.tertiary),
                ),
              ]),
            ),
            // Versão
            SizedBox(height: 36, child: Global.versaoDoAppText),
          ],
        ),
      ),
    );
  }
}
