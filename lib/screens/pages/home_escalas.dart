import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/functions/metodos_firebase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '/global.dart';
import '/models/culto.dart';
import '/screens/views/view_culto.dart';
import '/utils/mensagens.dart';
import '/utils/utils.dart';

class TelaEscalas extends StatefulWidget {
  final String? id;
  const TelaEscalas({Key? key, this.id}) : super(key: key);

  @override
  State<TelaEscalas> createState() => _TelaEscalasState();
}

class _TelaEscalasState extends State<TelaEscalas>
    with TickerProviderStateMixin {
  /// Lista de cultos
  final List<DocumentSnapshot<Culto>> _listaCultos = [];

  /* VARIÁVEIS */
  late TabController _tabController;
  late Timestamp _hoje;

  /* SISTEMA */

  @override
  void initState() {
    var agora = DateTime.now();
    _hoje = Timestamp.fromDate(
        DateTime(agora.year, agora.month, agora.day).toUtc());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot<Culto>>(
        future: MeuFirebase.obterListaCultos(
            igreja: Global.igrejaSelecionada.value?.reference,
            dataMinima: _hoje),
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
          if (_listaCultos.isEmpty) {
            return Center(
              child: Text(
                'Nenhuma agenda para\n\n${Global.igrejaSelecionada.value?.data()?.nome ?? ''}',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            );
          }
          _tabController =
              TabController(length: snapshot.data?.size ?? 0, vsync: this);
          if (widget.id != null) {
            var index =
                _listaCultos.indexWhere((element) => element.id == widget.id);
            if (index != -1) {
              _tabController.animateTo(index);
            }
          }
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
                    onPressed: () {
                      Mensagem.bottomDialog(
                        context: context,
                        titulo: 'Ir para',
                        conteudo: _listaDeCultos,
                      );
                    },
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
                      labelPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 0),
                      tabs: List.generate(
                        _listaCultos.length,
                        (index) => const Tab(
                          icon: Icon(Icons.circle, size: 6),
                        ),
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
                    (index) {
                      return ViewCulto(
                          key: LabeledGlobalKey(_listaCultos[index].id),
                          culto: _listaCultos[index].reference);
                    },
                    growable: false,
                  ).toList(),
                ),
              ),
            ],
          );
        }));
  }

  Widget get _listaDeCultos {
    return Scrollbar(
      isAlwaysShown: true,
      child: OrientationBuilder(
        builder: (context, orientation) {
          return ListView(
            shrinkWrap: true,
            children: List.generate(
              _tabController.length,
              (index) {
                return TextButton(
                  onPressed: () {
                    // fecha o bottomDialog
                    Modular.to.pop();
                    // vai até a pagina selecionada
                    _tabController.animateTo(
                      index,
                      duration: const Duration(milliseconds: 600),
                    );
                  },
                  child: Text(MyInputs.mascaraData
                      .format(_listaCultos[index].data()!.dataCulto.toDate())),
                );
              },
            ),
          );
        },
      ),
    );
  }
}