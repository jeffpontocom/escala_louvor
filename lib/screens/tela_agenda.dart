import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../preferencias.dart';
import '/functions/metodos.dart';
import '/global.dart';
import '/models/culto.dart';
import '/models/igreja.dart';
import '/models/integrante.dart';
import '/utils/mensagens.dart';

class TelaAgenda extends StatelessWidget {
  const TelaAgenda({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<Map<DateTime, String>> meusEventos = ValueNotifier({});
    var _dataFoco = DateTime.now();
    var _dataCorrente = DateTime.now();
    var _dataMin = DateTime(_dataFoco.year, _dataFoco.month, 1);
    var _dataMax = _dataFoco.month + 6 <= 12
        ? DateTime(_dataFoco.year, _dataFoco.month + 6, 31)
        : DateTime(_dataFoco.year + 1, _dataFoco.month - 6, 31);
    CalendarFormat format = CalendarFormat.month;

    final ValueNotifier<DateTime> mesCorrente =
        ValueNotifier(DateTime(_dataCorrente.year, _dataCorrente.month));

    void _dialogNovoCulto() async {
      if (Global.igrejaAtual == null) {
        // TODO: Utilizar a mesma interface do floatbutton em Home
        Mensagem.bottomDialog(
          context: context,
          titulo: 'Selecione uma igreja',
          conteudo: StreamBuilder<QuerySnapshot<Igreja>>(
              stream: Metodo.escutarIgrejas(ativos: true),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                    heightFactor: 4,
                  );
                }
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: List.generate(
                            snapshot.data?.size ?? 0,
                            (index) => OutlinedButton.icon(
                                  onPressed: () {
                                    Preferencias.igrejaAtual =
                                        snapshot.data?.docs[index].reference.id;
                                    Modular.to.pop(); // fecha dialog
                                  },
                                  icon: CircleAvatar(
                                    child: const Icon(Icons.church),
                                    foregroundImage: NetworkImage(snapshot
                                            .data?.docs[index]
                                            .data()
                                            .fotoUrl ??
                                        ''),
                                  ),
                                  label: Text(
                                      snapshot.data?.docs[index].data().sigla ??
                                          '[erro]'),
                                  style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(96, 64)),
                                ),
                            growable: false)
                        .toList(),
                  ),
                );
              }),
        );
        return;
      }
      var novoCulto = Culto(
        dataCulto: Timestamp.fromDate(_dataCorrente),
        igreja: Global.igrejaAtual!.reference,
      );

      List<String> ocasioes = ['EBD', 'Culto vespertino', 'Evento especial'];
      return Mensagem.bottomDialog(
        context: context,
        titulo: 'Novo registro de culto',
        conteudo: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          children: [
            StatefulBuilder(builder: (_, innerState) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Igreja
                  CircleAvatar(
                    radius: 24,
                    foregroundImage: Image(
                      image: NetworkImage(
                          Global.igrejaAtual?.data()?.fotoUrl ?? ''),
                      loadingBuilder: (_, child, event) {
                        if (event?.expectedTotalBytes == null ||
                            event!.expectedTotalBytes! <
                                event.cumulativeBytesLoaded) {
                          return const CircularProgressIndicator();
                        }
                        return child;
                      },
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.church),
                      ),
                    ).image,
                  ),
                  // Data
                  ActionChip(
                    avatar: const Icon(Icons.edit_calendar),
                    label: Text(
                      DateFormat.yMEd('pt_BR')
                          .format(novoCulto.dataCulto.toDate()),
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    labelPadding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    onPressed: () async {
                      var dataPrevia = novoCulto.dataCulto.toDate();
                      showDatePicker(
                        context: context,
                        initialDate: dataPrevia,
                        firstDate: DateTime(2022),
                        lastDate: DateTime.now().add(
                          const Duration(days: 180),
                        ),
                      ).then((dia) {
                        if (dia != null) {
                          innerState(() {
                            novoCulto.dataCulto = Timestamp.fromDate(
                              DateTime(dia.year, dia.month, dia.day,
                                  dataPrevia.hour, dataPrevia.minute),
                            );
                          });
                        }
                      });
                    },
                  ),
                  // Hora
                  ActionChip(
                    avatar: const Icon(Icons.access_time_outlined),
                    label: Text(
                      DateFormat.Hm('pt_BR')
                          .format(novoCulto.dataCulto.toDate()),
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    labelPadding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    onPressed: () async {
                      var dataPrevia = novoCulto.dataCulto.toDate();
                      showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(dataPrevia))
                          .then((hora) {
                        if (hora != null) {
                          innerState(() {
                            novoCulto.dataCulto = Timestamp.fromDate(
                              DateTime(dataPrevia.year, dataPrevia.month,
                                  dataPrevia.day, hora.hour, hora.minute),
                            );
                          });
                        }
                      });
                    },
                  ),
                ],
              );
            }),
            const SizedBox(height: 12),

            // Ocasiao
            Autocomplete(
              initialValue: TextEditingValue(text: novoCulto.ocasiao ?? ''),
              optionsBuilder: (textEditingValue) {
                List<String> matches = <String>[];
                matches.addAll(ocasioes);
                matches.retainWhere((s) {
                  return s
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase());
                });
                return matches;
              },
              fieldViewBuilder: (context, controller, focus, onSubmit) {
                return TextFormField(
                  controller: controller,
                  focusNode: focus,
                  decoration: const InputDecoration(
                    labelText: 'Ocasião',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  onChanged: (value) {
                    novoCulto.ocasiao = value;
                  },
                  onFieldSubmitted: (value) => onSubmit,
                );
              },
              onSelected: (String value) {
                novoCulto.ocasiao = value;
              },
            ),

            //Obs
            TextFormField(
              initialValue: novoCulto.obs,
              minLines: 5,
              maxLines: 15,
              decoration: const InputDecoration(
                labelText: 'Observações',
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              onChanged: (value) {
                novoCulto.obs = value;
              },
            ),

            const SizedBox(height: 64),
          ],
        ),
        rodape: Row(
          children: [
            const Expanded(child: SizedBox()),
            // Botão criar
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('CRIAR'),
              onPressed: () async {
                // Abre progresso
                Mensagem.aguardar(context: context);
                // Salva os dados no firebase
                await Metodo.salvarCulto(novoCulto);
                Modular.to.pop(); // Fecha progresso
                Modular.to.pop(); // Fecha dialog
              },
            ),
          ],
        ),
      );
    }

    return Column(children: [
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
                    _dataFoco = data1;
                    _dataCorrente = data1;
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
                  mesCorrente.value = data;
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
        color: Colors.amber.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // Legenda
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12), color: Colors.black),
              width: 8,
              height: 8,
            ),
            const Text('Cultos'),
            const SizedBox(width: 12),
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.amber,
              ),
              width: 8,
              height: 8,
            ),
            const Text('Aniversários'),
            // Espaço em branco
            const Expanded(child: SizedBox()),
            // Botão criar novo registro de culto
            ActionChip(
              avatar: const Icon(Icons.add_circle),
              label: const Text('Culto'),
              onPressed: _dialogNovoCulto,
            ),
          ],
        ),
      ),
      const Divider(height: 1),
      // Listas
      Expanded(
        child: ListView(children: [
          // Lista de Aniversários
          FutureBuilder<QuerySnapshot<Integrante>>(
              future: Metodo.getIntegrantes(ativo: true),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var integrantes = snapshot.data!.docs;
                  return ListView(
                      shrinkWrap: true,
                      children:
                          List.generate(snapshot.data?.size ?? 0, (index) {
                        var dn =
                            integrantes[index].data().dataNascimento?.toDate();
                        var data = '';
                        if (dn != null) {
                          dn = DateTime(DateTime.now().year, dn.month, dn.day);
                          data = DateFormat.MEd('pt_BR').format(dn);
                          meusEventos.value
                              .putIfAbsent(dn, () => 'aniversario');
                        }
                        return ListTile(
                          leading: const Icon(
                            Icons.cake,
                            color: Colors.amber,
                          ),
                          title: Text(integrantes[index].data().nome),
                          subtitle: Text(data),
                          visualDensity: VisualDensity.compact,
                          dense: true,
                        );
                      }, growable: false)
                              .toList());
                }
                return const Center(
                  child: CircularProgressIndicator(),
                  heightFactor: 2,
                );
              }),
          const Divider(height: 1),
          // Lista de Cultos
          StreamBuilder<QuerySnapshot<Culto>>(
              stream: Metodo.escutarCultos(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var cultos = snapshot.data!.docs;
                  return ListView(
                      shrinkWrap: true,
                      children:
                          List.generate(snapshot.data?.size ?? 0, (index) {
                        var data = cultos[index].data().dataCulto.toDate();
                        var dataFormatada =
                            DateFormat.yMEd('pt_BR').format(data);
                        var horaFormatada = DateFormat.Hm('pt_BR').format(data);
                        meusEventos.value.putIfAbsent(data, () => 'culto');
                        return ValueListenableBuilder<DateTime>(
                            valueListenable: mesCorrente,
                            builder: (context, dataMin, _) {
                              if (data.isAfter(dataMin) &&
                                  data.isBefore(
                                      dataMin.add(const Duration(days: 31)))) {
                                return ListTile(
                                  leading: const Icon(Icons.event),
                                  title: Text(
                                      cultos[index].data().ocasiao ?? 'Culto'),
                                  subtitle:
                                      Text('$dataFormatada às $horaFormatada'),
                                );
                              } else {
                                return const SizedBox();
                              }
                            });
                      }, growable: false)
                              .toList());
                }
                return const Center(
                  child: CircularProgressIndicator(),
                  heightFactor: 4,
                );
              }),
        ]),
      ),
    ]);
    // FIM
  }
}