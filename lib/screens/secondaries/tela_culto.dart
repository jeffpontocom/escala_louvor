import 'dart:convert';
import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_quill/flutter_quill.dart' as rich;
import 'package:intl/intl.dart';

import '/functions/metodos_firebase.dart';
import '/models/cantico.dart';
import '/models/culto.dart';
import '/models/instrumento.dart';
import '/models/integrante.dart';
import '/screens/home/pagina_canticos.dart';
import '/utils/global.dart';
import '/utils/mensagens.dart';
import '/views/auth_guard.dart';
import '/views/scaffold_falha.dart';
import '/widgets/card_integrante_instrumento.dart';
import '/widgets/card_integrante_responsavel.dart';
import '/widgets/dialogos.dart';
import '/widgets/tela_mensagem.dart';
import '/widgets/tile_cantico.dart';
import '/widgets/tile_culto.dart';

class TelaDetalhesEscala extends StatefulWidget {
  final String id;
  final DocumentSnapshot<Culto>? snapCulto;

  const TelaDetalhesEscala({Key? key, required this.id, this.snapCulto})
      : super(key: key);

  @override
  State<TelaDetalhesEscala> createState() => _TelaDetalhesEscalaState();
}

class _TelaDetalhesEscalaState extends State<TelaDetalhesEscala> {
  /* VARIÁVEIS */
  late Culto mCulto;
  late DocumentSnapshot<Culto> mSnapshot;
  Integrante? mLogado;

  /* GETTERS */
  bool get _ehODirigente =>
      mCulto.dirigente != null &&
      (mCulto.dirigente!.id == Global.logadoSnapshot?.id);
  bool get _ehOCoordenador =>
      mCulto.coordenador != null &&
      (mCulto.coordenador!.id == Global.logadoSnapshot?.id);

  /* SISTEMA */
  @override
  Widget build(BuildContext context) {
    return AuthGuardView(
      scaffoldView: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () async {
              if (!await Modular.to.maybePop()) {
                Modular.to.pushNamed(Global.rotaInicial);
              }
            },
          ),
          title: const Text('Escala'),
          actions: [_menuSuspenso],
        ),
        body: StreamBuilder<DocumentSnapshot<Culto>>(
            initialData: widget.snapCulto,
            stream: MeuFirebase.ouvinteCulto(id: widget.id),
            builder: (context, snapshot) {
              // Progresso
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // Erro
              if (snapshot.hasError || snapshot.data?.data() == null) {
                return const ViewFalha(
                    mensagem: 'Falha ao carregar dados do culto');
              }

              // Conteúdo
              mSnapshot = snapshot.data!;
              mCulto = mSnapshot.data()!;
              mLogado = Global.logadoSnapshot?.data();
              return _layout;
            }),
      ),
    );
  }

  /// LAYOUT DA TELA
  get _layout {
    return DefaultTabController(
      length: 2,
      child: OrientationBuilder(builder: (context, orientation) {
        // MODO RETRATO
        if (orientation == Orientation.portrait) {
          return Column(
            children: [
              _tileCulto,
              Expanded(
                child: NestedScrollView(
                    headerSliverBuilder:
                        (BuildContext context, bool innerBoxIsScrolled) {
                      return [
                        SliverOverlapAbsorber(
                          handle:
                              NestedScrollView.sliverOverlapAbsorberHandleFor(
                                  context),
                          sliver: SliverToBoxAdapter(
                            child: Material(
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _secaoEnsaio,
                                    _secaoLiturgia,
                                    if (mCulto.obs != null &&
                                        mCulto.obs!.isNotEmpty)
                                      _rowObservacoes,
                                  ]),
                            ),
                          ),
                        ),
                      ];
                    },
                    body: Column(
                      children: [
                        _tabBar,
                        Expanded(child: _tabView),
                      ],
                    )
                    //_tabView,
                    ),
              ),
              _rodape,
            ],
          );
        }

        // MODO PAISAGEM
        return LayoutBuilder(builder: (context, constraints) {
          return Wrap(children: [
            SizedBox(
              height: constraints.maxHeight,
              width: constraints.maxWidth * 0.4 - 1,
              child: Material(
                child: Column(
                  children: [
                    _tileCulto,
                    Expanded(
                      child: ListView(
                        children: [
                          _secaoEnsaio,
                          _secaoLiturgia,
                          if (mCulto.obs != null && mCulto.obs!.isNotEmpty)
                            _rowObservacoes,
                        ],
                      ),
                    ),
                    _rodape,
                  ],
                ),
              ),
            ),
            Container(
                height: constraints.maxHeight,
                width: 1,
                color: Colors.grey.withOpacity(0.38)),
            SizedBox(
                height: constraints.maxHeight,
                width: constraints.maxWidth * 0.6,
                child: Column(
                  children: [
                    _tabBar,
                    Expanded(child: _tabView),
                  ],
                )),
          ]);
        });
      }),
    );
  }

  /* WIDGETS */

  get _tileCulto {
    return Material(
      elevation: 4,
      child: TileCulto(
        culto: mCulto,
        reference: mSnapshot.reference,
        theme: Theme.of(context),
      ),
    );
  }

  get _tabBar {
    return Material(
      elevation: 4,
      child: TabBar(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          labelPadding: const EdgeInsets.symmetric(horizontal: 16),
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(40), // Creates border
            color: Theme.of(context).colorScheme.secondary,
          ),
          splashBorderRadius: BorderRadius.circular(40),
          splashFactory: NoSplash.splashFactory,
          overlayColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
              return states.contains(MaterialState.focused)
                  ? null
                  : Colors.transparent;
            },
          ),
          indicatorSize: TabBarIndicatorSize.label,
          automaticIndicatorColorAdjustment: false,
          indicatorPadding:
              const EdgeInsets.symmetric(horizontal: -16, vertical: 8),
          unselectedLabelColor: Theme.of(context).colorScheme.onBackground,
          tabs: const [
            Tab(text: 'ESCALADOS'),
            Tab(text: 'CÂNTICOS'),
          ]),
    );
  }

  get _tabView {
    return TabBarView(children: [
      _escalados,
      _canticos,
    ]);
  }

  get _escalados {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Escalados (Responsáveis)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dirigente
                Expanded(
                  child: _secaoResponsavel(
                    Funcao.dirigente,
                    mCulto.dirigente,
                    () => _escalarResponsavel(Funcao.dirigente),
                  ),
                ),
                const SizedBox(width: 24),
                // Coordenador
                Expanded(
                  child: _secaoResponsavel(
                    Funcao.coordenador,
                    mCulto.coordenador,
                    () => _escalarResponsavel(Funcao.coordenador),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Escalados (Equipe)
            _secaoEquipe(
              'Equipe',
              mCulto.equipe ?? {},
              constraints,
              () => _escalarIntegrante(mCulto.equipe),
            ),
          ],
        );
      },
    );
  }

  get _canticos {
    return Flex(
      direction: Axis.vertical,
      children: [
        (mLogado?.adm ?? false) || _ehODirigente || _ehOCoordenador
            ? Container(
                width: double.infinity,
                color: Colors.grey.withOpacity(0.05),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.queue_music),
                      label: const Text('Selecionar'),
                      onPressed: () => _adicionarCanticos(),
                    ),
                    Text(
                      'Segure e arraste para reordenar',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.caption,
                    ),
                  ],
                ),
              )
            : const SizedBox(),
        Flexible(
          child: _listaDeCanticos,
        ),
      ],
    );
  }

  /// Menu Suspenso
  get _menuSuspenso {
    const int editar = 0;
    const int verDisponiveis = 1;
    const int notificarEscalados = 2;

    return PopupMenuButton(
      tooltip: 'Menu',
      child: kIsWeb
          ? Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [const Text('Menu'), Icon(Icons.adaptive.more)],
              ),
            )
          : null,
      itemBuilder: (context) {
        List<PopupMenuEntry> opcoes = [];
        // Opção editar dados do culto
        if ((mLogado?.adm ?? false) ||
            (mLogado?.ehRecrutador ?? false) ||
            _ehODirigente ||
            _ehOCoordenador) {
          opcoes.add(const PopupMenuItem(
            value: editar,
            child: Text('Editar dados do culto'),
          ));
        }
        // Opção notificar escalados
        if (((mLogado?.adm ?? false) ||
                (mLogado?.ehRecrutador ?? false) ||
                _ehODirigente ||
                _ehOCoordenador) &&
            mCulto.equipe?.values != null &&
            mCulto.equipe!.values.any((element) => element.isNotEmpty)) {
          opcoes.add(const PopupMenuItem(
            value: notificarEscalados,
            child: Text('Notificar escalados'),
          ));
        }
        // Opção ver disponibilidade da equipe
        opcoes.add(const PopupMenuItem(
          value: verDisponiveis,
          child: Text('Ver disponibilidade da equipe'),
        ));
        return opcoes;
      },
      onSelected: (value) {
        switch (value) {
          case editar:
            Dialogos.editarCulto(context,
                culto: mCulto, reference: mSnapshot.reference);
            break;
          case verDisponiveis:
            _verificarDisponibilidades();
            break;
          case notificarEscalados:
            _notificarEscalados();
            break;
        }
      },
    );
  }

  /// Dados sobre data e hora do ensaio
  Widget get _secaoEnsaio {
    var dataFormatada = 'Solicite ao dirigente';
    if (mCulto.dataEnsaio != null) {
      dataFormatada = DateFormat("EEE, d/MM/yyyy 'às' HH:mm", 'pt_BR')
          .format(mCulto.dataEnsaio!.toDate());
    }
    return ListTile(
      dense: true,
      minLeadingWidth: 64,
      // Título
      leading: const Text('ENSAIO'),
      // Texto de apoio
      title: Text(
        dataFormatada,
        style: mCulto.dataEnsaio != null
            ? Theme.of(context)
                .textTheme
                .labelLarge!
                .copyWith(fontWeight: FontWeight.bold)
            : Theme.of(context).textTheme.bodySmall,
      ),
      // Botão de edição (somente para dirigentes e coordenadores)
      trailing: (mLogado?.adm ?? false) || _ehODirigente || _ehOCoordenador
          ? mCulto.dataEnsaio == null
              ? IconButton(
                  onPressed: () => _definirHoraDoEnsaio(),
                  icon: const Icon(Icons.more_time),
                )
              : IconButton(
                  onPressed: () =>
                      mSnapshot.reference.update({'dataEnsaio': null}),
                  icon: const Icon(Icons.clear),
                )
          : null,
    );
  }

  /// Dialog Data e Hora do Ensaio
  void _definirHoraDoEnsaio() {
    var dataPrevia = mCulto.dataEnsaio?.toDate() ?? mCulto.dataCulto.toDate();
    showDatePicker(
            context: context,
            initialDate: dataPrevia,
            firstDate: DateTime(dataPrevia.year - 1),
            lastDate: DateTime(dataPrevia.year + 1))
        .then((data) {
      if (data == null) return;
      showTimePicker(
              context: context, initialTime: TimeOfDay.fromDateTime(dataPrevia))
          .then((hora) {
        if (hora == null) return;
        var dataHora = Timestamp.fromDate(
            DateTime(data.year, data.month, data.day, hora.hour, hora.minute));
        mSnapshot.reference.update({'dataEnsaio': dataHora});
      });
    });
  }

  /// Acesso ao arquivo da liturgia do culto
  Widget get _secaoLiturgia {
    return ListTile(
      dense: true,
      minLeadingWidth: 64,
      // Título
      leading: const Text('LITURGIA'),
      // Texto de apoio
      title: mCulto.liturgia == null || mCulto.liturgia!.isEmpty
          ? Text(
              'Solicite ao liturgo',
              style: Theme.of(context).textTheme.bodySmall,
            )
          : OutlinedButton.icon(
              onPressed: _verLiturgia,
              style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact),
              icon: const Icon(Icons.subtitles),
              label: const Text('Abrir'),
            ),
      // Botão de edição (somente para dirigente, coordenadores ou liturgos)
      trailing: (mLogado?.adm ?? false) ||
              _ehODirigente ||
              _ehOCoordenador ||
              (mLogado?.ehLiturgo ?? false)
          ? IconButton(
              icon: const Icon(Icons.edit_note),
              onPressed: () async {
                Dialogos.editarLiturgia(context,
                    reference: mSnapshot.reference,
                    texto: mCulto.liturgia ?? '');
              },
            )
          : null,
    );
  }

  void _verLiturgia() {
    rich.QuillController controller;
    // Tratamento para texto vazio ou fora dos parâmetros JSON
    try {
      final doc = rich.Document.fromJson(jsonDecode(mCulto.liturgia!));
      controller = rich.QuillController(
          document: doc, selection: const TextSelection.collapsed(offset: 0));
    } catch (error) {
      final doc = rich.Document()
        ..insert(0, 'Falha ao ler o texto. Solicite alteração ao liturgo.');
      controller = rich.QuillController(
          document: doc, selection: const TextSelection.collapsed(offset: 0));
    }
    Mensagem.bottomDialog(
      context: context,
      titulo: 'Liturgia do culto',
      conteudo: SingleChildScrollView(
        padding:
            const EdgeInsets.only(top: 16, bottom: 32, left: 16, right: 16),
        child: rich.QuillEditor.basic(
          controller: controller,
          readOnly: true,
        ),
      ),
    );
  }

  /// Seção observações
  /// (só deve aparece se houver alguma)
  Widget get _rowObservacoes {
    return ListTile(
      dense: true,
      minLeadingWidth: 64,
      shape: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.26)),
      ),
      leading: const Text('ATENÇÃO'),
      title: Text(
        mCulto.obs ?? '',
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  /// Rodapé
  ///
  /// Exibe analise da equipe e botão para abrir ou fechar a escala
  Widget get _rodape {
    return Material(
      elevation: 0,
      child: Container(
        color: Colors.grey.withOpacity(0.38),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: FutureBuilder<QuerySnapshot<Instrumento>>(
                  future: MeuFirebase.obterListaInstrumentos(ativo: true),
                  builder: (context, snapshot) {
                    String resultado;
                    if (mCulto.equipe == null ||
                        mCulto.equipe!.isEmpty ||
                        !mCulto.equipe!.values
                            .any((element) => element.isNotEmpty)) {
                      resultado = 'Escalar equipe!';
                    } else if (!snapshot.hasData) {
                      resultado = 'Analisando equipe...';
                    } else if (snapshot.hasError) {
                      resultado = 'Falha ao analisar equipe!';
                    } else {
                      resultado = _analisarEquipe(snapshot.data);
                    }
                    return Text(resultado,
                        style: Theme.of(context).textTheme.caption);
                  }),
            ),
            (mLogado?.adm ?? false) || (mLogado?.ehRecrutador ?? false)
                ? mCulto.emEdicao
                    ? ElevatedButton.icon(
                        icon: const Icon(Icons.lock_outline),
                        label: const Text('FECHAR'),
                        style: ElevatedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            primary: Theme.of(context).colorScheme.secondary),
                        onPressed: () {
                          mSnapshot.reference.update({'emEdicao': false});
                        },
                      )
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.hail),
                        label: const Text('RECRUTAR'),
                        style: ElevatedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            primary: Theme.of(context).colorScheme.primary),
                        onPressed: () {
                          mSnapshot.reference.update({'emEdicao': true});
                        },
                      )
                : const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  /// Verifica se há o mínimo de instrumentos para compor a equipe
  String _analisarEquipe(QuerySnapshot<Instrumento>? mInstrumentos) {
    // Precisa de instrumentos cadastrados na base de dados
    if (mInstrumentos == null) {
      return 'Sem instrumentos cadastrados na base de dados';
    }

    // Lista de instrumentos com integrantes escalados
    List<String> instrumentosEscalados = mCulto.equipe?.keys.toList() ?? [];

    // Lista de instrumentos faltantes
    Map<String, int> faltantes = {};

    // No mínimo 1 dirigente
    if (mCulto.dirigente == null) {
      faltantes.putIfAbsent(funcaoGetString(Funcao.dirigente), () => 1);
    }

    // Analise dos mínimos para cada instrumento conforme regra da base de dados
    for (var instrumentoSnap in mInstrumentos.docs) {
      int minimo = instrumentoSnap.data().composMin;
      int qtdEscalados = 0;
      for (var instrumento in instrumentosEscalados) {
        if (instrumento == instrumentoSnap.id) {
          qtdEscalados += mCulto.equipe?[instrumento]?.length ?? 0;
        }
      }
      if (qtdEscalados < minimo) {
        faltantes.putIfAbsent(
            instrumentoSnap.data().nome, () => minimo - qtdEscalados);
      }
    }

    // Resultado 1: Faltam instrumentos
    if (faltantes.isNotEmpty) {
      var resultado = 'Precisamos de: ';
      for (var falta in faltantes.entries) {
        resultado += '${falta.value} ${falta.key}; ';
      }
      resultado = '${resultado.substring(0, resultado.length - 2)}.';
      return resultado;
    }

    // Resultado 2: Equipe mínima completa
    return 'Equipe mínima completa!';
  }

  /// Seção responsável
  Widget _secaoResponsavel(
    Funcao funcao,
    DocumentReference<Integrante>? integranteRef,
    Function()? funcaoEditar,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icone
            SizedBox.square(
              dimension: ButtonTheme.of(context).height,
              child: Icon(funcaoGetIcon(funcao), size: 20),
            ),
            // Título
            Expanded(
              child: Text(
                funcaoGetString(funcao).toUpperCase(),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Botão de edição (somente para recrutadores)
            ((mLogado?.adm ?? false) || (mLogado?.ehRecrutador ?? false)) &&
                    mCulto.emEdicao
                ? IconButton(
                    onPressed: funcaoEditar,
                    icon: const Icon(
                      Icons.playlist_add_circle,
                      color: Colors.grey,
                    ),
                  )
                : SizedBox.square(dimension: ButtonTheme.of(context).height),
          ],
        ),
        // Responsável
        integranteRef == null
            ? const ListTile(
                subtitle: Text(
                  '♫',
                  textAlign: TextAlign.center,
                ),
              )
            : CardIntegranteResponsavel(integranteRef: integranteRef)
      ],
    );
  }

  /// Seção equipe escalada
  Widget _secaoEquipe(
    String titulo,
    Map<String?, List<DocumentReference<Integrante>?>?> dados,
    BoxConstraints constraints,
    Function()? funcaoEditar,
  ) {
    final int colunas = (constraints.maxWidth / 192).floor();
    final double cardWidth =
        (constraints.maxWidth - (colunas * 8 + 24)) / colunas;

    return Column(
        //mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Row(children: [
            // Icone
            SizedBox.square(
              dimension: ButtonTheme.of(context).height,
              child: Icon(funcaoGetIcon(Funcao.membro), size: 20),
            ),
            // Título
            Expanded(
              child: Text(
                titulo.toUpperCase(),
                textAlign: TextAlign.center,
              ),
            ),
            // Botão de edição
            ((mLogado?.adm ?? false) || (mLogado?.ehRecrutador ?? false)) &&
                    mCulto.emEdicao
                ? IconButton(
                    onPressed: funcaoEditar,
                    icon: const Icon(
                      Icons.playlist_add_circle,
                      color: Colors.grey,
                    ),
                  )
                : SizedBox.square(dimension: ButtonTheme.of(context).height),
          ]),
          // Integrantes
          FutureBuilder<QuerySnapshot<Instrumento>>(
              future: MeuFirebase.obterListaInstrumentos(ativo: true),
              builder: (context, snapshot) {
                // Em caso de falha
                if (snapshot.hasError) {
                  return const SizedBox(
                    height: 256,
                    child:
                        ViewFalha(mensagem: 'Falha ao carregar instrumentos'),
                  );
                }

                // Retorno principal
                List<Widget> escalados = [];
                if (snapshot.hasData) {
                  var instrumentos = snapshot.data!.docs;
                  // Montar cards dos escalados
                  for (var instrumento in instrumentos) {
                    var instrumentoId = instrumento.id;
                    if (dados.containsKey(instrumentoId)) {
                      for (var integranteRef in dados[instrumentoId]!) {
                        if (integranteRef != null) {
                          var widget = SizedBox(
                              width: cardWidth,
                              child: CardIntegranteInstrumento(
                                  integranteRef: integranteRef,
                                  instrumento: instrumento.data()));
                          escalados.add(widget);
                        }
                      }
                    }
                  }
                  // Interface vazia
                  if (escalados.isEmpty) {
                    return const SizedBox(
                      height: 256,
                      child: TelaMensagem('Ninguém escalado'),
                    );
                  }
                  // Interface com equipe
                  else {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: escalados,
                    );
                  }
                }

                // Carregamento
                return Container(
                  alignment: Alignment.center,
                  height: 256,
                  padding: const EdgeInsets.all(16),
                  child: const CircularProgressIndicator(),
                );
              }),
        ]);
  }

  Widget get _listaDeCanticos {
    if (mCulto.canticos == null || mCulto.canticos!.isEmpty) {
      return const TelaMensagem(
        'Nenhum cântico selecionado',
        icone: Icons.queue_music,
      );
    }

    // Em listas reordenáveis todos os itens devem possuir uma chave
    List<Widget> lista = List.generate(mCulto.canticos!.length, (index) {
      var doc = mCulto.canticos![index];
      return StreamBuilder<DocumentSnapshot<Cantico>?>(
          key: Key('Future${doc.id}'),
          stream: MeuFirebase.ouvinteCantico(id: doc.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return ListTile(
                  subtitle: Text('Carregando cântico ${index + 1}...'));
            }
            if (snapshot.hasError || snapshot.data?.data() == null) {
              return ListTile(
                title: const Text('Falha ao carregar cântico!'),
                subtitle: Text('ID:  ${snapshot.data?.id ?? '[nulo]'}'),
              );
            }
            return TileCantico(
              snapshot: snapshot.data!,
              selecionado: null,
              reordenavel: true,
            );
          });
    });

    return ReorderableListView(
      buildDefaultDragHandles: _ehODirigente || (mLogado?.adm ?? false),
      onReorder: (int old, int current) async {
        dev.log('${old.toString()} | ${current.toString()}');
        // dragging from top to bottom
        Widget startItem = lista[old];
        var startCantico = mCulto.canticos![old];
        if (old < current) {
          for (int i = old; i < current - 1; i++) {
            lista[i] = lista[i + 1];
            mCulto.canticos![i] = mCulto.canticos![i + 1];
          }
          lista[current - 1] = startItem;
          mCulto.canticos![current - 1] = startCantico;
        }
        // dragging from bottom to top
        else if (old > current) {
          for (int i = old; i > current; i--) {
            lista[i] = lista[i - 1];
            mCulto.canticos![i] = mCulto.canticos![i - 1];
          }
          lista[current] = startItem;
          mCulto.canticos![current] = startCantico;
        }
        mSnapshot.reference.update({'canticos': mCulto.canticos});
      },
      children: lista,
    );
  }

  /* FUNÇÕES */

  void _escalarIntegrante(
      Map<String, List<DocumentReference<Integrante>>>?
          instrumentosIntegrantes) {
    Mensagem.bottomDialog(
      context: context,
      leading: Icon(funcaoGetIcon(Funcao.membro)),
      titulo: 'Selecionar ${funcaoGetString(Funcao.membro).toLowerCase()}',
      // Busca por instrumentos ativos
      conteudo: FutureBuilder<QuerySnapshot<Instrumento>>(
          future: MeuFirebase.obterListaInstrumentos(ativo: true),
          builder: (_, snapInstr) {
            // Aguardando
            if (!snapInstr.hasData) {
              return const SizedBox(
                  height: 128,
                  child: Center(child: CircularProgressIndicator()));
            }
            // Colhendo instrumentos
            var instrumentos = snapInstr.data?.docs;
            // Busca por integrantes ativos na função componente da equipe
            return FutureBuilder<QuerySnapshot<Integrante>>(
                future: MeuFirebase.obterListaIntegrantes(
                    funcao: Funcao.membro.index),
                builder: (context, snapIntegrantes) {
                  // Aguardando
                  if (!snapIntegrantes.hasData ||
                      snapIntegrantes.connectionState ==
                          ConnectionState.waiting) {
                    return const SizedBox(
                        height: 128,
                        child: Center(child: CircularProgressIndicator()));
                  }
                  if (snapIntegrantes.hasError) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Falha ao buscar integrantes!'),
                    );
                  }
                  if (snapIntegrantes.data?.docs.isEmpty ?? true) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Nenhum integrante disponível'),
                    );
                  }
                  // Colhendo integrantes
                  List<QueryDocumentSnapshot<Integrante>>? integrantes =
                      snapIntegrantes.data?.docs;
                  // Builder da lista
                  return StatefulBuilder(builder: (context, innerState) {
                    // Lista resultados por instrumento
                    return ListView(
                      shrinkWrap: true,
                      children:
                          List.generate(instrumentos?.length ?? 0, (index) {
                        var instrumento = instrumentos![index].data();
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          child: Row(children: [
                            // Instrumento
                            LayoutBuilder(builder: (context, constraints) {
                              return SizedBox(
                                width: 80,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Image.asset(
                                      instrumento.iconAsset,
                                      width: 20,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onBackground,
                                      colorBlendMode: BlendMode.srcATop,
                                    ),
                                    Text(
                                      instrumento.nome,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(width: 12),
                            // Integrantes
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _integrantesDisponiveisNoInstrumento(
                                    integrantes,
                                    instrumentos[index],
                                    instrumentos,
                                    innerState),
                              ),
                            ),
                          ]),
                        );
                      }).toList(),
                    );
                  });
                });
          }),
    );
  }

  List<Widget> _integrantesDisponiveisNoInstrumento(
    List<QueryDocumentSnapshot<Integrante>>? integrantes,
    QueryDocumentSnapshot<Instrumento> instrumentoRef,
    List<QueryDocumentSnapshot<Instrumento>>? listaInstrumentos,
    Function innerSetState,
  ) {
    // Ninguém disponível para nenhum instrumento
    if (integrantes == null || integrantes.isEmpty) {
      return const [Text('Ninguém disponível no momento!')];
    }
    try {
      List<QueryDocumentSnapshot<Integrante>> integrantesDoInstrumento = [];
      for (var integrante in integrantes) {
        var instrumentosDoIntegrante = integrante.data().instrumentos;
        if (instrumentosDoIntegrante != null) {
          // dev.log('Verificando integrante: ${integrante.data().nome}');
          if (instrumentosDoIntegrante
              .map((e) => e.toString())
              .contains(instrumentoRef.reference.toString())) {
            // dev.log('Integrante toca o instrumento');
            if (mCulto.disponiveis!
                .map((e) => e.toString())
                .contains(integrante.reference.toString())) {
              // dev.log('Integrante está disponivel');
              integrantesDoInstrumento.add(integrante);
            }
          }
        }
      }
      // Ninguém disponível no instrumento
      if (integrantesDoInstrumento.isEmpty) {
        return const [Text('Ninguém disponivel!')];
      }
      dev.log(
          'integrantesDoInstrumento ${instrumentoRef.data().nome} : ${integrantesDoInstrumento.length}');
      // Lista de integrantes disponíveis
      return List.generate(integrantesDoInstrumento.length, (index) {
        bool loading = false;
        return StatefulBuilder(builder: (context, setState) {
          var integranteRef =
              integrantesDoInstrumento[index].reference.toString();
          var nomeSplit =
              integrantesDoInstrumento[index].data().nome.split(' ');
          dev.log(nomeSplit.toSet().toString());
          var nomeCurto = '${nomeSplit.first} ${nomeSplit.last[0]}.';
          // Verifica se integrante está recrutado para o instrumento
          bool selected = mCulto.equipe?[instrumentoRef.reference.id]
                  ?.map((e) => e.toString())
                  .contains(integranteRef) ??
              false;
          // Verifica se integrante está recrutado em outro instrumento para habilitar seleção
          bool disable = false;

          // Se o instrumento permite outros recrutamentos, então ignorar
          if (instrumentoRef.data().permiteOutro) {
            disable = false;
          }
          // Varre a equipe para desabilitar o botão caso integrante já esteja recrutado
          else if (mCulto.equipe != null && mCulto.equipe!.isNotEmpty) {
            for (var entry in mCulto.equipe!.entries) {
              Instrumento? instrumento = listaInstrumentos
                  ?.where((element) => element.id == entry.key)
                  .first
                  .data();
              if (instrumento != null) {
                // Se instrumento não permite outro recrutamento
                if (!instrumento.permiteOutro) {
                  // Verifica se o integrante já está escalado
                  if (entry.value
                      .map((e) => e.toString())
                      .contains(integranteRef)) {
                    disable = true;
                  }
                }
              }
            }
          }
          // Por fim, desabilitar se excede a quantidade de recrutados no instrumento
          if (mCulto.equipe?[instrumentoRef.id] != null &&
              mCulto.equipe![instrumentoRef.id]!.length >=
                  instrumentoRef.data().composMax) {
            disable = true;
          }
          // CHIP
          return ChoiceChip(
            avatar: loading
                ? const Padding(
                    padding: EdgeInsets.all(4),
                    child: CircularProgressIndicator(
                        strokeWidth: 1, color: Colors.white))
                : null,
            label: Text(nomeCurto),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            selected: selected,
            selectedColor: Theme.of(context).colorScheme.primary,
            disabledColor: Colors.grey.withOpacity(0.05),
            onSelected: !selected && disable
                ? null
                : (value) async {
                    setState(() => loading = true);
                    if (value) {
                      await mSnapshot.reference.update({
                        'equipe.${instrumentoRef.reference.id}':
                            FieldValue.arrayUnion(
                                [integrantesDoInstrumento[index].reference])
                      });
                    } else {
                      await mSnapshot.reference.update({
                        'equipe.${instrumentoRef.reference.id}':
                            FieldValue.arrayRemove(
                                [integrantesDoInstrumento[index].reference])
                      });
                    }
                    Future.delayed(const Duration(milliseconds: 50), () {
                      innerSetState(() {});
                    });
                    //setState(() => loading = false);
                  },
          );
        });
      }).toList();
    } catch (e) {
      return const [Text('Falha na aquisição dos dados!')];
    }
  }

  void _escalarResponsavel(Funcao funcao) {
    showDialog(
        context: context,
        builder: (context) {
          // Buscar integrantes ativos que possuem determinada função
          return FutureBuilder<QuerySnapshot<Integrante>>(
              future: MeuFirebase.obterListaIntegrantes(funcao: funcao.index),
              builder: (context, snap) {
                // Construtor Stateful
                return StatefulBuilder(builder: (context, innerState) {
                  // Identifica o integrante selecionado (se houver)
                  String? selecionado = funcao == Funcao.dirigente
                      ? mCulto.dirigente.toString()
                      : mCulto.coordenador.toString();
                  // Monta a lista de integrantes disponiveis
                  List<QueryDocumentSnapshot<Integrante>> disponiveis = [];
                  if (snap.hasData) {
                    for (var integrante in snap.data!.docs) {
                      if (mCulto.disponiveis != null &&
                          mCulto.disponiveis!
                              .map((e) => e.toString())
                              .contains(integrante.reference.toString())) {
                        disponiveis.add(integrante);
                      }
                    }
                  }
                  // Builder do dialog
                  return SimpleDialog(
                    title: Text(
                        'Selecionar ${funcaoGetString(funcao).toLowerCase()}'),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      // Com resultados
                      snap.connectionState == ConnectionState.waiting
                          ? const Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 24, horizontal: 12),
                              child: Text('Verificando integrantes...'),
                            )
                          : snap.hasError
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 24, horizontal: 12),
                                  child: Text('Falha ao buscar integrantes!'),
                                )
                              : disponiveis.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 24, horizontal: 12),
                                      child:
                                          Text('Nenhum integrante disponível!'),
                                    )
                                  : Wrap(
                                      spacing: 8,
                                      children: List.generate(
                                          disponiveis.length, (index) {
                                        var integrante = disponiveis[index];
                                        return ChoiceChip(
                                            selected: selecionado ==
                                                integrante.reference.toString(),
                                            selectedColor: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            onSelected: (value) async {
                                              if (value) {
                                                await mSnapshot.reference
                                                    .update({
                                                  funcao.name:
                                                      integrante.reference
                                                });
                                              } else {
                                                await mSnapshot.reference
                                                    .update(
                                                        {funcao.name: null});
                                              }
                                              Modular.to
                                                  .pop(); // fecha o dialog
                                            },
                                            label: Text(integrante
                                                .data()
                                                .nome
                                                .split(' ')
                                                .first));
                                      }).toList(),
                                    ),
                    ],
                  );
                });
              });
        });
  }

  void _adicionarCanticos() {
    Mensagem.bottomDialog(
      context: context,
      titulo: 'Cânticos do culto',
      conteudo: PaginaCanticos(culto: mSnapshot),
    );
  }

  void _verificarDisponibilidades() {
    Mensagem.bottomDialog(
        context: context,
        titulo: 'Disponibilidade dos integrantes',
        conteudo: FutureBuilder<QuerySnapshot<Integrante>>(
            future: MeuFirebase.obterListaIntegrantes(igreja: mCulto.igreja),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }
              Map<String, String> disponiveis = {};
              Map<String, String> restritos = {};
              Map<String, String> indecisos = {};
              for (var integrante in snapshot.data!.docs) {
                if (integrante.data().ehDirigente ||
                    integrante.data().ehCoordenador ||
                    integrante.data().ehComponente) {
                  if (mCulto.disponiveis
                          ?.map((e) => e.toString())
                          .contains(integrante.reference.toString()) ??
                      false) {
                    disponiveis.putIfAbsent(
                        integrante.id, () => integrante.data().nome);
                  } else if (mCulto.restritos
                          ?.map((e) => e.toString())
                          .contains(integrante.reference.toString()) ??
                      false) {
                    restritos.putIfAbsent(
                        integrante.id, () => integrante.data().nome);
                  }
                }
              }

              for (var integrante in snapshot.data!.docs) {
                if (integrante.data().ehDirigente ||
                    integrante.data().ehCoordenador ||
                    integrante.data().ehComponente) {
                  if (integrante
                          .data()
                          .igrejas
                          ?.map((e) => e.toString())
                          .contains(mCulto.igreja.toString()) ??
                      false) {
                    if (!disponiveis.containsKey(integrante.id) &&
                        !restritos.containsKey(integrante.id)) {
                      indecisos.putIfAbsent(
                          integrante.id, () => integrante.data().nome);
                    }
                  }
                }
              }

              return ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shrinkWrap: true,
                children: [
                  Text(
                    'Disponíveis',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 8,
                    children: List.generate(
                        disponiveis.values.length,
                        (index) => Text(
                            '${index + 1}. ${disponiveis.values.elementAt(index)}')),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Restritos',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 8,
                    children: List.generate(
                        restritos.values.length,
                        (index) => Text(
                            '${index + 1}. ${restritos.values.elementAt(index)}')),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Indecisos',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 8,
                    children: List.generate(
                        indecisos.values.length,
                        (index) => Text(
                            '${index + 1}. ${indecisos.values.elementAt(index)}')),
                  ),
                  (mLogado?.adm ?? false) || (mLogado?.ehRecrutador ?? false)
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: ElevatedButton.icon(
                            onPressed: indecisos.isEmpty
                                ? null
                                : () async {
                                    Mensagem.aguardar(context: context);
                                    var avisados = [];
                                    // Avisar dirigente
                                    for (var id in indecisos.keys) {
                                      if (!avisados.contains(id)) {
                                        var token = await MeuFirebase
                                            .obterTokenDoIntegrante(id);
                                        if (token != null) {
                                          MeuFirebase.notificarIndeciso(
                                              token: token,
                                              igreja: Global.igrejaSelecionada
                                                      .value?.id ??
                                                  '',
                                              culto: mCulto,
                                              cultoId: mSnapshot.id);
                                          dev.log('Integrante $id avisado!');
                                        }
                                      }
                                      avisados.add(id);
                                    }
                                    Modular.to.pop();
                                    Mensagem.simples(
                                        context: context,
                                        titulo: 'Sucesso!',
                                        mensagem:
                                            'Todos os integrantes indecisos foram notificados.');
                                  },
                            icon: const Icon(Icons.notification_important),
                            label: const Text('Notificar indecisos'),
                          ),
                        )
                      : const SizedBox(height: 12),
                ],
              );
            }));
  }

  void _notificarEscalados() async {
    Mensagem.decisao(
        context: context,
        titulo: 'Confirme',
        mensagem:
            'Deseja notificar todos os usuários escalados sobre esse culto?',
        onPressed: (ok) async {
          if (ok) {
            // abre progresso
            Mensagem.aguardar(context: context);
            var avisados = [];
            // Avisar dirigente
            if (mCulto.dirigente?.id != null) {
              var token = await MeuFirebase.obterTokenDoIntegrante(
                  mCulto.dirigente!.id);
              if (token != null) {
                await MeuFirebase.notificarEscalado(
                    token: token,
                    igreja: Global.igrejaSelecionada.value?.id ?? '',
                    culto: mCulto,
                    cultoId: mSnapshot.id);
                dev.log('Dirigente avisado!');
              }
              avisados.add(mCulto.dirigente!.id);
            }
            // Avisar coordenador técnico
            if (mCulto.coordenador?.id != null &&
                mCulto.coordenador?.id != mCulto.dirigente?.id) {
              var token = await MeuFirebase.obterTokenDoIntegrante(
                  mCulto.coordenador!.id);
              if (token != null) {
                await MeuFirebase.notificarEscalado(
                    token: token,
                    igreja: Global.igrejaSelecionada.value?.id ?? '',
                    culto: mCulto,
                    cultoId: mSnapshot.id);
                dev.log('Coordenador avisado!');
              }
              avisados.add(mCulto.coordenador!.id);
            }
            // Avisar equipe
            for (var instrumento in mCulto.equipe!.values.toList()) {
              for (var integrante in instrumento) {
                if (!avisados.contains(integrante.id)) {
                  var token =
                      await MeuFirebase.obterTokenDoIntegrante(integrante.id);
                  if (token != null) {
                    await MeuFirebase.notificarEscalado(
                        token: token,
                        igreja: Global.igrejaSelecionada.value?.id ?? '',
                        culto: mCulto,
                        cultoId: mSnapshot.id);
                    dev.log('Integrante ${integrante.id} avisado!');
                  }
                }
                avisados.add(integrante.id);
              }
            }
            Modular.to.pop(); // fecha progresso
            Mensagem.simples(
                context: context,
                titulo: 'Sucesso!',
                mensagem: 'Todos os integrantes escalados foram notificados.');
          }
        });
  }
}
