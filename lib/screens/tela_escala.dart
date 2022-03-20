import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/models/igreja.dart';
import 'package:flutter/material.dart';

import '/global.dart';
import '/models/culto.dart';
import '/models/instrumento.dart';
import '/models/integrante.dart';
import '/screens/escalas/view_culto.dart';

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
        igreja: Igreja(ativa: true, nome: '', alias: ''),
        ocasiao: 'EBD',
        dirigente: Integrante(ativo: true, nome: 'Jimmy Stauffer', email: ''),
        coordenador:
            Integrante(ativo: true, nome: 'Luciana Verdolin', email: ''),
        equipe: {
          Instrumento(
            ativo: true,
            nome: 'Violão',
            icone: Icons.abc,
          ): Global.integranteLogado ??
              Integrante(
                  ativo: true, nome: 'Jefferson Rodrigo de Melo', email: ''),
          Instrumento(
            ativo: true,
            nome: 'Baixo',
            icone: Icons.access_time,
          ): Integrante(ativo: true, nome: 'André', email: ''),
          Instrumento(
            ativo: true,
            nome: 'Teclado',
            icone: Icons.keyboard,
          ): Integrante(
              ativo: true, nome: 'Juliano Augusto de Souza', email: ''),
          Instrumento(
            ativo: true,
            nome: 'Voz',
            icone: Icons.mic,
          ): Integrante(ativo: true, nome: 'Suzani Sottomaior', email: ''),
          Instrumento(
                  ativo: true,
                  nome: 'Sonorização',
                  icone: Icons.surround_sound):
              Integrante(ativo: true, nome: 'Jedson Oliveira', email: ''),
        }),
    Culto(
      dataCulto: Timestamp.fromDate(DateTime(2022, 3, 13, 19, 30)),
      //dataEnsaio: Timestamp.fromDate(DateTime(2022, 3, 12, 17, 0)),
      igreja: Igreja(ativa: true, nome: '', alias: ''),
      ocasiao: 'culto vespertino',
      dirigente: Global.integranteLogado,
    ),
    Culto(
      dataCulto: Timestamp.fromDate(DateTime(2022, 3, 18, 19, 0)),
      dataEnsaio: Timestamp.fromDate(DateTime(2022, 3, 15, 14, 0)),
      igreja: Igreja(ativa: true, nome: '', alias: ''),
      ocasiao: 'Evento especial',
    ),
  ];

  /* VARIÁVEIS */
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
