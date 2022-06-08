import 'package:flutter/material.dart';

import '../resources/animations/bouncing.dart';

class TelaCarregamento extends StatelessWidget {
  const TelaCarregamento({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(64),
      alignment: Alignment.center,
      color: Theme.of(context).primaryColor,
      // Animação
      child: AnimacaoPulando(
        objectToAnimate: Image.asset('assets/icons/ic_launcher.png'),
      ),
    );
  }
}
