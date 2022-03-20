import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class TelaAgenda extends StatelessWidget {
  const TelaAgenda({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var _hoje = DateTime.now();
    var _min = DateTime(_hoje.year, _hoje.month, 1);
    var _max = _hoje.month + 6 <= 12
        ? DateTime(_hoje.year, _hoje.month + 6, 31)
        : DateTime(_hoje.year + 1, _hoje.month - 6, 31);
    return TableCalendar(
      focusedDay: _hoje,
      firstDay: _min,
      lastDay: _max,
      locale: 'pt_BR',
    );
  }
}
