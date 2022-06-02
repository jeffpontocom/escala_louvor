import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/functions/metodos_firebase.dart';
import 'package:escala_louvor/utils/global.dart';
import 'package:escala_louvor/utils/mensagens.dart';
import 'package:escala_louvor/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../../models/cantico.dart';
import '../../../models/culto.dart';
import '../../rotas.dart';
import '../../widgets/dialogos.dart';

class PaginaCanticos extends StatefulWidget {
  final DocumentSnapshot<Culto>? culto;
  const PaginaCanticos({Key? key, this.culto}) : super(key: key);

  @override
  State<PaginaCanticos> createState() => _PaginaCanticosState();
}

class _PaginaCanticosState extends State<PaginaCanticos> {
  /* VARIÁVEIS */
  late bool _isPortrait;
  bool? somenteHinos;
  List<DocumentReference<Cantico>>? _selecionados;
  final ValueNotifier<String> sFiltro = ValueNotifier('');
  TextEditingController searchInputController = TextEditingController();

  //Integrante? logado = Global.logado;

  @override
  void initState() {
    _selecionados = widget.culto?.data()?.canticos;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(builder: (context, orientation) {
      _isPortrait = orientation == Orientation.portrait;
      return LayoutBuilder(builder: (context, constraints) {
        return Wrap(children: [
          // Topo (retrato) | Esquerda (paisagem)
          SizedBox(
            height: _isPortrait ? 150 : constraints.maxHeight,
            width: _isPortrait
                ? constraints.maxWidth
                : constraints.maxWidth * 0.4 - 1,
            child: _cabecalho,
          ),
          // Divisor (apenas em modo paisagem)
          _isPortrait
              ? const SizedBox()
              : Container(
                  height: constraints.maxHeight,
                  width: 1,
                  color: Colors.grey,
                ),
          // Base (retrato) | Direita (paisagem)
          SizedBox(
            height: _isPortrait
                ? constraints.maxHeight - 151 - 56
                : constraints.maxHeight,
            width:
                _isPortrait ? constraints.maxWidth : constraints.maxWidth * 0.6,
            child: _dados,
          ),
        ]);
      });
    });
  }

  /// Cabeçalho: filtros
  get _cabecalho {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        color: Colors.grey.withOpacity(0.15),
        child: Row(
          children: [
            // Filtros
            const Text('Apresentando:'),
            const SizedBox(width: 8),
            RawChip(
              label: Text(somenteHinos == null
                  ? 'Toda a lista'
                  : somenteHinos == true
                      ? 'Somente hinos'
                      : 'Somente cânticos'),
              onPressed: () {
                setState(() {
                  switch (somenteHinos) {
                    case null:
                      somenteHinos = true;
                      break;
                    case true:
                      somenteHinos = false;
                      break;
                    default:
                      somenteHinos = null;
                      break;
                  }
                });
              },
            ),
            const Expanded(child: SizedBox()),
            // Botão adicionar
            Global.logado!.adm ||
                    Global.logado!.ehDirigente ||
                    Global.logado!.ehCoordenador
                ? ActionChip(
                    avatar: const Icon(Icons.add),
                    label: const Text('Novo'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    onPressed: () {
                      var cantico = Cantico(nome: '');
                      Dialogos.editarCantico(context, cantico);
                    })
                : const SizedBox(),
          ],
        ),
      ),
      const Divider(height: 1),
      const SizedBox(height: 8),
      // Campo de Busca
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: TextField(
          controller: searchInputController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  searchInputController.clear();
                  sFiltro.value = '';
                }),
            hintText: 'Buscar...',
          ),
          onChanged: (value) {
            sFiltro.value = value;
          },
        ),
      ),
      widget.culto != null
          ? Container(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  // Seleção
                  Expanded(child: _selecionadosToString),
                  // Botão adicionar/atualizar canticos do evento
                  ElevatedButton(
                    child: const Text('CONCLUIR'),
                    onPressed: () async {
                      Mensagem.aguardar(context: context);
                      await widget.culto?.reference
                          .update({'canticos': _selecionados});
                      Modular.to.pop(); // fechar progresso
                      Modular.to.pop(); // fecha dialog
                    },
                  )
                ],
              ))
          : const SizedBox(),
    ]);
  }

  /// Dados: Lista de cânticos
  get _dados {
    return StreamBuilder<QuerySnapshot<Cantico>>(
        stream: MeuFirebase.escutarCanticos(somenteHinos),
        builder: (_, canticos) {
          if (!canticos.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          List<QueryDocumentSnapshot<Cantico>>? listaOriginal =
              canticos.data?.docs;
          List<QueryDocumentSnapshot<Cantico>> listaFiltrada = [];
          if (listaOriginal == null || listaOriginal.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(64),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Imagem
                  Flexible(
                    child: Image.asset(
                      'assets/images/song.png',
                      fit: BoxFit.contain,
                      width: 256,
                      height: 256,
                    ),
                  ),
                  // Informação
                  Text(
                    'Nenhum ${somenteHinos == null ? "cântico ou hino" : somenteHinos == true ? "hino" : "cântico"} cadastrado',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return ValueListenableBuilder<String>(
              valueListenable: sFiltro,
              builder: (_, filtro, child) {
                listaFiltrada.clear();
                if (filtro.isEmpty || filtro.length < 4) {
                  listaFiltrada.addAll(listaOriginal.where((element) => true));
                } else {
                  listaFiltrada.addAll(listaOriginal.where((element) =>
                      MyStrings.hasContain(element.data().nome, filtro) ||
                      MyStrings.hasContain(
                          element.data().autor ?? '', filtro) ||
                      MyStrings.hasContain(
                          element.data().letra ?? '', filtro)));
                }
                if (listaFiltrada.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(64),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Imagem
                        Flexible(
                          child: Image.asset(
                            'assets/images/song.png',
                            fit: BoxFit.contain,
                            width: 256,
                            height: 256,
                          ),
                        ),
                        // Informação
                        Text(
                          'Nenhum ${somenteHinos == null ? "cântico ou hino" : somenteHinos == true ? "hino" : "cântico"} encontrado na busca',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                return LayoutBuilder(
                  builder: ((context, constraints) {
                    return Container(
                      //height: constraints.maxHeight,
                      child: ListView(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        children: List.generate(listaFiltrada.length, (index) {
                          bool selecionado = (_selecionados
                                  ?.map((e) => e.toString())
                                  .contains(listaFiltrada[index]
                                      .reference
                                      .toString()) ??
                              false);
                          return ListTile(
                            visualDensity: VisualDensity.compact,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            leading: selecionado
                                ? const SizedBox(
                                    width: kMinInteractiveDimension,
                                    height: kMinInteractiveDimension,
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                  )
                                : IconButton(
                                    onPressed: () {
                                      Modular.to.pushNamed(AppRotas.CANTICO,
                                          arguments: [
                                            listaFiltrada[index].data()
                                          ]);
                                      //Dialogos.verLetraDoCantico(
                                      //    context, listaFiltrada[index].data());
                                    },
                                    icon: const Icon(Icons.abc)),
                            horizontalTitleGap: 4,
                            title: Text(
                              listaFiltrada[index].data().nome,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              listaFiltrada[index].data().autor ?? '',
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Cifra
                                listaFiltrada[index].data().cifraUrl == null
                                    ? const SizedBox()
                                    : IconButton(
                                        onPressed: () {
                                          MeuFirebase.abrirArquivosPdf(
                                              context, [
                                            listaFiltrada[index]
                                                .data()
                                                .cifraUrl!
                                          ]);
                                        },
                                        icon: const Icon(Icons.queue_music,
                                            color: Colors.green)),
                                // YouTube
                                listaFiltrada[index].data().youTubeUrl ==
                                            null ||
                                        listaFiltrada[index]
                                            .data()
                                            .youTubeUrl!
                                            .isEmpty
                                    ? const SizedBox()
                                    : IconButton(
                                        onPressed: () async {
                                          if (!await launch(listaFiltrada[index]
                                                  .data()
                                                  .youTubeUrl ??
                                              '')) {
                                            throw 'Could not launch youTubeUrl';
                                          }
                                        },
                                        icon: const FaIcon(
                                            FontAwesomeIcons.youtube,
                                            color: Colors.red)),
                                // Menu
                                Global.logado!.adm ||
                                        Global.logado!.ehDirigente ||
                                        Global.logado!.ehCoordenador
                                    ? PopupMenuButton(
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            Dialogos.editarCantico(context,
                                                listaFiltrada[index].data(),
                                                reference: listaFiltrada[index]
                                                    .reference);
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
                            onTap: widget.culto == null
                                ? null
                                : () {
                                    setState(() {
                                      _selecionados ??= [];
                                      if (_selecionados!
                                          .map((e) => e.toString())
                                          .contains(listaFiltrada[index]
                                              .reference
                                              .toString())) {
                                        _selecionados!.removeWhere((element) =>
                                            element.toString() ==
                                            listaFiltrada[index]
                                                .reference
                                                .toString());
                                      } else {
                                        _selecionados!.add(
                                            listaFiltrada[index].reference);
                                      }
                                    });
                                  },
                          );
                        }),
                      ),
                    );
                  }),
                );
              });
        });
  }

  /// Rodapé: Cânticos selecionados
  Widget get _selecionadosToString {
    if (_selecionados == null || _selecionados!.isEmpty) {
      return const Text('Nenhum cântico selecionado.');
    }
    return Wrap(
      children: List.generate(_selecionados!.length, (index) {
        return FutureBuilder<DocumentSnapshot<Cantico>?>(
            future: MeuFirebase.obterSnapshotCantico(_selecionados![index].id),
            builder: (context, snapshot) {
              return Text(
                  '${index + 1} - ${snapshot.data?.data()?.nome ?? '[erro]'}${index < _selecionados!.length - 1 ? "; " : ""}');
            });
      }),
    );
  }
}
