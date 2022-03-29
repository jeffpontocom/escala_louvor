import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/screens/views/view_igrejas.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../rotas.dart';
import '/global.dart';
import '/preferencias.dart';
import '/functions/notificacoes.dart';
import '/functions/metodos_firebase.dart';
import '/models/integrante.dart';
import '/models/igreja.dart';
import '/screens/pages/home_agenda.dart';
import '/screens/pages/home_canticos.dart';
import '/screens/pages/home_chats.dart';
import '/screens/pages/home_escalas.dart';
import '/utils/estilos.dart';
import '/utils/mensagens.dart';
import '/utils/utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /* VARIÁVEIS */
  int _telaSelecionada = 0;
  final ValueNotifier<Igreja?> _igrejaContexto = ValueNotifier(null);

  String get titulo {
    switch (_telaSelecionada) {
      case 0:
        return 'Escala do Louvor';
      case 1:
        return 'Minhas escalas';
      case 2:
        return 'Chat dos eventos';
      case 3:
        return 'Todos do cânticos';
      default:
        return 'Nenhuma tela';
    }
  }

  Widget get corpo {
    switch (_telaSelecionada) {
      case 0:
        // ignore: prefer_const_constructors
        return TelaEscala();
      case 1:
        // ignore: prefer_const_constructors
        return TelaAgenda();
      case 2:
        // ignore: prefer_const_constructors
        return TelaChat();
      case 3:
        // ignore: prefer_const_constructors
        return TelaCanticos();
      default:
        return const Center(child: Text('Nenhuma tela selecionada'));
    }
  }

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
    MeuFirebase.obterSnapshotIgreja(Preferencias.igrejaAtual).then((value) {
      Global.igrejaAtual = value;
      _igrejaContexto.value = value?.data();
    });
  }

  @override
  Widget build(BuildContext context) {
    dev.log('HOME PAGE Build');
    return StreamBuilder<DocumentSnapshot<Integrante>?>(
        stream: MeuFirebase.obterSnapshotIntegrante(
                FirebaseAuth.instance.currentUser?.uid)
            .asStream(),
        builder: (_, snapshotIntegrante) {
          Global.integranteLogado = snapshotIntegrante.data;
          dev.log('Integrante ID: ${Global.integranteLogado?.id}');
          // Aguardando dados do integrante
          if (!snapshotIntegrante.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // Falha ao obter dados do integrante
          if (snapshotIntegrante.hasError) {
            return const Scaffold(
              body: Center(child: Text('Falha: integrante não localizado!')),
            );
          }
          // Sucesso. Escutar Igreja em contexto
          return ValueListenableBuilder<Igreja?>(
              valueListenable: _igrejaContexto,
              builder: (context, igrejaContexto, _) {
                // Nenhum Igreja em contexto
                if (igrejaContexto == null) {
                  return Scaffold(
                    body: SafeArea(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Selecionar Igreja ou local',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          const Expanded(child: Center(child: ViewIgrejas())),
                        ],
                      ),
                    ),
                  );
                }
                // Com Igreja em contexto
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
                      titulo,
                      style: Estilo.appBarTitulo,
                    ),
                    titleSpacing: 0,
                    // Ações
                    actions: [
                      // Tela administrador
                      (snapshotIntegrante.data?.data()?.ehAdm ?? false)
                          ? IconButton(
                              onPressed: () => Modular.to.pushNamed('/admin'),
                              icon: const Icon(Icons.admin_panel_settings),
                            )
                          : const SizedBox(),
                      // Tela perfil do usuário
                      IconButton(
                        onPressed: () => Modular.to.pushNamed(
                            '${AppRotas.PERFIL}?id=${FirebaseAuth.instance.currentUser?.uid ?? ''}'),
                        icon: CircleAvatar(
                          child: const Icon(Icons.person),
                          foregroundImage: MyNetwork.getImageFromUrl(
                                  snapshotIntegrante.data?.data()?.fotoUrl, 12)
                              ?.image,
                        ),
                      ),
                    ],
                  ),
                  // CORPO
                  body: corpo,
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
        });
  }

  Widget get _igrejas {
    return FutureBuilder<QuerySnapshot<Igreja>>(
        future: MeuFirebase.obterListaIgrejas(ativo: true),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
              heightFactor: 4,
            );
          }
          var igrejas = snapshot.data?.docs;
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 24),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                // Lista
                children: List.generate(
                  igrejas?.length ?? 0,
                  (index) {
                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 150),
                      // Card da Igreja
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        color: igrejas?[index].reference.toString() ==
                                Global.igrejaAtual?.reference.toString()
                            ? Colors.amber.withOpacity(0.5)
                            : null,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.grey.withOpacity(0.5)),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(16)),
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
                                await MeuFirebase.obterSnapshotIgreja(id);
                            Modular.to.pop(); // fecha progresso
                            Modular.to.pop(); // fecha dialog
                            _igrejaContexto.value = Global.igrejaAtual?.data();
                          },
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Foto da igreja
                                SizedBox(
                                  height: 150,
                                  child: MyNetwork.getImageFromUrl(
                                          igrejas?[index].data().fotoUrl,
                                          null) ??
                                      const Center(child: Icon(Icons.church)),
                                ),
                                // Sigla
                                const SizedBox(height: 8),
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text(
                                      igrejas?[index]
                                              .data()
                                              .sigla
                                              .toUpperCase() ??
                                          '',
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                    )),

                                // Nome
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child:
                                      Text(igrejas?[index].data().nome ?? ''),
                                ),
                                const SizedBox(height: 12),
                              ]),
                        ),
                      ),
                    );
                  },
                  growable: false,
                ).toList(),
              ),
            ),
          );
        });
  }
}
