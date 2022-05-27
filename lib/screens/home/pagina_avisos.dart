import 'package:flutter/material.dart';

class PaginaAvisos extends StatelessWidget {
  const PaginaAvisos({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(builder: (context, orientation) {
      return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logotipo
              Flexible(
                child: Image.asset(
                  'assets/images/chat.png',
                  fit: BoxFit.contain,
                  width: 256,
                  height: 256,
                ),
              ),
              // Informação
              Text(
                'Nenhum aviso recente!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ));
    });
  }
}
