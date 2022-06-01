import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/functions/metodos_firebase.dart';
import 'package:escala_louvor/models/integrante.dart';
import 'package:escala_louvor/utils/utils.dart';
import 'package:escala_louvor/widgets/avatar_integrante.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../models/instrumento.dart';
import '../rotas.dart';

class TileIntegrante extends StatelessWidget {
  final DocumentSnapshot<Integrante> snapshot;
  const TileIntegrante({Key? key, required this.snapshot}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var integrante = snapshot.data()!;
    return ListTile(
      isThreeLine: true,
      leading: AvatarIntegrante(integrante: integrante),
      title: Text(
        integrante.nome,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Funções
          Wrap(
            children: List.generate(integrante.funcoes?.length ?? 0, (index) {
              var separator =
                  integrante.funcoes!.length - 1 == index ? '' : ' • ';
              return Text(
                  funcaoGetString(integrante.funcoes![index]) + separator);
            }),
          ),
          const SizedBox(height: 4),
          // Instrumentos
          Wrap(
            spacing: 4,
            children:
                List.generate(integrante.instrumentos?.length ?? 0, (index) {
              var instrumento = integrante.instrumentos![index];
              return FutureBuilder<DocumentSnapshot<Instrumento>?>(
                future: MeuFirebase.obterSnapshotInstrumento(instrumento.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData ||
                      snapshot.data?.data()?.iconAsset == null) {
                    return const SizedBox();
                  }
                  return CircleAvatar(
                    backgroundColor: Colors.grey.withOpacity(0.12),
                    radius: 10,
                    child: Image.asset(
                      snapshot.data!.data()!.iconAsset,
                      height: 16,
                      color: Theme.of(context).colorScheme.onBackground,
                      colorBlendMode: BlendMode.srcATop,
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      trailing: IconButton(
          onPressed: integrante.telefone == null
              ? null
              : () => MyActions.openWhatsApp(integrante.telefone!),
          icon: const Icon(
            Icons.whatsapp,
            color: Colors.green,
          )),
      onTap: () => Modular.to.pushNamed(
          '${AppRotas.PERFIL}?id=${snapshot.id}&hero=${snapshot.id}',
          arguments: snapshot),
    );
  }
}
