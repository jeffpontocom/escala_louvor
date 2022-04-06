import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/functions/metodos_firebase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';

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
          // Falha ao obter lista de cultos
          if (snapshot.hasError) {
            return const Center(
                child: Text('Falha! Comunicar o desenvolvedor.'));
          }
          // Carregando lista de cultos
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          // Adicionado cultos encontrados
          _listaCultos.clear();
          for (var snap in snapshot.data!.docs) {
            _listaCultos.add(snap);
          }
          // Interface vazia
          if (_listaCultos.isEmpty) {
            return Padding(
                padding: const EdgeInsets.all(64),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logotipo
                    const Image(
                      image: AssetImage('assets/images/church.png'),
                      height: 256,
                      width: 256,
                    ),
                    // Informação
                    const Text(
                      'Nenhuma agenda para\n',
                      textAlign: TextAlign.center,
                    ),
                    // Igreja
                    Text(
                      Global.igrejaSelecionada.value?.data()?.nome ?? '',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ));
          }
          // Controlador de abas
          _tabController =
              TabController(length: snapshot.data?.size ?? 0, vsync: this);
          if (widget.id != null) {
            var index =
                _listaCultos.indexWhere((element) => element.id == widget.id);
            if (index != -1) {
              _tabController.animateTo(index);
            }
          }
          // Interface preenchida
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
    String logadoRef = Global.integranteLogado!.reference.toString();
    return ListView(
      shrinkWrap: true,
      children: List.generate(
        _tabController.length,
        (index) {
          Culto culto = _listaCultos[index].data()!;
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            trailing: Text(culto.ocasiao ?? ''),
            title: Text(
                DateFormat.MMMMEEEEd('pt_BR').format(culto.dataCulto.toDate())),
            subtitle:
                Text(DateFormat.Hm('pt_BR').format(culto.dataCulto.toDate())),
            leading: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: (culto.equipe?.values
                                .toList()
                                .map((e) => e.toString())
                                .contains(logadoRef) ??
                            false) ||
                        (culto.dirigente.toString() == logadoRef) ||
                        (culto.coordenador.toString() == logadoRef)
                    ? Colors.green
                    : (culto.disponiveis?.map((e) => e.toString()).contains(
                                Global.integranteLogado?.reference
                                    .toString()) ??
                            false)
                        ? Colors.blue
                        : (culto.restritos?.map((e) => e.toString()).contains(
                                    Global.integranteLogado?.reference
                                        .toString()) ??
                                false)
                            ? Colors.red
                            : Colors.grey.withOpacity(0.5),
              ),
              width: 16,
              height: 16,
            ),
            onTap: () {
              // fecha o bottomDialog
              Modular.to.pop();
              // vai até a pagina selecionada
              _tabController.animateTo(
                index,
                duration: const Duration(milliseconds: 600),
              );
            },
          );
        },
      ),
    );
  }
}
