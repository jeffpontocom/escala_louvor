import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/functions/metodos_firebase.dart';
import 'package:escala_louvor/screens/views/dialogos.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../models/cantico.dart';

class TelaCanticos extends StatefulWidget {
  const TelaCanticos({Key? key}) : super(key: key);

  @override
  State<TelaCanticos> createState() => _TelaCanticosState();
}

class _TelaCanticosState extends State<TelaCanticos> {
  bool mostrarCanticos = true;
  bool mostrarHinos = true;

  bool? get somenteHinos {
    if (mostrarCanticos && !mostrarHinos) {
      return false;
    } else if (!mostrarCanticos && mostrarHinos) {
      return true;
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<String> _filtro = ValueNotifier('');
    TextEditingController _f = TextEditingController();
    return Column(
      children: [
        // Filtros e Adição
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          color: Colors.grey.withOpacity(0.15),
          child: Row(
            children: [
              // Fitros
              const Text('APRESENTAR:'),
              const SizedBox(width: 8),
              Expanded(
                  child: Wrap(
                children: [
                  FilterChip(
                    label: const Text('Cânticos'),
                    selected: mostrarCanticos,
                    onSelected: (value) {
                      setState(() {
                        mostrarCanticos = value;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Hinos'),
                    selected: mostrarHinos,
                    onSelected: (value) {
                      setState(() {
                        mostrarHinos = value;
                      });
                    },
                  ),
                ],
              )),
              const SizedBox(width: 12),
              // Botão adicionar
              ActionChip(
                  avatar: const Icon(Icons.add),
                  label: const Text('Novo'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  onPressed: () {
                    var cantico = Cantico(nome: '');
                    Dialogos.editarCantico(context, cantico);
                  })
            ],
          ),
        ),
        const Divider(height: 1),
        const SizedBox(height: 8),
        // Campo de Busca
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: _f,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _f.clear(),
              ),
              hintText: 'Buscar...',
            ),
            onChanged: (value) {
              _filtro.value = value;
            },
          ),
        ),
        const SizedBox(height: 8),
        // Lista
        Expanded(
          child: StreamBuilder<QuerySnapshot<Cantico>>(
              stream: MeuFirebase.escutarCanticos(somenteHinos),
              builder: (_, canticos) {
                if (!canticos.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                List<QueryDocumentSnapshot<Cantico>>? listaOriginal =
                    canticos.data?.docs;
                List<QueryDocumentSnapshot<Cantico>> listaFiltrada = [];
                if (listaOriginal == null || listaOriginal.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(64),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        // Imagem
                        Image(
                          image: AssetImage('assets/images/song.png'),
                          height: 256,
                          width: 256,
                        ),
                        // Informação
                        Text(
                          'Nenhum cântico ou hino cadastrado',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                return ValueListenableBuilder<String>(
                    valueListenable: _filtro,
                    builder: (_, filtro, child) {
                      listaFiltrada.clear();
                      if (filtro.isEmpty || filtro.length < 4) {
                        listaFiltrada
                            .addAll(listaOriginal.where((element) => true));
                      } else {
                        listaFiltrada.addAll(listaOriginal.where((element) =>
                            element.data().nome.contains(filtro) ||
                            (element.data().autor?.contains(filtro) ?? false) ||
                            (element.data().letra?.contains(filtro) ?? false)));
                      }
                      if (listaFiltrada.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(64),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              // Imagem
                              Image(
                                image: AssetImage('assets/images/song.png'),
                                height: 256,
                                width: 256,
                              ),
                              // Informação
                              Text(
                                'Nenhum cântico ou hino encontrado na busca',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        children: List.generate(listaFiltrada.length, (index) {
                          return ListTile(
                            visualDensity: VisualDensity.compact,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            leading: IconButton(
                                onPressed: () {
                                  //ver letra
                                },
                                icon: const Icon(Icons.abc)),
                            horizontalTitleGap: 4,
                            title: Text(listaFiltrada[index].data().nome),
                            subtitle:
                                Text(listaFiltrada[index].data().autor ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Cifra
                                IconButton(
                                    onPressed: () {
                                      MeuFirebase.abrirArquivoPdf(context,
                                          listaFiltrada[index].data().cifraUrl);
                                    },
                                    icon: const Icon(Icons.queue_music)),
                                // YouTube
                                IconButton(
                                    onPressed: () async {
                                      if (!await launch(listaFiltrada[index]
                                              .data()
                                              .youTubeUrl ??
                                          '')) {
                                        throw 'Could not launch youTubeUrl';
                                      }
                                    },
                                    icon: const Icon(Icons.ondemand_video)),
                                // Menu
                                PopupMenuButton(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      Dialogos.editarCantico(
                                          context, listaFiltrada[index].data(),
                                          reference:
                                              listaFiltrada[index].reference);
                                    }
                                  },
                                  itemBuilder: (_) {
                                    return const [
                                      PopupMenuItem(
                                        child: Text('Editar'),
                                        value: 'edit',
                                      ),
                                      PopupMenuItem(
                                        child: Text('Adicionar ao culto...'),
                                        value: 'add',
                                      ),
                                    ];
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                      );
                    });
              }),
        ),
      ],
    );
  }
}
