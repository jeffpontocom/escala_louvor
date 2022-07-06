import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '/functions/metodos_firebase.dart';
import '/models/culto.dart';
import '/models/integrante.dart';
import '/modulos.dart';
import '/utils/global.dart';
import '/utils/mensagens.dart';
import '../../widgets/cached_circle_avatar.dart';
import '/widgets/dialogos.dart';
import '/widgets/tela_mensagem.dart';
import '/widgets/tile_culto.dart';

class PaginaAgenda extends StatefulWidget {
  const PaginaAgenda({Key? key}) : super(key: key);

  @override
  State<PaginaAgenda> createState() => _PaginaAgendaState();
}

class _PaginaAgendaState extends State<PaginaAgenda> {
  /* VARIÁVEIS */

  /// Lista de cultos
  List<QueryDocumentSnapshot<Culto>> cultos = [];

  // Variáveis para calendário
  final DateTime agora = DateTime.now();
  late DateTime sDiaSelecionado;
  late DateTime sDiaEmFoco;

  /// Notificador de eventos para calendário
  final ValueNotifier<Map<DateTime, String>> meusEventos = ValueNotifier({});

  /// Notificador para lista de eventos
  late ValueNotifier<DateTime?> mesCorrente = ValueNotifier(null);

  /* MÉTODOS */

  /// Define o mês corrente
  void _setMesCorrente(DateTime dia) {
    mesCorrente.value = DateTime(dia.year, dia.month);
  }

  /// Verifica se duas datas são o mesmo dia
  bool _ehMesmoDia(DateTime dia1, DateTime dia2) =>
      (dia1.year == dia2.year) &&
      (dia1.month == dia2.month) &&
      (dia1.day == dia2.day);

  /* SISTEMA */

  @override
  void initState() {
    _setMesCorrente(DateTime(agora.year, agora.month));
    sDiaSelecionado = agora;
    sDiaEmFoco = agora;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Inicia com um listener para os filtros
    // Datas minima e máxima, e Igreja
    return ValueListenableBuilder<bool>(
        valueListenable: Global.filtroMostrarTodosCultos,
        builder: (context, mostrarTudo, _) {
          var igrejas = mostrarTudo
              ? Global.logadoSnapshot!.data()!.igrejas
              : [Global.igrejaSelecionada.value?.reference];

          return ValueListenableBuilder<FiltroAgenda>(
              valueListenable: Global.filtroAgenda,
              builder: (context, agenda, _) {
                // Limpa a lista para forçar a interface a apresentar a tela de progresso
                cultos.clear();

                Timestamp? dataMin;
                Timestamp? dataMax;
                switch (agenda) {
                  case FiltroAgenda.historico:
                    dataMax = Timestamp.fromDate(
                        agora.subtract(const Duration(hours: 4)));
                    break;
                  case FiltroAgenda.mesAtual:
                    var ano = agora.year;
                    var mes = agora.month;
                    dataMin = Timestamp.fromDate(DateTime(ano, mes, 1));
                    dataMax = Timestamp.fromDate(DateTime(ano, mes + 1, -1));
                    break;
                  case FiltroAgenda.proximos:
                    dataMin = Timestamp.fromDate(
                        agora.subtract(const Duration(hours: 4)));
                    break;
                  default:
                }

                // Stream para montar a lista de cultos dinâmica,
                // ou seja, observa cada mudança nos registros
                return StreamBuilder<QuerySnapshot<Culto>>(
                    stream: MeuFirebase.ouvinteCultos(
                        dataMinima: dataMin,
                        dataMaxima: dataMax,
                        igrejas: igrejas),
                    builder: (context, snapshot) {
                      // TELA DE PROGRESSO
                      if (!snapshot.hasData ||
                          (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              cultos.isEmpty)) {
                        return Column(
                          children: const [
                            LinearProgressIndicator(),
                            Expanded(
                              child: TelaMensagem(
                                'Carregando a lista...',
                                asset: 'assets/images/church.png',
                              ),
                            )
                          ],
                        );
                      }
                      // TELA DE FALHA
                      if (snapshot.hasError) {
                        return const TelaMensagem(
                          'Falha ao tentar obter dados',
                          isError: true,
                        );
                      }

                      // Preenche a lista de cultos
                      cultos = snapshot.data!.docs.toList();
                      if (Global.filtroAgenda.value == FiltroAgenda.historico) {
                        cultos = cultos.reversed.toList();
                      }
                      // Limpa e preenche novamente a lista de eventos do calendário
                      meusEventos.value.clear();
                      for (var culto in cultos) {
                        var dataCulto = culto.data().dataCulto.toDate();
                        meusEventos.value.putIfAbsent(dataCulto, () => 'culto');
                      }

                      // TELA PRINCIPAL
                      return _layout;
                    });
              });
        });
  }

  /// LAYOUT DA TELA
  get _layout {
    return OrientationBuilder(builder: (context, orientation) {
      // MODO RETRATO
      if (orientation == Orientation.portrait) {
        return Column(children: [
          Container(
            color: Colors.grey.withOpacity(0.12),
            child: _rowAcoes,
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(child: _conteudo),
        ]);
      }
      // MODO PAISAGEM
      return LayoutBuilder(builder: (context, constraints) {
        return Wrap(children: [
          Container(
            height: constraints.maxHeight,
            width: constraints.maxWidth * 0.4 - 1,
            color: Colors.grey.withOpacity(0.12),
            child: Column(
              children: [
                _rowAcoes,
                const Divider(height: 1),
                Expanded(child: _calendario),
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
              child: _conteudo),
        ]);
      });
    });
  }

  /// WIDGET AÇÕES
  get _rowAcoes {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // BOTÃO DE FILTROS
          const Icon(Icons.filter_alt),
          const SizedBox(width: 4),
          DropdownButtonHideUnderline(
            child: DropdownButton<FiltroAgenda>(
                value: Global.filtroAgenda.value,
                items: const [
                  DropdownMenuItem(
                    value: FiltroAgenda.proximos,
                    child: Text('Próximos'),
                  ),
                  DropdownMenuItem(
                    value: FiltroAgenda.mesAtual,
                    child: Text('Mês atual'),
                  ),
                  DropdownMenuItem(
                    value: FiltroAgenda.historico,
                    child: Text('Histórico'),
                  ),
                ],
                onChanged: (value) {
                  Global.filtroAgenda.value = value ?? FiltroAgenda.proximos;
                }),
          ),

          // Espaço em branco com altura padrão de interação
          const Expanded(child: SizedBox(height: kMinInteractiveDimension)),

          // BOTÃO NOVO CULTO
          // Apenas para Recrutadores ou administrador do sistema
          ((Global.logado?.adm ?? false) ||
                  (Global.logado?.ehRecrutador ?? false))
              ? ActionChip(
                  avatar: const Icon(Icons.add, size: 20),
                  label: const Text('Novo'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  onPressed: () {
                    // Tratamento de erros
                    if (Global.igrejaSelecionada.value == null) {
                      Mensagem.simples(
                          context: context,
                          mensagem:
                              'Isso não deveria ter acontecido. Sem igreja selecionada.');
                      return;
                    }
                    var dataInicial = DateTime(sDiaSelecionado.year,
                        sDiaSelecionado.month, sDiaSelecionado.day, 9, 30);
                    var culto = Culto(
                      dataCulto: Timestamp.fromDate(dataInicial),
                      igreja: Global.igrejaSelecionada.value!.reference,
                      emEdicao: true,
                    );
                    Dialogos.editarCulto(context, culto: culto);
                  })
              : const SizedBox(),
        ],
      ),
    );
  }

  /// WIDGET CALENDÁRIO
  get _calendario {
    return ValueListenableBuilder<Map<DateTime, String>>(
        valueListenable: meusEventos,
        builder: (context, eventos, _) {
          return StatefulBuilder(builder: (context, setState) {
            return TableCalendar(
              focusedDay: sDiaEmFoco,
              firstDay: DateTime(agora.year, agora.month),
              lastDay: DateTime(agora.year, agora.month + 6, 0),
              locale: 'pt_BR',
              shouldFillViewport: true,
              headerStyle: const HeaderStyle(headerPadding: EdgeInsets.zero),
              onPageChanged: (diaEmFoco) {
                setState(() {
                  sDiaEmFoco = diaEmFoco;
                  _setMesCorrente(diaEmFoco);
                });
              },
              onDaySelected: (diaSelecionado, diaEmFoco) {
                setState(() {
                  sDiaEmFoco = diaEmFoco;
                  sDiaSelecionado = diaSelecionado;
                  _setMesCorrente(diaSelecionado);
                });
              },
              selectedDayPredicate: (dia) {
                return _ehMesmoDia(dia, sDiaSelecionado);
              },
              holidayPredicate: (dia) {
                var datas = eventos.entries
                    .where((element) => element.value == 'aniversario');
                for (var data in datas) {
                  if (_ehMesmoDia(dia, data.key)) {
                    return true;
                  }
                }
                return false;
              },
              eventLoader: (data) {
                List cultos = [];
                eventos.entries
                    .where((element) => element.value == 'culto')
                    .forEach((element) {
                  if (_ehMesmoDia(data, element.key)) {
                    cultos.add(element.value);
                  }
                });
                return cultos;
              },
              availableCalendarFormats: const {CalendarFormat.month: 'Mês'},
              calendarStyle: CalendarStyle(
                weekendTextStyle: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onBackground
                        .withOpacity(0.7)),
                outsideTextStyle:
                    TextStyle(color: Colors.grey.withOpacity(0.5)),
                todayDecoration: BoxDecoration(
                    color: null,
                    border: Border.fromBorderSide(BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.4)),
                    shape: BoxShape.circle),
                todayTextStyle:
                    TextStyle(color: Theme.of(context).colorScheme.primary),
                selectedDecoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.75),
                    border: Border.fromBorderSide(
                      BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1.4),
                    ),
                    shape: BoxShape.circle),
                holidayDecoration: BoxDecoration(
                    border: Border.fromBorderSide(BorderSide(
                        color: Theme.of(context).colorScheme.secondary,
                        width: 1.4)),
                    shape: BoxShape.circle),
                holidayTextStyle:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
                markerDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.primary),
              ),
            );
          });
        });
  }

  /// CONTEÚDO PRINCIPAL
  get _conteudo {
    return cultos.isNotEmpty
        ? _listaCultos
        : const TelaMensagem(
            'Nenhum culto previsto!',
            asset: 'assets/images/church.png',
          );
  }

  /// LISTA DE CULTOS
  get _listaCultos {
    bool mostrarCabecalho = true;
    return ListView.separated(
      shrinkWrap: true,
      separatorBuilder: (context, index) {
        return Divider(
          height: 4,
          thickness: 4,
          color: Theme.of(context).highlightColor,
        );
      },
      itemCount: cultos.length,
      itemBuilder: (context, index) {
        var culto = cultos[index].data();
        var reference = cultos[index].reference;
        mostrarCabecalho = index - 1 < 0
            ? true
            : culto.dataCulto.toDate().month ==
                        cultos[index - 1].data().dataCulto.toDate().month &&
                    culto.dataCulto.toDate().year ==
                        cultos[index - 1].data().dataCulto.toDate().year
                ? false
                : true;
        return Column(
          children: [
            // Cabeçalho do mês
            mostrarCabecalho
                ? cabecalhoDoMes(culto.dataCulto.toDate())
                : const SizedBox(),
            // Divisor
            mostrarCabecalho
                ? Divider(
                    height: 4,
                    thickness: 4,
                    color: Theme.of(context).highlightColor,
                  )
                : const SizedBox(),
            // Tile do culto
            InkWell(
              onTap: () => Modular.to.pushNamed(
                  '${AppModule.CULTO}?id=${cultos[index].id}',
                  arguments: cultos[index]),
              child: TileCulto(
                culto: culto,
                reference: reference,
                theme: Theme.of(context),
                showResumo: true,
              ),
            ),
            index == cultos.length - 1
                ? Divider(
                    height: 4,
                    thickness: 4,
                    color: Theme.of(context).highlightColor,
                  )
                : const SizedBox(),
          ],
        );
      },
    );
  }

  // CABEÇALHO DO MÊS
  Widget cabecalhoDoMes(DateTime data) {
    String mesAno = DateFormat('MMMM y', 'pt_BR').format(data);
    var capitalize = mesAno.characters.first.toUpperCase();
    mesAno = capitalize + mesAno.substring(1);
    return Column(children: [
      // Mês e ano
      Padding(
        padding: const EdgeInsets.only(top: 56, left: 16, right: 16, bottom: 8),
        child: Text(
          mesAno,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      // Aniversariantes
      Row(children: [
        // Leading Icone
        Container(
          width: 56,
          height: 32,
          decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.38),
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(32))),
          child: const Icon(Icons.cake, size: 20),
        ),
        // Lista
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          height: kToolbarHeight,
          child: FutureBuilder<QuerySnapshot<Integrante>>(
              future: MeuFirebase.obterListaIntegrantes(),
              builder: (context, snapshot) {
                List<QueryDocumentSnapshot<Integrante>> aniversariantes = [];
                // Aguardando
                if (!snapshot.hasData) {
                  return Container(
                    alignment: Alignment.centerLeft,
                    height: kMinInteractiveDimension,
                    child: Text('Analisando a equipe...',
                        style: Theme.of(context).textTheme.bodySmall),
                  );
                }
                for (var integrante in snapshot.data!.docs) {
                  if (integrante.data().dataNascimento?.toDate().month ==
                      data.month) {
                    aniversariantes.add(integrante);
                  }
                }
                // Lista vazia
                if (aniversariantes.isEmpty) {
                  return Container(
                    alignment: Alignment.centerLeft,
                    height: kMinInteractiveDimension,
                    child: Text('Nenhum aniversariante esse mês!',
                        style: Theme.of(context).textTheme.bodySmall),
                  );
                }
                // Ordenação
                aniversariantes.sort(((a, b) {
                  var diaA = a.data().dataNascimento!.toDate().day;
                  var diaB = b.data().dataNascimento!.toDate().day;
                  return diaA.compareTo(diaB);
                }));
                // Preenchimento
                return ListView.separated(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: aniversariantes.length,
                  separatorBuilder: (context, index) {
                    return const SizedBox(width: 8);
                  },
                  itemBuilder: (context, index) {
                    var integrante = aniversariantes[index].data();
                    var dn = integrante.dataNascimento?.toDate();
                    var data = '';
                    if (dn != null) {
                      dn = DateTime(DateTime.now().year, dn.month, dn.day);
                      data = DateFormat.Md('pt_BR').format(dn);
                      meusEventos.value.putIfAbsent(dn, () => 'aniversario');
                    }
                    var hero = data.replaceAll('/', 'm');
                    return RawChip(
                      label: Text(data),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      avatar: Hero(
                        tag: hero,
                        child: CachedAvatar(
                          nome: integrante.nome,
                          url: integrante.fotoUrl,
                        ),
                      ),
                      onPressed: () => Modular.to.pushNamed(
                          '${AppModule.PERFIL}?id=${aniversariantes[index].id}&hero=$hero',
                          arguments: aniversariantes[index]),
                    );
                  },
                );
              }),
        ),
      ]),
    ]);
  }
}

/* return Column(
      children: [
        // Linha com legenda e botão de criação de culto
        Container(
          color: Colors.grey.withOpacity(0.25),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          height: kMinInteractiveDimension,
          child: Row(
            children: [
              // Legenda cultos
              Container(
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.primary),
                width: 8,
                height: 8,
              ),
              const Text('Cultos'),
              const SizedBox(width: 12),
              // Legenda aniversários
              Container(
                margin: const EdgeInsets.only(right: 4),
                decoration: const BoxDecoration(
                  border: Border.fromBorderSide(
                    BorderSide(color: Colors.orange, width: 1.4),
                  ),
                  shape: BoxShape.circle,
                ),
                width: 12,
                height: 12,
              ),
              const Text('Aniversários'),
              
            ],
          ),
        ),
        // Listas
        Expanded(
          child: Column(children: [
            
            // Lista de Cultos
            Expanded(
              child: StreamBuilder<QuerySnapshot<Culto>>(
                  stream: MeuFirebase.escutarCultos(
                      dataMinima: Timestamp.fromDate(agora),
                      igreja: Global.igrejaSelecionada.value?.reference),
                  builder: (context, snapshot) {
                    meusEventos.value
                        .removeWhere((key, value) => value == 'culto');
                    if (snapshot.hasData) {
                      return ValueListenableBuilder<DateTime>(
                          valueListenable: mesCorrente,
                          builder: (context, data, _) {
                            var cultos = snapshot.data!.docs
                                .where((element) =>
                                    element.data().dataCulto.toDate().year ==
                                        data.year &&
                                    element.data().dataCulto.toDate().month ==
                                        data.month)
                                .toList();
                            // Notificar após carregamento da interface
                            WidgetsBinding.instance.addPostFrameCallback(
                                (_) => meusEventos.notifyListeners());
                            if (cultos.isEmpty) {
                              return const Center(
                                child: Text(
                                  'Nenhum culto previsto.\n\nAvance para o próximo mês ou retorne ao anterior.',
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }
                            return ListView(
                                children: List.generate(cultos.length, (index) {
                              Culto culto = cultos[index].data();
                              // Analise das datas de cada culto
                              var dataCulto = culto.dataCulto.toDate();
                              var dataFormatada =
                                  DateFormat.yMEd('pt_BR').format(dataCulto);
                              var horaFormatada =
                                  DateFormat.Hm('pt_BR').format(dataCulto);
                              meusEventos.value
                                  .putIfAbsent(dataCulto, () => 'culto');
                              // Analise do usuario logado em cada culto
                              bool escalado = culto.usuarioEscalado(
                                  Global.integranteLogado?.reference);
                              bool disponivel = culto.usuarioDisponivel(
                                  Global.integranteLogado?.reference);
                              bool restrito = culto.usuarioRestrito(
                                  Global.integranteLogado?.reference);
                              // Tile
                              return StatefulBuilder(
                                  builder: (context, innerState) {
                                return ListTile(
                                  title: Text(culto.ocasiao ?? 'Culto'),
                                  subtitle:
                                      Text('$dataFormatada às $horaFormatada'),
                                  trailing:
                                      // Botão disponibilidade
                                      _podeSerEscalado
                                          ? OutlinedButton.icon(
                                              label: Text(
                                                escalado
                                                    ? 'Escalado'
                                                    : disponivel
                                                        ? 'Disponível'
                                                        : restrito
                                                            ? 'Restrito'
                                                            : 'Indefinido',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              icon: const Icon(
                                                  Icons.emoji_people),
                                              style: OutlinedButton.styleFrom(
                                                elevation: 0,
                                                primary: escalado ||
                                                        disponivel ||
                                                        restrito
                                                    ? Colors.white
                                                    : Colors.grey
                                                        .withOpacity(0.5),
                                                backgroundColor: escalado
                                                    ? Colors.green
                                                    : disponivel
                                                        ? Colors.blue
                                                        : restrito
                                                            ? Colors.red
                                                            : Colors
                                                                .transparent,
                                                maximumSize: const Size(96, 36),
                                                minimumSize: const Size(96, 36),
                                              ),
                                              onPressed: escalado || restrito
                                                  ? () {}
                                                  : () async {
                                                      await MeuFirebase
                                                          .definirDisponibilidadeParaOCulto(
                                                              cultos[index]
                                                                  .reference);
                                                      innerState(() {});
                                                    },
                                              onLongPress:
                                                  escalado || disponivel
                                                      ? () {}
                                                      : () async {
                                                          await MeuFirebase
                                                              .definirRestricaoParaOCulto(
                                                                  cultos[index]
                                                                      .reference);
                                                          innerState(() {});
                                                        },
                                            )
                                          : const SizedBox(),
                                  onTap: () {
                                    Global.paginaSelecionada.value =
                                        Paginas.escalas.index;
                                    Modular.to.navigate(
                                        '/${Paginas.escalas.name}?id=${cultos[index].id}');
                                  },
                                );
                              });
                            }, growable: false)
                                    .toList());
                          });
                    }
                    return const Center(child: CircularProgressIndicator());
                  }),
            ),
          ]),
        ),
      ],
    ); */
// FIM
