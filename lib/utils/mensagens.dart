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
    Widget? leading,
    Widget? rodape,
    bool arrasteParaFechar = true,
    VoidCallback? onClose,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: arrasteParaFechar,
      useRootNavigator: true, // para sobrepor a Bottom Navigation
      // Formato do Dialog
      /* shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ), */
      builder: (context) {
        return OrientationBuilder(builder: (context, orientation) {
          return ConstrainedBox(
            // Altura mínima e máxima do Dialog
            constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height * 0.25,
                maxHeight: MediaQuery.of(context).size.height * 0.90),
            // Padding com MediaQuery para redimensionar ao apresentar o teclado virtual
            // Largura do conteúdo restrita ao máximo definido em Medidas
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).viewInsets.top,
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: Medidas.paddingListH(context),
                right: Medidas.paddingListH(context),
              ),
              // Interface
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // CABEÇALHO
                  Row(
                    children: [
                      // Leading
                      Padding(
                          padding: EdgeInsets.only(
                              left: 16, right: leading == null ? 0 : 8),
                          child: leading),
                      // Título
                      Expanded(
                        child: Text(
                          titulo,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Botão para fechar
                      CloseButton(color: Colors.grey.withOpacity(0.5)),
                    ],
                  ),
                  const Divider(height: 1),

                  // CONTEÚDO
                  Flexible(child: conteudo),

                  // RODAPÉ
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
}
