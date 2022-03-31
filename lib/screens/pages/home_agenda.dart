import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '/functions/metodos_firebase.dart';
import '/global.dart';
import '/models/culto.dart';
import '/models/integrante.dart';
import '/rotas.dart';
import '/screens/views/dialogos.dart';
import '/utils/mensagens.dart';
import '/utils/utils.dart';

class TelaAgenda extends StatelessWidget {
  const TelaAgenda({Key? key}) : super(key: key);
  static final ValueNotifier<DateTime> _dataSelecionada =
      ValueNotifier(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<Map<DateTime, String>> meusEventos = ValueNotifier({});
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    var _dataCorrente = DateTime.now();
    var _dataFoco = DateTime(_dataCorrente.year, _dataCorrente.month);
    var _dataMin = DateTime(_dataFoco.year, _dataFoco.month);
    var _dataMax = DateTime(_dataFoco.year, _dataFoco.month + 6, 0);
    CalendarFormat format = CalendarFormat.month;

    final ValueNotifier<DateTime> mesCorrente =
        ValueNotifier(DateTime(_dataCorrente.year, _dataCorrente.month));

    return Column(
      children: [
        // Calendário
        ValueListenableBuilder<Map<DateTime, String>>(
            valueListenable: meusEventos,
            builder: (context, datas, _) {
              return StatefulBuilder(builder: ((context, setState) {
                return TableCalendar(
                  focusedDay: _dataFoco,
                  firstDay: _dataMin,
                  lastDay: _dataMax,
                  currentDay: _dataCorrente,
                  locale: 'pt_BR',
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarFormat: format,
                  calendarStyle: CalendarStyle(
                    todayDecoration: const BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    weekendTextStyle: TextStyle(
                        color: Theme.of(context).colorScheme.secondary),
                    outsideTextStyle:
                        TextStyle(color: Colors.grey.withOpacity(0.5)),
                    markerDecoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).colorScheme.primary),
                    holidayDecoration: const BoxDecoration(
                      border: Border.fromBorderSide(
                        BorderSide(color: Colors.amber, width: 1.4),
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Mês',
                    CalendarFormat.twoWeeks: 'Quinzena',
                  },
                  onFormatChanged: (value) {
                    setState((() {
                      format = value;
                    }));
                  },
                  onDaySelected: (data1, data2) {
                    setState(() {
                      _dataFoco = DateTime(data1.year, data1.month);
                      _dataCorrente = data1;
                      _dataSelecionada.value = _dataCorrente;
                    });
                  },
                  holidayPredicate: (data) {
                    var isAniversario = false;
                    datas.entries
                        .where((element) => element.value == 'aniversario')
                        .forEach((element) {
                      isAniversario = (element.key.day == data.day &&
                          element.key.month == data.month);
                    });
                    return isAniversario;
                  },
                  onPageChanged: (data) {
                    mesCorrente.value = DateTime(data.year, data.month);
                  },
                  eventLoader: (data) {
                    List cultos = [];
                    datas.entries
                        .where((element) => element.value == 'culto')
                        .forEach((element) {
                      if (element.key.isAfter(data) &&
                          element.key.isBefore(
                            data.add(
                              const Duration(days: 1),
                            ),
                          )) {
                        cultos.add(element.value);
                      }
                    });
                    return cultos;
                  },
                );
              }));
            }),
        const Divider(height: 1),
        // Linha com legenda e botão de criação de culto
        Container(
          color: Colors.grey.withOpacity(0.25),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              // Legenda
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
              Container(
                margin: const EdgeInsets.only(right: 4),
                decoration: const BoxDecoration(
                  border: Border.fromBorderSide(
                    BorderSide(color: Colors.amber, width: 1.4),
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
              ActionChip(
                  avatar: const Icon(Icons.add_circle),
                  label: const Text('Culto'),
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
                    var culto = Culto(
                      dataCulto: Timestamp.fromDate(_dataSelecionada.value),
                      igreja: Global.igrejaSelecionada.value!.reference,
                    );
                    Dialogos.editarCulto(context, culto);
                  }),
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
                    if (snapshot.hasData) {
                      var integrantes = snapshot.data!.docs;
                      return ValueListenableBuilder<DateTime>(
                        valueListenable: mesCorrente,
                        builder: (context, dataMin, _) {
                          List<QueryDocumentSnapshot<Integrante>>
                              aniversariantes = [];
                          aniversariantes.addAll(integrantes.where((element) =>
                              element.data().dataNascimento?.toDate().month ==
                              mesCorrente.value.month));
                          if (aniversariantes.isEmpty) {
                            return Center(
                              child: Text(
                                  'Nenhum aniversariante em ${DateFormat.MMMM('pt_BR').format(mesCorrente.value)}'),
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
                                  dn = DateTime(DateTime.now().toLocal().year,
                                      dn.month, dn.day);
                                  data = DateFormat.Md('pt_BR').format(dn);
                                  meusEventos.value
                                      .putIfAbsent(dn, () => 'aniversario');
                                }
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: RawChip(
                                    label: Text(data),
                                    avatar: CircleAvatar(
                                      child: const Icon(Icons.person),
                                      foregroundImage:
                                          MyNetwork.getImageFromUrl(
                                                  aniversariantes[index]
                                                      .data()
                                                      .fotoUrl,
                                                  null)
                                              ?.image,
                                    ),
                                    onPressed: () => Modular.to.pushNamed(
                                        '/perfil?id=${aniversariantes[index].id}'),
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
                      dataMinima: Timestamp.fromDate(hoje),
                      igreja: Global.igrejaSelecionada.value?.reference),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      //var cultos = snapshot.data!.docs;

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
                                  Global.integranteLogado.value?.reference);
                              bool disponivel = culto.usuarioDisponivel(
                                  Global.integranteLogado.value?.reference);
                              bool restrito = culto.usuarioRestrito(
                                  Global.integranteLogado.value?.reference);

                              // Tile
                              return StatefulBuilder(
                                  builder: (context, innerState) {
                                return ListTile(
                                  title: Text(culto.ocasiao ?? 'Culto'),
                                  //horizontalTitleGap: 0,
                                  subtitle:
                                      Text('$dataFormatada às $horaFormatada'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      OutlinedButton.icon(
                                        label: Text(
                                          escalado
                                              ? 'Escalado'
                                              : disponivel
                                                  ? 'Disponível'
                                                  : restrito
                                                      ? 'Restrito'
                                                      : 'Indefinido',
                                          style: Theme.of(context)
                                              .textTheme
                                              .caption,
                                        ),
                                        icon: Icon(
                                          Icons.emoji_people,
                                          color: escalado
                                              ? Colors.green
                                              : disponivel
                                                  ? Colors.blue
                                                  : restrito
                                                      ? Colors.red
                                                      : Colors.grey
                                                          .withOpacity(0.5),
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
                                        onLongPress: escalado || disponivel
                                            ? () {}
                                            : () async {
                                                await MeuFirebase
                                                    .definirRestricaoParaOCulto(
                                                        cultos[index]
                                                            .reference);
                                                innerState(() {});
                                              },
                                      ),
                                      IconButton(
                                        onPressed: () => Modular.to.navigate(
                                            '${AppRotas.HOME}?escala=${cultos[index].id}'),
                                        icon: const Icon(Icons.dvr_rounded),
                                        tooltip: 'Ver detalhes',
                                      ),
                                    ],
                                  ),
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
