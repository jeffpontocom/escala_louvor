import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:wakelock/wakelock.dart';

import '/functions/metodos_firebase.dart';
import '/models/cantico.dart';
import '/modulos.dart';
import '/utils/global.dart';
import '/utils/mensagens.dart';
import '/views/auth_guard.dart';
import '/views/scaffold_falha.dart';
import '/widgets/dialogos.dart';
import '/widgets/tela_mensagem.dart';

class TelaCantico extends StatefulWidget {
  final String id;
  final DocumentSnapshot<Cantico>? snapshot;
  const TelaCantico({Key? key, required this.id, this.snapshot})
      : super(key: key);

  @override
  State<TelaCantico> createState() => _TelaCanticoState();
}

class _TelaCanticoState extends State<TelaCantico> {
  late Cantico mCantico;
  late DocumentSnapshot<Cantico> mSnapshot;

  static const double _minFontSize = 15.0;
  static const double _maxFontSize = 50.0;
  ValueNotifier<double> fontSize = ValueNotifier(20);
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
    return AuthGuardView(
      scaffoldView: StreamBuilder<DocumentSnapshot<Cantico>>(
          initialData: widget.snapshot,
          stream: MeuFirebase.ouvinteCantico(id: widget.id),
          builder: (context, snapshot) {
            // Progresso
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            // Erro
            if (snapshot.hasError || snapshot.data?.data() == null) {
              return const ViewFalha(
                  mensagem: 'Falha ao carregar dados do cantico.');
            }
            // Conteúdo
            mSnapshot = snapshot.data!;
            mCantico = mSnapshot.data()!;
            return Scaffold(
              appBar: AppBar(
                leading: BackButton(
                  onPressed: () async {
                    if (!await Modular.to.maybePop()) {
                      Modular.to.pushNamed(Global.rotaInicial);
                    }
                  },
                ),
                title: Column(
                  children: [
                    // NOME DO CÂNTICO
                    Text(mCantico.nome),
                    Text(mCantico.autor ?? '',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.normal)),
                  ],
                ),
                actions: [
                  Global.logado!.adm ||
                          Global.logado!.ehDirigente ||
                          Global.logado!.ehCoordenador
                      ? PopupMenuButton(
                          tooltip: 'Menu',
                          child: kIsWeb
                              ? Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Wrap(
                                    spacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      const Text('Menu'),
                                      Icon(Icons.adaptive.more)
                                    ],
                                  ),
                                )
                              : null,
                          onSelected: (value) {
                            if (value == 'edit') {
                              Dialogos.editarCantico(
                                context,
                                cantico: mCantico,
                                reference: mSnapshot.reference,
                              );
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
                  // CABEÇALHO
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.grey.withOpacity(0.38),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Tom
                        Column(
                          children: [
                            Text(mCantico.tom ?? '',
                                style: const TextStyle(
                                    fontSize: 36, fontWeight: FontWeight.bold)),
                            Text('Tom',
                                style: Theme.of(context).textTheme.caption),
                          ],
                        ),
                        const SizedBox(width: 12),
                        // Compasso
                        Column(
                          children: [
                            Text(mCantico.compasso ?? '',
                                style: const TextStyle(fontSize: 24)),
                            Text('Compasso',
                                style: Theme.of(context).textTheme.caption),
                          ],
                        ),
                        const Expanded(child: SizedBox()),
                        // Cifra
                        mCantico.cifraUrl == null
                            ? const SizedBox()
                            : Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          color: Colors.grey.withOpacity(0.38)),
                                      child: IconButton(
                                        icon: const Icon(Icons.queue_music),
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () {
                                          var url = mCantico.cifraUrl!;
                                          var name =
                                              '${mCantico.nome.toUpperCase()} (${mCantico.tom ?? "_"})';
                                          Modular.to.pushNamed(
                                              AppModule.ARQUIVOS,
                                              arguments: [url, name]);
                                          /* MeuFirebase.abrirArquivosPdf(
                                          context, [mCantico.cifraUrl!]); */
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Cifra',
                                        style: Theme.of(context)
                                            .textTheme
                                            .caption),
                                  ],
                                ),
                              ),
                        // YouTube
                        mCantico.youTubeUrl == null ||
                                mCantico.youTubeUrl!.isEmpty
                            ? const SizedBox()
                            : Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          color: Colors.grey.withOpacity(0.38)),
                                      child: IconButton(
                                        icon: const FaIcon(
                                            FontAwesomeIcons.youtube,
                                            color: Colors.red),
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () async {
                                          if (!await launchUrlString(
                                              mCantico.youTubeUrl!)) {
                                            Mensagem.simples(
                                                context: context,
                                                mensagem:
                                                    'Não foi possível abrir o link');
                                            throw 'Could not launch youTubeUrl';
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Vídeo',
                                        style: Theme.of(context)
                                            .textTheme
                                            .caption),
                                  ],
                                ),
                              ),
                      ],
                    ),
                  ),

                  // LETRA
                  Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      child: mCantico.letra == null || mCantico.letra!.isEmpty
                          ? const TelaMensagem(
                              'Solicite a um Coordenador Técnico a atualização.',
                              title: 'Sem letra!',
                              asset: 'assets/images/song.png',
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
                                      padding: const EdgeInsets.all(24),
                                      child: SelectableText(
                                        mCantico.letra!,
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
          }),
    );
  }
}
