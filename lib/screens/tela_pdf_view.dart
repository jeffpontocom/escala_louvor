import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:printing/printing.dart';

class TelaPdfView extends StatelessWidget {
  final List<Response> arquivos;
  const TelaPdfView({Key? key, required this.arquivos}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: arquivos.length,
      child: SafeArea(
        child: Scaffold(
          body: TabBarView(
            children: List.generate(arquivos.length, (index) {
              return PdfPreview(
                build: (format) {
                  return arquivos[index].bodyBytes;
                },
                previewPageMargin: const EdgeInsets.all(8),
                canDebug: false,
                canChangeOrientation: false,
                canChangePageFormat: false,
                /* actions: [
                  PdfPreviewAction(
                      icon: const Icon(Icons.fast_rewind),
                      onPressed: (_, __, ___) =>
                          DefaultTabController.of(context)
                              ?.animateTo(index - 1))
                ], */
              );
            }),
          ),
        ),
      ),
    );
  }
}
