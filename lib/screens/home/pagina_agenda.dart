import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/rotas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../widgets/tile_culto.dart';
import '/functions/metodos_firebase.dart';
import '../../../utils/global.dart';
import '/models/culto.dart';
import '/models/integrante.dart';
import '../../widgets/dialogos.dart';
import '/utils/mensagens.dart';
import '/utils/utils.dart';

class PaginaAgenda extends StatefulWidget {
  const PaginaAgenda({Key? key}) : super(key: key);

  @override
  State<PaginaAgenda> createState() => _PaginaAgendaState();
}

class _PaginaAgendaState extends State<PaginaAgenda> {
  //Integrante get logado => Global.logadoSnapshot!.data()!;
  bool get _podeSerEscalado =>
      (Global.logado?.ehDirigente ?? false) ||
      (Global.logado?.ehCoordenador ?? false) ||
      (Global.logado?.ehComponente ?? false);

  ///
  List<QueryDocumentSnapshot<Culto>> cultos = [];
  final agora = DateTime.now();
  var formato = CalendarFormat.month;
  late DateTime sDiaSelecionado;
  late DateTime sDiaEmFoco;
  bool _isPortrait = true;

  /// Notificador para calendário
  final ValueNotifier<Map<DateTime, String>> meusEventos = ValueNotifier({});

  /// Notificador para lista de eventos
  late ValueNotifier<DateTime?> mesCorrente = ValueNotifier(null);

  /// Define o mês corrente
  void _setMesCorrente(DateTime dia) {
    mesCorrente.value = DateTime(dia.year, dia.month);
  }

  /// Verifica se duas datas são o mesmo dia
  bool _ehMesmoDia(DateTime dia1, DateTime dia2) =>
      (dia1.year == dia2.year) &&
      (dia1.month == dia2.month) &&
      (dia1.day == dia2.day);

  @override
  void initState() {
    _setMesCorrente(DateTime(agora.year, agora.month));
    sDiaSelecionado = agora;
    sDiaEmFoco = agora;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FiltroAgenda>(
        valueListenable: Global.meusFiltros,
        builder: (context, filtros, _) {
          cultos.clear();
          return StreamBuilder<QuerySnapshot<Culto>>(
              stream: MeuFirebase.escutarCultos(
                  dataMinima: filtros.timeStampMin,
                  dataMaxima: filtros.timeStampMax,
                  igrejas: filtros.igrejas),
              builder: (context, snapshot) {
                if (!snapshot.hasData ||
                    (snapshot.connectionState == ConnectionState.waiting &&
                        cultos.isEmpty)) {
                  return Column(
                    children: const [
                      LinearProgressIndicator(),
                      Expanded(
                        child: Center(
                          child: Text('Carregando a lista...',
                              textAlign: TextAlign.center),
                        ),
                      )
                    ],
                  );
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Falha ao tentar obter dados',
                        textAlign: TextAlign.center),
                  );
                }
                cultos = snapshot.data!.docs.toList();
                meusEventos.value.clear();
                for (var culto in cultos) {
                  var dataCulto = culto.data().dataCulto.toDate();
                  meusEventos.value.putIfAbsent(dataCulto, () => 'culto');
                }
                return OrientationBuilder(builder: (context, orientation) {
                  _isPortrait = orientation == Orientation.portrait;
                  return LayoutBuilder(builder: (context, constraints) {
                    return Wrap(children: [
                      // Lado Esquerdo == Topo
                      SizedBox(
                        height: _isPortrait
                            ? kMinInteractiveDimension + 1
                            : constraints.maxHeight,
                        width: _isPortrait
                            ? constraints.maxWidth
                            : constraints.maxWidth * 0.4 - 1,
                        child: _cabecalho,
                      ),
                      // Divisor
                      _isPortrait
                          ? const SizedBox()
                          : Container(
                              height: constraints.maxHeight,
                              width: 1,
                              color: Colors.grey,
                            ),
                      // Lado direito == Base
                      SizedBox(
                        height: _isPortrait
                            ? constraints.maxHeight -
                                (kMinInteractiveDimension + 1)
                            : constraints.maxHeight,
                        width: _isPortrait
                            ? constraints.maxWidth
                            : constraints.maxWidth * 0.6,
                        //constraints.maxWidth - constraints.maxHeight - 1,
                        child: _dados,
                      ),
                    ]);
                  });
                });
              });
        });
  }

  get _cabecalho {
    return Column(children: [
      // Ações
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Botão Novo Culto
            ((Global.logado?.adm ?? false) ||
                    (Global.logado?.ehRecrutador ?? false))
                ? ActionChip(
                    avatar: const Icon(Icons.add),
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
                      );
                      Dialogos.editarCulto(context, culto);
                    })
                : const SizedBox(),
            const Expanded(child: SizedBox(height: kMinInteractiveDimension)),
            // Botão Filtro
            ActionChip(
                avatar: const Icon(Icons.filter_alt),
                label: Text(Global.meusFiltros.value.dataMaxima == null
                    ? 'Próximos'
                    : 'Passados'),
                onPressed: () {
                  if (Global.meusFiltros.value.dataMaxima == null) {
                    Global.meusFiltros.value.dataMaxima = DateTime.now();
                    Global.meusFiltros.value.dataMinima = null;
                  } else {
                    Global.meusFiltros.value.dataMaxima = null;
                    Global.meusFiltros.value.dataMinima = DateTime.now();
                  }
                  Global.meusFiltros.notifyListeners();
                })
          ],
        ),
      ),
      const Divider(height: 1),
      // Calendário
      _isPortrait
          ? const SizedBox()
          : Expanded(
              child: ValueListenableBuilder<Map<DateTime, String>>(
                  valueListenable: meusEventos,
                  builder: (context, eventos, _) {
                    return StatefulBuilder(builder: (context, setState) {
                      return TableCalendar(
                        focusedDay: sDiaEmFoco,
                        firstDay: DateTime(agora.year, agora.month),
                        lastDay: DateTime(agora.year, agora.month + 6, 0),
                        locale: 'pt_BR',
                        shouldFillViewport: true,
                        headerStyle:
                            const HeaderStyle(headerPadding: EdgeInsets.zero),
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
                          var datas = eventos.entries.where(
                              (element) => element.value == 'aniversario');
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
                        availableCalendarFormats: const {
                          CalendarFormat.month: 'Mês'
                        },
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
                          todayTextStyle: TextStyle(
                              color: Theme.of(context).colorScheme.primary),
                          selectedDecoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.75),
                              border: Border.fromBorderSide(
                                BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 1.4),
                              ),
                              shape: BoxShape.circle),
                          holidayDecoration: BoxDecoration(
                              border: Border.fromBorderSide(BorderSide(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  width: 1.4)),
                              shape: BoxShape.circle),
                          holidayTextStyle: TextStyle(
                              color: Theme.of(context).colorScheme.secondary),
                          markerDecoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Theme.of(context).colorScheme.primary),
                        ),
                      );
                    });
                  }),
            ),
    ]);
  }

  // LISTA DE CULTOS
  get _dados {
    return cultos.isEmpty
        ? const Center(
            child: Text('Nenhum culto previsto.', textAlign: TextAlign.center),
          )
        : listaCultos;
  }

  /// View Lista de Cultos
  get listaCultos {
    bool mostrarCabecalho = true;
    return ListView(
      shrinkWrap: true,
      children: List.generate(cultos.length, (index) {
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
            // Tile do culto
            InkWell(
              onTap: () => Modular.to.pushNamed(
                  '${AppRotas.CULTO}?id=${cultos[index].id}',
                  arguments: cultos[index]),
              child: TileCulto(culto: culto, reference: reference),
            ),
            // Divisor
            const Divider(height: 1),
          ],
        );
      }),
    );
  }

  Widget cabecalhoDoMes(DateTime data) {
    String mesAno = DateFormat('MMMM y', 'pt_BR').format(data);
    var capitalize = mesAno.characters.first.toUpperCase();
    mesAno = capitalize + mesAno.substring(1);
    return Column(
      children: [
        // Mês e ano
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            mesAno,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        // Aniversariantes
        Row(
          children: [
            // Leading Icone
            Container(
              width: 56,
              height: 32,
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(32))),
              child: const Icon(Icons.cake, size: 20),
            ),
            // Lista
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                height: kToolbarHeight,
                child: FutureBuilder<QuerySnapshot<Integrante>>(
                  future: MeuFirebase.obterListaIntegrantes(ativo: true),
                  builder: (context, snapshot) {
                    List<QueryDocumentSnapshot<Integrante>> aniversariantes =
                        [];
                    // Aguardando
                    if (!snapshot.hasData) {
                      return Container(
                        alignment: Alignment.centerLeft,
                        height: kMinInteractiveDimension,
                        child: Text('Analisando a equipe...',
                            style: Theme.of(context).textTheme.caption),
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
                            style: Theme.of(context).textTheme.caption),
                      );
                    }
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
                        var dn = aniversariantes[index]
                            .data()
                            .dataNascimento
                            ?.toDate();
                        var data = '';
                        if (dn != null) {
                          dn = DateTime(DateTime.now().year, dn.month, dn.day);
                          data = DateFormat.Md('pt_BR').format(dn);
                          meusEventos.value
                              .putIfAbsent(dn, () => 'aniversario');
                        }
                        var hero = data.replaceAll('/', 'm');
                        return RawChip(
                          label: Text(data),
                          avatar: Hero(
                            tag: hero,
                            child: CircleAvatar(
                              foregroundImage: MyNetwork.getImageFromUrl(
                                      aniversariantes[index].data().fotoUrl)
                                  ?.image,
                              child: Text(
                                  MyStrings.getUserInitials(
                                      aniversariantes[index].data().nome),
                                  textScaleFactor: 0.6),
                            ),
                          ),
                          onPressed: () => Modular.to.pushNamed(
                              '${AppRotas.PERFIL}?id=${aniversariantes[index].id}&hero=$hero',
                              arguments: aniversariantes[index]),
                        );
                      },
                    );
                  },
                )),
          ],
        )
      ],
    );
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
