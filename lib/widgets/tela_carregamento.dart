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
            const Expanded(child: SizedBox()),
            // Icone da aplicação
            AnimacaoPulando(
                objectToAnimate: Image.asset('assets/icons/ic_launcher.png')),
            const SizedBox(height: 12),
            // Mensagem
            Text(mensagem),
            const Expanded(child: SizedBox()),
            // Versão
            Global.versaoDoAppText,
          ],
        ),
      ),
    );
  }
}
