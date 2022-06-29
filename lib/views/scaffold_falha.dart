import 'package:escala_louvor/utils/global.dart';
import 'package:flutter/material.dart';

class ViewFalha extends StatelessWidget {
  final String mensagem;
  const ViewFalha({Key? key, required this.mensagem}) : super(key: key);

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
                  height: 256,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 12),
              // Título
              const Text(
                'Falha!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent),
              ),
              const SizedBox(height: 12),
              // Mensagem
              Text(
                mensagem,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // logo
              Wrap(
                spacing: 8,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Image.asset('assets/icons/ic_launcher.png', width: 20),
                  Text(
                    Global.nomeDoApp,
                    style: TextStyle(color: Colors.grey.withOpacity(0.5)),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
