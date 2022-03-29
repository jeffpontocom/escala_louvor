import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';

import '/functions/metodos.dart';
import '/functions/notificacoes.dart';
import '/global.dart';
import '/models/culto.dart';
import '/models/instrumento.dart';
import '/models/integrante.dart';
import '/utils/mensagens.dart';
import '/utils/utils.dart';

class ViewCulto extends StatefulWidget {
  const ViewCulto({Key? key, required this.culto}) : super(key: key);
  final DocumentReference<Culto> culto;

  @override
  State<ViewCulto> createState() => _ViewCultoState();
}

class _ViewCultoState extends State<ViewCulto> {
  /* SISTEMA */
  late Culto mCulto;

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
          if (snapshot.hasError) {
            return const Center(
                child: Text('Falha ao carregar dados do culto.'));
          }
          // Conteúdo
          mCulto = snapshot.data!.data()!;
          return Column(
            children: [
              // Cabeçalho
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    // Dados sobre o culto
                    Expanded(child: _cultoData),
                    // Botão de disponibilidade
                    _buttonDisponibilidade,
                  ],
                ),
              ),
              const Divider(height: 1),
              // Corpo
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // Dados sobre o ensaio
                    _rowEnsaio,
                    const Divider(height: 1),
                    // Dados sobre a liturgia
                    _rowLiturgia,
                    const Divider(height: 1),
                    // Informação sobre a composição da equipe
                    _rowOqueFalta,
                    const Divider(height: 1),
                    // Escalados (Coordenação)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Dirigente
                        _sectionResponsaveis(
                          'Dirigente',
                          Funcao.dirigente,
                          mCulto.dirigente,
                          () => _escalarDirigente(),
                        ),
                        // Coordenador
                        _sectionResponsaveis(
                          'Coord. técnico',
                          Funcao.coordenador,
                          mCulto.coordenador,
                          () => _escalarCoordenador(),
                        ),
                      ],
                    ),
                    // Escalados (Equipe)
                    _sectionEscalados(
                      'Equipe',
                      Funcao.integrante,
                      mCulto.equipe ?? {},
                      () => _escalarIntegrante(Funcao.dirigente, mCulto.equipe),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Cânticos',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(),
                    // Observações
                    _observacoes,
                    // Botões de ação do administrador
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            onPressed: null,
                            label: const Text('Alterar dados do culto'),
                            icon: const Icon(Icons.edit_calendar),
                          ),
                          ElevatedButton.icon(
                            onPressed: null,
                            label: const Text('Ver indecisos'),
                            icon: const Icon(Icons.device_unknown),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              Mensagem.aguardar(
                                  context: context); // abre progresso
                              Notificacoes.instancia.enviarMensagemPush();
                              Modular.to.pop(); // fecha progresso
                            },
                            label: const Text('Notificar escalados'),
                            icon: const Icon(Icons.notifications),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    // Fim da tela
                  ],
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
      bool escalado = _usuarioEscalado;
      bool disponivel = _usuarioDisponivel;
      bool restrito = _usuarioRestrito;
      dev.log('Estou escalado: $escalado | Estou disponível: $disponivel');
      return OutlinedButton(
        onPressed: escalado || restrito
            ? () {}
            : () async {
                setState(() {
                  alterar = true;
                });
                await Metodo.definirDisponibilidadeParaOCulto(widget.culto);
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
                await Metodo.definirRestricaoParaOCulto(widget.culto);
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
          minimumSize: const Size(136, 56),
          maximumSize: const Size.fromWidth(136),
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

  /// Dados sobre data e hora do ensaio
  Widget get _rowEnsaio {
    var dataFormatada = 'Sem horário definido';
    if (mCulto.dataEnsaio != null) {
      dataFormatada = DateFormat("EEE, d/MM/yyyy 'às' HH:mm", 'pt_BR')
          .format(mCulto.dataEnsaio!.toDate());
    }
    return Row(
      children: [
        const SizedBox(width: 12),
        const SizedBox(width: 80, child: Text('ENSAIO')),
        // Informação
        Expanded(
            child: Text(
          dataFormatada,
          style: Theme.of(context)
              .textTheme
              .labelLarge!
              .copyWith(fontWeight: FontWeight.bold),
        )),
        const SizedBox(width: 8),
        // Botão de ação para dirigentes
        IconButton(
          onPressed: () => _definirHoraDoEnsaio(),
          icon: const Icon(Icons.more_time, color: Colors.grey),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  /// Dialog Data e Hora do Ensaio
  void _definirHoraDoEnsaio() {
    var dataPrevia = mCulto.dataEnsaio?.toDate() ?? DateTime.now();
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
        Metodo.definirDataHoraDoEnsaio(widget.culto, dataHora);
      });
    });
  }

  /// Acesso ao arquivo da liturgia do culto
  Widget get _rowLiturgia {
    return Row(
      children: [
        const SizedBox(width: 12),
        const SizedBox(
          width: 80,
          child: Text('LITURGIA'),
        ),
        // Botão para abrir arquivo
        mCulto.liturgiaUrl == null
            ? Text(
                'Nenhum arquivo carregado',
                style: Theme.of(context).textTheme.caption,
              )
            : TextButton(
                child: const Text('Ver documento'),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () =>
                    Metodo.abrirArquivoPdf(context, mCulto.liturgiaUrl)),
        const Expanded(child: SizedBox()),
        // Botão de ação para dirigentes
        IconButton(
          onPressed: () async {
            String? url = await Metodo.carregarArquivoPdf();
            if (url != null && url.isNotEmpty) {
              var ok = await Metodo.atualizarCampoDoCulto(
                  reference: widget.culto, campo: 'liturgiaUrl', valor: url);
              if (!ok) {
                Mensagem.simples(
                    context: context, mensagem: 'Falha ao atualizar o campo');
              }
            }
          },
          icon: const Icon(
            Icons.upload_file,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  /// Seção o que falta
  Widget get _rowOqueFalta {
    return FutureBuilder<QuerySnapshot<Instrumento>>(
        future: Metodo.getInstrumentos(ativo: true),
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
          return Container(
            color: Colors.amber.withOpacity(0.5),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
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
  Widget _sectionResponsaveis(
    String titulo,
    Funcao funcao,
    DocumentReference<Integrante>? integrante,
    Function()? funcaoEditar,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 8, top: 0, bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Título
              Text(titulo.toUpperCase()),
              // Botão de edição
              IconButton(
                onPressed: funcaoEditar,
                icon: const Icon(
                  Icons.more_horiz,
                  color: Colors.grey,
                  size: 18,
                ),
              ),
            ],
          ),
          // Responsável
          _cardIntegranteInstrumento(integrante, null, funcao)
        ],
      ),
    );
  }

  /// Seção escalados
  Widget _sectionEscalados(
    String titulo,
    Funcao funcao,
    Map<String?, List<DocumentReference<Integrante>?>?> dados,
    Function()? funcaoEditar,
  ) {
    List<Widget> escalados = [];
    for (var entrada in dados.entries) {
      var instrumentoId = entrada.key;
      var integrantes = entrada.value;
      if (integrantes != null && integrantes.isNotEmpty) {
        for (var integrante in integrantes) {
          escalados.add(
              _cardIntegranteInstrumento(integrante, instrumentoId, funcao));
        }
      }
    }
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 0, bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Título
              Text(titulo.toUpperCase()),
              // Botão de edição
              IconButton(
                onPressed: funcaoEditar,
                icon: const Icon(
                  Icons.more_horiz,
                  color: Colors.grey,
                  size: 18,
                ),
              ),
            ],
          ),
          // Integrantes
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: escalados,
          ),
          /* GridView.count(
            shrinkWrap: true,
            crossAxisCount: escalados.length,
            children: escalados,
          ), */
        ],
      ),
    );
  }

  Widget _cardIntegranteInstrumento(
    DocumentReference<Integrante>? refIntegrante,
    String? instrumentoId,
    Funcao funcao,
  ) {
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
                return Container(
                  width: 172,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 1,
                      color: Colors.grey.withOpacity(0.5),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: (Global.integranteLogado != null &&
                            integrante?.id == Global.integranteLogado?.id)
                        ? Colors.amber.withOpacity(0.25)
                        : null,
                  ),
                  // Pilha
                  child: Stack(
                    alignment: Alignment.topLeft,
                    children: [
                      Row(
                        children: [
                          // Foto do integrante
                          const SizedBox(width: 8),
                          CircleAvatar(
                            child: const Icon(
                              Icons.person,
                              color: Colors.grey,
                            ),
                            foregroundImage: MyNetwork.getImageFromUrl(
                                    integrante?.data()?.fotoUrl, 16)
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
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                      // Imagem do instrumento
                      Image.asset(
                        instrumento?.iconAsset ??
                            (funcao == Funcao.dirigente
                                ? 'assets/icons/music_dirigente.png'
                                : funcao == Funcao.coordenador
                                    ? 'assets/icons/music_coordenador.png'
                                    : 'assets/icons/ic_launcher.png'),
                        width: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .inverseSurface
                            .withOpacity(0.75),
                        colorBlendMode: BlendMode.srcATop,
                      ),
                    ],
                  ),
                );
              });
        });
  }

  /// Seção observações
  Widget get _observacoes {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextFormField(
        initialValue: mCulto.obs,
        enabled: false,
        minLines: 5,
        maxLines: 15,
        decoration: const InputDecoration(
          labelText: 'Observações',
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        onChanged: (value) {
          mCulto.obs = value;
        },
      ),
    );
  }

  /* FUNÇÕES */

  /// Verifica se usuário está disponivel
  bool get _usuarioDisponivel {
    return mCulto.disponiveis
            ?.map((e) => e.toString())
            .contains(Global.integranteLogado?.reference.toString()) ??
        false;
  }

  /// Verifica se usuário está restrito
  bool get _usuarioRestrito {
    return mCulto.restritos
            ?.map((e) => e.toString())
            .contains(Global.integranteLogado?.reference.toString()) ??
        false;
  }

  /// Verifica se usuário está escalado
  bool get _usuarioEscalado {
    if (mCulto.dirigente.toString() ==
            Global.integranteLogado?.reference.toString() ||
        mCulto.coordenador.toString() ==
            Global.integranteLogado?.reference.toString()) {
      return true;
    }
    if (mCulto.equipe == null || mCulto.equipe!.isEmpty) {
      return false;
    }
    for (var instrumentosEquipe in mCulto.equipe!.values.toList()) {
      for (var integrante in instrumentosEquipe) {
        if (integrante.toString() ==
            Global.integranteLogado?.reference.toString()) {
          return true;
        }
      }
    }
    return false;
  }

  void _escalarIntegrante(
    Funcao funcao,
    Map<String, List<DocumentReference<Integrante>>>? instrumentosIntegrantes,
  ) {
    showDialog(
        context: context,
        builder: (context) {
          return FutureBuilder<QuerySnapshot<Instrumento>>(
              future: Metodo.getInstrumentos(ativo: true),
              builder: (_, snapInstr) {
                if (!snapInstr.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var instrumentos = snapInstr.data?.docs;
                return FutureBuilder<QuerySnapshot<Integrante>>(
                    future: Metodo.getIntegrantes(
                        ativo: true, funcao: funcao.index),
                    builder: (context, snapIntegrantes) {
                      if (!snapIntegrantes.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      List<QueryDocumentSnapshot<Integrante>>? integrantes =
                          snapIntegrantes.data?.docs;
                      return StatefulBuilder(builder: (context, innerState) {
                        return SimpleDialog(
                          title: const Text('Selecionar integrante'),
                          children: snapIntegrantes.hasData
                              ? List.generate(instrumentos?.length ?? 0,
                                  (index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 4),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(instrumentos?[index]
                                                  .data()
                                                  .nome ??
                                              'Instrumento'),
                                          Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            children:
                                                _integrantesDisponiveisNoInstrumento(
                                                    integrantes,
                                                    instrumentos![index]),
                                          ),
                                          const SizedBox(height: 12),
                                        ]),
                                  );
                                }).toList()
                              : const [
                                  Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text('Nenhum integrante disponível'),
                                  )
                                ],
                        );
                      });
                    });
              });
        });
  }

  List<Widget> _integrantesDisponiveisNoInstrumento(
      List<QueryDocumentSnapshot<Integrante>>? integrantes,
      QueryDocumentSnapshot<Instrumento> instrumentoRef) {
    dev.log(instrumentoRef.reference.id);
    if (integrantes == null || integrantes.isEmpty) {
      return const [Text('Ninguém disponivel!')];
    }
    try {
      List<QueryDocumentSnapshot<Integrante>> integrantesDoInstrumento = [];
      for (var integrante in integrantes) {
        var instrumentosDoIntegrante = integrante.data().instrumentos;
        if (instrumentosDoIntegrante != null) {
          if (instrumentosDoIntegrante
              .map((e) => e.toString())
              .contains(instrumentoRef.reference.toString())) {
            integrantesDoInstrumento.add(integrante);
          }
        }
      }
      if (integrantesDoInstrumento.isEmpty) {
        return const [Text('Ninguém disponivel!')];
      }
      return List.generate(integrantesDoInstrumento.length, (index) {
        return StatefulBuilder(builder: (context, setState) {
          bool selected = mCulto.equipe?[instrumentoRef.reference.id]
                  ?.map((e) => e.toString())
                  .contains(
                      integrantesDoInstrumento[index].reference.toString()) ??
              false;
          return ChoiceChip(
              selected: selected,
              selectedColor: Theme.of(context).colorScheme.primary,
              onSelected: (value) {
                if (value) {
                  widget.culto.update({
                    'equipe.${instrumentoRef.reference.id}':
                        FieldValue.arrayUnion([
                      integrantesDoInstrumento.toList()[index].reference
                    ])
                  }).then((value) => setState(() {}));
                } else {
                  widget.culto.update({
                    'equipe.${instrumentoRef.reference.id}':
                        FieldValue.arrayRemove([
                      integrantesDoInstrumento.toList()[index].reference
                    ])
                  }).then((value) => setState(() {}));
                }
              },
              label: Text(integrantesDoInstrumento[index]
                  .data()
                  .nome
                  .split(' ')
                  .first));
        });
      }).toList();
    } catch (e) {
      return const [Text('Falha na aquisição dos dados!')];
    }
  }

  void _escalarDirigente() {
    showDialog(
        context: context,
        builder: (context) {
          return FutureBuilder<QuerySnapshot<Integrante>>(
              future: Metodo.getIntegrantes(
                  ativo: true, funcao: Funcao.dirigente.index),
              builder: (context, snap) {
                return StatefulBuilder(builder: (context, innerState) {
                  String? selecionado = mCulto.dirigente.toString();
                  return SimpleDialog(
                    title: const Text('Selecionar dirigente'),
                    children: snap.hasData
                        ? List.generate(snap.data?.size ?? 0, (index) {
                            String? integrante =
                                snap.data?.docs[index].reference.toString();
                            return ChoiceChip(
                                selected: selecionado ==
                                    snap.data?.docs[index].reference.toString(),
                                selectedColor:
                                    Theme.of(context).colorScheme.primary,
                                onSelected: (value) {
                                  if (value) {
                                    widget.culto.update({
                                      'dirigente':
                                          snap.data?.docs[index].reference
                                    }).then((value) => innerState(() {}));
                                  } else {
                                    widget.culto
                                        .update({'dirigente': null}).then(
                                            (value) => innerState(() {}));
                                  }
                                },
                                label: Text(snap.data?.docs[index]
                                        .data()
                                        .nome
                                        .split(' ')
                                        .first ??
                                    'Sem nome'));
                            /* RadioListTile<String?>(
                              value: integrante ?? '',
                              groupValue: selecionado,
                              onChanged: (value) {
                                innerState(() {
                                  selecionado = value;
                                  Metodo.escalarDirigente(widget.culto,
                                      snap.data!.docs[index].reference);
                                });
                              },
                              title: Text(snap.data?.docs[index].data().nome ??
                                  'Sem nome'),
                            ); */
                          }).toList()
                        : const [
                            Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('Nenhum integrante disponível'),
                            )
                          ],
                  );
                });
              });
        });
  }

  void _escalarCoordenador() {
    String? selecionado = mCulto.coordenador.toString();
    showDialog(
        context: context,
        builder: (context) {
          return FutureBuilder<QuerySnapshot<Integrante>>(
              future: Metodo.getIntegrantes(
                  ativo: true, funcao: Funcao.coordenador.index),
              builder: (context, snap) {
                return StatefulBuilder(builder: (context, innerState) {
                  return SimpleDialog(
                    title: const Text('Selecionar coordenador técnico'),
                    children: snap.hasData
                        ? List.generate(snap.data?.size ?? 0, (index) {
                            String? integrante =
                                snap.data?.docs[index].reference.toString();
                            return RadioListTile<String?>(
                              value: integrante ?? '',
                              groupValue: selecionado,
                              onChanged: (value) {
                                innerState(() {
                                  selecionado = value;
                                  Metodo.escalarCoordenador(widget.culto,
                                      snap.data!.docs[index].reference);
                                });
                              },
                              title: Text(snap.data?.docs[index].data().nome ??
                                  'Sem nome'),
                            );
                          }).toList()
                        : const [
                            Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('Nenhum integrante disponível'),
                            )
                          ],
                  );
                });
              });
        });
  }
}
