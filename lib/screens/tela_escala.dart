import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/models/igreja.dart';
import 'package:flutter/material.dart';

import '../global.dart';
import '/functions/metodos.dart';
import '/models/culto.dart';
import '/screens/escalas/view_culto.dart';

class TelaEscala extends StatefulWidget {
  const TelaEscala({Key? key}) : super(key: key);

  @override
  State<TelaEscala> createState() => _TelaEscalaState();
}

class _TelaEscalaState extends State<TelaEscala> with TickerProviderStateMixin {
  /// Lista de cultos
  final List<DocumentSnapshot<Culto>> _listaCultos = [];

  /* VARIÁVEIS */
  late TabController _tabController;

  /* SISTEMA */
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot<Culto>>(
        future: FirebaseFirestore.instance
            .collection(Culto.collection)
            //.where('dataCulto', isGreaterThanOrEqualTo: dataMinima)
            //.where('igreja', isEqualTo: Global.igrejaAtual!.reference)
            .orderBy('dataCulto')
            .withConverter<Culto>(
              fromFirestore: (snapshot, _) => Culto.fromJson(snapshot.data()!),
              toFirestore: (model, _) => model.toJson(),
            )
            .get(),
        builder: ((context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
                child: Text('Falha! Comunicar o desenvolvedor.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          _listaCultos.clear();
          for (var snap in snapshot.data!.docs) {
            _listaCultos.add(snap);
          }
          _tabController =
              TabController(length: snapshot.data?.size ?? 0, vsync: this);
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                    (index) => ViewCulto(culto: _listaCultos[index].reference),
                    growable: false,
                  ).toList(),
                ),
              ),
            ],
          );
        }));
  }
}
