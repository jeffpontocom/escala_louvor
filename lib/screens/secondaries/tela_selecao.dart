//import 'dart:developer' as dev;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '/functions/metodos_firebase.dart';
import '/functions/metodos_integrante.dart';
import '/models/igreja.dart';
import '/utils/mensagens.dart';
import '/utils/global.dart';

class TelaContexto extends StatefulWidget {
  const TelaContexto({Key? key}) : super(key: key);

  @override
  State<TelaContexto> createState() => _TelaContextoState();
}

class _TelaContextoState extends State<TelaContexto> {
  List<QueryDocumentSnapshot<Igreja>> igrejas = [];
  var carouselController = CarouselController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Modular.routerDelegate.canPop()
            ? BackButton(
                onPressed: () async {
                  if (!await Modular.to.maybePop()) {
                    Modular.to.pushNamed(Global.rotaInicial);
                  }
                },
              )
            : null,
        title: const Text('Selecione a igreja'),
      ),
      body: _layout,
      // Versão do app
      bottomNavigationBar: Container(
        alignment: Alignment.center,
        color: Colors.transparent,
        height: 40,
        child: Global.versaoDoAppText,
      ),
    );
  }

  /// Corpo
  get _layout {
    return OrientationBuilder(builder: (context, orientation) {
      // MODO RETRATO
      if (orientation == Orientation.portrait) {
        return Column(
          children: [
            Expanded(
              flex: 7,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      child: carroselOpcoes,
                    ),
                  ),
                  opcaoMostrarTudo
                ],
              ),
            ),
            Flexible(
              flex: 3,
              child: Container(
                alignment: Alignment.center,
                child: botaoInscricao,
              ),
            ),
          ],
        );
      }
      // MODO PAISAGEM
      return Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    child: carroselOpcoes,
                  ),
                ),
                opcaoMostrarTudo,
              ],
            ),
          ),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: botaoInscricao,
            ),
          ),
        ],
      );
    });
  }

  /// Carrossel de opções (Igrejas inscritas)
  get carroselOpcoes {
    return ValueListenableBuilder(
        valueListenable: Global.igrejaSelecionada,
        builder: (context, select, _) {
          return FutureBuilder<QuerySnapshot<Igreja>>(
              future: MeuFirebase.obterListaIgrejas(ativo: true),
              builder: (context, snapshot) {
                // RETORNO: Carregamento
                if (!snapshot.hasData) {
                  return CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.secondary);
                }

                igrejas = snapshot.data?.docs ?? [];

                // RETORNO: Nenhuma igreja encontrada
                if (igrejas.isEmpty) {
                  return Text(
                    'Nenhuma igreja encontrada na base de dados!\n\nFale com o administrador.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  );
                }

                // Verificação de inscrições
                List<QueryDocumentSnapshot<Igreja>> inscritas = [];
                for (var igreja in igrejas) {
                  if (Global.logado?.igrejas
                          ?.map((e) => e.toString())
                          .contains(igreja.reference.toString()) ??
                      false) {
                    inscritas.add(igreja);
                  }
                }

                // RETORNO: Nenhuma inscrição encontrada
                if (inscritas.isEmpty) {
                  return Text(
                    'Inscreva-se em ao menos um igreja.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  );
                }

                // RETORNO: Carrossel
                return SizedBox(
                  child: CarouselSlider.builder(
                      carouselController: carouselController,
                      options: CarouselOptions(
                        enableInfiniteScroll: false,
                        enlargeCenterPage: true,
                        scrollPhysics: const BouncingScrollPhysics(),
                      ),
                      itemCount: inscritas.length,
                      itemBuilder: (context, index, realIndex) {
                        bool selecionada =
                            inscritas[index].reference.toString() ==
                                Global.igrejaSelecionada.value?.reference
                                    .toString();

                        if (selecionada) {
                          WidgetsBinding.instance
                              .scheduleFrameCallback((duration) {
                            carouselController.animateToPage(index);
                          });
                        }

                        // Card da Igreja
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            side: selecionada
                                ? BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    width: 3)
                                : const BorderSide(color: Colors.grey),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(16)),
                          ),
                          child: InkWell(
                            onTap: () async {
                              Mensagem.aguardar(
                                context: context,
                                mensagem: 'Alterando contexto...',
                              );
                              String id = inscritas[index].reference.id;
                              var igreja =
                                  await MeuFirebase.obterIgreja(id: id);
                              Modular.to.pop(); // fecha progresso
                              Modular.to.maybePop(true); // fecha dialog
                              Global.prefIgrejaId = id;
                              Global.igrejaSelecionada.value = igreja;
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
                                      child: inscritas[index].data().fotoUrl ==
                                              null
                                          ? const Icon(Icons.church)
                                          : CachedNetworkImage(
                                              fit: BoxFit.cover,
                                              imageUrl: inscritas[index]
                                                  .data()
                                                  .fotoUrl!),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Sigla
                                  Text(
                                    inscritas[index].data().sigla.toUpperCase(),
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
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
                      }),
                );
              });
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

  /// Opção mostrar todos os cultos
  get opcaoMostrarTudo {
    return CheckboxListTile(
      value: Global.prefMostrarTodosOsCultos,
      activeColor: Theme.of(context).colorScheme.secondary,
      contentPadding:
          const EdgeInsets.only(left: 72, right: 16, top: 8, bottom: 8),
      title: const Text(
          'Apresentar a agenda de todas as igrejas na lista de escalas',
          textAlign: TextAlign.center),
      onChanged: (value) {
        setState(() {
          Global.prefMostrarTodosOsCultos = value!;
          Global.filtroMostrarTodosCultos.value =
              Global.prefMostrarTodosOsCultos;
        });
      },
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
    MetodosIntegrante(context, Global.logadoSnapshot!).editarIgrejas(igrejas);
  }
}
