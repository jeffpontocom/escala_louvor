import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock/wakelock.dart';

import '../../functions/metodos_firebase.dart';
import '../../utils/global.dart';
import '../../widgets/dialogos.dart';
import '/models/cantico.dart';

class TelaLetrasView extends StatefulWidget {
  final QueryDocumentSnapshot<Cantico> snapshot;
  const TelaLetrasView({Key? key, required this.snapshot}) : super(key: key);

  @override
  State<TelaLetrasView> createState() => _TelaLetrasViewState();
}

class _TelaLetrasViewState extends State<TelaLetrasView> {
  static const double _minFontSize = 15.0;
  static const double _maxFontSize = 50.0;
  ValueNotifier<double> fontSize = ValueNotifier(20);
  late double _textSizeBefore;
  late double _textSizeAfter;
  late Cantico cantico;

  @override
  void initState() {
    cantico = widget.snapshot.data();
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
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            // NOME DO CÂNTICO
            Text(cantico.nome),
            Text(cantico.autor ?? '',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          Global.logado!.adm ||
                  Global.logado!.ehDirigente ||
                  Global.logado!.ehCoordenador
              ? PopupMenuButton(
                  onSelected: (value) {
                    if (value == 'edit') {
                      Dialogos.editarCantico(context, cantico,
                          reference: widget.snapshot.reference);
                    }
                  },
                  itemBuilder: (_) {
                    return const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Editar'),
                      ),
                    ];
                  },
                )
              : const SizedBox(),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.withOpacity(0.38),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Tom
                Column(
                  children: [
                    Text(cantico.tom ?? 'G',
                        style: Theme.of(context).textTheme.headlineMedium),
                    Text('Tom', style: Theme.of(context).textTheme.caption),
                  ],
                ),
                const SizedBox(width: 12),
                // Compasso
                Column(
                  children: [
                    Text(cantico.compasso ?? '3/4',
                        style: Theme.of(context).textTheme.headlineSmall),
                    Text('Compasso',
                        style: Theme.of(context).textTheme.caption),
                  ],
                ),
                const Expanded(child: SizedBox()),
                // Cifra
                cantico.cifraUrl == null
                    ? const SizedBox()
                    : Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.withOpacity(0.38)),
                            child: IconButton(
                                onPressed: () {
                                  MeuFirebase.abrirArquivosPdf(
                                      context, [cantico.cifraUrl!]);
                                },
                                icon: const Icon(Icons.queue_music)),
                          ),
                          const SizedBox(height: 4),
                          Text('Cifra',
                              style: Theme.of(context).textTheme.caption),
                        ],
                      ),
                const SizedBox(width: 12),
                // YouTube
                cantico.youTubeUrl == null || cantico.youTubeUrl!.isEmpty
                    ? const SizedBox()
                    : Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.withOpacity(0.38)),
                            child: IconButton(
                                onPressed: () async {
                                  if (!await launch(cantico.youTubeUrl ?? '')) {
                                    throw 'Could not launch youTubeUrl';
                                  }
                                },
                                icon: const FaIcon(FontAwesomeIcons.youtube,
                                    color: Colors.red)),
                          ),
                          const SizedBox(height: 4),
                          Text('Vídeo',
                              style: Theme.of(context).textTheme.caption),
                        ],
                      ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              child: cantico.letra == null
                  ? const Center(
                      child: Text(
                        'Sem letra!\nSolicite a um Coordenador Técnico a atualização.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : GestureDetector(
                      // Captura de gestos para alterar tamanho da fonte
                      onScaleStart: (details) {
                        _textSizeAfter = fontSize.value;
                        _textSizeBefore = fontSize.value;
                      },
                      onScaleUpdate: (details) {
                        _textSizeAfter =
                            _textSizeBefore * details.verticalScale;
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
                            return SingleChildScrollView(
                              child: SelectableText(
                                cantico.letra!,
                                style: TextStyle(fontSize: size),
                              ),
                            );
                          }),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
