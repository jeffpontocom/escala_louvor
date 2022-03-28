import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'models/integrante.dart';
import 'preferencias.dart';
import 'global.dart';
import 'models/igreja.dart';
import 'functions/notificacoes.dart';
import 'functions/metodos.dart';
import 'screens/tela_agenda.dart';
import 'screens/tela_canticos.dart';
import 'screens/tela_chat.dart';
import 'screens/tela_escala.dart';
import 'utils/estilos.dart';
import 'utils/mensagens.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /* VARIÁVEIS */
  int _telaSelecionada = 0;

  /// Lista de Telas
  final List _telas = [
    {'titulo': 'Escala do Louvor', 'tela': const TelaEscala()},
    {'titulo': 'Minhas escalas', 'tela': const TelaAgenda()},
    {'titulo': 'Chat dos eventos', 'tela': const TelaChat()},
    {'titulo': 'Todos os cânticos', 'tela': const TelaCanticos()},
  ];

  /* WIDGETS */

  /// Bottom NavigationBar Itens
  final List<BottomNavigationBarItem> _navigationItens = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.access_time),
      label: 'Escalas',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.calendar_month),
      label: 'Agenda',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.chat),
      label: 'Chat',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.music_note),
      label: 'Cânticos',
    ),
    const BottomNavigationBarItem(
      icon: SizedBox(),
      label: '',
    )
  ];

  /* SISTEMA */

  @override
  void initState() {
    super.initState();
    // Its Important to place this line after runApp() otherwise
    // FlutterLocalNotificationsPlugin will not be initialize and you will get error
    Notificacoes.carregarInstancia(context);
  }

  @override
  Widget build(BuildContext context) {
    dev.log('HOME PAGE Build');
    return StreamBuilder<DocumentSnapshot<Integrante>?>(
        stream: FirebaseFirestore.instance
            .collection(Integrante.collection)
            .doc(Global.auth.currentUser?.uid)
            .withConverter<Integrante>(
                fromFirestore: (snapshot, _) =>
                    Integrante.fromJson(snapshot.data()!),
                toFirestore: (pacote, _) => pacote.toJson())
            .get()
            .asStream(),
        builder: (_, snapshotIntegrante) {
          Global.integranteLogado = snapshotIntegrante.data;
          dev.log('Integrante ID: ${Global.integranteLogado?.id}');
          if (!snapshotIntegrante.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshotIntegrante.hasError) {
            return const Center(
                child: Text('Falha: integrante não localizado!'));
          }
          return Scaffold(
            // APP BAR
            appBar: AppBar(
              // Ícone da aplicação
              leading: Padding(
                padding: const EdgeInsets.all(12),
                child: Image.asset('assets/icons/ic_launcher.png'),
              ),
              // Título da aplicação
              title: Text(
                _telas[_telaSelecionada]['titulo'],
                style: Estilo.appBarTitulo,
              ),
              titleSpacing: 0,
              // Ações
              actions: [
                // Tela administrador
                IconButton(
                  onPressed: () => Modular.to.pushNamed('/admin'),
                  icon: const Icon(Icons.admin_panel_settings),
                ),
                // Tela perfil do usuário
                IconButton(
                  onPressed: () => Modular.to.pushNamed(
                      '/perfil?id=${Global.auth.currentUser?.uid ?? ''}'),
                  icon: CircleAvatar(
                    child: const Icon(Icons.person),
                    foregroundImage: MyNetwork.getImageFromUrl(
                            Global.integranteLogado?.data()?.fotoUrl, 12)
                        ?.image,
                  ),
                ),
              ],
            ),
            // CORPO
            body: _telas[_telaSelecionada]['tela'],
            // NAVIGATION BAR
            bottomNavigationBar: BottomNavigationBar(
              items: _navigationItens,
              currentIndex: _telaSelecionada,
              selectedItemColor: Colors.blue,
              unselectedItemColor: Colors.grey.withOpacity(0.5),
              type: BottomNavigationBarType.shifting,
              onTap: (index) {
                if (index == 4) return;
                setState(() {
                  _telaSelecionada = index;
                });
              },
            ),
            // FLOAT ACTION
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Mensagem.bottomDialog(
                  context: context,
                  titulo: 'Selecionar igreja ou local',
                  conteudo: _igrejas,
                );
              },
              child: const Icon(Icons.church),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.endDocked,
          );
        });
  }

  void _refresh() {
    setState(() {});
  }

  Widget get _igrejas {
    return FutureBuilder<QuerySnapshot<Igreja>>(
        future: Metodo.getIgrejas(ativo: true),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
              heightFactor: 4,
            );
          }
          var igrejas = snapshot.data?.docs;
          return Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 24),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: List.generate(igrejas?.length ?? 0, (index) {
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    color: igrejas?[index].reference.toString() ==
                            Global.igrejaAtual?.reference.toString()
                        ? Colors.amber.withOpacity(0.5)
                        : null,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.withOpacity(0.5)),
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                    ),
                    child: InkWell(
                      radius: 16,
                      customBorder: const RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.all(
                          Radius.circular(16),
                        ),
                      ),
                      onTap: () async {
                        Mensagem.aguardar(context: context);
                        String? id = igrejas?[index].reference.id;
                        Preferencias.igrejaAtual = id;
                        Global.igrejaAtual =
                            await Metodo.obterSnapshotIgreja(id);
                        Modular.to.pop(); // fecha progresso
                        Modular.to.pop(); // fecha dialog
                        setState(() {});
                        _refresh();
                      },
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Foto da igreja
                            SizedBox(
                              height: 150,
                              child: MyNetwork.getImageFromUrl(
                                      igrejas?[index].data().fotoUrl, null) ??
                                  const Center(child: Icon(Icons.church)),
                            ),
                            // Sigla
                            const SizedBox(height: 8),
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  igrejas?[index].data().sigla.toUpperCase() ??
                                      '',
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                )),

                            // Nome
                            const SizedBox(height: 4),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(igrejas?[index].data().nome ?? ''),
                            ),
                            const SizedBox(height: 12),
                          ]),
                    ),
                  ),
                );
              }, growable: false)
                  .toList(),
            ),
          );
        });
  }
}
