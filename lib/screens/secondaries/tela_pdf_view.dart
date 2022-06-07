import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:wakelock/wakelock.dart';

import '/views/scaffold_falha.dart';

class TelaPdfView extends StatefulWidget {
  final String fileUrl;
  final String fileName;

  const TelaPdfView({Key? key, required this.fileUrl, required this.fileName})
      : super(key: key);

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
    return SafeArea(
      child: Scaffold(
        body: PdfPreview(
          padding: EdgeInsets.zero,
          previewPageMargin: const EdgeInsets.all(8),
          canDebug: false,
          canChangeOrientation: false,
          canChangePageFormat: false,
          pdfFileName: widget.fileName,
          dpi: 200,
          shouldRepaint: true,
          actions: const [BackButton()],
          build: (format) async {
            var data = await http.get(Uri.parse(widget.fileUrl));
            return data.bodyBytes;
          },
          onError: (context, _) =>
              const ViewFalha(mensagem: 'Não foi possível abrir o arquivo'),
        ),
      ),
    );
  }
}
