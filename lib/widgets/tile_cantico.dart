import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../functions/metodos_firebase.dart';
import '../models/cantico.dart';
import '../rotas.dart';

class TileCantico extends StatelessWidget {
  final QueryDocumentSnapshot<Cantico> snapshot;
  final bool? selecionado;
  final GestureTapCallback? onTap;
  const TileCantico(
      {Key? key, required this.snapshot, this.selecionado = false, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Cantico cantico = snapshot.data();
    return ListTile(
      // ICONE DE SELEÇÃO
      leading: selecionado == null
          ? null
          : selecionado!
              ? const Icon(Icons.check_circle, color: Colors.green)
              : Icon(Icons.circle_outlined,
                  color: Colors.grey.withOpacity(0.38)),
      // NOME DO CÂNTICO + TOM
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              cantico.nome,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 10,
            backgroundColor: Colors.grey.withOpacity(0.38),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: FittedBox(child: Text(cantico.tom ?? '?')),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      // AUTO DO CÂNTICO
      subtitle: Text(
        cantico.autor ?? '',
        overflow: TextOverflow.ellipsis,
      ),
      // AÇÕES PRINCIPAIS
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cifra
          // TODO: Mostrar erro se não houver conexão com internet
          cantico.cifraUrl == null
              ? const SizedBox()
              : Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.withOpacity(0.38)),
                  child: IconButton(
                    icon: const Icon(Icons.queue_music),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      MeuFirebase.abrirArquivosPdf(
                          context, [cantico.cifraUrl!]);
                    },
                  ),
                ),
          const SizedBox(width: 8),
          // YouTube
          cantico.youTubeUrl == null || cantico.youTubeUrl!.isEmpty
              ? const SizedBox()
              : Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.withOpacity(0.38)),
                  child: IconButton(
                    icon: const FaIcon(FontAwesomeIcons.youtube,
                        color: Colors.red),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: () async {
                      if (!await launch(cantico.youTubeUrl ?? '')) {
                        throw 'Could not launch youTubeUrl';
                      }
                    },
                  ),
                ),
        ],
      ),
      onTap: onTap ??
          () => Modular.to.pushNamed('${AppRotas.CANTICO}?id=${snapshot.id}',
              arguments: snapshot),
      /* onTap: widget.culto == null
          ? null
          : () {
              setState(() {
                _selecionados ??= [];
                if (_selecionados!
                    .map((e) => e.toString())
                    .contains(listaFiltrada[index].reference.toString())) {
                  _selecionados!.removeWhere((element) =>
                      element.toString() ==
                      listaFiltrada[index].reference.toString());
                } else {
                  _selecionados!.add(listaFiltrada[index].reference);
                }
              });
            }, */
    );
  }
}
