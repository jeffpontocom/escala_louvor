import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '/functions/metodos_firebase.dart';
import '/global.dart';
import '/models/cantico.dart';
import '/models/culto.dart';
import '/models/instrumento.dart';
import '/models/integrante.dart';
import '/screens/pages/home_canticos.dart';
import '/screens/views/dialogos.dart';
import '/utils/mensagens.dart';
import '/utils/utils.dart';

class ViewCulto extends StatefulWidget {
  const ViewCulto({Key? key, required this.culto}) : super(key: key);
  final DocumentReference<Culto> culto;

  @override
  State<ViewCulto> createState() => _ViewCultoState();
}

class _ViewCultoState extends State<ViewCulto> {
  /* VARIÁVEIS */
  late Culto mCulto;
  late DocumentSnapshot<Culto> mSnapshot;
  late Integrante logado;

  bool get _podeSerEscalado {
    return logado.ehDirigente || logado.ehCoordenador || logado.ehComponente;
  }

  bool get ehODirigente {
    if (mCulto.dirigente == null) {
      return false;
    }
    return (mCulto.dirigente?.id == Global.integranteLogado?.id);
  }

  bool get ehOCoordenador {
    if (mCulto.coordenador == null) {
      return false;
    }
    return (mCulto.coordenador?.id == Global.integranteLogado?.id);
  }

  /* SISTEMA */
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Culto>>(
        stream: widget.culto.snapshots(),
        builder: ((context, snapshot) {
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
          mCulto = snapshot.data!.data()!;
          mSnapshot = snapshot.data!;
          logado = Global.integranteLogado!.data()!;
          dev.log(
              'Building view: Culto ${DateFormat.MEd('pt_BR').format(mCulto.dataCulto.toDate())}');
          return Column(
            children: [
              // Cabeçalho
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Dados sobre o culto
                    Expanded(child: _cultoData),
                    // Botão de disponibilidade
                    _podeSerEscalado
                        ? _buttonDisponibilidade
                        : const SizedBox(),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.grey),
              // Corpo
              Expanded(
                child: Material(
                  child: ListView(
                    children: [
                      // Dados sobre o ensaio
                      _secaoEnsaio,
                      // Dados sobre a liturgia
                      _secaoLiturgia,
                      // Observações
                      mCulto.obs == null || mCulto.obs!.isEmpty
                          ? const SizedBox()
                          : _rowObservacoes,
                      // Informação sobre a composição da equipe
                      _secaoOqueFalta,
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
                      const Divider(),
                      // Canticos
                      _secaoCanticos,
                      _listaDeCanticos,
                      const Divider(height: 24),
                      // Botões de ação
                      _secaoAcoes,
                      const SizedBox(height: 24),
                      // Fim da tela
                    ],
                  ),
                ),
              ),
            ],
          );
        }));
  }

  /* WIDGETS */

  /// Informações sobre a data do culto
  Widget get _cultoData {
    DateTime data = mCulto.dataCulto.toDate();
    var diaSemana = DateFormat(DateFormat.WEEKDAY, 'pt_BR').format(data);
    var diaMes = DateFormat(DateFormat.ABBR_MONTH_DAY, 'pt_BR').format(data);
    var hora = DateFormat(DateFormat.HOUR24_MINUTE, 'pt_BR').format(data);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ícone dia/noite
        Icon(
          data.hour >= 6 && data.hour < 18 ? Icons.sunny : Icons.dark_mode,
          size: 20,
        ),
        const VerticalDivider(width: 8),
        // Informações
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ocasião
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text((mCulto.ocasiao ?? '').toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall),
            ),
            // Dia da Semana
            Text(diaSemana, style: Theme.of(context).textTheme.labelMedium),
            // Data e Hora abreviados
            Text(diaMes + ' | ' + hora,
                style: Theme.of(context).textTheme.headline5),
          ],
        ),
      ],
    );
  }

  /// Botão disponibilidade
  Widget get _buttonDisponibilidade {
    bool alterar = false;
    return StatefulBuilder(builder: (context, setState) {
      bool escalado =
          mCulto.usuarioEscalado(Global.integranteLogado?.reference);
      bool disponivel =
          mCulto.usuarioDisponivel(Global.integranteLogado?.reference);
      bool restrito =
          mCulto.usuarioRestrito(Global.integranteLogado?.reference);
      return OutlinedButton(
        onPressed: escalado || restrito
            ? () {}
            : () async {
                setState(() {
                  alterar = true;
                });
                await MeuFirebase.definirDisponibilidadeParaOCulto(
                    widget.culto);
                setState(() {
                  alterar = false;
                });
              },
        onLongPress: escalado || disponivel
            ? () {}
            : () async {
                setState(() {
                  alterar = true;
                });
                await MeuFirebase.definirRestricaoParaOCulto(widget.culto);
                setState(() {
                  alterar = false;
                });
              },
        child: Wrap(
          direction: Axis.vertical,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            alterar
                ? const Center(
                    child: SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(),
                    ),
                  )
                : const Icon(Icons.emoji_people),
            Text(escalado
                ? 'Estou escalado!'
                : disponivel
                    ? 'Estou disponível!'
                    : restrito
                        ? 'Estou restrito!'
                        : 'Estou disponível?'),
          ],
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(128, 56),
          maximumSize: const Size.fromWidth(128),
          padding: const EdgeInsets.all(12),
          backgroundColor: escalado
              ? Colors.green
              : disponivel
                  ? Colors.blue
                  : restrito
                      ? Colors.red
                      : null,
          primary: escalado || disponivel || restrito
              ? Colors.white
              : Colors.grey.withOpacity(0.5),
        ),
      );
    });
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
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.26)),
      ),
      leading: const Text('ENSAIO'),
      title: Text(
        dataFormatada,
        style: Theme.of(context)
            .textTheme
            .labelLarge!
            .copyWith(fontWeight: FontWeight.bold),
      ),
      trailing: logado.adm || ehODirigente || ehOCoordenador
          ? mCulto.dataEnsaio == null
              ? IconButton(
                  onPressed: () => _definirHoraDoEnsaio(),
                  icon: const Icon(Icons.more_time),
                )
              : IconButton(
                  onPressed: () => widget.culto.update({'dataEnsaio': null}),
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
        MeuFirebase.definirDataHoraDoEnsaio(widget.culto, dataHora);
      });
    });
  }

  /// Acesso ao arquivo da liturgia do culto
  Widget get _secaoLiturgia {
    return ListTile(
      dense: true,
      minLeadingWidth: 64,
      shape: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.26)),
      ),
      leading: const Text('LITURGIA'),
      title: mCulto.liturgiaUrl == null
          ? Text(
              'Nenhum arquivo carregado',
              style: Theme.of(context).textTheme.caption,
            )
          : Text(
              'Abrir documento',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
      trailing: logado.adm || ehODirigente || ehOCoordenador || logado.ehLiturgo
          ? mCulto.liturgiaUrl == null
              ? IconButton(
                  onPressed: () async {
                    String? url = await MeuFirebase.carregarArquivoPdf(context,
                        pasta: 'liturgias');
                    if (url != null && url.isNotEmpty) {
                      widget.culto.update({'liturgiaUrl': url}).then(
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
                  onPressed: () => widget.culto.update({'liturgiaUrl': null}),
                  icon: const Icon(Icons.clear),
                )
          : null,
      onTap: mCulto.liturgiaUrl == null
          ? null
          : () => MeuFirebase.abrirArquivosPdf(context, [mCulto.liturgiaUrl!]),
    );
  }

  /// Seção o que falta
  Widget get _secaoOqueFalta {
    return FutureBuilder<QuerySnapshot<Instrumento>>(
        future: MeuFirebase.obterListaInstrumentos(ativo: true),
        builder: (context, snapshot) {
          String resultado;
          if (!snapshot.hasData) {
            resultado = 'Analisando equipe...';
          }
          if (snapshot.hasError) {
            resultado = 'Falha ao analisar equipe!';
          } else {
            resultado = _verificaEquipe(snapshot.data);
          }
          return ListTile(
            dense: true,
            tileColor: Colors.orange.withOpacity(0.15),
            shape: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.26)),
            ),
            title: Text(
              resultado,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        });
  }

  /// Verifica se há o mínimo de instrumentos para compor a equipe
  String _verificaEquipe(QuerySnapshot<Instrumento>? mInstrumentos) {
    if (mInstrumentos == null) {
      return 'Sem instrumentos cadastrados';
    }
    if (mCulto.equipe == null || mCulto.equipe!.isEmpty) {
      return 'Escalar equipe!';
    }
    List<String> instrumentosEscalados = mCulto.equipe?.keys.toList() ?? [];
    Map<String, int> faltantes = {};
    // No mínimo 1 dirigente
    if (mCulto.dirigente == null) {
      faltantes.putIfAbsent(funcaoGetString(Funcao.dirigente), () => 1);
    }
    // Analise dos mínimos para cada instrumento
    for (var instrumentoSnap in mInstrumentos.docs) {
      int minimo = instrumentoSnap.data().composMin;
      int escalados = 0;
      for (var instrumento in instrumentosEscalados) {
        if (instrumento == instrumentoSnap.id) {
          escalados += mCulto.equipe?[instrumento]?.length ?? 0;
        }
      }
      if (escalados < minimo) {
        faltantes.putIfAbsent(
            instrumentoSnap.data().nome, () => minimo - escalados);
      }
    }

    // Regras
    if (faltantes.isNotEmpty) {
      var resultado = 'Precisamos de: ';
      for (var falta in faltantes.entries) {
        resultado += '${falta.value} ${falta.key}; ';
      }
      resultado = resultado.substring(0, resultado.length - 2) + '.';
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              // Botão de edição
              logado.adm || logado.ehRecrutador
                  ? IconButton(
                      onPressed: funcaoEditar,
                      icon: const Icon(
                        Icons.edit_note,
                        color: Colors.grey,
                        size: 16,
                      ),
                    )
                  : SizedBox(height: ButtonTheme.of(context).height),
            ],
          ),
          // Responsável
          integrante == null
              ? const SizedBox()
              : _cardIntegranteResponsavel(integrante)
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
    List<Widget> escalados = [];
    for (var entrada in dados.entries) {
      var instrumentoId = entrada.key;
      var integrantes = entrada.value;
      if (integrantes != null && integrantes.isNotEmpty) {
        for (var integrante in integrantes) {
          escalados.add(_cardIntegranteInstrumento(integrante, instrumentoId));
        }
      }
      // TODO: Ordenar escalados conforme ordem dos instrumento
      //escalados.sort();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icone
              Icon(funcaoGetIcon(Funcao.membro), size: 20),
              const SizedBox(width: 4),
              // Título
              Text(titulo.toUpperCase()),
              // Botão de edição
              logado.adm || logado.ehRecrutador
                  ? IconButton(
                      onPressed: funcaoEditar,
                      icon: const Icon(
                        Icons.edit_note,
                        color: Colors.grey,
                        size: 16,
                      ),
                    )
                  : SizedBox(height: ButtonTheme.of(context).height),
            ],
          ),
          // Integrantes
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: escalados,
          ),
        ],
      ),
    );
  }

  Widget _cardIntegranteResponsavel(
      DocumentReference<Integrante> refIntegrante) {
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
              : nomePrimeiro + ' ' + nomeSegundo;
          return InkWell(
            onTap: () => Modular.to.pushNamed('/perfil?id=${integrante?.id}'),
            child: Container(
              width: 128,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(
                  width: 1,
                  color: Colors.grey.withOpacity(0.5),
                ),
                borderRadius: BorderRadius.circular(12),
                color: (Global.integranteLogado != null &&
                        integrante?.id == Global.integranteLogado?.id)
                    ? Colors.orange.withOpacity(0.25)
                    : null,
              ),
              // Pilha
              child: Column(
                children: [
                  // Foto do integrante
                  CircleAvatar(
                    child: const Icon(
                      Icons.person,
                      color: Colors.grey,
                    ),
                    foregroundImage: MyNetwork.getImageFromUrl(
                            integrante?.data()?.fotoUrl,
                            progressoSize: 16)
                        ?.image,
                    backgroundColor: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
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
                ],
              ),
            ),
          );
        });
  }

  Widget _cardIntegranteInstrumento(
      DocumentReference<Integrante>? refIntegrante, String? instrumentoId) {
    return FutureBuilder<DocumentSnapshot<Integrante>>(
        future: refIntegrante?.get(),
        builder: (_, snapIntegrante) {
          if (!snapIntegrante.hasData) return const SizedBox();
          var integrante = snapIntegrante.data;
          var nomeIntegrante = integrante?.data()?.nome ?? '[Sem nome]';
          var nomePrimeiro = nomeIntegrante.split(' ').first;
          var nomeSegundo = nomeIntegrante.split(' ').last;
          nomeIntegrante = nomePrimeiro == nomeSegundo
              ? nomePrimeiro
              : nomePrimeiro + ' ' + nomeSegundo;
          return FutureBuilder<DocumentSnapshot<Instrumento>>(
              future: instrumentoId == null || instrumentoId.isEmpty
                  ? null
                  : FirebaseFirestore.instance
                      .collection(Instrumento.collection)
                      .doc(instrumentoId)
                      .withConverter<Instrumento>(
                        fromFirestore: (snapshot, _) =>
                            Instrumento.fromJson(snapshot.data()!),
                        toFirestore: (model, _) => model.toJson(),
                      )
                      .get(),
              builder: (_, instr) {
                Instrumento? instrumento;
                if (!instr.hasError) {
                  instrumento = instr.data?.data();
                }
                // Box
                return InkWell(
                  onTap: () =>
                      Modular.to.pushNamed('/perfil?id=${integrante?.id}'),
                  child: Container(
                    width: 172, //TODO: Definir largura por tamanho da tela
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 1,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: (Global.integranteLogado != null &&
                              integrante?.id == Global.integranteLogado?.id)
                          ? Colors.orange.withOpacity(0.25)
                          : null,
                    ),
                    // Pilha
                    child: Stack(
                      alignment: Alignment.topLeft,
                      children: [
                        Row(
                          children: [
                            // Foto do integrante
                            const SizedBox(width: 12),
                            CircleAvatar(
                              child: const Icon(
                                Icons.person,
                                color: Colors.grey,
                              ),
                              foregroundImage: MyNetwork.getImageFromUrl(
                                      integrante?.data()?.fotoUrl,
                                      progressoSize: 16)
                                  ?.image,
                              backgroundColor: Colors.grey.withOpacity(0.5),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Nome do integrante
                                  Text(
                                    nomeIntegrante,
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
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                        // Imagem do instrumento
                        CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.75),
                          radius: 10,
                          child: Image.asset(
                            instrumento?.iconAsset ??
                                'assets/icons/ic_launcher.png',
                            width: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              });
        });
  }

  /// Acesso ao arquivo da liturgia do culto
  Widget get _secaoCanticos {
    return ListTile(
      dense: true,
      minLeadingWidth: 64,
      leading: const Text('CÂNTICOS'),
      /* title: TextButton.icon(
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text('Todas as cifras'),
                                onPressed: mCulto.canticos == null ||
                                        mCulto.canticos!.isEmpty
                                    ? null
                                    : () async {
                                        Mensagem.aguardar(context: context);
                                        List<String> canticosUrls = [];
                                        for (var cantico in mCulto.canticos!) {
                                          var snap = await MeuFirebase
                                              .obterSnapshotCantico(cantico.id);
                                          if (snap?.data()?.cifraUrl != null) {
                                            canticosUrls
                                                .add(snap!.data()!.cifraUrl!);
                                          }
                                        }
                                        Modular.to.pop();
                                        MeuFirebase.abrirArquivosPdf(
                                            context, canticosUrls);
                                      },
                              ), */
      subtitle: logado.adm || ehODirigente
          ? Padding(
              padding: EdgeInsets.zero,
              child: Text(
                'Segure e arraste para reordenar (somente dirigente)',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          : null,
      trailing: logado.adm || ehODirigente
          ? IconButton(
              onPressed: () => _adicionarCanticos(),
              icon: const Icon(Icons.edit_note),
            )
          : null,
    );
  }

  Widget get _listaDeCanticos {
    List<Widget> _list = [];
    if (mCulto.canticos == null || mCulto.canticos!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Nenhum cântico selecionado'),
      );
    }
    _list = List.generate(mCulto.canticos!.length, (index) {
      return FutureBuilder<DocumentSnapshot<Cantico>?>(
          key: Key('Future${mCulto.canticos![index]}'),
          future: MeuFirebase.obterSnapshotCantico(mCulto.canticos![index].id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Text('Carregando lista...');
            }
            if (snapshot.hasError) {
              return const Text('Falha ao carregar dados do cântico');
            }
            return ListTile(
              visualDensity: VisualDensity.compact,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: IconButton(
                  onPressed: () {
                    Dialogos.verLetraDoCantico(context, snapshot.data!.data()!);
                  },
                  icon: const Icon(Icons.abc)),
              horizontalTitleGap: 8,
              title: Text(
                snapshot.data?.data()?.nome ?? '...',
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                snapshot.data?.data()?.autor ?? '',
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cifra
                  IconButton(
                      onPressed: snapshot.data?.data()?.cifraUrl == null
                          ? null
                          : () {
                              MeuFirebase.abrirArquivosPdf(
                                  context, [snapshot.data!.data()!.cifraUrl!]);
                            },
                      icon: const Icon(Icons.queue_music)),
                  // YouTube
                  IconButton(
                      onPressed: () async {
                        if (!await launch(
                            snapshot.data?.data()?.youTubeUrl ?? '')) {
                          throw 'Could not launch youTubeUrl';
                        }
                      },
                      icon: const Icon(Icons.ondemand_video)),
                  const SizedBox(width: kIsWeb ? 24 : 0),
                ],
              ),
            );
          });
    });
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: _list,
      buildDefaultDragHandles: ehODirigente || logado.adm,
      onReorder: (int old, int current) async {
        dev.log('${old.toString()} | ${current.toString()}');
        // dragging from top to bottom
        Widget startItem = _list[old];
        var startCantico = mCulto.canticos![old];
        if (old < current) {
          for (int i = old; i < current - 1; i++) {
            _list[i] = _list[i + 1];
            mCulto.canticos![i] = mCulto.canticos![i + 1];
          }
          _list[current - 1] = startItem;
          mCulto.canticos![current - 1] = startCantico;
        }
        // dragging from bottom to top
        else if (old > current) {
          for (int i = old; i > current; i--) {
            _list[i] = _list[i - 1];
            mCulto.canticos![i] = mCulto.canticos![i - 1];
          }
          _list[current] = startItem;
          mCulto.canticos![current] = startCantico;
        }
        widget.culto.update({'canticos': mCulto.canticos});
      },
    );
  }

  Widget get _secaoAcoes {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          const Text('AÇÕES'),
          const SizedBox(height: 8),
          // Verificar disponibilidade da equipe
          TextButton.icon(
            onPressed: () => _verificarDisponibilidades(),
            label: const Text('Verificar disponibilidades da equipe'),
            icon: const Icon(Icons.groups),
          ),
          // Enviar notificação aos escalados
          logado.adm || logado.ehRecrutador || ehODirigente || ehOCoordenador
              ? TextButton.icon(
                  onPressed: null,
                  /* onPressed: () async {
                    Mensagem.aguardar(context: context); // abre progresso
                    Notificacoes.instancia.enviarMensagemPush();
                    Modular.to.pop(); // fecha progresso
                  }, */
                  label: const Text('Notificar escalados'),
                  icon: const Icon(Icons.notifications),
                )
              : const SizedBox(),
          // Editar evento
          logado.adm || logado.ehRecrutador || ehODirigente || ehOCoordenador
              ? TextButton.icon(
                  onPressed: () => Dialogos.editarCulto(context, mCulto,
                      reference: widget.culto),
                  label: const Text('Editar dados do evento'),
                  icon: const Icon(Icons.edit_calendar),
                )
              : const SizedBox(),
        ],
      ),
    );
  }

  /* FUNÇÕES */

  void _escalarIntegrante(
      Map<String, List<DocumentReference<Integrante>>>?
          instrumentosIntegrantes) {
    Mensagem.bottomDialog(
      context: context,
      icon: funcaoGetIcon(Funcao.membro),
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
                  if (snapIntegrantes.connectionState ==
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
                  if (!snapIntegrantes.hasData ||
                      (snapIntegrantes.data?.docs.isEmpty ?? true)) {
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
                                spacing: 4,
                                runSpacing: 4,
                                children: _integrantesDisponiveisNoInstrumento(
                                    integrantes, instrumentos[index]),
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
      QueryDocumentSnapshot<Instrumento> instrumentoRef) {
    //dev.log('Instrumento: ${instrumentoRef.data().nome}');
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
      return List.generate(integrantesDoInstrumento.length, (index) {
        bool loading = false;
        return StatefulBuilder(builder: (context, setState) {
          bool selected = mCulto.equipe?[instrumentoRef.reference.id]
                  ?.map((e) => e.toString())
                  .contains(
                      integrantesDoInstrumento[index].reference.toString()) ??
              false;
          var nomeSplit =
              integrantesDoInstrumento[index].data().nome.split(' ');
          var nomeCurto = '${nomeSplit.first} ${nomeSplit.last[0]}.';
          return ChoiceChip(
            avatar: loading
                ? const CircularProgressIndicator(strokeWidth: 1)
                : null,
            label: Text(nomeCurto),
            selected: selected,
            selectedColor: Theme.of(context).colorScheme.primary,
            onSelected:
                // TODO: Verificar se integrante está em outro instrumento para habilitar seleção
                (value) async {
              setState((() => loading = true));
              if (value) {
                await widget.culto.update({
                  'equipe.${instrumentoRef.reference.id}':
                      FieldValue.arrayUnion(
                          [integrantesDoInstrumento[index].reference])
                });
              } else {
                await widget.culto.update({
                  'equipe.${instrumentoRef.reference.id}':
                      FieldValue.arrayRemove(
                          [integrantesDoInstrumento[index].reference])
                });
              }
              setState(() => loading = false);
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
                      if (mCulto.disponiveis!
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
                                                await widget.culto.update({
                                                  funcao.name:
                                                      integrante.reference
                                                });
                                              } else {
                                                await widget.culto.update(
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
      icon: Icons.music_note,
      conteudo: TelaCanticos(culto: mSnapshot),
    );
  }

  void _verificarDisponibilidades() {
    Mensagem.bottomDialog(
        context: context,
        titulo: 'Disponibilidades dos integrantes',
        conteudo: FutureBuilder<QuerySnapshot<Integrante>>(
            future: MeuFirebase.obterListaIntegrantes(ativo: true),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }
              List<String> disponiveis = [];
              for (var integrante in snapshot.data!.docs) {
                if (integrante.data().ehDirigente ||
                    integrante.data().ehCoordenador ||
                    integrante.data().ehComponente) {
                  if (mCulto.disponiveis
                          ?.map((e) => e.toString())
                          .contains(integrante.reference.toString()) ??
                      false) {
                    disponiveis.add(integrante.data().nome);
                  }
                }
              }

              List<String> restritos = [];
              for (var integrante in snapshot.data!.docs) {
                if (integrante.data().ehDirigente ||
                    integrante.data().ehCoordenador ||
                    integrante.data().ehComponente) {
                  if (mCulto.restritos
                          ?.map((e) => e.toString())
                          .contains(integrante.reference.toString()) ??
                      false) {
                    restritos.add(integrante.data().nome);
                  }
                }
              }

              List indecisos = [];
              for (var integrante in snapshot.data!.docs) {
                if (integrante.data().ehDirigente ||
                    integrante.data().ehCoordenador ||
                    integrante.data().ehComponente) {
                  indecisos.add(integrante.data().nome);
                }
              }
              indecisos.removeWhere((element) => disponiveis.contains(element));
              indecisos.removeWhere((element) => restritos.contains(element));

              return ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                shrinkWrap: true,
                children: [
                  Text(
                    'Disponíveis',
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                  Wrap(
                    spacing: 8,
                    children: List.generate(disponiveis.length,
                        (index) => Text('${index + 1}. ${disponiveis[index]}')),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Restritos',
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                  Wrap(
                    spacing: 8,
                    children: List.generate(restritos.length,
                        (index) => Text('${index + 1}. ${restritos[index]}')),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Indecisos',
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                  Wrap(
                    spacing: 8,
                    children: List.generate(indecisos.length,
                        (index) => Text('${index + 1}. ${indecisos[index]}')),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.notification_important),
                    label: const Text('Notificar indecisos'),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            }));
  }
}
