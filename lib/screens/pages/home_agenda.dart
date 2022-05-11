import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/rotas.dart';
import 'package:escala_louvor/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '/functions/metodos_firebase.dart';
import '/global.dart';
import '/models/culto.dart';
import '/models/integrante.dart';
import '/screens/views/dialogos.dart';
import '/utils/mensagens.dart';
import '/utils/utils.dart';

class TelaAgenda extends StatelessWidget {
  const TelaAgenda({Key? key}) : super(key: key);

  Integrante get logado {
    return Global.integranteLogado!.data()!;
  }

  bool get _podeSerEscalado {
    return logado.ehDirigente || logado.ehCoordenador || logado.ehComponente;
  }

  @override
  Widget build(BuildContext context) {
    final _agora = DateTime.now();
    var _format = CalendarFormat.month;
    var _diaSelecionado = _agora;
    var _diaEmFoco = _agora;

    /// Notificador para calendário
    final ValueNotifier<Map<DateTime, String>> _meusEventos = ValueNotifier({});

    /// Notificador para lista de eventos
    final ValueNotifier<DateTime> _mesCorrente =
        ValueNotifier(DateTime(_agora.year, _agora.month));

    void _setMesCorrente(DateTime dia) {
      _mesCorrente.value = DateTime(dia.year, dia.month);
    }

    bool _ehMesmoDia(DateTime dia1, DateTime dia2) {
      return (dia1.year == dia2.year) &&
          (dia1.month == dia2.month) &&
          (dia1.day == dia2.day);
    }

    return Column(
      children: [
        // Calendário
        ValueListenableBuilder<Map<DateTime, String>>(
            valueListenable: _meusEventos,
            builder: (context, eventos, _) {
              return StatefulBuilder(builder: (context, setState) {
                return TableCalendar(
                  focusedDay: _diaEmFoco,
                  firstDay: DateTime(_agora.year, _agora.month),
                  lastDay: DateTime(_agora.year, _agora.month + 6, 0),
                  onFormatChanged: (format) {
                    setState((() {
                      _format = format;
                    }));
                  },
                  onPageChanged: (diaEmFoco) {
                    setState(() {
                      _diaEmFoco = diaEmFoco;
                      _setMesCorrente(diaEmFoco);
                    });
                  },
                  onDaySelected: (diaSelecionado, diaEmFoco) {
                    setState(() {
                      _diaEmFoco = diaEmFoco;
                      _diaSelecionado = diaSelecionado;
                      _setMesCorrente(diaSelecionado);
                    });
                  },
                  selectedDayPredicate: (dia) {
                    return _ehMesmoDia(dia, _diaSelecionado);
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
                  locale: 'pt_BR',
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarFormat: _format,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Mês',
                    CalendarFormat.twoWeeks: 'Quinzena',
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
                        border: Border.fromBorderSide(
                          BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1.4),
                        ),
                        shape: BoxShape.circle),
                    todayTextStyle:
                        TextStyle(color: Theme.of(context).colorScheme.primary),
                    selectedDecoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.75),
                        border: Border.fromBorderSide(
                          BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1.4),
                        ),
                        shape: BoxShape.circle),
                    holidayDecoration: const BoxDecoration(
                        border: Border.fromBorderSide(
                            BorderSide(color: Colors.orange, width: 1.4)),
                        shape: BoxShape.circle),
                    holidayTextStyle: const TextStyle(color: Colors.orange),
                    markerDecoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).colorScheme.primary),
                  ),
                );
              });
            }),
        const Divider(height: 1),
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
              // Espaço em branco
              const Expanded(child: SizedBox()),
              // Botão criar novo registro de culto
              (logado.adm || logado.ehRecrutador)
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
                        var dataInicial = DateTime(_diaSelecionado.year,
                            _diaSelecionado.month, _diaSelecionado.day, 9, 30);
                        var culto = Culto(
                          dataCulto: Timestamp.fromDate(dataInicial),
                          igreja: Global.igrejaSelecionada.value!.reference,
                        );
                        Dialogos.editarCulto(context, culto);
                      })
                  : const SizedBox(),
            ],
          ),
        ),
        const Divider(height: 1),
        // Listas
        Expanded(
          child: Column(children: [
            // Lista de Aniversários
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              height: kToolbarHeight,
              child: StreamBuilder<QuerySnapshot<Integrante>>(
                  stream:
                      MeuFirebase.obterListaIntegrantes(ativo: true).asStream(),
                  builder: (context, snapshot) {
                    _meusEventos.value
                        .removeWhere((key, value) => value == 'aniversario');
                    if (snapshot.hasData) {
                      var integrantes = snapshot.data!.docs;
                      return ValueListenableBuilder<DateTime>(
                        valueListenable: _mesCorrente,
                        builder: (context, dataMin, _) {
                          List<QueryDocumentSnapshot<Integrante>>
                              aniversariantes = [];
                          aniversariantes.addAll(integrantes.where((element) =>
                              element.data().dataNascimento?.toDate().month ==
                              _mesCorrente.value.month));
                          // Notificar após carregamento da interface
                          WidgetsBinding.instance?.addPostFrameCallback(
                              (_) => _meusEventos.notifyListeners());
                          if (aniversariantes.isEmpty) {
                            return Center(
                              child: Text(
                                  'Nenhum aniversariante em ${DateFormat.MMMM('pt_BR').format(_mesCorrente.value)}'),
                            );
                          }
                          return ListView(
                              scrollDirection: Axis.horizontal,
                              children: List.generate(aniversariantes.length,
                                      (index) {
                                var dn = aniversariantes[index]
                                    .data()
                                    .dataNascimento
                                    ?.toDate();
                                var data = '';
                                if (dn != null) {
                                  dn = DateTime(
                                      DateTime.now().year, dn.month, dn.day);
                                  data = DateFormat.Md('pt_BR').format(dn);
                                  _meusEventos.value
                                      .putIfAbsent(dn, () => 'aniversario');
                                }
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: RawChip(
                                    label: Text(data),
                                    avatar: Hero(
                                      tag: 'aniversariante',
                                      child: CircleAvatar(
                                        child: Text(
                                            MyStrings.getUserInitials(
                                                aniversariantes[index]
                                                    .data()
                                                    .nome),
                                            textScaleFactor: 0.6),
                                        foregroundImage:
                                            MyNetwork.getImageFromUrl(
                                                    aniversariantes[index]
                                                        .data()
                                                        .fotoUrl)
                                                ?.image,
                                      ),
                                    ),
                                    onPressed: () => Modular.to.pushNamed(
                                        '${AppRotas.PERFIL}?id=${aniversariantes[index].id}&hero=aniversariante',
                                        arguments: aniversariantes[index]),
                                  ),
                                );
                              }, growable: false)
                                  .toList());
                        },
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  }),
            ),
            const Divider(height: 1),
            // Lista de Cultos
            Expanded(
              child: StreamBuilder<QuerySnapshot<Culto>>(
                  stream: MeuFirebase.escutarCultos(
                      dataMinima: Timestamp.fromDate(_agora),
                      igreja: Global.igrejaSelecionada.value?.reference),
                  builder: (context, snapshot) {
                    _meusEventos.value
                        .removeWhere((key, value) => value == 'culto');
                    if (snapshot.hasData) {
                      return ValueListenableBuilder<DateTime>(
                          valueListenable: _mesCorrente,
                          builder: (context, data, _) {
                            var cultos = snapshot.data!.docs
                                .where((element) =>
                                    element.data().dataCulto.toDate().year ==
                                        data.year &&
                                    element.data().dataCulto.toDate().month ==
                                        data.month)
                                .toList();
                            // Notificar após carregamento da interface
                            WidgetsBinding.instance?.addPostFrameCallback(
                                (_) => _meusEventos.notifyListeners());
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
                              _meusEventos.value
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
    );
    // FIM
  }
}
