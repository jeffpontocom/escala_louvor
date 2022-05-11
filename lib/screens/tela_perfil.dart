import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/preferencias.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../utils/utils.dart';
import '/functions/metodos_firebase.dart';
import '/global.dart';
import '/models/integrante.dart';
import '/utils/mensagens.dart';
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
  late bool _ehMeuPerfil;

  /* SISTEMA */
  @override
  void initState() {
    // Ao visitar o próprio perfil o usuário habilita o modo de edição.
    _integrante = widget.snapIntegrante?.data();
    _ehMeuPerfil = (widget.id == FirebaseAuth.instance.currentUser?.uid);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: _ehMeuPerfil || (Global.integranteLogado?.data()?.adm ?? false)
            ? [_menuSuspenso]
            : null,
      ),
      body: widget.snapIntegrante != null
          ? _body
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
                return _body;
              }),
      /* floatingActionButton: FloatingActionButton(
        child: const FaIcon(FontAwesomeIcons.whatsapp),
        backgroundColor: Colors.green,
        onPressed: () {},
      ), */
    );
  }

  /// Corpo
  get _body {
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
                    color: Theme.of(context).colorScheme.primary,
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
              _integrante?.telefone != null
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
    /* return Stack(
      alignment: AlignmentDirectional.bottomEnd,
      children: [
        // Foto
        Hero(
          tag: widget.hero ?? 'fotoPerfil',
          child: CircleAvatar(
            child: Text(
              MyStrings.getUserInitials(_integrante!.nome),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            foregroundImage:
                MyNetwork.getImageFromUrl(_integrante!.fotoUrl)?.image,
            backgroundColor:
                Theme.of(context).colorScheme.onPrimary.withOpacity(0.5),
            maxRadius: 128,
            minRadius: 48,
          ),
        ),
        _ehMeuPerfil
            ? CircleAvatar(
                radius: 24,
                backgroundColor: _integrante!.fotoUrl == null ||
                        _integrante!.fotoUrl!.isEmpty
                    ? null
                    : Colors.red,
                child: _integrante!.fotoUrl == null ||
                        _integrante!.fotoUrl!.isEmpty
                    ? IconButton(
                        iconSize: 24,
                        onPressed: () async {
                          var url = await MeuFirebase.carregarFoto(context);
                          if (url != null && url.isNotEmpty) {
                            setState(() {
                              _integrante!.fotoUrl = url;
                              // TODO: alterar no firebase
                            });
                          }
                        },
                        icon: const Icon(Icons.add_a_photo))
                    : IconButton(
                        iconSize: 24,
                        onPressed: () async {
                          setState(() {
                            _integrante!.fotoUrl = null;
                            // TODO: alterar no firebase
                          });
                        },
                        icon: const Icon(Icons.no_photography)),
              )
            : const SizedBox(),
      ],
    ); */
  }

  /// Dados
  get _dados {
    return ListView(
      shrinkWrap: true,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 24),
          child: Text('FUNÇÕES'),
        ),
        ListTile(
          title: Text('mostrar funções'),
          onTap: () {},
        ),
        const Divider(height: 1),
        const Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 24),
          child: Text('INSTRUMENTOS E HABILIDADES'),
        ),
        ListTile(
          title: Text('mostrar habilidades'),
          onTap: () {},
        ),
        const Divider(height: 1),
        const Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 24),
          child: Text('IGREJAS (em que pode ser escalado)'),
        ),
        ListTile(
          title: Text('mostrar igrejas'),
          onTap: () {},
        ),
        const Divider(height: 1),
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
        List<PopupMenuEntry> opcoes = [
          PopupMenuItem(
            child: const Text('Editar dados'),
            onTap: _editarDados,
          ),
        ];
        if (Global.integranteLogado?.data()?.adm ?? false) {
          opcoes.add(PopupMenuItem(
            child: const Text('Editar funções'),
            onTap: _editarFuncoes,
          ));
        }
        if (_ehMeuPerfil) {
          opcoes.add(PopupMenuItem(
            child: const Text('Sair'),
            onTap: _sair,
          ));
        }
        return opcoes;
      },
    );
  }

  /* MÉTODOS */

  /// Logout
  Future _sair() async {
    Mensagem.aguardar(context: context, mensagem: 'Saindo...');
    await Preferencias.preferences?.clear();
    await FirebaseAuth.instance.signOut();
    Modular.to.navigate('/${Paginas.values[0].name}');
  }

  void _editarDados() {}

  void _editarFuncoes() {}
}
