import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:printing/printing.dart';

class TelaPdfView extends StatelessWidget {
  final List<Response> arquivos;
  const TelaPdfView({Key? key, required this.arquivos}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: DefaultTabController(
          length: arquivos.length,
          child: TabBarView(
            children: List.generate(arquivos.length, (index) {
              return PdfPreview(
                build: (format) {
                  return arquivos[index].bodyBytes;
                },
                previewPageMargin: EdgeInsets.zero,
                canDebug: false,
                canChangeOrientation: false,
                canChangePageFormat: false,
              );
            }),
          ),
        ),
      ),
    );
  }
}
