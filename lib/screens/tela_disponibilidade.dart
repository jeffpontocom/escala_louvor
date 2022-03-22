import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/functions/metodos.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/culto.dart';

class TelaAgenda extends StatelessWidget {
  const TelaAgenda({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<Map<String, DateTime>> meusEventos = ValueNotifier({});
    var _dataFoco = DateTime.now();
    var _dataCorrente = DateTime.now();
    var _dataMin = DateTime(_dataFoco.year, _dataFoco.month, 1);
    var _dataMax = _dataFoco.month + 6 <= 12
        ? DateTime(_dataFoco.year, _dataFoco.month + 6, 31)
        : DateTime(_dataFoco.year + 1, _dataFoco.month - 6, 31);
    CalendarFormat format = CalendarFormat.twoWeeks;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text('Legenda ${_dataFoco.toLocal()}'),
              ),
            ),
            // Botão criar novo registro de culto
            const IconButton(onPressed: null, icon: Icon(Icons.add_circle)),
          ],
        ),
        const Divider(height: 1),
        // Calendário
        ValueListenableBuilder<Map<String, DateTime>>(
            valueListenable: meusEventos,
            builder: (context, datas, _) {
              return StatefulBuilder(builder: ((context, setState) {
                return TableCalendar(
                  focusedDay: _dataFoco,
                  firstDay: _dataMin,
                  lastDay: _dataMax,
                  currentDay: _dataCorrente,
                  locale: 'pt_BR',
                  calendarFormat: format,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Mês',
                    CalendarFormat.twoWeeks: '2 semanas',
                  },
                  eventLoader: (data) {
                    return datas.values
                        .where(
                          (element) =>
                              element.isAfter(data) &&
                              element.isBefore(
                                data.add(const Duration(days: 1)),
                              ),
                        )
                        .toList();
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
                );
              }));
            }),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            children: [
              // Lista de Cultos
              StreamBuilder<QuerySnapshot<Culto>>(
                  stream: Metodo.escutarCultos(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      for (var snap in snapshot.data!.docs) {
                        meusEventos.value.putIfAbsent(
                            'culto', () => snap.data().dataCulto.toDate());
                      }
                    }
                    return ListView(
                        shrinkWrap: true,
                        children: List.generate(
                            2,
                            (index) => ListTile(
                                  title: Text('Teste $index'),
                                )).toList());
                  }),
              const Divider(height: 1),
              // Lista de Aniversarios
              StreamBuilder(builder: (context, snapshot) {
                return ListView(
                    shrinkWrap: true,
                    children: List.generate(
                        2,
                        (index) => ListTile(
                              title: Text('Aniversariante $index'),
                            )).toList());
              }),
            ],
          ),
        ),
      ],
    );
  }
}
