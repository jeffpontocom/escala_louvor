import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/utils/global.dart';
import 'package:flutter/material.dart';

import '../../functions/metodos_firebase.dart';
import '../../models/igreja.dart';
import '../../models/integrante.dart';
import '../../utils/utils.dart';

class PaginaEquipe extends StatefulWidget {
  const PaginaEquipe({Key? key}) : super(key: key);

  @override
  State<PaginaEquipe> createState() => _PaginaEquipeState();
}

class _PaginaEquipeState extends State<PaginaEquipe> {
  /* VARIÁVEIS */
  late bool _isPortrait;
  late Igreja _igreja;

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(builder: (context, orientation) {
      _isPortrait = orientation == Orientation.portrait;
      return StreamBuilder<DocumentSnapshot<Igreja>>(
          initialData: Global.igrejaSelecionada.value,
          stream: MeuFirebase.obterStreamIgreja(Global.igreja ?? ''),
          builder: (context, snapshot) {
            // Tela em carregamento
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            // Tela de falha
            if (!snapshot.data!.exists || snapshot.data!.data() == null) {
              return const Center(
                  child: Text('Falha ao obter dados da igreja.'));
            }
            // Tela carregada
            _igreja = snapshot.data!.data()!;
            return _corpo;
          });
    });
  }

  /// Corpo
  get _corpo {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Wrap(
              children: [
                // Cabeçalho
                Material(
                  elevation: _isPortrait ? 4 : 0,
                  color: Theme.of(context).primaryColor,
                  child: Container(
                    height: _isPortrait
                        ? constraints.maxHeight * 0.35
                        : constraints.maxHeight,
                    width: _isPortrait
                        ? constraints.maxWidth
                        : constraints.maxWidth * 0.35,
                    padding: const EdgeInsets.all(16),
                    child: _cabecalho,
                  ),
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
          ],
        );
      },
    );
  }

  /// Cabeçalho
  get _cabecalho {
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
        // Sigla
        Text(
          _igreja.sigla,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Offside',
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        // Nome Completo
        Text(
          _igreja.nome,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.5)),
        ),
        const SizedBox(height: 16),
        // Mapa
        _igreja.endereco == null || _igreja.endereco!.isEmpty
            ? const Text('Sem endereço cadastrado')
            : ActionChip(
                avatar: const Icon(Icons.map),
                label: const Text('Mapa'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                onPressed: () {
                  MyActions.openGoogleMaps(street: _igreja.endereco ?? '');
                }),
      ],
    );
  }

  /// Foto
  get _foto {
    return Hero(
      tag: 'fotoIgreja',
      child: CircleAvatar(
        maxRadius: 128,
        minRadius: 12,
        backgroundColor:
            Theme.of(context).colorScheme.onPrimary.withOpacity(0.5),
        foregroundImage: MyNetwork.getImageProvider(_igreja.fotoUrl),
        child: const Icon(Icons.church),
      ),
    );
  }

  /// Dados
  get _dados {
    return ListView(
      shrinkWrap: true,
      children: [
        //_tileFuncoes,
        const Divider(height: 12),
        //_tileInstrumentos,
        const Divider(height: 12),
        //_tileIgrejas,
        const Divider(height: 12),
        //_tileObservacoes,
      ],
    );
  }
}
