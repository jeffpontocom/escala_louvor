import 'dart:developer' as dev;

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/utils/medidas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../functions/metodos_firebase.dart';
import '../global.dart';
import '../models/igreja.dart';
import '../models/integrante.dart';
import '../preferencias.dart';
import '../utils/mensagens.dart';
import '../utils/utils.dart';

class TelaSelecao extends StatefulWidget {
  const TelaSelecao({Key? key}) : super(key: key);

  @override
  State<TelaSelecao> createState() => _TelaSelecaoState();
}

class _TelaSelecaoState extends State<TelaSelecao> {
  List<QueryDocumentSnapshot<Igreja>> igrejas = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Título
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Selecione a igreja',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Offside',
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
            ),
            // Carrossel de opções
            /* Flexible(
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(
                    horizontal: Medidas.bodyPadding(context), vertical: 16),
                child: OverflowBox(
                  maxHeight: 250,
                  child: carroselOpcoes,
                ),
              ),
            ), */
            Flexible(child: carroselOpcoes),
            // Botão de inscrição
            Padding(
              padding: const EdgeInsets.all(24),
              child: botaoInscricao,
            ),
            // Versão do app
            Container(
              alignment: Alignment.center,
              height: 36,
              color: Colors.black38,
              child: Global.versaoDoAppText,
            ),
          ],
        ),
      ),
    );
  }

  /// Carrossel de opções (Grupos inscritos)
  get carroselOpcoes {
    return FutureBuilder<QuerySnapshot<Igreja>>(
        future: MeuFirebase.obterListaIgrejas(ativo: true),
        builder: (context, snapshot) {
          // Retorna interface de carregamento
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }
          // Preenchimento
          igrejas = snapshot.data?.docs ?? [];
          // Retorna interface de falha ao encontrar ao menos um grupo
          if (igrejas.isEmpty) {
            return const Text(
                'Nenhuma igreja encontrada na base de dados!\n\nFale com o administrador');
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
          // Retorna interface de aviso para inscrição
          if (inscritas.isEmpty) {
            return const Text('Inscreva-se em ao menos um igreja.');
          }
          // Retorna carrossel
          return Center(
            child: CarouselSlider.builder(
                itemCount: inscritas.length,
                itemBuilder: (context, index, b) {
                  bool inscrita = inscritas[index].reference.toString() ==
                      Global.igrejaSelecionada.value?.reference.toString();
                  // Card da Igreja
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        side: inscrita
                            ? const BorderSide(color: Colors.orange, width: 3)
                            : const BorderSide(color: Colors.grey),
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
                          Preferencias.igreja = id;
                          Global.igrejaSelecionada.value =
                              await MeuFirebase.obterSnapshotIgreja(id);
                          Modular.to.pop(); // fecha progresso
                          Modular.to.maybePop(true); // fecha dialog
                        },
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Foto da igreja
                              SizedBox(
                                height: 128,
                                //width: 160,
                                child: MyNetwork.getImageFromUrl(
                                        inscritas[index].data().fotoUrl) ??
                                    const Center(child: Icon(Icons.church)),
                              ),
                              // Sigla
                              const SizedBox(height: 8),
                              Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Text(
                                    inscritas[index].data().sigla.toUpperCase(),
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  )),
                              // Nome
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                //alignment: Alignment.center,
                                //height: 64,
                                child: Text(
                                  inscritas[index].data().nome,
                                  softWrap: true,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 3,
                                ),
                              ),
                              /* ElevatedButton.icon(
                            onPressed: inscritas[index].data().endereco == null
                                ? null
                                : () => MyActions.openGoogleMaps(
                                    street: inscritas[index].data().endereco!),
                            style: ElevatedButton.styleFrom(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero)),
                            icon: const Icon(Icons.map),
                            label: const Text('Mapa'),
                          ), */
                            ]),
                      ),
                    ),
                  );
                },
                options: CarouselOptions(
                    enlargeStrategy: CenterPageEnlargeStrategy.scale)),
          );
          /* return ListView.separated(
            scrollDirection: Axis.horizontal,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemCount: inscritas.length,
            itemBuilder: (context, index) {
              bool inscrita = inscritas[index].reference.toString() ==
                  Global.igrejaSelecionada.value?.reference.toString();
              // Card da Igreja
              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    side: inscrita
                        ? const BorderSide(color: Colors.orange, width: 3)
                        : const BorderSide(color: Colors.grey),
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
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
                      Preferencias.igreja = id;
                      Global.igrejaSelecionada.value =
                          await MeuFirebase.obterSnapshotIgreja(id);
                      Modular.to.pop(); // fecha progresso
                      Modular.to.maybePop(true); // fecha dialog
                    },
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Foto da igreja
                          SizedBox(
                            height: 128,
                            //width: 160,
                            child: MyNetwork.getImageFromUrl(
                                    inscritas[index].data().fotoUrl) ??
                                const Center(child: Icon(Icons.church)),
                          ),
                          // Sigla
                          const SizedBox(height: 8),
                          Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                inscritas[index].data().sigla.toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              )),
                          // Nome
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            //alignment: Alignment.center,
                            //height: 64,
                            child: Text(
                              inscritas[index].data().nome,
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 3,
                            ),
                          ),
                          /* ElevatedButton.icon(
                            onPressed: inscritas[index].data().endereco == null
                                ? null
                                : () => MyActions.openGoogleMaps(
                                    street: inscritas[index].data().endereco!),
                            style: ElevatedButton.styleFrom(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero)),
                            icon: const Icon(Icons.map),
                            label: const Text('Mapa'),
                          ), */
                        ]),
                  ),
                ),
              );
            },
          ); */
        });
  }

  /// Botão de inscrição
  get botaoInscricao {
    return ElevatedButton.icon(
      icon: const Icon(Icons.add),
      label: const Text('Inscrever-me'),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        minimumSize: const Size(172, 40),
        primary: Colors.white,
        onPrimary: Colors.black,
      ),
      onPressed: igrejas.isEmpty ? null : _mostrarOpcoesParaInscricao,
    );
  }

  /* MÉTODOS */
  void _mostrarOpcoesParaInscricao() {
    Integrante integrante = Global.integranteLogado!.data()!;
    return Mensagem.bottomDialog(
      context: context,
      titulo: 'Opções',
      conteudo: StatefulBuilder(builder: (context, innerState) {
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
                            side:
                                BorderSide(color: Colors.grey.withOpacity(0.5)),
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
                                          igrejas[index].data().fotoUrl) ??
                                      const Icon(Icons.church),
                                ),
                                // Sigla
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    igrejas[index].data().sigla.toUpperCase(),
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
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
      }),
    );
  }
}
