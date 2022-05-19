import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:printing/printing.dart';
import 'package:wakelock/wakelock.dart';

class TelaPdfView extends StatefulWidget {
  final List<Response> arquivos;
  const TelaPdfView({Key? key, required this.arquivos}) : super(key: key);

  @override
  State<TelaPdfView> createState() => _TelaPdfViewState();
}

class _TelaPdfViewState extends State<TelaPdfView> {
  @override
  void initState() {
    Wakelock.enable();
    super.initState();
  }

  @override
  void dispose() {
    Wakelock.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: widget.arquivos.length,
      child: SafeArea(
        child: Scaffold(
          body: TabBarView(
            children: List.generate(widget.arquivos.length, (index) {
              return PdfPreview(
                build: (format) {
                  return widget.arquivos[index].bodyBytes;
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
