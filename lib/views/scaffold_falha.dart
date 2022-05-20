import 'package:flutter/material.dart';

class ViewFalha extends StatelessWidget {
  final String mensagem;
  const ViewFalha({Key? key, required this.mensagem}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(64),
          alignment: Alignment.center,
          // Animação
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // logo
              Image.asset('assets/icons/ic_launcher.png', width: 64),
              const SizedBox(height: 32),
              // texto
              Text(mensagem,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }
}
