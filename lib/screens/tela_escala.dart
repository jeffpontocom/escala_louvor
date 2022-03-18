import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/screens/escalas/view_culto.dart';
import 'package:flutter/material.dart';

import '../models/culto.dart';

class TelaEscala extends StatefulWidget {
  const TelaEscala({Key? key}) : super(key: key);

  @override
  State<TelaEscala> createState() => _TelaEscalaState();
}

class _TelaEscalaState extends State<TelaEscala> with TickerProviderStateMixin {
  /// PARA PROPOSITO DE TESTES
  final List<Culto> _listaCultos = [
    Culto(
      dataCulto: Timestamp.fromDate(DateTime(2022, 3, 13, 9, 0)),
      dataEnsaio: Timestamp.fromDate(DateTime(2022, 3, 13, 8, 15)),
      ocasiao: 'EBD',
    ),
    Culto(
      dataCulto: Timestamp.fromDate(DateTime(2022, 3, 13, 19, 30)),
      //dataEnsaio: Timestamp.fromDate(DateTime(2022, 3, 12, 17, 0)),
      ocasiao: 'culto vespertino',
    ),
    Culto(
      dataCulto: Timestamp.fromDate(DateTime(2022, 3, 18, 19, 0)),
      dataEnsaio: Timestamp.fromDate(DateTime(2022, 3, 15, 14, 0)),
      ocasiao: 'Evento especial',
    ),
  ];

  /* VARIAVEIS */
  late TabController _tabController;

  /* SISTEMA */
  @override
  Widget build(BuildContext context) {
    _tabController = TabController(length: _listaCultos.length, vsync: this);
    return Column(
      children: [
        // Controle de acesso aos cultos cadastrados
        Row(
          children: [
            const SizedBox(width: 12),
            // Butão de ação para selecionar o culto desejado
            ActionChip(
              label: const Text('Ir para'),
              avatar: const Icon(Icons.date_range),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              visualDensity: VisualDensity.compact,
              onPressed: () {},
            ),
            const SizedBox(width: 8),
            // Controle de paginação
            Expanded(
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorSize: TabBarIndicatorSize.label,
                indicator: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.grey.shade300,
                tabs: List.generate(
                  _listaCultos.length,
                  (index) => const Tab(icon: Icon(Icons.circle, size: 6)),
                  growable: false,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
        // Informações específicas sobre o culto
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: List.generate(
              _listaCultos.length,
              (index) => ViewCulto(culto: _listaCultos[index]),
              growable: false,
            ).toList(),
          ),
        ),
      ],
    );
  }
}
