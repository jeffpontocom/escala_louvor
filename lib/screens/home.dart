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
import '/screens/pages/home_agenda.dart';
import '/screens/pages/home_canticos.dart';
import '/screens/pages/home_chats.dart';
import '/screens/pages/home_escalas.dart';
import '/screens/views/view_igrejas.dart';
import '/utils/estilos.dart';
import '/utils/utils.dart';

enum Paginas { escala, agenda, chat, cantico }

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  // Selecionar de pagina
  int _paginaSelecionada = 0;
  String? _viewId;

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
          Global.integranteLogado = logado.data;
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
                return _scaffold(logado.data!, igreja);
              });
        });
  }

  Widget _scaffold(
      DocumentSnapshot<Integrante> logado, DocumentSnapshot<Igreja> igreja) {
    // Páginas não podem ser #[const] pois precisam ser atualizadas perante
    // uma atualização nos dados do integrante logado ou da igreja selecionada
    List<Widget> paginas = [
      TelaEscalas(id: _viewId),
      TelaAgenda(),
      TelaChat(),
      TelaCanticos(),
    ];

    List<String> titulos = const [
      'Escalas do Louvor',
      'Agenda da Igreja',
      'Chat dos eventos',
      'Cânticos e Hinos',
      'Nenhuma tela',
    ];

    List<BottomNavigationBarItem> _navigationItens = const [
      BottomNavigationBarItem(icon: Icon(Icons.access_time), label: 'Escalas'),
      BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month), label: 'Agenda'),
      BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
      BottomNavigationBarItem(icon: Icon(Icons.music_note), label: 'Cânticos'),
      BottomNavigationBarItem(icon: SizedBox(), label: '')
    ];

    return StatefulBuilder(builder: (context, setState) {
      return Scaffold(
        appBar: AppBar(
          // Ícone da aplicação
          leading: Padding(
            padding: const EdgeInsets.all(12),
            child: Image.asset('assets/icons/ic_launcher.png'),
          ),
          // Título da aplicação
          title: Text(
            titulos[_paginaSelecionada],
            style: Estilo.appBarTitulo,
          ),
          titleSpacing: 0,
          // Ações
          actions: [
            // Tela administrador
            (logado.data()?.adm ?? false)
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
                foregroundImage:
                    MyNetwork.getImageFromUrl(logado.data()?.fotoUrl, 12)
                        ?.image,
              ),
            ),
          ],
        ),
        // CORPO
        body: paginas[_paginaSelecionada],
        // NAVIGATION BAR
        bottomNavigationBar: BottomNavigationBar(
          items: _navigationItens,
          currentIndex: _paginaSelecionada,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey.withOpacity(0.5),
          type: BottomNavigationBarType.shifting,
          onTap: (index) {
            if (index == 4) return;
            setState(() {
              _paginaSelecionada = index;
            });
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
            Image.asset('assets/icons/ic_launcher.png',
                width: 128, height: 128),
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
            Icon(Icons.error, color: Colors.red, size: 128),
            // Texto de carregamento
            Text(
              'Falha ao carregar dados do usuário. Feche o aplicativo e tente novamente,',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget get _scaffoldSemIgrejaSelecionada {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: const [
            Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Selecionar Igreja ou local',
                style: TextStyle(fontSize: 22),
              ),
            ),
            Expanded(
              child: Center(child: ViewIgrejas()),
            ),
          ],
        ),
      ),
    );
  }
}
