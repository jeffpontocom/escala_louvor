import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/models/integrante.dart';
import 'package:escala_louvor/utils/global.dart';
import 'package:escala_louvor/widgets/avatar.dart';
import 'package:escala_louvor/widgets/tile_integrante.dart';
import 'package:flutter/material.dart';

import '../../functions/metodos_firebase.dart';
import '../../models/igreja.dart';
import '../../utils/utils.dart';

class PaginaEquipe extends StatefulWidget {
  const PaginaEquipe({Key? key}) : super(key: key);

  @override
  State<PaginaEquipe> createState() => _PaginaEquipeState();
}

class _PaginaEquipeState extends State<PaginaEquipe> {
  /* VARIÁVEIS */
  late bool _isPortrait;
  late Igreja _igreja;
  ValueNotifier<Funcao?> filtroFuncao = ValueNotifier(null);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Igreja>>(
        initialData: Global.igrejaSelecionada.value,
        stream: MeuFirebase.obterStreamIgreja(Global.igreja ?? ''),
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
          return _corpo;
        });
  }

  /// Corpo
  get _corpo {
    return OrientationBuilder(builder: (context, orientation) {
      _isPortrait = orientation == Orientation.portrait;
      return LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Wrap(
                children: [
                  // Cabeçalho
                  Material(
                    //elevation: _isPortrait ? 4 : 0,
                    color: Theme.of(context).colorScheme.background,
                    child: Container(
                      height: _isPortrait
                          ? constraints.maxHeight * 0.35
                          : constraints.maxHeight,
                      width: _isPortrait
                          ? constraints.maxWidth
                          : constraints.maxWidth * 0.35,
                      padding: const EdgeInsets.all(16),
                      child: _cabecalho,
                    ),
                  ),
                  // Conteúdo
                  SizedBox(
                    height: _isPortrait
                        ? constraints.maxHeight * 0.65
                        : constraints.maxHeight,
                    width: _isPortrait
                        ? constraints.maxWidth
                        : constraints.maxWidth * 0.65,
                    child: _dados,
                  ),
                ],
              ),
            ],
          );
        },
      );
    });
  }

  /// Cabeçalho
  get _cabecalho {
    return Column(
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
          style: const TextStyle(color: Colors.grey, fontSize: 16),
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
    return ValueListenableBuilder<Funcao?>(
        valueListenable: filtroFuncao,
        builder: (context, funcao, _) {
          String filtro =
              funcao == null ? 'Equipe completa' : funcaoGetString(funcao);
          return StreamBuilder<QuerySnapshot<Integrante>>(
            stream: MeuFirebase.obterListaIntegrantes(
                    ativo: true, funcao: filtroFuncao.value?.index)
                .asStream(),
            builder: (context, snapshot) {
              int total = snapshot.data?.size ?? 0;
              return Column(
                children: [
                  // Progress indicator
                  snapshot.connectionState == ConnectionState.waiting
                      ? const LinearProgressIndicator()
                      : const SizedBox(),

                  // Filtros de função
                  Row(
                    children: [
                      const SizedBox(width: 16),
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
                              child: Text(funcaoGetString(Funcao.coordenador)),
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
                            filtroFuncao.value = value;
                          }),
                      //
                      const Expanded(child: SizedBox()),
                      Text(
                        snapshot.connectionState == ConnectionState.waiting
                            ? 'Carregando lista...'
                            : '$total MEMBROS ATIVOS',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                  const Divider(height: 1),
                  // Integrantes,
                  Expanded(
                    child: snapshot.hasData
                        ? ListView.builder(
                            shrinkWrap: true,
                            itemCount: total,
                            itemBuilder: (context, index) {
                              var snap = snapshot.data!.docs[index];
                              return TileIntegrante(snapshot: snap);
                            },
                          )
                        : const Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            },
          );
        });
  }
}
