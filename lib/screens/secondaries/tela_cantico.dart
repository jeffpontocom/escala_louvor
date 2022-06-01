import 'package:escala_louvor/models/cantico.dart';
import 'package:flutter/material.dart';
import 'package:wakelock/wakelock.dart';

class TelaLetrasView extends StatefulWidget {
  final List<Cantico> canticos;
  const TelaLetrasView({Key? key, required this.canticos}) : super(key: key);

  @override
  State<TelaLetrasView> createState() => _TelaLetrasViewState();
}

class _TelaLetrasViewState extends State<TelaLetrasView> {
  static const double _minFontSize = 15.0;
  static const double _maxFontSize = 50.0;
  ValueNotifier<double> fontSize = ValueNotifier(_minFontSize);
  late double _textSizeBefore;
  late double _textSizeAfter;

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
      length: widget.canticos.length,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(title: const Text('Cântico')),
          body: TabBarView(
            children: List.generate(widget.canticos.length, (index) {
              Cantico cantico = widget.canticos[index];
              return GestureDetector(
                // Captura de gestos para alterar tamanho da fonte
                onScaleStart: (details) {
                  _textSizeAfter = fontSize.value;
                  _textSizeBefore = fontSize.value;
                },
                onScaleUpdate: (details) {
                  _textSizeAfter = _textSizeBefore * details.verticalScale;
                  if (_textSizeAfter > _minFontSize &&
                      _textSizeAfter < _maxFontSize) {
                    fontSize.value = _textSizeAfter;
                  }
                },
                onScaleEnd: (details) {
                  if (_textSizeAfter < _minFontSize) {
                    _textSizeAfter = _minFontSize;
                  }
                  if (_textSizeAfter > _maxFontSize) {
                    _textSizeAfter = _maxFontSize;
                  }
                  fontSize.value = _textSizeAfter;
                },
                // Pagina principal
                child: ValueListenableBuilder<double>(
                    valueListenable: fontSize,
                    builder: (context, size, _) {
                      return ListView(
                        padding: const EdgeInsets.all(24),
                        shrinkWrap: true,
                        children: [
                          // Título
                          Text(cantico.nome,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          // Autor
                          Text(cantico.autor ?? '',
                              style: Theme.of(context).textTheme.bodySmall),
                          // Letra
                          const SizedBox(height: 24),
                          SelectableText(
                            cantico.letra ??
                                'Sem letra!\nSolicite a um Coordenador Técnico a atualização.',
                            style: TextStyle(fontSize: size),
                          ),
                          const SizedBox(height: 48),
                        ],
                      );
                    }),
              );
              /* PdfPreview(
                build: (format) {
                  return widget.letras[index].bodyBytes;
                },
                previewPageMargin: const EdgeInsets.all(8),
                canDebug: false,
                canChangeOrientation: false,
                canChangePageFormat: false,
              ); */
            }),
          ),
        ),
      ),
    );
  }
}
