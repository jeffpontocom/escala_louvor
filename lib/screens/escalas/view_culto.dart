import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/functions/metodos.dart';
import 'package:escala_louvor/functions/notificacoes.dart';
import 'package:escala_louvor/utils/mensagens.dart';
import 'package:escala_louvor/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';

import '/global.dart';
import '/models/culto.dart';
import '/models/instrumento.dart';
import '/models/integrante.dart';

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
            return const Center(child: Text('Falha'));
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
                    _botaoDisponibilidade,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Dirigente
                        _secaoEscalados(
                          'Dirigente',
                          Funcao.dirigente,
                          {
                            null: [mCulto.dirigente]
                          },
                          () => _escalarIntegrante(Funcao.dirigente, null),
                        ),
                        // Coordenador
                        _secaoEscalados(
                            'Coord. técnico',
                            Funcao.leitor,
                            {
                              null: [mCulto.coordenador]
                            },
                            null),
                      ],
                    ),
                    // Escalados (Equipe)
                    _secaoEscalados(
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
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton.icon(
                              onPressed: null,
                              label: const Text('Alterar dados do culto'),
                              icon: const Icon(Icons.edit_calendar),
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
                          ]),
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
  Widget get _botaoDisponibilidade {
    bool alterar = false;
    return StatefulBuilder(builder: (context, setState) {
      bool escalado = _usuarioEscalado;
      bool disponivel = _usuarioDisponivel;
      dev.log('Estou escalado: $escalado | Estou disponível: $disponivel');
      return OutlinedButton(
        onPressed: escalado
            ? () {}
            : () async {
                setState(() {
                  alterar = true;
                });
                await Metodo.definirDisponibiliadeParaOCulto(widget.culto);
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
                : const Icon(Icons.hail_rounded),
            Text(escalado
                ? 'Estou escalado!'
                : disponivel
                    ? 'Estou disponível!'
                    : 'Estou disponível?'),
          ],
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(12),
          backgroundColor: escalado
              ? Colors.green
              : disponivel
                  ? Colors.blue
                  : null,
          primary: escalado || disponivel
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
              context: context, initialTime: TimeOfDay.fromDateTime(data))
          .then((hora) {
        if (data == null || hora == null) return;
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
        TextButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Abrir arquivo'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: mCulto.liturgiaUrl == null
                ? null
                : () => Metodo.abrirArquivoPdf(mCulto.liturgiaUrl)),
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
    var resultado = _verificaEquipe();
    return Container(
      color: Colors.amber.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        resultado,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }

  /// Seção escalados
  Widget _secaoEscalados(
    String titulo,
    Funcao funcao,
    Map<DocumentReference<Instrumento>?, List<DocumentReference<Integrante>?>?>
        dados,
    Function()? funcaoEditar,
  ) {
    List<Widget> escalados = [];
    for (var entrada in dados.entries) {
      var instrumento = entrada.key;
      var integrantes = entrada.value;
      if (integrantes == null || integrantes.isEmpty) {
        escalados.add(const SizedBox());
      } else {
        for (var integrante in integrantes) {
          escalados
              .add(_cardIntegranteInstrumento(integrante, instrumento, funcao));
        }
      }
    }
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 0, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        ],
      ),
    );
  }

  Widget _cardIntegranteInstrumento(
    DocumentReference<Integrante>? refIntegrante,
    DocumentReference<Instrumento>? refInstrumento,
    Funcao funcao,
  ) {
    return FutureBuilder<DocumentSnapshot<Integrante>>(
        future: refIntegrante?.get(),
        builder: (_, integ) {
          if (!integ.hasData) return const SizedBox();
          var integrante = integ.data;
          var nomeIntegrante = integrante?.data()?.nome ?? '[Sem nome]';
          var nomePrimeiro = nomeIntegrante.split(' ').first;
          var nomeSegundo = nomeIntegrante.split(' ').last;
          nomeIntegrante = nomePrimeiro == nomeSegundo
              ? nomePrimeiro
              : nomePrimeiro + ' ' + nomeSegundo;
          return FutureBuilder<DocumentSnapshot<Instrumento>>(
              future: refInstrumento?.get(),
              builder: (_, instr) {
                var instrumento = instr.data?.data();
                // Box
                return Container(
                  width: 112,
                  height: 128,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 1,
                      color: Colors.grey.withOpacity(0.5),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color:
                        _usuarioEscalado ? Colors.amber.withOpacity(0.5) : null,
                  ),
                  // Pilha
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Foto do integrante
                          CircleAvatar(
                            child: const Icon(
                              Icons.person,
                              color: Colors.grey,
                            ),
                            foregroundImage: MyNetwork.getImageFromUrl(
                                    integrante?.data()?.fotoUrl, 16)
                                ?.image,
                            backgroundColor: Colors.grey.shade200,
                            radius: 28,
                          ),
                          const SizedBox(height: 8),
                          // Nome do integrante
                          Text(
                            nomeIntegrante,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          // Instrumento para o qual está escalado
                          Text(
                            instrumento?.nome ?? '',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      // Imagem do instrumento
                      Image.asset(
                        instrumento?.iconAsset ??
                            (funcao == Funcao.dirigente
                                ? 'assets/icons/music_dirigente.png'
                                : funcao == Funcao.administrador
                                    ? 'assets/icons/music_coordenador.png'
                                    : 'assets/icons/ic_launcher.png'),
                        width: 20,
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
    for (var integrante in mCulto.equipe!.values) {
      if (integrante.toString() ==
          Global.integranteLogado?.reference.toString()) {
        return true;
      }
    }
    return false;
  }

  /// Verifica na equipe se há no mínimo:
  /// - 1 dirigente
  /// - 1 vocal
  /// - 1 guitarra ou 1 violão
  /// - 1 baixo
  /// - 1 teclado
  /// - 1 sonoplasta
  /// - 1 transmissão
  String _verificaEquipe() {
    if (mCulto.equipe == null || mCulto.equipe!.isEmpty) {
      return 'Escalar equipe!';
    }
    List<DocumentReference<Instrumento>> lista = [];
    for (var instrumento in mCulto.equipe!.keys) {
      lista.add(instrumento);
    }
    // Regras
    if (lista.isEmpty) return 'Falta: Voz, Violão, Teclado, Sonorização';
    return 'Equipe completa!';
  }

  void _escalarIntegrante(
    Funcao funcao,
    Map<DocumentReference<Instrumento>, List<DocumentReference<Integrante>>>?
        instrumentosIntegrantes,
  ) {
    Map<Funcao, Map<String, List<String>?>>? selecionados = {};
    switch (funcao) {
      case Funcao.dirigente:
        selecionados = {
          funcao: {
            'Dirigente': [mCulto.dirigente.toString()]
          }
        };
        break;
      case Funcao.coordenador:
        selecionados = {
          funcao: {
            'Coordenador': [mCulto.coordenador.toString()]
          }
        };
        break;
      case Funcao.integrante:
        selecionados = {funcao: Map.from(instrumentosIntegrantes!)};
        break;
      default:
        break;
    }
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
                                  return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(instrumentos?[index].data().nome ??
                                            'Instrumento'),
                                        Wrap(
                                          children:
                                              _integrantesDisponiveisNoInstrumento(
                                                  integrantes,
                                                  instrumentos?[index]
                                                          .reference
                                                          .toString() ??
                                                      ''),
                                        ),
                                        const SizedBox(height: 12),
                                      ]);
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
      String instrumentoRef) {
    dev.log(instrumentoRef);
    if (integrantes == null || integrantes.isEmpty) {
      return const [Text('Ninguém disponivel!')];
    }
    try {
      var integrantesDoInstrumento = integrantes
          .where((element) => element
              .data()
              .instrumentos!
              .map((e) => e.toString())
              .contains(instrumentoRef))
          .toList();
      return List.generate(
              integrantesDoInstrumento.length,
              (index) => RawChip(
                  label: Text(integrantesDoInstrumento[index].data().nome)))
          .toList();
    } catch (e) {
      return const [Text('Erro: Ninguém disponivel!')];
    }
  }

  /* void _escalarDirigente() {
    String? selecionado = mCulto.dirigente.toString();
    showDialog(
        context: context,
        builder: (context) {
          return FutureBuilder<QuerySnapshot<Integrante>>(
              future: Metodo.getIntegrantes(
                  ativo: true, funcao: Funcao.dirigente.index),
              builder: (context, snap) {
                return StatefulBuilder(builder: (context, innerState) {
                  return SimpleDialog(
                    title: const Text('Selecionar dirigente'),
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
                                  Metodo.escalarDirigente(widget.culto,
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
  } */
}
