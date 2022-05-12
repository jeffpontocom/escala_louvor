import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/functions/metodos_integrante.dart';
import 'package:escala_louvor/models/igreja.dart';
import 'package:escala_louvor/screens/views/tile_igreja.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../models/instrumento.dart';
import '/functions/metodos_firebase.dart';
import '/global.dart';
import '/models/integrante.dart';
import '/utils/mensagens.dart';
import '/utils/utils.dart';
import '/preferencias.dart';
import 'home.dart';

class TelaPerfil extends StatefulWidget {
  final String id;
  final String? hero;
  final DocumentSnapshot<Integrante>? snapIntegrante;
  const TelaPerfil({Key? key, required this.id, this.hero, this.snapIntegrante})
      : super(key: key);

  @override
  State<TelaPerfil> createState() => _TelaPerfilState();
}

class _TelaPerfilState extends State<TelaPerfil> {
  /* VARIÁVEIS */
  //late DocumentReference _documentReference;
  Integrante? _integrante;
  late MetodosIntegrante _metodos;
  late bool _ehMeuPerfil;
  late bool _ehAdm;

  /* SISTEMA */
  @override
  void initState() {
    // Ao visitar o próprio perfil o usuário habilita o modo de edição.
    _integrante = widget.snapIntegrante?.data();
    _metodos = MetodosIntegrante(context);
    _ehMeuPerfil = (widget.id == FirebaseAuth.instance.currentUser?.uid);
    _ehAdm = Global.integranteLogado?.data()?.adm ?? false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: _ehMeuPerfil || _ehAdm ? [_menuSuspenso] : null,
      ),
      body: widget.snapIntegrante != null
          ? _corpo
          : FutureBuilder<DocumentSnapshot<Integrante>?>(
              future: MeuFirebase.obterSnapshotIntegrante(widget.id),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.data!.exists || snap.data!.data() == null) {
                  return const Center(
                      child: Text('Falha ao obter dados do integrante.'));
                }
                _integrante = snap.data?.data();
                return _corpo;
              }),
    );
  }

  /// Corpo
  get _corpo {
    return OrientationBuilder(builder: (context, orientation) {
      var _isPortrait = orientation == Orientation.portrait;
      return LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Wrap(
                children: [
                  // Cabeçalho
                  Container(
                    height: _isPortrait
                        ? constraints.maxHeight * 0.35
                        : constraints.maxHeight,
                    width: _isPortrait
                        ? constraints.maxWidth
                        : constraints.maxWidth * 0.35,
                    color: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.all(16),
                    child: _cabecalho,
                  ),
                  // Conteúdo
                  SizedBox(
                    height: _isPortrait
                        ? constraints.maxHeight * 0.65
                        : constraints.maxHeight,
                    width: _isPortrait
                        ? constraints.maxWidth
                        : constraints.maxWidth * 0.65,
                    child: _dados,
                  ),
                ],
              ),
              // Botão flutuante
              _integrante?.telefone != null && _integrante!.telefone!.isNotEmpty
                  ? Positioned(
                      top: _isPortrait
                          ? constraints.maxHeight * 0.35 - 28
                          : null,
                      bottom: _isPortrait ? null : 28,
                      right: 16,
                      child: FloatingActionButton(
                        child: const FaIcon(FontAwesomeIcons.whatsapp),
                        backgroundColor: Colors.green,
                        onPressed: () =>
                            MyActions.openWhatsApp(_integrante!.telefone!),
                      ),
                    )
                  : const SizedBox(),
            ],
          );
        },
      );
    });
  }

  /// Cabeçalho
  get _cabecalho {
    var nascimento = _integrante?.dataNascimento == null
        ? '?'
        : DateFormat.MMMd('pt_BR')
            .format(_integrante!.dataNascimento!.toDate());
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Foto
        Flexible(
          child: LayoutBuilder(
            builder: (context, constraints) {
              var dimension = constraints.maxHeight < constraints.maxWidth
                  ? constraints.maxHeight
                  : constraints.maxWidth;
              return ConstrainedBox(
                constraints:
                    BoxConstraints(maxWidth: dimension, maxHeight: dimension),
                child: _foto,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Nome
        Text(
          _integrante?.nome ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Offside',
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // E-mail
        Text(
          _integrante?.email ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 16),
        // Aniversário
        Wrap(
          spacing: 8,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            const Icon(Icons.cake),
            Text(
              nascimento,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        )
      ],
    );
  }

  /// Foto
  get _foto {
    if (_integrante == null) {
      return const Text('Erro');
    }
    return Hero(
      tag: widget.hero ?? 'fotoPerfil',
      child: CircleAvatar(
        child: Text(
          MyStrings.getUserInitials(_integrante!.nome),
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        backgroundColor:
            Theme.of(context).colorScheme.onPrimary.withOpacity(0.5),
        foregroundImage: MyNetwork.getImageProvider(_integrante!.fotoUrl),
        maxRadius: 128,
        minRadius: 12,
      ),
    );
  }

  /// Dados
  get _dados {
    return ListView(
      shrinkWrap: true,
      children: [
        // Funções
        const Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 24),
          child: Text('FUNÇÕES'),
        ),
        ListTile(
          title: _funcoes,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          trailing: _ehAdm
              ? IconButton(onPressed: () {}, icon: const Icon(Icons.edit_note))
              : null,
        ),
        const Divider(height: 1),
        // Instrumentos
        const Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 24),
          child: Text('INSTRUMENTOS E HABILIDADES'),
        ),
        ListTile(
          title: _instrumentos,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          trailing: _ehMeuPerfil || _ehAdm
              ? IconButton(onPressed: () {}, icon: const Icon(Icons.edit_note))
              : null,
        ),
        const Divider(height: 1),
        // Igrejas
        const Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 24),
          child: Text('IGREJAS (em que pode ser escalado)'),
        ),
        ListTile(
          title: _igrejas,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          trailing: _ehMeuPerfil || _ehAdm
              ? IconButton(onPressed: () {}, icon: const Icon(Icons.edit_note))
              : null,
        ),
        const Divider(height: 1),
        // Observações
        const Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 24),
          child: Text('Observações'),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
          child: Text(_integrante?.obs ?? ''),
        ),
      ],
    );
  }

  /// Funções
  get _funcoes {
    return Wrap(
      spacing: 8,
      children: List.generate(
        _integrante?.funcoes?.length ?? 0,
        (index) => Tooltip(
          message: funcaoGetString(_integrante!.funcoes![index]),
          child: CircleAvatar(
            child: Icon(funcaoGetIcon(_integrante!.funcoes![index])),
            backgroundColor: Colors.orange,
          ),
        ),
      ),
    );
  }

  /// Instrumentos
  get _instrumentos {
    return FutureBuilder<QuerySnapshot<Instrumento>>(
      future: MeuFirebase.obterListaInstrumentos(ativo: true),
      builder: (context, snapshot) {
        // Carregando
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var instrumentos = snapshot.data?.docs;
        if (instrumentos == null || instrumentos.isEmpty) {
          return const Text('Nenhum instrumento cadastrado!');
        }
        List<Instrumento> instrumentosDoIntegrante = [];
        for (var instrumento in instrumentos) {
          if (_integrante!.instrumentos!
              .map((e) => e.toString())
              .contains(instrumento.reference.toString())) {
            instrumentosDoIntegrante.add(instrumento.data());
          }
        }
        if (instrumentosDoIntegrante.isEmpty) {
          return const Text('Nenhum instrumento selecionado!');
        }
        return Wrap(
          spacing: 8,
          children: List.generate(instrumentosDoIntegrante.length, (index) {
            return Tooltip(
              message: instrumentosDoIntegrante[index].nome,
              child: CircleAvatar(
                child: Image.asset(instrumentosDoIntegrante[index].iconAsset,
                    height: 24),
                backgroundColor: Colors.cyan,
              ),
            );
          }),
        );
      },
    );
  }

  /// Igrejas
  get _igrejas {
    return FutureBuilder<QuerySnapshot<Igreja>>(
      future: MeuFirebase.obterListaIgrejas(ativo: true),
      builder: (context, snapshot) {
        // Carregando
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var igrejas = snapshot.data?.docs;
        if (igrejas == null || igrejas.isEmpty) {
          return const Text('Nenhuma igreja cadastrada!');
        }
        List<Igreja> igrejasDoIntegrante = [];
        for (var igreja in igrejas) {
          if (_integrante!.igrejas!
              .map((e) => e.toString())
              .contains(igreja.reference.toString())) {
            igrejasDoIntegrante.add(igreja.data());
          }
        }
        if (igrejasDoIntegrante.isEmpty) {
          return const Text('Nenhuma igreja selecionada!');
        }
        return Wrap(
          spacing: 8,
          children: List.generate(igrejasDoIntegrante.length, (index) {
            return Tooltip(
              message: igrejasDoIntegrante[index].nome,
              child: TileIgrejaSmall(igreja: igrejasDoIntegrante[index]),
            );
          }),
        );
      },
    );
  }

  /// Menu Suspenso
  get _menuSuspenso {
    return PopupMenuButton(
      tooltip: 'Menu',
      child: kIsWeb
          ? Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [const Text('Menu'), Icon(Icons.adaptive.more)],
              ),
            )
          : null,
      itemBuilder: (context) {
        List<PopupMenuEntry> opcoes = [];
        opcoes.add(const PopupMenuItem(
          child: Text('Editar dados'),
          value: 'editar',
        ));
        if (_ehMeuPerfil) {
          opcoes.add(const PopupMenuItem(
            child: Text('Sair'),
            value: 'sair',
          ));
        }
        return opcoes;
      },
      onSelected: (value) {
        switch (value) {
          case 'editar':
            _editarDadosDoIntegrante();
            break;
          case 'sair':
            _sair();
            break;
          default:
        }
      },
    );
  }

  /* MÉTODOS */

  void _editarDadosDoIntegrante() async {
    _metodos.editarDados(
      widget.snapIntegrante!,
      () => setState(() {}),
    );
  }

  void _editarFuncoesDoIntegrante() {}

  void _editarInstrumentosDoIntegrante() {}

  void _editarIgrejasDoIntegrante() {}

  /// Logout
  Future _sair() async {
    Mensagem.aguardar(context: context, mensagem: 'Saindo...');
    await Preferencias.preferences?.clear();
    await FirebaseAuth.instance.signOut();
    Modular.to.navigate('/${Paginas.values[0].name}');
  }
}
