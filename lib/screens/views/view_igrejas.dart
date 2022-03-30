import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/models/integrante.dart';
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
            // Adicionar igrejas
            return _listaDeIgrejasParaInscricao(igrejas);
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
                    // Card da Igreja
                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 150),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        color: inscritas[index].reference.toString() ==
                                Global.igrejaSelecionada.value?.reference
                                    .toString()
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
                            Global.igrejaSelecionada.value =
                                await MeuFirebase.obterSnapshotIgreja(id);
                            Modular.to.pop(); // fecha progresso
                            Modular.to.maybePop(true); // fecha dialog
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

  Widget _listaDeIgrejasParaInscricao(
      List<QueryDocumentSnapshot<Igreja>> igrejas) {
    Integrante integrante = Global.integranteLogado!.data()!;
    return StatefulBuilder(builder: (context, innerState) {
      return Center(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
              'É necessário estar inscrito em ao menos uma igreja ou local de culto!'),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              igrejas.length,
              (index) {
                bool inscrito = integrante.igrejas
                        ?.map((e) => e.toString())
                        .contains(igrejas[index].reference.toString()) ??
                    false;
                return InkWell(
                  onTap: () {
                    integrante.igrejas ??= [];
                    innerState(() {
                      inscrito
                          ? integrante.igrejas?.removeWhere((element) =>
                              element.toString() ==
                              igrejas[index].reference.toString())
                          : integrante.igrejas?.add(igrejas[index].reference);
                    });
                  },
                  // Card da Igreja
                  child: Stack(
                    alignment: AlignmentDirectional.topEnd,
                    children: [
                      Card(
                        clipBehavior: Clip.antiAlias,
                        margin: const EdgeInsets.only(top: 8, right: 8),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.grey.withOpacity(0.5)),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8)),
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Foto da igreja
                              SizedBox(
                                height: 56,
                                width: 64,
                                child: MyNetwork.getImageFromUrl(
                                        igrejas[index].data().fotoUrl, null) ??
                                    const Icon(Icons.church),
                              ),
                              // Sigla
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  igrejas[index].data().sigla.toUpperCase(),
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                            ]),
                      ),
                      // Icone inscrito
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 12,
                        child: inscrito
                            ? Icon(Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary)
                            : const Icon(Icons.remove_circle,
                                color: Colors.grey),
                      ),
                    ],
                  ),
                );
              },
              growable: false,
            ).toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: (integrante.igrejas?.isNotEmpty ?? false)
                ? () async {
                    await MeuFirebase.salvarIntegrante(integrante,
                        id: Global.integranteLogado!.id);
                    Global.igrejaSelecionada.value = igrejas.firstWhere(
                        (element) =>
                            element.reference.toString() ==
                            integrante.igrejas![0].toString());
                  }
                : null,
            child: const Text('INSCREVER-ME'),
          )
        ],
      ));
    });
  }
}
