import 'dart:developer' as dev;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:upgrader/upgrader.dart';

import '../../../utils/global.dart';
import '../../rotas.dart';
import '../../../utils/utils.dart';

enum Paginas {
  agenda,
  avisos,
  canticos,
  escalas,
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  /// Notificador de pagina selecionada
  static ValueNotifier<int> paginaSelecionada = ValueNotifier(0);

  static int setPage(String rota) {
    rota = rota.substring(1, rota.contains('?') ? rota.indexOf('?') : null);
    dev.log(rota, name: 'log:Rota');
    var index = 0;
    try {
      index = Paginas.values.indexWhere((element) => element.name == rota);
    } catch (e) {
      index = 0;
    }
    paginaSelecionada.value = index < 0 ? 0 : index;
    return index < 0 ? 0 : index;
  }

  BottomNavigationBarItem navigationItem(int index) {
    if (index >= Paginas.values.length) {
      return const BottomNavigationBarItem(icon: SizedBox(), label: '');
    }
    var pagina = Paginas.values[index];
    switch (pagina) {
      case Paginas.agenda:
        return const BottomNavigationBarItem(
            icon: Icon(Icons.today), label: 'Agenda');
      case Paginas.avisos:
        return const BottomNavigationBarItem(
            icon: Icon(Icons.campaign), label: 'Avisos');
      case Paginas.canticos:
        return const BottomNavigationBarItem(
            icon: Icon(Icons.music_note), label: 'Cânticos');
      case Paginas.escalas:
        return const BottomNavigationBarItem(
            icon: Icon(Icons.timer_sharp), label: 'Escalas');
    }
  }

  @override
  void initState() {
    setPage(Modular.routerDelegate.path);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          appBar: AppBar(
            // Ícone da aplicação
            leading: Padding(
                padding: const EdgeInsets.all(12),
                child: Image.asset('assets/icons/ic_launcher.png')),
            // Título da aplicação
            title: Text(Global.nomeDoApp),
            titleSpacing: 0,
            centerTitle: false,
            // Ações
            actions: [
              // Tela administrador
              (Global.logado?.adm ?? false)
                  ? IconButton(
                      onPressed: () => Modular.to.pushNamed('/admin'),
                      icon: const Icon(Icons.admin_panel_settings),
                    )
                  : const SizedBox(),
              // Tela perfil do usuário
              IconButton(
                icon: Hero(
                  tag: 'logado',
                  child: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    foregroundImage: MyNetwork.getImageFromUrl(
                            Global.logado?.fotoUrl,
                            progressoSize: 12)
                        ?.image,
                    child:
                        const Icon(Icons.account_circle, color: Colors.white),
                  ),
                ),
                onPressed: () => Modular.to.pushNamed(
                    '${AppRotas.PERFIL}?id=${FirebaseAuth.instance.currentUser?.uid ?? ''}&hero=logado',
                    arguments: Global.logadoSnapshot),
              ),
            ],
          ),
          // CORPO
          body: UpgradeAlert(
            upgrader: Upgrader(
              //debugDisplayOnce: true,
              debugLogging: true,
              canDismissDialog: true,
              shouldPopScope: () => true,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Flex(
                direction: Axis.vertical,
                children: const [
                  // TODO: Container para aviso sem rede
                  // Conteúdo
                  Flexible(child: RouterOutlet()),
                ],
              ),
            ),
          ),

          // NAVIGATION BAR
          bottomNavigationBar: ValueListenableBuilder<int>(
            valueListenable: paginaSelecionada,
            builder: (context, pagina, _) {
              return BottomNavigationBar(
                  items: List.generate(5, (index) => navigationItem(index)),
                  currentIndex: pagina,
                  selectedItemColor: Colors.blue,
                  unselectedItemColor: Colors.grey.withOpacity(0.5),
                  type: BottomNavigationBarType.shifting,
                  onTap: (index) {
                    if (index == 4) return;
                    paginaSelecionada.value = index;
                    Modular.to.navigate('/${Paginas.values[index].name}');
                  });
            },
          ),

          // FLOAT ACTION
          floatingActionButton: FloatingActionButton(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.church, color: Colors.white),
              Text(
                Global.igrejaSelecionada.value?.data()?.sigla ?? '',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Offside',
                    letterSpacing: 0),
              )
            ]),
            onPressed: () {
              Modular.to.pushNamed(AppRotas.CONTEXTO);
              /* showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) {
                    return OrientationBuilder(
                      builder: (context, orientation) {
                        return const TelaSelecao();
                      },
                    );
                  }); */
            },
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        );
      },
    );
  }
}
