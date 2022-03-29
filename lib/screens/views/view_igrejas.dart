import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/rotas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '/global.dart';
import '/functions/metodos_firebase.dart';
import '/models/igreja.dart';
import '/preferencias.dart';
import '/utils/mensagens.dart';
import '/utils/utils.dart';

class ViewIgrejas extends StatelessWidget {
  const ViewIgrejas({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot<Igreja>>(
        future: MeuFirebase.obterListaIgrejas(ativo: true),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
              heightFactor: 4,
            );
          }
          var igrejas = snapshot.data?.docs;
          if (igrejas == null || igrejas.isEmpty) {
            // acessar ambiente administrativo para cadastrar igrejas
            return const Center(
              child: Text(
                  'É necessário cadastrar ao menos uma igreja ou local de culto!'),
              heightFactor: 4,
            );
          }
          List<QueryDocumentSnapshot<Igreja>> inscritas = [];
          for (var igreja in igrejas) {
            if (Global.integranteLogado
                    ?.data()
                    ?.igrejas
                    ?.map((e) => e.toString())
                    .contains(igreja.reference.toString()) ??
                false) {
              inscritas.add(igreja);
            }
          }
          if (inscritas.isEmpty) {
            // acessar perfil para adicionar igrejas
            return Center(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    'É necessário estar inscrito em ao menos uma igreja ou local de culto!'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Modular.to.pushNamed(
                      '${AppRotas.PERFIL}?id=${Global.integranteLogado?.id}'),
                  child: const Text('IR PARA MEU PERFIL'),
                )
              ],
            ));
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 24),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                // Lista
                children: List.generate(
                  inscritas.length,
                  (index) {
                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 150),
                      // Card da Igreja
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        color: inscritas[index].reference.toString() ==
                                Global.igrejaAtual?.reference.toString()
                            ? Colors.amber.withOpacity(0.5)
                            : null,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.grey.withOpacity(0.5)),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(16)),
                        ),
                        child: InkWell(
                          radius: 16,
                          customBorder: const RoundedRectangleBorder(
                            side: BorderSide(color: Colors.grey),
                            borderRadius: BorderRadius.all(
                              Radius.circular(16),
                            ),
                          ),
                          onTap: () async {
                            Mensagem.aguardar(context: context);
                            String? id = inscritas[index].reference.id;
                            Preferencias.igrejaAtual = id;
                            Global.igrejaAtual =
                                await MeuFirebase.obterSnapshotIgreja(id);
                            Modular.to.pop(); // fecha progresso
                            Modular.to.pop(); // fecha dialog
                            //_igrejaContexto.value = Global.igrejaAtual?.data();
                          },
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Foto da igreja
                                SizedBox(
                                  height: 150,
                                  child: MyNetwork.getImageFromUrl(
                                          inscritas[index].data().fotoUrl,
                                          null) ??
                                      const Center(child: Icon(Icons.church)),
                                ),
                                // Sigla
                                const SizedBox(height: 8),
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text(
                                      inscritas[index]
                                          .data()
                                          .sigla
                                          .toUpperCase(),
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                    )),

                                // Nome
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Text(inscritas[index].data().nome),
                                ),
                                const SizedBox(height: 12),
                              ]),
                        ),
                      ),
                    );
                  },
                  growable: false,
                ).toList(),
              ),
            ),
          );
        });
  }
}
