import 'dart:developer' as dev;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:wakelock/wakelock.dart';

import '/views/scaffold_falha.dart';

class TelaPdfView extends StatefulWidget {
  final String fileUrl;
  final String name;

  const TelaPdfView({
    Key? key,
    required this.fileUrl,
    required this.name,
  }) : super(key: key);

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
          canDebug: false,
          canChangePageFormat: false,
          pdfFileName: '${widget.name}.pdf',
          dpi: 200,
          shouldRepaint: true,
          actions: const [BackButton()],
          scrollViewDecoration: const BoxDecoration(color: Colors.transparent),
          build: (format) async {
            var token = Uri.parse(widget.fileUrl).queryParameters['token'];
            dev.log('File token: $token');

            if (token != null &&
                await PdfBaseCache.defaultCache.contains(token)) {
              dev.log('Abrindo arquivo em cache');
              var cachedFile = await PdfBaseCache.defaultCache.get(token);
              return cachedFile!;
            }

            dev.log('Baixando arquivo em nuvem...');
            FirebaseStorage.instance
                .setMaxDownloadRetryTime(const Duration(seconds: 25));
            var data = await FirebaseStorage.instance
                .refFromURL(widget.fileUrl)
                .getData();

            dev.log('Salvando em cache...');
            if (token != null && data != null) {
              PdfBaseCache.defaultCache
                  .add(token, data)
                  .then((value) => dev.log('Arquivo salvo em cache'));
            } else {
              dev.log('Não foi possível salvar em cache');
            }

            dev.log('Abrindo arquivo');
            return data!;
          },
          onError: (context, _) =>
              const ViewFalha(mensagem: 'Não foi possível abrir o arquivo'),
        ),
      ),
    );
  }
}
