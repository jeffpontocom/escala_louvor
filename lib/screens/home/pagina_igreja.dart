import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/functions/metodos_firebase.dart';
import '/models/igreja.dart';
import '/models/integrante.dart';
import '/utils/global.dart';
import '/utils/utils.dart';
import '../../widgets/cached_circle_avatar.dart';
import '/widgets/tile_integrante.dart';

class PaginaEquipe extends StatefulWidget {
  const PaginaEquipe({Key? key}) : super(key: key);

  @override
  State<PaginaEquipe> createState() => _PaginaEquipeState();
}

class _PaginaEquipeState extends State<PaginaEquipe> {
  /* VARIÁVEIS */
  late Igreja _igreja;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Igreja>>(
        initialData: Global.igrejaSelecionada.value,
        stream: MeuFirebase.ouvinteIgreja(
            id: Global.prefIgrejaId ??
                Global.igrejaSelecionada.value!.reference.id),
        builder: (context, snapshot) {
          // Tela em carregamento
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          // Tela de falha
          if (!snapshot.data!.exists || snapshot.data!.data() == null) {
            return const Center(child: Text('Falha ao obter dados da igreja.'));
          }
          // Tela carregada
          _igreja = snapshot.data!.data()!;
          return _layout;
        });
  }

  /// Corpo
  get _layout {
    return OrientationBuilder(
      builder: (context, orientation) {
        // MODO RETRATO
        if (orientation == Orientation.portrait) {
          return NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Container(
                      color: Colors.grey.withOpacity(0.12),
                      height: 300,
                      child: _cabecalho),
                ),
              ];
            },
            body: _dados,
          );
        }
        // MODO PAISAGEM
        return LayoutBuilder(builder: (context, constraints) {
          return Wrap(children: [
            Container(
              height: constraints.maxHeight,
              width: constraints.maxWidth * 0.4 - 1,
              color: Colors.grey.withOpacity(0.12),
              child: _cabecalho,
            ),
            Container(
                height: constraints.maxHeight,
                width: 1,
                color: Colors.grey.withOpacity(0.38)),
            SizedBox(
                height: constraints.maxHeight,
                width: constraints.maxWidth * 0.6,
                child: _dados),
          ]);
        });
      },
    );
  }

  /// Cabeçalho
  get _cabecalho {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Foto
          Flexible(
            child: LayoutBuilder(
              builder: (context, constraints) {
                var dimension = constraints.maxHeight < constraints.maxWidth
                    ? constraints.maxHeight
                    : constraints.maxWidth;
                return ConstrainedBox(
                  constraints:
                      BoxConstraints(maxWidth: dimension, maxHeight: dimension),
                  child: _foto,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Sigla
          Text(
            _igreja.sigla,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Offside',
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // Nome Completo
          Text(
            _igreja.nome,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          // Mapa
          _igreja.endereco == null || _igreja.endereco!.isEmpty
              ? const Text('Sem endereço cadastrado')
              : ActionChip(
                  avatar: const Icon(Icons.place, size: 20),
                  label: const Text('Localização'),
                  elevation: 0,
                  onPressed: () {
                    MyActions.openGoogleMaps(street: _igreja.endereco ?? '');
                  }),
        ],
      ),
    );
  }

  /// Foto
  get _foto {
    return Hero(
      tag: 'fotoIgreja',
      child: CachedAvatar(
        icone: Icons.church,
        url: _igreja.fotoUrl,
        maxRadius: 128,
      ),
    );
  }

  /// Dados
  get _dados {
    return StreamBuilder<QuerySnapshot<Integrante>>(
        stream: MeuFirebase.obterListaIntegrantes(
          igreja: Global.igrejaSelecionada.value?.reference,
        ).asStream(),
        builder: (context, snapshot) {
          return ValueListenableBuilder<Funcao?>(
              valueListenable: Global.filtroEquipe,
              builder: (context, funcao, _) {
                int total = 0;
                List<QueryDocumentSnapshot<Integrante>>? snapshotFiltrado;
                if (snapshot.hasData) {
                  if (funcao == null) {
                    snapshotFiltrado = snapshot.data?.docs;
                  } else {
                    snapshotFiltrado = snapshot.data?.docs
                        .where((element) =>
                            element.data().funcoes?.contains(funcao) ?? false)
                        .toList();
                  }
                  total = snapshotFiltrado?.length ?? 0;
                }
                return Column(children: [
                  // Filtros de função
                  Container(
                    color: Colors.grey.withOpacity(0.12),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Filtro
                        const Icon(Icons.filter_alt),
                        const SizedBox(width: 4),
                        DropdownButton<Funcao?>(
                            value: funcao,
                            underline: const SizedBox(),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Todos'),
                              ),
                              DropdownMenuItem(
                                value: Funcao.dirigente,
                                child: Text(funcaoGetString(Funcao.dirigente)),
                              ),
                              DropdownMenuItem(
                                value: Funcao.coordenador,
                                child:
                                    Text(funcaoGetString(Funcao.coordenador)),
                              ),
                              DropdownMenuItem(
                                value: Funcao.recrutador,
                                child: Text(funcaoGetString(Funcao.recrutador)),
                              ),
                              DropdownMenuItem(
                                value: Funcao.liturgo,
                                child: Text(funcaoGetString(Funcao.liturgo)),
                              ),
                              DropdownMenuItem(
                                value: Funcao.membro,
                                child: Text(funcaoGetString(Funcao.membro)),
                              ),
                            ],
                            onChanged: (value) {
                              Global.filtroEquipe.value = value;
                            }),
                        //
                        const Expanded(child: SizedBox()),
                        Text(
                          snapshot.connectionState == ConnectionState.waiting
                              ? 'Carregando lista...'
                              : '$total membros ativos',
                          style: Theme.of(context).textTheme.caption,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),
                  // Integrantes,
                  Expanded(
                    child: Column(
                      children: [
                        snapshot.connectionState == ConnectionState.waiting
                            ? const LinearProgressIndicator()
                            : const SizedBox(),
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: total,
                            separatorBuilder: (context, index) {
                              return const Divider(height: 1);
                            },
                            itemBuilder: (context, index) {
                              var snap = snapshotFiltrado![index];
                              return TileIntegrante(snapshot: snap);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ]);
              });
        });
  }
}
