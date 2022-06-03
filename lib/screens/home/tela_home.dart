import 'dart:developer' as dev;

import 'package:escala_louvor/widgets/avatar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';

import '/rotas.dart';
import '/utils/global.dart';

enum Paginas {
  agenda,
  avisos,
  equipe,
  canticos,
}

String paginaNome(int index) {
  var pagina = Paginas.values[index];
  switch (pagina) {
    case Paginas.agenda:
      return 'Agenda de cultos';
    case Paginas.avisos:
      return 'Avisos importantes';
    case Paginas.canticos:
      return 'Repertório musical';
    case Paginas.equipe:
      return 'Equipe de louvor';
  }
}

Icon paginaIcone(int index) {
  var pagina = Paginas.values[index];
  switch (pagina) {
    case Paginas.agenda:
      return const Icon(Icons.today);
    case Paginas.avisos:
      return const Icon(Icons.campaign);
    case Paginas.canticos:
      return const Icon(Icons.music_note);
    case Paginas.equipe:
      return const Icon(Icons.groups);
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  /// Notificador de pagina selecionada
  final ValueNotifier<int> _pagina = ValueNotifier(0);

  /// Identificador de orientação do dispositivo
  bool _isPortrait = true;

  /// Define a página conforme o nome da Rota (#Modular)
  int setPage(String rota) {
    rota = rota.substring(1, rota.contains('?') ? rota.indexOf('?') : null);
    dev.log(rota, name: 'log:Rota');
    var index = 0;
    try {
      index = Paginas.values.indexWhere((element) => element.name == rota);
    } catch (e) {
      index = 0;
    }
    _pagina.value = index < 0 ? 0 : index;
    return index < 0 ? 0 : index;
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
        _isPortrait = orientation == Orientation.portrait;
        return _isPortrait
            ? Scaffold(
                extendBody: true,
                appBar: appBar,
                body: corpo,
                bottomNavigationBar: bottomNavigation,
                floatingActionButton: Visibility(
                  visible: MediaQuery.of(context).viewInsets.bottom == 0.0,
                  child: floatButton,
                ),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.centerDocked,
              )
            : Scaffold(
                body: Row(
                  children: [
                    SafeArea(child: railNavigation),
                    const VerticalDivider(thickness: 1, width: 1),
                    Expanded(
                        child: Scaffold(
                      appBar: appBar,
                      body: corpo,
                    )),
                  ],
                ),
              );
      },
    );
  }

  /// AppBar
  get appBar {
    return AppBar(
      // Ícone da aplicação
      /* leading: Padding(
          padding: const EdgeInsets.all(12),
          child: Image.asset('assets/icons/ic_launcher.png')), */
      // Título da aplicação
      title: ValueListenableBuilder<int>(
          valueListenable: _pagina,
          builder: (context, pagina, _) {
            return Text(paginaNome(pagina));
          }),
      centerTitle: false,
      elevation: _isPortrait ? null : 0,
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
            child: CachedAvatar(
              icone: Icons.account_circle,
              url: Global.logado?.fotoUrl,
            ),
          ),
          onPressed: () => Modular.to.pushNamed(
              '${AppRotas.PERFIL}?id=${FirebaseAuth.instance.currentUser?.uid ?? ''}&hero=logado',
              arguments: Global.logadoSnapshot),
        ),
      ],
    );
  }

  /// Corpo
  get corpo {
    return Flex(
      direction: Axis.vertical,
      children: const [
        // TODO: Container para aviso sem rede
        // Conteúdo
        Flexible(child: RouterOutlet()),
      ],
    );
  }

  /// Bottom Navigation (para modo retrato)
  get bottomNavigation {
    return ValueListenableBuilder<int>(
      valueListenable: _pagina,
      builder: (context, pagina, _) {
        return StylishBottomBar(
          currentIndex: pagina,
          iconStyle: IconStyle.animated,
          hasNotch: true,
          fabLocation: StylishBarFabLocation.center,
          backgroundColor: Theme.of(context).colorScheme.background,
          items: List.generate(Paginas.values.length, (index) {
            return AnimatedBarItems(
                icon: paginaIcone(index),
                selectedColor: Theme.of(context).colorScheme.primary,
                title: Text(paginaNome(index).split(' ').first));
          }),
          onTap: (index) {
            _pagina.value = index ?? 0;
            Modular.to.navigate('/${Paginas.values[index ?? 0].name}');
          },
        );
      },
    );
  }

  /// Rail Navigation (para modo paisagem)
  get railNavigation {
    return ValueListenableBuilder<int>(
      valueListenable: _pagina,
      builder: (context, pagina, _) {
        return NavigationRail(
          selectedIndex: pagina,
          elevation: 4,
          extended: kIsWeb ? true : false,
          groupAlignment: 0,
          minExtendedWidth: 176,
          leading: floatButton,
          destinations: List.generate(Paginas.values.length, (index) {
            return NavigationRailDestination(
                icon: paginaIcone(index), label: Text(paginaNome(index)));
          }),
          onDestinationSelected: (index) {
            _pagina.value = index;
            Modular.to.navigate('/${Paginas.values[index].name}');
          },
        );
      },
    );
  }

  /// FAB - Floating Action Button
  get floatButton {
    return FloatingActionButton(
      heroTag: 'none',
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.church),
        Text(
          Global.igrejaSelecionada.value?.data()?.sigla ?? '',
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Offside',
              letterSpacing: 0),
        ),
      ]),
      onPressed: () {
        Modular.to.pushNamed(AppRotas.CONTEXTO);
      },
    );
  }
}
