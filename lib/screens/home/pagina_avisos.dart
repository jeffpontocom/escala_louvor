import 'package:flutter/material.dart';

import '../../widgets/tela_mensagem.dart';

class PaginaAvisos extends StatelessWidget {
  const PaginaAvisos({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const TelaMensagem(
      'Nenhum aviso recente!',
      asset: 'assets/images/chat.png',
    );
  }
}
