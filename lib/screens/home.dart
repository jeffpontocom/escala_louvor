import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '/rotas.dart';
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
import '/screens/views/view_igrejas.dart';
import '/utils/estilos.dart';
import '/utils/mensagens.dart';
import '/utils/utils.dart';

class HomePage extends StatefulWidget {
  final String? escala;
  const HomePage({Key? key, this.escala}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /* VARIÁVEIS */
  late int _telaSelecionada;

  String get _titulo {
    switch (_telaSelecionada) {
      case 0:
        return 'Escalas do Louvor';
      case 1:
        return 'Agenda da Igreja';
      case 2:
        return 'Chat dos eventos';
      case 3:
        return 'Cânticos e Hinos';
      default:
        return 'Nenhuma tela';
    }
  }

  Widget get _corpo {
    switch (_telaSelecionada) {
      case 0:
        return TelaEscalas(id: widget.escala);
      case 1:
        return const TelaAgenda();
      case 2:
        return const TelaChat();
      case 3:
        return const TelaCanticos();
      default:
        return const Center(child: Text('Nenhuma tela selecionada'));
    }
  }

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
    _telaSelecionada = 0;
    // Its Important to place this line after runApp() otherwise
    // FlutterLocalNotificationsPlugin will not be initialize and you will get error
    Notificacoes.carregarInstancia(context);
    // Preenche igreja selecionada pela igreja preferencial
    MeuFirebase.obterSnapshotIgreja(Preferencias.igrejaAtual).then((value) {
      // Verifica se usuário logado está inscrito na igreja
      bool inscrito = Global.integranteLogado.value
              ?.data()
              ?.igrejas
              ?.map((e) => e.toString())
              .contains(value?.reference.toString()) ??
          false;
      if (inscrito) {
        Global.igrejaSelecionada.value = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Escuta alterações no usuário logado
    return ValueListenableBuilder<DocumentSnapshot<Integrante>?>(
        valueListenable: Global.integranteLogado,
        builder: (context, snapshotIntegrante, _) {
          dev.log('Integrante ID: ${Global.integranteLogado.value?.id}',
              name: 'log:home');
          // Aguardando dados do integrante
          if (snapshotIntegrante?.data() == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // Falha ao obter dados do integrante
          if (!(snapshotIntegrante?.exists ?? true)) {
            return const Scaffold(
              body: Center(child: Text('Falha: integrante não localizado!')),
            );
          }
          // Sucesso. Escutar igreja preferencial
          return ValueListenableBuilder<DocumentSnapshot<Igreja>?>(
              valueListenable: Global.igrejaSelecionada,
              builder: (context, igrejaContexto, _) {
                // Nenhuma igreja preferencial. Abrir tela de seleção
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
                // Com igreja selecionada
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
                      _titulo,
                      style: Estilo.appBarTitulo,
                    ),
                    titleSpacing: 0,
                    // Ações
                    actions: [
                      // Tela administrador
                      (snapshotIntegrante?.data()?.ehRecrutador ?? false)
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
                                  snapshotIntegrante?.data()?.fotoUrl, 12)
                              ?.image,
                        ),
                      ),
                    ],
                  ),
                  // CORPO
                  body: _corpo,
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
                          conteudo: const ViewIgrejas(),
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.church,
                            color: Colors.white,
                          ),
                          Text(
                            Global.igrejaSelecionada.value?.data()?.sigla ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0,
                            ),
                          )
                        ],
                      )),
                  floatingActionButtonLocation:
                      FloatingActionButtonLocation.endDocked,
                );
              });
        });
  }
}
