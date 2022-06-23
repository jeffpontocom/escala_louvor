import 'dart:developer' as dev;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';

import '/modulos.dart';
import '/utils/global.dart';
import '/widgets/avatar.dart';

enum HomePages {
  agenda,
  equipe,
  avisos,
  canticos,
}

String paginaNome(int index) {
  var pagina = HomePages.values[index];
  switch (pagina) {
    case HomePages.agenda:
      return 'Agenda de cultos';
    case HomePages.avisos:
      return 'Avisos importantes';
    case HomePages.canticos:
      return 'Repertório musical';
    case HomePages.equipe:
      return 'Membros da equipe';
  }
}

Icon paginaIcone(int index) {
  var pagina = HomePages.values[index];
  switch (pagina) {
    case HomePages.agenda:
      return const Icon(Icons.today);
    case HomePages.avisos:
      return const Icon(Icons.campaign);
    case HomePages.canticos:
      return const Icon(Icons.music_note);
    case HomePages.equipe:
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
    rota = rota.substring(rota.lastIndexOf('/') + 1,
        rota.contains('?') ? rota.indexOf('?') : null);
    dev.log('Router: $rota', name: 'Home');
    var index = 0;
    try {
      index = HomePages.values.indexWhere((element) => element.name == rota);
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
    return _layout;
  }

  /// Layout
  get _layout {
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
                appBar: appBar,
                body: Row(
                  children: [
                    railNavigation,
                    VerticalDivider(
                        thickness: 1,
                        width: 1,
                        color: Colors.grey.withOpacity(0.12)),
                    Expanded(child: corpo),
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
      leading: _isPortrait
          ? null
          : Padding(padding: const EdgeInsets.all(4), child: floatButton),
      leadingWidth: 64,
      // Título da aplicação
      title: ValueListenableBuilder<int>(
          valueListenable: _pagina,
          builder: (context, pagina, _) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Global.nomeDoApp,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  Text(paginaNome(pagina)),
                ]);
          }),
      centerTitle: false,
      // Ações
      actions: [
        // Tela administrador
        (Global.logado?.adm ?? false)
            ? IconButton(
                onPressed: () => Modular.to.pushNamed(AppModule.ADMIN),
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
              '${AppModule.PERFIL}?id=${FirebaseAuth.instance.currentUser?.uid ?? ''}&hero=logado',
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
          items: List.generate(HomePages.values.length, (index) {
            return AnimatedBarItems(
                icon: paginaIcone(index),
                selectedColor: Theme.of(context).colorScheme.primary,
                title: Text(paginaNome(index).split(' ').first));
          }),
          onTap: (index) {
            _pagina.value = index ?? 0;
            Modular.to.navigate(
                '${AppModule.HOME}/${HomePages.values[_pagina.value].name}');
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
          labelType: NavigationRailLabelType.none,
          //leading: floatButton,
          destinations: List.generate(HomePages.values.length, (index) {
            return NavigationRailDestination(
                icon: paginaIcone(index),
                label: Text(paginaNome(index).split(' ').first));
          }),
          onDestinationSelected: (index) {
            _pagina.value = index;
            Modular.to.navigate(
                '${AppModule.HOME}/${HomePages.values[_pagina.value].name}');
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
        Modular.to.pushNamed(AppModule.CONTEXTO);
      },
    );
  }
}
