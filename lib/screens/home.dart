import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '/rotas.dart';
import '/global.dart';
import '/functions/metodos_firebase.dart';
import '/models/integrante.dart';
import '/models/igreja.dart';
import '/screens/views/view_igrejas.dart';
import '/utils/estilos.dart';
import '/utils/utils.dart';

enum Paginas { escala, agenda, chat, cantico }

class HomeInit extends StatelessWidget {
  const HomeInit({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ouvinte para integrante logado
    return StreamBuilder<DocumentSnapshot<Integrante>?>(
        stream: MeuFirebase.escutarIntegranteLogado(),
        builder: (_, logado) {
          dev.log('Home: ${logado.connectionState.name}');
          if (logado.connectionState == ConnectionState.active) {
            dev.log(
                'Firebase Integrante: ${logado.data?.data()?.nome ?? 'não logado!'}');
          }
          if (!logado.hasData) {
            if (logado.connectionState == ConnectionState.waiting) {
              return _scaffoldCarregando;
            } else {
              return _scaffoldSemIntegranteLogado;
            }
          }
          if (logado.hasError) {
            return _scaffoldSemIntegranteLogado;
          }
          Global.integranteLogado = logado.data;
          if (!(logado.data?.data()?.ativo ?? true) &&
              !(logado.data?.data()?.adm ?? true)) {
            return _scaffoldIntegranteInativo;
          }
          // Ouvinte para igreja selecionada
          return ValueListenableBuilder<DocumentSnapshot<Igreja>?>(
              valueListenable: Global.igrejaSelecionada,
              child: _scaffoldSemIgrejaSelecionada,
              builder: (context, igreja, child) {
                if (igreja == null) {
                  return child!;
                }
                // Verifica se usuário logado está inscrito na igreja
                bool inscrito = logado.data
                        ?.data()
                        ?.igrejas
                        ?.map((e) => e.toString())
                        .contains(igreja.reference.toString()) ??
                    false;
                if (!inscrito) {
                  return child!;
                }
                // Scaffold
                dev.log('Igreja alterada!');
                return HomePage(
                    key: Key(igreja.id), logado: logado.data!, igreja: igreja);
                //_scaffold(logado.data!, igreja);
              });
        });
  }

  Widget get _scaffoldCarregando {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gif de carregamento
            Image.asset('assets/icons/ic_launcher.png', width: 64, height: 64),
            const SizedBox(height: 24),
            // Texto de carregamento
            const Text('Carregando dados do usuário...',
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget get _scaffoldSemIntegranteLogado {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            // Icone de erro
            Icon(Icons.error, color: Colors.red, size: 64),
            SizedBox(height: 24),
            // Texto de carregamento
            Text(
              'Falha ao carregar dados do usuário.\nFeche o aplicativo e tente novamente.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget get _scaffoldIntegranteInativo {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icone de erro
            Flexible(
              child: Image.asset(
                'assets/images/login.png',
                width: 160,
                height: 160,
                color: Colors.orange,
                colorBlendMode: BlendMode.modulate,
              ),
            ),
            const SizedBox(height: 24),
            // Texto de carregamento
            const Text(
              'Seu cadastro está inativo!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text(
              'Fale com o administrador do sistema para solucionar o problema.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FutureBuilder<QuerySnapshot<Integrante>>(
                future: MeuFirebase.obterListaIntegrantesAdministradores(),
                builder: (context, snap) {
                  var whats = snap.data?.docs.first.data().telefone;
                  return ElevatedButton.icon(
                    onPressed: whats == null
                        ? null
                        : () => MyActions.openWhatsApp(whats),
                    label: const Text('Chamar no whats'),
                    icon: const Icon(Icons.whatsapp),
                    style: ElevatedButton.styleFrom(primary: Colors.green),
                  );
                }),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Modular.to.navigate(AppRotas.LOGIN);
              },
              label: const Text('Sair'),
              icon: const Icon(Icons.logout),
              style: ElevatedButton.styleFrom(primary: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

Widget get _scaffoldSemIgrejaSelecionada {
  return Scaffold(
    body: SafeArea(
      child: Column(
        children: const [
          Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Selecionar igreja ou local',
              style: TextStyle(fontSize: 22),
            ),
          ),
          Expanded(
            child: Center(child: ViewIgrejas()),
          ),
          Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Versão do app: ${Global.appVersion}',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.logado, required this.igreja})
      : super(key: key);

  final DocumentSnapshot<Integrante> logado;
  final DocumentSnapshot<Igreja> igreja;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int paginaSelecionada = 0;

  List<String> titulos = const [
    'Escalas do Louvor',
    'Agenda da Igreja',
    'Chat dos eventos',
    'Cânticos e Hinos',
    'Nenhuma tela',
  ];

  int setPage(String rota) {
    rota = rota.substring(1, rota.contains('?') ? rota.indexOf('?') : null);
    dev.log(rota, name: 'log:Rota');
    dev.log(widget.igreja.id, name: 'log:Rota');
    try {
      var index = Paginas.values.byName(rota).index;
      return index;
    } catch (e) {
      return 0;
    }
  }

  final List<BottomNavigationBarItem> _navigationItens = const [
    BottomNavigationBarItem(icon: Icon(Icons.access_time), label: 'Escalas'),
    BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Agenda'),
    BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
    BottomNavigationBarItem(icon: Icon(Icons.music_note), label: 'Cânticos'),
    BottomNavigationBarItem(icon: SizedBox(), label: '')
  ];

  @override
  void initState() {
    paginaSelecionada = setPage(Modular.routerDelegate.path);
    Modular.routerDelegate.addListener(() {
      setState(() {
        paginaSelecionada = setPage(Modular.routerDelegate.path);
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    Modular.routerDelegate.removeListener(() {
      setState(() {
        paginaSelecionada = setPage(Modular.routerDelegate.path);
      });
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Ícone da aplicação
        leading: Padding(
          padding: const EdgeInsets.all(12),
          child: Image.asset('assets/icons/ic_launcher.png'),
        ),
        // Título da aplicação
        title: Text(
          titulos[paginaSelecionada],
          style: Estilo.appBarTitulo,
        ),
        titleSpacing: 0,
        // Ações
        actions: [
          // Tela administrador
          (widget.logado.data()?.adm ?? false)
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
                      widget.logado.data()?.fotoUrl,
                      progressoSize: 12)
                  ?.image,
            ),
          ),
        ],
      ),
      // CORPO
      //body: paginas[paginaSelecionada],
      body: const RouterOutlet(),
      // NAVIGATION BAR
      bottomNavigationBar: BottomNavigationBar(
        items: _navigationItens,
        currentIndex: paginaSelecionada,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey.withOpacity(0.5),
        type: BottomNavigationBarType.shifting,
        onTap: (index) {
          if (index == 4) return;
          Modular.to.navigate('/${Paginas.values[index].name}');
          /* setState(() {
            }); */
        },
      ),
      // FLOAT ACTION
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
                context: context,
                builder: (context) {
                  return _scaffoldSemIgrejaSelecionada;
                });
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
                  fontFamily: 'Offside',
                  letterSpacing: 0,
                ),
              )
            ],
          )),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}
