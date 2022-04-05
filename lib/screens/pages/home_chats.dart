import 'package:flutter/material.dart';

class TelaChat extends StatelessWidget {
  const TelaChat({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logotipo
            const Image(
              image: AssetImage('assets/images/chat.png'),
              height: 256,
              width: 256,
            ),
            // Informação
            const Text(
              'Chats para os cultos/eventos em que você está escalado.\n',
              textAlign: TextAlign.center,
            ),
            Text(
              'Em breve!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ));
  }
}
