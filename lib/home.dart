import 'package:escala_louvor/screens/tela_canticos.dart';
import 'package:escala_louvor/screens/tela_chat.dart';
import 'package:escala_louvor/screens/tela_disponbilidade.dart';
import 'package:escala_louvor/screens/tela_escala.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  /* VARIAVEIS */
  int _telaSelecionada = 0;

  /// Lista de Telas
  final List _telas = [
    {'titulo': 'Escalas', 'tela': const TelaEscala()},
    {'titulo': 'Agenda', 'tela': const TelaAgenda()},
    {'titulo': 'Chat', 'tela': const TelaChat()},
    {'titulo': 'Canticos', 'tela': const TelaCanticos()},
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
        title: Text(_telas[_telaSelecionada]['titulo']),
        titleSpacing: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.change_circle),
          ),
          IconButton(
            onPressed: () {},
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
