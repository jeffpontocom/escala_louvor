import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/widgets/sliver_pinned_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '/functions/metodos_firebase.dart';
import '/models/cantico.dart';
import '/models/culto.dart';
import '/utils/global.dart';
import '/utils/mensagens.dart';
import '/utils/utils.dart';
import '/widgets/tela_mensagem.dart';
import '/widgets/tile_cantico.dart';
import '/widgets/dialogos.dart';

enum FiltroRepertorio {
  todos,
  cantos,
  hinos,
}

class PaginaCanticos extends StatefulWidget {
  final DocumentSnapshot<Culto>? culto;
  const PaginaCanticos({Key? key, this.culto}) : super(key: key);

  @override
  State<PaginaCanticos> createState() => _PaginaCanticosState();
}

class _PaginaCanticosState extends State<PaginaCanticos> {
  /* VARIÁVEIS */

  /// Lista de cânticos selecionados
  List<DocumentReference<Cantico>>? _selecionados;

  /// Filtro de Repertório
  final ValueNotifier<FiltroRepertorio> filtroRepertorio =
      ValueNotifier(FiltroRepertorio.todos);

  /// Controlador do campo de busca
  final TextEditingController searchInputController = TextEditingController();

  /// Notificador do campo de busca
  final ValueNotifier<String> buscaFiltro = ValueNotifier('');

  /// Notificador de total de itens encontrados
  final ValueNotifier<int> totalItens = ValueNotifier(0);

/* SISTEMA  */
  @override
  void initState() {
    _selecionados = widget.culto?.data()?.canticos;
    super.initState();
  }

  @override
  void dispose() {
    filtroRepertorio.dispose();
    buscaFiltro.dispose();
    totalItens.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _layout;
  }

  /// LAYOUT DA TELA
  get _layout {
    return OrientationBuilder(builder: (context, orientation) {
      // MODO RETRATO
      if (orientation == Orientation.portrait) {
        return Column(children: [
          Expanded(
            child: NestedScrollView(
              floatHeaderSlivers: true,
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(child: _rowAcoes),
                  SliverPinnedBox(child: Material(child: _rowBusca)),
                  const SliverPinnedBox(
                      child: Divider(height: 1, thickness: 1)),
                ];
              },
              body: _listaCanticos,
            ),
          ),
          _rowSelecao
        ]);
      }
      // MODO PAISAGEM
      return LayoutBuilder(builder: (context, constraints) {
        return Wrap(children: [
          Container(
            color: Colors.grey.withOpacity(0.12),
            height: constraints.maxHeight,
            width: constraints.maxWidth * 0.4 - 1,
            child: Column(
              children: [
                _rowAcoes,
                _rowBusca,
                const Divider(height: 1),
                const Expanded(child: SizedBox()),
                _rowSelecao,
              ],
            ),
          ),
          Container(
              height: constraints.maxHeight,
              width: 1,
              color: Colors.grey.withOpacity(0.38)),
          SizedBox(
              height: constraints.maxHeight,
              width: constraints.maxWidth * 0.6,
              child: _listaCanticos),
        ]);
      });
    });
  }

  /// WIDGET DE AÇÕES
  get _rowAcoes {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // BOTÃO DE FILTROS
          const Icon(Icons.filter_alt),
          const SizedBox(width: 4),
          StatefulBuilder(
            builder: (context, innerState) {
              return DropdownButtonHideUnderline(
                child: DropdownButton<FiltroRepertorio>(
                    value: filtroRepertorio.value,
                    items: const [
                      DropdownMenuItem(
                        value: FiltroRepertorio.todos,
                        child: Text('Lista completa'),
                      ),
                      DropdownMenuItem(
                        value: FiltroRepertorio.cantos,
                        child: Text('Somente cânticos'),
                      ),
                      DropdownMenuItem(
                        value: FiltroRepertorio.hinos,
                        child: Text('Somente hinos'),
                      ),
                    ],
                    onChanged: (value) {
                      innerState(() {
                        filtroRepertorio.value =
                            value ?? FiltroRepertorio.todos;
                      });
                    }),
              );
            },
          ),

          // Espaço em branco com altura padrão de interação
          const Expanded(child: SizedBox(height: kMinInteractiveDimension)),

          // BOTÃO NOVO CÂNTICOS
          // Apenas para Dirigentes, Coordenadores ou administrador do sistema
          Global.logado!.adm ||
                  Global.logado!.ehDirigente ||
                  Global.logado!.ehCoordenador
              ? ActionChip(
                  avatar: const Icon(Icons.add, size: 20),
                  label: const Text('Novo'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  onPressed: () {
                    Dialogos.editarCantico(context, cantico: Cantico(nome: ''));
                  })
              : const SizedBox(),
        ],
      ),
    );
  }

  /// WIDGET DE BUSCA
  get _rowBusca {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ValueListenableBuilder(
          valueListenable: totalItens,
          builder: (context, total, _) {
            return TextField(
              controller: searchInputController,
              decoration: InputDecoration(
                  isDense: true,
                  fillColor: Theme.of(context).colorScheme.background,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchInputController.clear();
                        buscaFiltro.value = '';
                      }),
                  hintText: 'Buscar... ',
                  helperText: '$total itens na lista'),
              onChanged: (value) {
                buscaFiltro.value = value;
              },
            );
          }),
    );
  }

  /// WIDGET DE CÂNTICOS SELECIONADOS
  get _rowSelecao {
    return widget.culto != null
        ? Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.25),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Seleção
                _selecionadosToString,
                // Botão adicionar/atualizar canticos do evento
                ElevatedButton(
                  child: const Text('CONCLUIR'),
                  onPressed: () async {
                    Mensagem.aguardar(context: context);
                    await widget.culto?.reference
                        .update({'canticos': _selecionados});
                    Modular.to.pop(); // fechar progresso
                    Modular.to.maybePop(); // fecha dialog
                  },
                )
              ],
            ))
        : const SizedBox();
  }

  /// TEXTO DE CÂNTICOS SELECIONADOS
  Widget get _selecionadosToString {
    if (_selecionados == null || _selecionados!.isEmpty) {
      return const Text('Nenhum cântico selecionado.');
    }
    return Wrap(
      children: List.generate(_selecionados!.length, (index) {
        return FutureBuilder<DocumentSnapshot<Cantico>?>(
            future: MeuFirebase.obterCantico(id: _selecionados![index].id),
            builder: (context, snapshot) {
              return Text(
                  '${index + 1} - ${snapshot.data?.data()?.nome ?? '[erro]'}${index < _selecionados!.length - 1 ? "; " : ""}');
            });
      }),
    );
  }

  /// LISTA DE CÂNTICOS
  get _listaCanticos {
    return ValueListenableBuilder(
        valueListenable: filtroRepertorio,
        builder: (context, filtro, _) {
          bool? somenteHinos;
          switch (filtro) {
            case FiltroRepertorio.todos:
              somenteHinos = null;
              break;
            case FiltroRepertorio.cantos:
              somenteHinos = false;
              break;
            case FiltroRepertorio.hinos:
              somenteHinos = true;
              break;
            default:
          }
          return StreamBuilder<QuerySnapshot<Cantico>>(
              stream: MeuFirebase.ouvinteCanticos(somenteHinos: somenteHinos),
              builder: (_, canticos) {
                if (!canticos.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                List<QueryDocumentSnapshot<Cantico>>? listaOriginal =
                    canticos.data?.docs;
                List<QueryDocumentSnapshot<Cantico>> listaFiltrada = [];
                if (listaOriginal == null || listaOriginal.isEmpty) {
                  return TelaMensagem(
                    'Nenhum ${somenteHinos == null ? "cântico ou hino" : somenteHinos == true ? "hino" : "cântico"} cadastrado',
                    asset: 'assets/images/song.png',
                  );
                }
                return ValueListenableBuilder<String>(
                    valueListenable: buscaFiltro,
                    builder: (_, filtro, child) {
                      listaFiltrada.clear();
                      if (filtro.isEmpty || filtro.length < 3) {
                        listaFiltrada
                            .addAll(listaOriginal.where((element) => true));
                      } else {
                        listaFiltrada.addAll(listaOriginal.where((element) =>
                            MyStrings.hasContain(element.data().nome, filtro) ||
                            MyStrings.hasContain(
                                element.data().autor ?? '', filtro) ||
                            MyStrings.hasContain(
                                element.data().letra ?? '', filtro)));
                      }
                      WidgetsBinding.instance.scheduleFrameCallback((duration) {
                        totalItens.value = listaFiltrada.length;
                      });
                      if (listaFiltrada.isEmpty) {
                        return TelaMensagem(
                          'Nenhum ${somenteHinos == null ? "cântico ou hino" : somenteHinos == true ? "hino" : "cântico"} encontrado na busca',
                          asset: 'assets/images/song.png',
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: listaFiltrada.length,
                        itemBuilder: (context, index) {
                          bool? selecionado = widget.culto == null
                              ? null
                              : (_selecionados
                                      ?.map((e) => e.toString())
                                      .contains(listaFiltrada[index]
                                          .reference
                                          .toString())) ??
                                  false;
                          //
                          return TileCantico(
                            snapshot: listaFiltrada[index],
                            selecionado: selecionado,
                            onTap: widget.culto == null
                                ? null
                                : () => onSelectItem(
                                    listaFiltrada[index].reference),
                          );
                        },
                        separatorBuilder: (context, index) {
                          return const Divider(height: 1);
                        },
                      );
                    });
              });
        });
  }

  void onSelectItem(DocumentReference<Cantico> reference) {
    setState(() {
      _selecionados ??= [];
      if (_selecionados!
          .map((e) => e.toString())
          .contains(reference.toString())) {
        _selecionados!.removeWhere(
            (element) => element.toString() == reference.toString());
      } else {
        _selecionados!.add(reference);
      }
    });
  }
}
