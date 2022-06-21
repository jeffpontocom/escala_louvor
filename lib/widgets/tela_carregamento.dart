import 'package:flutter/material.dart';

import '/resources/animations/bouncing.dart';

class TelaCarregamento extends StatelessWidget {
  const TelaCarregamento({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      color: MediaQueryData.fromWindow(WidgetsBinding.instance.window)
                  .platformBrightness ==
              Brightness.dark
          ? const Color(0xFF121212)
          : const Color(0xFF2094f3),
      // Animação
      child: AnimacaoPulando(
        objectToAnimate: Image.asset('assets/icons/ic_launcher.png'),
      ),
    );
  }
}
