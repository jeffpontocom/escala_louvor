import 'package:escala_louvor/screens/tela_canticos.dart';
import 'package:escala_louvor/screens/tela_chat.dart';
import 'package:escala_louvor/screens/tela_disponbilidade.dart';
import 'package:escala_louvor/screens/tela_escala.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'main.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /* VARIAVEIS */
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
      label: 'Canticos',
    ),
    const BottomNavigationBarItem(
      icon: SizedBox(),
      label: '',
    )
  ];

  /* SISTEMA */

  @override
  void initState() {
    //initializeDateFormatting('pt_BR', null);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // APPBAR
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(12),
          child: Image.asset('assets/icons/ic_launcher.png'),
        ),
        title: Text(
          _telas[_telaSelecionada]['titulo'],
          style: const TextStyle(
            fontFamily: 'Offside',
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        titleSpacing: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.change_circle),
          ),
          IconButton(
            onPressed: () => Modular.to
                .pushNamed('/integrante?id=${auth.currentUser?.uid ?? ''}'),
            /* Modular.to
                .navigate('/integrante?id=${auth.currentUser?.uid ?? ''}'), */
            icon: const Icon(Icons.person),
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
        onPressed: () {},
        child: const Icon(Icons.admin_panel_settings),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}
