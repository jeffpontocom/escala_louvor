import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/widgets/tela_mensagem.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';

import '/rotas.dart';
import '/functions/metodos_firebase.dart';
import '/models/cantico.dart';
import '/models/culto.dart';
import '/models/instrumento.dart';
import '/models/integrante.dart';
import '/resources/animations/shimmer.dart';
import '/screens/home/pagina_canticos.dart';
import '/screens/home/tela_home.dart';
import '/utils/global.dart';
import '/utils/mensagens.dart';
import '/widgets/avatar.dart';
import '/widgets/dialogos.dart';
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
  Integrante? mLogado = Global.logado;

  bool get _ehODirigente {
    if (mCulto.dirigente == null) {
      return false;
    }
    return (mCulto.dirigente?.id == Global.logadoSnapshot?.id);
  }

  bool get _ehOCoordenador {
    if (mCulto.coordenador == null) {
      return false;
    }
    return (mCulto.coordenador?.id == Global.logadoSnapshot?.id);
  }

  /* SISTEMA */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // TODO: Copiar esse backbutton para todas as telas secundárias
        leading: BackButton(
          onPressed: () async {
            if (!await Modular.to.maybePop()) {
              Modular.to.pushNamed(AppRotas.HOME);
            }
          },
        ),
        title: const Text('Escala'),
        actions: [_menuSuspenso],
      ),
      body: StreamBuilder<DocumentSnapshot<Culto>>(
          initialData: widget.snapCulto,
          stream: MeuFirebase.obterStreamCulto(widget.id),
          builder: (context, snapshot) {
            // Progresso
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            // Erro
            if (snapshot.hasError || snapshot.data?.data() == null) {
              return const Center(
                  child: Text('Falha ao carregar dados do culto.'));
            }
            // Conteúdo
            mSnapshot = snapshot.data!;
            mCulto = mSnapshot.data()!;
            return _layout;
          }),
    );
  }

  /// LAYOUT DA TELA
  get _layout {
    return OrientationBuilder(builder: (context, orientation) {
      // MODO RETRATO
      if (orientation == Orientation.portrait) {
        return Column(
          children: [
            // Cabeçalho
            _tileCulto,
            const Divider(height: 1, color: Colors.grey),
            // Corpo
            _secaoEnsaio,
            _secaoLiturgia,
            // Observações (só aparece se houver alguma)
            mCulto.obs == null || mCulto.obs!.isEmpty
                ? const SizedBox()
                : _rowObservacoes,
            Expanded(child: _tabs),
            _secaoOqueFalta,
          ],
        );
      }
      // MODO PAISAGEM
      return LayoutBuilder(builder: (context, constraints) {
        return Wrap(children: [
          SizedBox(
            height: constraints.maxHeight,
            width: constraints.maxWidth * 0.4 - 1,
            child: Column(
              children: [
                _tileCulto,
                const Divider(height: 1),
                _secaoEnsaio,
                _secaoLiturgia,
                // Observações (só aparece se houver alguma)
                mCulto.obs == null || mCulto.obs!.isEmpty
                    ? const SizedBox()
                    : _rowObservacoes,
                const Expanded(child: SizedBox()),
                _secaoOqueFalta,
              ],
            ),
          ),
          Container(
              height: constraints.maxHeight, width: 1, color: Colors.grey),
          SizedBox(
              height: constraints.maxHeight,
              width: constraints.maxWidth * 0.6,
              child: Expanded(child: _tabs)),
        ]);
      });
    });
  }

  /* WIDGETS */

  get _tileCulto {
    return TileCulto(
      culto: mCulto,
      reference: mSnapshot.reference,
      theme: Theme.of(context),
    );
  }

  get _tabs {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
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
          const Divider(height: 1),
          Expanded(
            child: TabBarView(children: [
              // ESCALADOS
              ListView(
                shrinkWrap: true,
                children: [
                  // Escalados (Responsáveis)
                  Flex(
                    direction: Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dirigente
                      Flexible(
                        child: _secaoResponsavel(
                          Funcao.dirigente,
                          mCulto.dirigente,
                          () => _escalarResponsavel(Funcao.dirigente),
                        ),
                      ),
                      // Coordenador
                      Flexible(
                        child: _secaoResponsavel(
                          Funcao.coordenador,
                          mCulto.coordenador,
                          () => _escalarResponsavel(Funcao.coordenador),
                        ),
                      ),
                    ],
                  ),
                  // Escalados (Equipe)
                  _secaoEquipe(
                    'Equipe',
                    mCulto.equipe ?? {},
                    () => _escalarIntegrante(mCulto.equipe),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
              // CÂNTICOS
              _listaDeCanticos,
            ]),
          ),
        ],
      ),
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
    var dataFormatada = 'Sem horário definido';
    if (mCulto.dataEnsaio != null) {
      dataFormatada = DateFormat("EEE, d/MM/yyyy 'às' HH:mm", 'pt_BR')
          .format(mCulto.dataEnsaio!.toDate());
    }
    return ListTile(
      dense: true,
      minLeadingWidth: 64,
      shape: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.26))),
      // Título
      leading: const Text('ENSAIO'),
      // Texto de apoio
      title: Text(
        dataFormatada,
        style: Theme.of(context)
            .textTheme
            .labelLarge!
            .copyWith(fontWeight: FontWeight.bold),
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
        MeuFirebase.definirDataHoraDoEnsaio(mSnapshot.reference, dataHora);
      });
    });
  }

  /// Acesso ao arquivo da liturgia do culto
  Widget get _secaoLiturgia {
    return ListTile(
      dense: true,
      minLeadingWidth: 64,
      shape: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.26))),
      // Título
      leading: const Text('LITURGIA'),
      // Texto de apoio
      title: mCulto.liturgiaUrl == null
          ? Text(
              'Nenhum arquivo carregado',
              style: Theme.of(context).textTheme.bodySmall,
            )
          : Text(
              'Abrir documento',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
      // Botão de edição (somente para dirigente, coordenadores ou liturgos)
      trailing: (mLogado?.adm ?? false) ||
              _ehODirigente ||
              _ehOCoordenador ||
              (mLogado?.ehLiturgo ?? false)
          ? mCulto.liturgiaUrl == null
              ? IconButton(
                  onPressed: () async {
                    String? url = await MeuFirebase.carregarArquivoPdf(context,
                        pasta: 'liturgias');
                    if (url != null && url.isNotEmpty) {
                      mSnapshot.reference.update({'liturgiaUrl': url}).then(
                          (value) => null, onError: (_) {
                        Mensagem.simples(
                            context: context,
                            mensagem: 'Falha ao atualizar o campo');
                      });
                    }
                  },
                  icon: const Icon(Icons.upload_file),
                )
              : IconButton(
                  onPressed: () =>
                      mSnapshot.reference.update({'liturgiaUrl': null}),
                  icon: const Icon(Icons.clear),
                )
          : null,
      // Ação de toque
      onTap: mCulto.liturgiaUrl == null
          ? null
          : () => Modular.to.pushNamed(AppRotas.ARQUIVOS,
              arguments: [mCulto.liturgiaUrl!, 'Liturgia']),

      /* MeuFirebase.abrirArquivosPdf(context, [mCulto.liturgiaUrl!]), */
    );
  }

  /// Seção observações
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

  /// Seção o que falta
  Widget get _secaoOqueFalta {
    return Container(
      color: Theme.of(context).colorScheme.secondary.withOpacity(0.15),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: FutureBuilder<QuerySnapshot<Instrumento>>(
                future: MeuFirebase.obterListaInstrumentos(ativo: true),
                builder: (context, snapshot) {
                  String resultado = 'Analisando equipe...';
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
                    resultado = _verificaEquipe(snapshot.data);
                  }
                  return Text(resultado,
                      style: Theme.of(context).textTheme.bodySmall);
                }),
          ),
          (mLogado?.adm ?? false) || (mLogado?.ehRecrutador ?? false)
              ? mCulto.emEdicao
                  ? OutlinedButton.icon(
                      onPressed: () {
                        mSnapshot.reference.update({'emEdicao': false});
                      },
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('FECHAR'),
                    )
                  : OutlinedButton.icon(
                      onPressed: () {
                        mSnapshot.reference.update({'emEdicao': true});
                      },
                      icon: const Icon(Icons.lock_open),
                      label: const Text('RECRUTAR'),
                    )
              : const SizedBox(),
        ],
      ),
    );
  }

  /// Verifica se há o mínimo de instrumentos para compor a equipe
  String _verificaEquipe(QuerySnapshot<Instrumento>? mInstrumentos) {
    if (mInstrumentos == null) {
      return 'Sem instrumentos cadastrados na base de dados';
    }
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
    // Resultado
    if (faltantes.isNotEmpty) {
      var resultado = 'Precisamos de: ';
      for (var falta in faltantes.entries) {
        resultado += '${falta.value} ${falta.key}; ';
      }
      resultado = '${resultado.substring(0, resultado.length - 2)}.';
      return resultado;
    }
    return 'Equipe mínima completa!';
  }

  /// Seção escalados
  Widget _secaoResponsavel(
    Funcao funcao,
    DocumentReference<Integrante>? integrante,
    Function()? funcaoEditar,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icone
              Icon(funcaoGetIcon(funcao), size: 20),
              const SizedBox(width: 4),
              // Título
              Flexible(
                child: Text(
                  funcaoGetString(funcao).toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Botão de edição (somente para recrutadores)
              (mLogado?.adm ?? false) || (mLogado?.ehRecrutador ?? false)
                  ? IconButton(
                      onPressed: funcaoEditar,
                      icon: const Icon(Icons.edit_note,
                          color: Colors.grey, size: 16),
                    )
                  : SizedBox(height: ButtonTheme.of(context).height),
            ],
          ),
          // Responsável
          integrante == null
              ? const SizedBox()
              : _cardIntegranteResponsavel(integrante, funcao.name)
        ],
      ),
    );
  }

  /// Seção escalados
  Widget _secaoEquipe(
    String titulo,
    Map<String?, List<DocumentReference<Integrante>?>?> dados,
    Function()? funcaoEditar,
  ) {
    return FutureBuilder<QuerySnapshot<Instrumento>>(
        future: MeuFirebase.obterListaInstrumentos(ativo: true),
        builder: (context, snapshot) {
          List<Widget> escalados = [];
          if (snapshot.hasData && !snapshot.hasError) {
            var instrumentos = snapshot.data!.docs;
            var i = 0;
            for (var instrumento in instrumentos) {
              var instrumentoId = instrumento.id;
              if (dados.containsKey(instrumentoId)) {
                for (var integranteRef in dados[instrumentoId]!) {
                  escalados.add(_cardIntegranteInstrumento(integranteRef,
                      instrumentoId, '${i++}_${integranteRef!.id}'));
                }
              }
            }
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho
                  Row(children: [
                    // Icone
                    Icon(funcaoGetIcon(Funcao.membro), size: 20),
                    const SizedBox(width: 4),
                    // Título
                    Text(titulo.toUpperCase()),
                    // Botão de edição
                    (mLogado?.adm ?? false) || (mLogado?.ehRecrutador ?? false)
                        ? IconButton(
                            onPressed: funcaoEditar,
                            icon: const Icon(Icons.edit_note,
                                color: Colors.grey, size: 16),
                          )
                        : SizedBox(height: ButtonTheme.of(context).height),
                  ]),
                  // Integrantes
                  Wrap(spacing: 8, runSpacing: 8, children: escalados),
                ]),
          );
        });
  }

  Widget _cardIntegranteResponsavel(
      DocumentReference<Integrante> refIntegrante, String hero) {
    return FutureBuilder<DocumentSnapshot<Integrante>>(
        future: refIntegrante.get(),
        builder: (_, snapIntegrante) {
          if (!snapIntegrante.hasData) return const SizedBox();
          var integrante = snapIntegrante.data;
          var nomeIntegrante = integrante?.data()?.nome ?? '[Sem nome]';
          var nomePrimeiro = nomeIntegrante.split(' ').first;
          var nomeSegundo = nomeIntegrante.split(' ').last;
          nomeIntegrante = nomePrimeiro == nomeSegundo
              ? nomePrimeiro
              : '$nomePrimeiro $nomeSegundo';
          return InkWell(
            onTap: () => Modular.to.pushNamed(
                '${AppRotas.PERFIL}?id=${integrante?.id}&hero=$hero',
                arguments: integrante),
            child: Container(
              width: 128,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  width: 1,
                  color: Colors.grey.withOpacity(0.5),
                ),
                borderRadius: BorderRadius.circular(12),
                color: (Global.logadoSnapshot != null &&
                        integrante?.id == Global.logadoSnapshot?.id)
                    ? Theme.of(context).colorScheme.secondary.withOpacity(0.25)
                    : null,
              ),
              // Pilha
              child: Column(children: [
                // Foto do integrante
                Hero(
                  tag: hero,
                  child: CachedAvatar(
                    nome: integrante?.data()?.nome,
                    url: integrante?.data()?.fotoUrl,
                    maxRadius: 24,
                  ),
                ),
                const SizedBox(height: 8),
                // Nome do integrante
                Center(
                  child: Text(
                    nomeIntegrante,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ]),
            ),
          );
        });
  }

  Widget _cardIntegranteInstrumento(
      DocumentReference<Integrante>? refIntegrante,
      String? instrumentoId,
      String hero) {
    return FutureBuilder<DocumentSnapshot<Integrante>>(
        future: refIntegrante?.get(),
        builder: (_, snapIntegrante) {
          // Recolhe dados do integrante
          if (!snapIntegrante.hasData) {
            // TODO: Tile de carregamento
            return const SizedBox();
          }
          var integrante = snapIntegrante.data;
          var nome = integrante?.data()?.nome ?? '';
          var nomePrimeiro = nome.split(' ').first;
          var nomeUltimo = nome.split(' ').last;
          nome = nomePrimeiro == nomeUltimo
              ? nomePrimeiro
              : '$nomePrimeiro $nomeUltimo';
          // Recolhe dados do instrumento
          return FutureBuilder<DocumentSnapshot<Instrumento>?>(
              future: instrumentoId == null || instrumentoId.isEmpty
                  ? null
                  : MeuFirebase.obterSnapshotInstrumento(instrumentoId),
              builder: (_, instr) {
                Instrumento? instrumento;
                if (!instr.hasError) {
                  instrumento = instr.data?.data();
                }
                // Box
                return InkWell(
                  onTap: () => Modular.to.pushNamed(
                      '${AppRotas.PERFIL}?id=${integrante?.id}&hero=$hero',
                      arguments: integrante),
                  child: Container(
                    // Tamanho
                    width: 172,
                    height: kToolbarHeight,
                    // Margens
                    padding: const EdgeInsets.all(4),
                    alignment: Alignment.centerLeft,
                    // Bordas
                    decoration: BoxDecoration(
                      border: Border.all(
                          width: 1, color: Colors.grey.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(12),
                      color: (Global.logadoSnapshot != null &&
                              integrante?.id == Global.logadoSnapshot?.id)
                          ? Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.25)
                          : null,
                    ),
                    // Pilha
                    child: Stack(alignment: Alignment.topLeft, children: [
                      Row(
                        children: [
                          // Espaço para icone do instrumento
                          const SizedBox(width: 12),
                          // Foto do integrante
                          Hero(
                            tag: hero,
                            child: CachedAvatar(
                              nome: integrante?.data()?.nome,
                              url: integrante?.data()?.fotoUrl,
                              maxRadius: 24,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nome do integrante
                                Text(
                                  nome,
                                  maxLines: 1,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(
                                        fontWeight: FontWeight.bold,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                ),
                                // Instrumento para o qual está escalado
                                Text(
                                  instrumento?.nome ?? '',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Icone do instrumento
                      instrumento?.iconAsset == null
                          ? const SizedBox()
                          : CircleAvatar(
                              backgroundColor: Colors.white.withOpacity(0.75),
                              radius: 10,
                              child: Image.asset(instrumento!.iconAsset,
                                  width: 16),
                            ),
                    ]),
                  ),
                );
              });
        });
  }

  /// Acesso ao arquivo da liturgia do culto
  Widget get _secaoCanticos {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Segure e arraste para reordenar',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _adicionarCanticos(),
            icon: const Icon(Icons.edit_note),
            label: const Text('Editar lista'),
          )
        ],
      ),
    );
  }

  Widget get _listaDeCanticos {
    List<Widget> lista = [];
    if (mCulto.canticos == null || mCulto.canticos!.isEmpty) {
      return const TelaMensagem(
        'Nenhum cântico selecionado',
        icone: Icons.queue_music,
      );
    }
    lista = List.generate(mCulto.canticos!.length, (index) {
      return FutureBuilder<DocumentSnapshot<Cantico>?>(
          key: Key('Future${mCulto.canticos![index]}'),
          future: MeuFirebase.obterSnapshotCantico(mCulto.canticos![index].id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return ListTile(
                title: Shimmer.fromColors(
                  baseColor: Colors.grey.withOpacity(0.38),
                  highlightColor: Colors.grey.withOpacity(0.12),
                  child: const Text('          '),
                ),
                subtitle: Shimmer.fromColors(
                  baseColor: Colors.grey.withOpacity(0.38),
                  highlightColor: Colors.grey.withOpacity(0.12),
                  child: const Text('          '),
                ),
                trailing: Shimmer.fromColors(
                  baseColor: Colors.grey.withOpacity(0.38),
                  highlightColor: Colors.grey.withOpacity(0.12),
                  child: const CircleAvatar(radius: 12),
                ),
              );
            }
            if (snapshot.hasError || snapshot.data?.data() == null) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                    'Falha ao carregar dados do cântico\nID:  ${snapshot.data?.id ?? '[nulo]'}'),
              );
            }
            return TileCantico(
              snapshot: snapshot.data!,
              selecionado: null,
              reordenavel: true,
            );
          });
    });
    return ListView(shrinkWrap: true, children: [
      (mLogado?.adm ?? false) || _ehODirigente
          ? _secaoCanticos
          : const SizedBox(),
      Expanded(
        child: ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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
        ),
      ),
    ]);
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
                    ativo: true, funcao: Funcao.membro.index),
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
                ? const CircularProgressIndicator(strokeWidth: 1)
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
              future: MeuFirebase.obterListaIntegrantes(
                  ativo: true, funcao: funcao.index),
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
        titulo: 'Disponibilidades dos integrantes',
        conteudo: FutureBuilder<QuerySnapshot<Integrante>>(
            future: MeuFirebase.obterListaIntegrantes(
                ativo: true, igreja: mCulto.igreja),
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
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: indecisos.isEmpty
                        ? null
                        : () async {
                            Mensagem.aguardar(context: context);
                            var avisados = [];
                            // Avisar dirigente
                            for (var id in indecisos.keys) {
                              if (!avisados.contains(id)) {
                                var token =
                                    await MeuFirebase.obterTokenDoIntegrante(
                                        id);
                                if (token != null) {
                                  MeuFirebase.notificarIndecisos(
                                      token: token,
                                      igreja:
                                          Global.igrejaSelecionada.value?.id ??
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
                  const SizedBox(height: 24),
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
