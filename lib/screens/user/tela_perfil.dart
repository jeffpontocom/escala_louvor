import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/views/auth_guard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';

import '/functions/metodos_firebase.dart';
import '/functions/metodos_integrante.dart';
import '/models/igreja.dart';
import '/models/instrumento.dart';
import '/models/integrante.dart';
import '/utils/global.dart';
import '/utils/mensagens.dart';
import '/utils/utils.dart';
import '../../widgets/cached_circle_avatar.dart';
import '/widgets/tile_igreja.dart';

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
  late Integrante _integrante;
  late MetodosIntegrante _metodos;
  late bool _ehMeuPerfil;
  late bool _ehAdm;
  late bool _isPortrait;

  /* SISTEMA */
  @override
  void initState() {
    // Ao visitar o próprio perfil o usuário habilita o botão de edição.
    _ehMeuPerfil = (widget.id == FirebaseAuth.instance.currentUser?.uid);
    _ehAdm = Global.logado?.adm ?? false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AuthGuardView(
      scaffoldView: OrientationBuilder(builder: (context, orientation) {
        _isPortrait = orientation == Orientation.portrait;
        return Scaffold(
          appBar: AppBar(
            leading: BackButton(
              onPressed: () async {
                if (!await Modular.to.maybePop()) {
                  Modular.to.pushNamed(Global.rotaInicial);
                }
              },
            ),
            title: const Text('Perfil'),
            actions: _ehMeuPerfil || _ehAdm ? [_menuSuspenso] : null,
          ),
          body: StreamBuilder<DocumentSnapshot<Integrante>>(
            initialData: widget.snapIntegrante,
            stream: MeuFirebase.ouvinteIntegrante(id: widget.id),
            builder: (context, snapshot) {
              // Tela em carregamento
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              // Tela de falha
              if (!snapshot.data!.exists || snapshot.data!.data() == null) {
                return const Center(
                    child: Text('Falha ao obter dados do integrante.'));
              }
              // Tela carregada
              _integrante = snapshot.data!.data()!;
              _metodos = MetodosIntegrante(context, snapshot.data!);
              return _layout;
            },
          ),
        );
      }),
    );
  }

  /// Corpo
  get _layout {
    // MODO RETRATO
    return LayoutBuilder(builder: (context, constraints) {
      var flutuante = // Botão flutuante
          _integrante.telefone != null && _integrante.telefone!.isNotEmpty
              ? Positioned(
                  top: _isPortrait ? 300 - 28 : null,
                  bottom: _isPortrait ? null : 28,
                  right: 16,
                  child: FloatingActionButton(
                    backgroundColor: Colors.green,
                    onPressed: () =>
                        MyActions.openWhatsApp(_integrante.telefone!),
                    child: const Icon(Icons.whatsapp),
                  ),
                )
              : const SizedBox();
      if (_isPortrait) {
        return Stack(children: [
          Column(children: [
            Container(
              color: Colors.grey.withOpacity(0.12),
              height: 300,
              child: _cabecalho,
            ),
            Expanded(child: _dados),
          ]),
          flutuante,
        ]);
      }
      // MODO PAISAGEM
      return LayoutBuilder(builder: (context, constraints) {
        return Stack(children: [
          Wrap(children: [
            SizedBox(
              height: constraints.maxHeight,
              width: constraints.maxWidth * 0.4 - 1,
              child: _cabecalho,
            ),
            Container(
                height: constraints.maxHeight,
                width: 1,
                color: Colors.grey.withOpacity(0.38)),
            SizedBox(
                height: constraints.maxHeight,
                width: constraints.maxWidth * 0.6,
                child: _dados),
          ]),
          flutuante,
        ]);
      });
    });
  }

  /// Cabeçalho
  get _cabecalho {
    var nascimento = _integrante.dataNascimento == null
        ? '... ? ...'
        : DateFormat.MMMd('pt_BR').format(_integrante.dataNascimento!.toDate());
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: Column(
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
            _integrante.nome,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Offside',
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // E-mail
          Text(
            _integrante.email,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          // Aniversário
          RawChip(
            avatar: const Icon(Icons.cake, size: 20),
            labelPadding: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            label: Text(
              nascimento,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  /// Foto
  get _foto {
    return Hero(
      tag: widget.hero ?? 'fotoPerfil',
      child: CachedAvatar(
        nome: _integrante.nome,
        url: _integrante.fotoUrl,
        maxRadius: 128,
      ),
    );
  }

  /// Dados
  get _dados {
    return ListView(
      shrinkWrap: true,
      children: [
        _tileFuncoes,
        const Divider(height: 12),
        _tileInstrumentos,
        const Divider(height: 12),
        _tileIgrejas,
        const Divider(height: 12),
        _tileObservacoes,
        const SizedBox(height: 16),
      ],
    );
  }

  /// Tile Funções
  get _tileFuncoes {
    Widget conteudo;
    if (_integrante.funcoes == null || _integrante.funcoes!.isEmpty) {
      conteudo = const Text('Nenhuma função atribuída');
    } else {
      conteudo = Wrap(
        spacing: 4,
        runSpacing: 4,
        children: List.generate(
          _integrante.funcoes?.length ?? 0,
          (index) => Tooltip(
            message: funcaoGetString(_integrante.funcoes![index]),
            child: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: Icon(
                funcaoGetIcon(_integrante.funcoes![index]),
                color: Colors.black,
              ),
            ),
          ),
        ),
      );
    }

    return ListTile(
      dense: true,
      title: Row(
        children: [
          const Text('FUNÇÕES'),
          const SizedBox(width: 8, height: kMinInteractiveDimension),
          _ehAdm
              ? ActionChip(
                  avatar: const Icon(Icons.edit_note, size: 20),
                  label: const Text('editar', textScaleFactor: 0.9),
                  labelPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _metodos.editarFuncoes())
              : const SizedBox(),
        ],
      ),
      subtitle: conteudo,
    );
  }

  /// Tile Instrumentos
  get _tileInstrumentos {
    return FutureBuilder<QuerySnapshot<Instrumento>>(
      future: MeuFirebase.obterListaInstrumentos(ativo: true),
      builder: (context, snapshot) {
        var instrumentos = snapshot.data?.docs;
        Widget conteudo;
        if (!snapshot.hasData) {
          conteudo = const Center(child: CircularProgressIndicator());
        } else {
          if (instrumentos == null || instrumentos.isEmpty) {
            conteudo = const Text('Nenhum instrumento cadastrado!');
          } else {
            List<Instrumento> instrumentosDoIntegrante = [];
            for (var instrumento in instrumentos) {
              if (_integrante.instrumentos
                      ?.map((e) => e.toString())
                      .contains(instrumento.reference.toString()) ??
                  false) {
                instrumentosDoIntegrante.add(instrumento.data());
              }
            }
            if (instrumentosDoIntegrante.isEmpty) {
              conteudo = const Text('Nenhum instrumento selecionado!');
            } else {
              conteudo = Wrap(
                spacing: 4,
                runSpacing: 4,
                children:
                    List.generate(instrumentosDoIntegrante.length, (index) {
                  return Tooltip(
                    message: instrumentosDoIntegrante[index].nome,
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Image.asset(
                        instrumentosDoIntegrante[index].iconAsset,
                        height: 22,
                      ),
                    ),
                  );
                }),
              );
            }
          }
        }
        // Tile
        return ListTile(
          dense: true,
          title: Row(
            children: [
              const Text('INSTRUMENTO e HABILIDADES'),
              const SizedBox(width: 8, height: kMinInteractiveDimension),
              instrumentos != null &&
                      instrumentos.isNotEmpty &&
                      (_ehMeuPerfil || _ehAdm)
                  ? ActionChip(
                      avatar: const Icon(Icons.edit_note, size: 20),
                      label: const Text('editar', textScaleFactor: 0.9),
                      labelPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          _metodos.editarInstrumentos(instrumentos))
                  : const SizedBox(),
            ],
          ),
          subtitle: conteudo,
        );
      },
    );
  }

  /// Tile Igrejas
  get _tileIgrejas {
    return FutureBuilder<QuerySnapshot<Igreja>>(
      future: MeuFirebase.obterListaIgrejas(ativo: true),
      builder: (context, snapshot) {
        var igrejas = snapshot.data?.docs;
        Widget conteudo;
        if (!snapshot.hasData) {
          conteudo = const Center(child: CircularProgressIndicator());
        } else {
          if (igrejas == null || igrejas.isEmpty) {
            conteudo = const Text('Nenhuma igreja cadastrada!');
          } else {
            List<Igreja> igrejasDoIntegrante = [];
            for (var igreja in igrejas) {
              if (_integrante.igrejas
                      ?.map((e) => e.toString())
                      .contains(igreja.reference.toString()) ??
                  false) {
                igrejasDoIntegrante.add(igreja.data());
              }
            }
            if (igrejasDoIntegrante.isEmpty) {
              conteudo = const Text('Nenhuma igreja selecionada!');
            } else {
              conteudo = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(igrejasDoIntegrante.length, (index) {
                  return Tooltip(
                    message: igrejasDoIntegrante[index].nome,
                    child: TileIgrejaSmall(igreja: igrejasDoIntegrante[index]),
                  );
                }),
              );
            }
          }
        }
        // Tile
        return ListTile(
          dense: true,
          title: Row(
            children: [
              const Text('IGREJAS'),
              const SizedBox(width: 8, height: kMinInteractiveDimension),
              igrejas != null && igrejas.isNotEmpty && (_ehMeuPerfil || _ehAdm)
                  ? ActionChip(
                      avatar: const Icon(Icons.edit_note, size: 20),
                      label: const Text('editar', textScaleFactor: 0.9),
                      labelPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _metodos.editarIgrejas(igrejas))
                  : const SizedBox(),
            ],
          ),
          subtitle: conteudo,
        );
      },
    );
  }

  /// Tile Observações
  get _tileObservacoes {
    return ListTile(
      dense: true,
      title: Row(
        children: [
          const Text('OBSERVAÇÕES'),
          const SizedBox(width: 8, height: kMinInteractiveDimension),
          _ehMeuPerfil || _ehAdm
              ? ActionChip(
                  avatar: const Icon(Icons.edit_note, size: 20),
                  label: const Text('editar', textScaleFactor: 0.9),
                  labelPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _metodos.editarDados())
              : const SizedBox(),
        ],
      ),
      subtitle: Text(_integrante.obs ?? ''),
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
          value: 'editar',
          child: Text('Editar dados'),
        ));
        if (_ehMeuPerfil) {
          opcoes.add(const PopupMenuItem(
            value: 'sair',
            child: Text('Sair'),
          ));
        }
        return opcoes;
      },
      onSelected: (value) {
        switch (value) {
          case 'editar':
            _metodos.editarDados();
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

  /// Logout
  Future _sair() async {
    Mensagem.aguardar(context: context, mensagem: 'Saindo...');
    await Global.preferences?.clear();
    await FirebaseAuth.instance.signOut();
    Modular.to.navigate(Global.rotaInicial);
  }
}
