//import 'dart:developer' as dev;

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '/functions/metodos_firebase.dart';
import '/global.dart';
import '/models/igreja.dart';
import '/models/integrante.dart';
import '/preferencias.dart';
import '/utils/mensagens.dart';
import '/utils/utils.dart';

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
              padding: EdgeInsets.all(16),
              child: Text(
                'Selecione a igreja',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Offside',
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Carrossel de opções
            Flexible(child: Center(child: carroselOpcoes)),
            // Espaço mínimo
            const SizedBox(height: 16),
            // Botão de inscrição
            botaoInscricao,
            // Opção mostrar todos os cultos
            CheckboxListTile(
              value: Preferencias.mostrarTodosOsCultos,
              tristate: false,
              contentPadding:
                  const EdgeInsets.only(left: 72, right: 16, top: 8, bottom: 8),
              onChanged: (value) {
                setState(() {
                  Preferencias.mostrarTodosOsCultos = value!;
                });
              },
              activeColor: Colors.orange,
              title: const Text(
                'Apresentar a agenda de todas as igrejas na lista de cultos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
            // Versão do app
            Container(
              alignment: Alignment.center,
              height: 36,
              //color: Colors.black12,
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
            return const CircularProgressIndicator(color: Colors.orange);
          }
          // Preenchimento
          igrejas = snapshot.data?.docs ?? [];
          // Retorna interface de falha ao encontrar ao menos um grupo
          if (igrejas.isEmpty) {
            return Text(
              'Nenhuma igreja encontrada na base de dados!\n\nFale com o administrador.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white),
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
          // Retorna interface de aviso para inscrição
          if (inscritas.isEmpty) {
            return Text(
              'Inscreva-se em ao menos um igreja.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white),
            );
          }
          // Retorna carrossel
          var carouselController = CarouselController();
          return SizedBox(
            height: 300,
            child: CarouselSlider.builder(
              carouselController: carouselController,
              options: CarouselOptions(
                enableInfiniteScroll: false,
                enlargeCenterPage: true,
                scrollPhysics: const BouncingScrollPhysics(),
              ),
              itemCount: inscritas.length,
              itemBuilder: (context, index, realIndex) {
                bool selecionada = inscritas[index].reference.toString() ==
                    Global.igrejaSelecionada.value?.reference.toString();
                if (selecionada) {
                  WidgetsBinding.instance?.scheduleFrameCallback((timeStamp) {
                    carouselController.animateToPage(index);
                  });
                }
                // Card da Igreja
                return Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    side: selecionada
                        ? const BorderSide(color: Colors.orange, width: 3)
                        : const BorderSide(color: Colors.grey),
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                  ),
                  child: InkWell(
                    onTap: () async {
                      Mensagem.aguardar(context: context);
                      String? id = inscritas[index].reference.id;
                      Preferencias.igreja = id;
                      Global.igrejaSelecionada.value =
                          await MeuFirebase.obterSnapshotIgreja(id);
                      Modular.to.pop(); // fecha progresso
                      Modular.to.maybePop(true); // fecha dialog
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      width: double.maxFinite,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Foto da igreja
                          Expanded(
                            child: Container(
                              width: double.maxFinite,
                              clipBehavior: Clip.antiAlias,
                              decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(12))),
                              child: MyNetwork.getImageFromUrl(
                                      inscritas[index].data().fotoUrl) ??
                                  const Icon(Icons.church),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Sigla
                          Text(
                            inscritas[index].data().sigla.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          // Nome
                          Text(
                            inscritas[index].data().nome,
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        });
  }

  /// Botão de inscrição
  get botaoInscricao {
    return ElevatedButton.icon(
      icon: const Icon(Icons.add),
      label: const Text('IGREJAS'),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        minimumSize: const Size(172, 40),
        primary: Colors.white,
        onPrimary: Colors.black,
      ),
      onPressed: _mostrarOpcoesParaInscricao,
    );
  }

  /* MÉTODOS */
  void _mostrarOpcoesParaInscricao() {
    if (igrejas.isEmpty) {
      return Mensagem.simples(
          context: context,
          titulo: 'Atenção!',
          mensagem: 'Nenhuma igreja cadastrada na base de dados');
    }
    Integrante integrante = Global.integranteLogado!.data()!;
    return Mensagem.bottomDialog(
      context: context,
      titulo: 'Igrejas',
      conteudo: StatefulBuilder(builder: (context, innerState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Selecione uma ou mais igrejas em que você pode ser escalado'),
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
                    onTap: () async {
                      integrante.igrejas ??= [];
                      innerState(() {
                        inscrito
                            ? integrante.igrejas?.removeWhere((element) =>
                                element.toString() ==
                                igrejas[index].reference.toString())
                            : integrante.igrejas?.add(igrejas[index].reference);
                      });
                      if (!(integrante.igrejas
                              ?.map((e) => e.toString())
                              .contains(Global
                                  .igrejaSelecionada.value?.reference
                                  .toString()) ??
                          false)) {
                        Global.igrejaSelecionada.value = null;
                      }
                      await Global.integranteLogado?.reference
                          .update({'igrejas': integrante.igrejas});
                      setState(() {});
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
            /* ElevatedButton(
              onPressed: () async {
                Modular.to.pop(); // Fecha dialogo
                await MeuFirebase.salvarIntegrante(integrante,
                    id: Global.integranteLogado!.id);
                setState(() {});
              },
              child: const Text('ATUALIZAR'),
            ),
            const SizedBox(height: 24), */
          ],
        );
      }),
    );
  }
}
