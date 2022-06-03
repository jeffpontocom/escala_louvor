import 'package:flutter/material.dart';

class TelaMensagem extends StatelessWidget {
  final String mensagem;
  final String? asset;
  final IconData? icone;
  final bool isError;
  final bool isLoading;

  const TelaMensagem(this.mensagem,
      {Key? key,
      this.asset,
      this.icone,
      this.isError = false,
      this.isLoading = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        isLoading ? const LinearProgressIndicator() : const SizedBox(),
        Expanded(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // IMAGEM
                  Flexible(
                    child: asset != null
                        ? Image.asset(
                            asset!,
                            fit: BoxFit.contain,
                            width: 256,
                            height: 256,
                          )
                        : icone != null
                            ? Icon(icone!, size: 256)
                            : const SizedBox(height: 256),
                  ),
                  const SizedBox(height: 24),
                  // MENSAGEM
                  Text(
                    mensagem,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isError ? Colors.white : null,
                        backgroundColor: isError
                            ? Theme.of(context).colorScheme.error
                            : null),
                  ),
                ],
              )),
        ),
      ],
    );
  }
}
