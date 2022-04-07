import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/functions/metodos_firebase.dart';
import 'package:escala_louvor/global.dart';
import 'package:escala_louvor/models/integrante.dart';
import 'package:escala_louvor/screens/views/dialogos.dart';
import 'package:escala_louvor/utils/mensagens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../models/cantico.dart';
import '../../models/culto.dart';

class TelaCanticos extends StatefulWidget {
  final DocumentSnapshot<Culto>? culto;
  const TelaCanticos({Key? key, this.culto}) : super(key: key);

  @override
  State<TelaCanticos> createState() => _TelaCanticosState();
}

class _TelaCanticosState extends State<TelaCanticos> {
  Integrante? logado = Global.integranteLogado?.data();
  bool? somenteHinos;
  List<DocumentReference<Cantico>>? _selecionados;

  @override
  void initState() {
    _selecionados = widget.culto?.data()?.canticos;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<String> _filtro = ValueNotifier('');
    TextEditingController _searchInputController = TextEditingController();
    return Column(
      children: [
        // Filtros e Adição
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
              logado!.adm || logado!.ehDirigente || logado!.ehCoordenador
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
            controller: _searchInputController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchInputController.clear();
                    _filtro.value = '';
                  }),
              hintText: 'Buscar...',
            ),
            onChanged: (value) {
              _filtro.value = value;
            },
          ),
        ),
        const SizedBox(height: 8),
        // Lista
        Expanded(
          child: StreamBuilder<QuerySnapshot<Cantico>>(
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
                    valueListenable: _filtro,
                    builder: (_, filtro, child) {
                      listaFiltrada.clear();
                      if (filtro.isEmpty || filtro.length < 4) {
                        listaFiltrada
                            .addAll(listaOriginal.where((element) => true));
                      } else {
                        listaFiltrada.addAll(listaOriginal.where((element) =>
                            element.data().nome.contains(filtro) ||
                            (element.data().autor?.contains(filtro) ?? false) ||
                            (element.data().letra?.contains(filtro) ?? false)));
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
                      return ListView(
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
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                    width: kMinInteractiveDimension,
                                    height: kMinInteractiveDimension,
                                  )
                                : IconButton(
                                    onPressed: () {
                                      Dialogos.verLetraDoCantico(
                                          context, listaFiltrada[index].data());
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
                                IconButton(
                                    onPressed:
                                        listaFiltrada[index].data().cifraUrl ==
                                                null
                                            ? null
                                            : () {
                                                MeuFirebase.abrirArquivosPdf(
                                                    context, [
                                                  listaFiltrada[index]
                                                      .data()
                                                      .cifraUrl!
                                                ]);
                                              },
                                    icon: const Icon(Icons.queue_music)),
                                // YouTube
                                IconButton(
                                    onPressed: () async {
                                      if (!await launch(listaFiltrada[index]
                                              .data()
                                              .youTubeUrl ??
                                          '')) {
                                        throw 'Could not launch youTubeUrl';
                                      }
                                    },
                                    icon: const Icon(Icons.ondemand_video)),
                                // Menu
                                logado!.adm ||
                                        logado!.ehDirigente ||
                                        logado!.ehCoordenador
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
                                              child: Text('Editar'),
                                              value: 'edit',
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
                      );
                    });
              }),
        ),
        widget.culto != null
            ? Container(
                color: Colors.orange.withOpacity(0.2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
      ],
    );
  }

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
