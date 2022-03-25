import 'package:flutter/material.dart';

import 'medidas.dart';

class Mensagem {
  // Variáveis Globais
  static const double _alertMaxWidth = 360;

  /// Apresenta popup com uma mensagem simples
  static void simples(
      {required BuildContext context,
      String? titulo,
      String? mensagem,
      ValueNotifier? notificacao,
      VoidCallback? onPressed}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(titulo ?? 'Mensagem'),
          titleTextStyle: Theme.of(context).textTheme.titleLarge,
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _alertMaxWidth),
            child: Text(
                mensagem ?? notificacao?.value ?? 'Sua atenção foi requerida!'),
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.maybePop(context);
                if (onPressed != null) {
                  onPressed();
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// Apresenta popup de alerta
  static void decisao(
      {required BuildContext context,
      required String titulo,
      required String mensagem,
      Widget? extra,
      required Function(bool) onPressed}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _alertMaxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mensagem),
                extra ?? const SizedBox(),
              ],
            ),
          ),
          //buttonPadding: const EdgeInsets.all(0),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 12),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              child: const Text(
                'CANCELAR',
                style: TextStyle(color: Colors.grey),
              ),
              onPressed: () {
                // Fecha o dialogo
                Navigator.pop(context);
                onPressed(false);
              },
            ),
            TextButton(
              child: const Text('SIM'),
              onPressed: () {
                // Fecha o dialogo
                Navigator.pop(context);
                onPressed(true);
              },
            ),
          ],
        );
      },
    );
  }

  /// Apresenta popup com indicador de execução
  static void aguardar(
      {required BuildContext context,
      String? titulo,
      String? mensagem,
      ValueNotifier? notificacao}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return SimpleDialog(
          contentPadding: const EdgeInsets.all(24),
          title: Text(titulo ?? 'Aguarde'),
          titleTextStyle: Theme.of(context).textTheme.titleLarge,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _alertMaxWidth),
              child: Wrap(
                spacing: 24,
                runSpacing: 24,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  Text(mensagem ?? notificacao?.value ?? 'Executando...'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Apresenta um bottom dialog padrão com o título e conteúdo definido
  static void bottomDialog({
    required BuildContext context,
    required String titulo,
    required Widget conteudo,
    Widget? rodape,
    IconData? icon,
    ScrollController? scrollController,
    VoidCallback? onPressed,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.3,
          maxHeight: MediaQuery.of(context).size.height * 0.9),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).viewInsets.top,
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: Medidas.paddingListH(context),
            right: Medidas.paddingListH(context),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Elemento grafico (indicador de dialog)
              Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  color: Colors.grey.withOpacity(0.5),
                ),
              ),
              // Cabeçalho
              Row(
                children: [
                  IconButton(
                    onPressed: null,
                    icon: Icon(icon ?? Icons.subtitles,
                        color: Colors.grey.withOpacity(0.5)),
                  ),
                  Expanded(
                    child: Text(
                      titulo,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  CloseButton(color: Colors.grey.withOpacity(0.5)),
                ],
              ),
              // Conteúdo
              Flexible(child: conteudo),
              // Rodapé
              rodape == null ? const SizedBox() : const Divider(height: 1),
              rodape == null
                  ? const SizedBox()
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      child: rodape,
                    ),
            ],
          ),
        );
      },
    ).then((value) {
      if (onPressed != null) onPressed();
    });
  }
}
