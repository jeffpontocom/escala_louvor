import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/functions/metodos_firebase.dart';
import 'package:escala_louvor/utils/global.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'cached_circle_avatar.dart';
import '/models/integrante.dart';
import '/modulos.dart';

class CardIntegranteResponsavel extends StatelessWidget {
  final DocumentReference<Integrante> integranteRef;
  const CardIntegranteResponsavel({Key? key, required this.integranteRef})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var hero = integranteRef.id;

    return StreamBuilder<DocumentSnapshot<Integrante>>(
        stream: MeuFirebase.ouvinteIntegrante(id: integranteRef.id),
        builder: (_, snapshot) {
          // Carregando...
          if (!snapshot.hasData) {
            return const ListTile(
              subtitle: Text('Carregando...'),
            );
          }

          // Recolhe dados do integrante
          var integrante = snapshot.data?.data();

          // Falha
          if (integrante == null) {
            return const ListTile(title: Text('Falha!'));
          }

          var nome = integrante.nome;
          var nomePrimeiro = nome.split(' ').first;
          var nomeUltimo = nome.split(' ').last;
          nome = nomePrimeiro == nomeUltimo
              ? nomePrimeiro
              : '$nomePrimeiro $nomeUltimo';

          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(width: 1, color: Colors.grey.withOpacity(0.5)),
            ),

            selected: integranteRef.id == Global.logadoReference?.id,
            selectedTileColor:
                Theme.of(context).colorScheme.secondary.withOpacity(0.25),

            // Foto
            title: Center(
              child: Hero(
                tag: hero,
                child: CachedAvatar(
                  nome: integrante.nome,
                  url: integrante.fotoUrl,
                  maxRadius: 28,
                ),
              ),
            ),

            // Nome
            subtitle: Center(
              child: Text(
                nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),

            // Função ao tocar
            onTap: () => Modular.to.pushNamed(
                '${AppModule.PERFIL}?id=${integranteRef.id}&hero=$hero',
                arguments: snapshot.data),
          );
        });
  }
}
