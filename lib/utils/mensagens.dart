import 'package:flutter/material.dart';

import '../resources/medidas.dart';

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
    VoidCallback? onClose,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      /* shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ), */
      builder: (context) {
        return OrientationBuilder(builder: (context, orientation) {
          return ConstrainedBox(
            constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height * 0.3,
                maxHeight: MediaQuery.of(context).size.height * 0.9),
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).viewInsets.top,
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: Medidas.paddingListH(context),
                right: Medidas.paddingListH(context),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cabeçalho
                  Row(
                    children: [
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          titulo,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      CloseButton(color: Colors.grey.withOpacity(0.5)),
                    ],
                  ),
                  const Divider(height: 1),
                  // Conteúdo
                  Flexible(child: conteudo),
                  // Rodapé
                  rodape == null
                      ? const SizedBox()
                      : Column(
                          children: [
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: rodape,
                            ),
                          ],
                        ),
                ],
              ),
            ),
          );
        });
      },
    ).then((value) {
      if (onClose != null) onClose();
    });
  }

  /// Apresenta popup no padrão bottom dialog
  static void showPdf(
      {required BuildContext context,
      required String titulo,
      required Widget conteudo}) {
    ScrollController scrollController = ScrollController();
    bottomDialog(
      context: context,
      titulo: titulo,
      conteudo: SingleChildScrollView(
        controller: scrollController,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: conteudo,
        ),
      ),
      scrollController: scrollController,
    );
  }
}

/// Caixa de diálogo de notificação por push para primeiro plano
class DialogoMensagem extends StatelessWidget {
  final String titulo;
  final String corpo;
  const DialogoMensagem({Key? key, required this.titulo, required this.corpo})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(titulo),
      content: Text(corpo),
      actions: [
        OutlinedButton.icon(
            label: const Text('Fechar'),
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close))
      ],
    );
  }
}
