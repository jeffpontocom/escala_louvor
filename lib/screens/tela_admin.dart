import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/screens/views/view_integrante.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../functions/metodos_firebase.dart';
import '../models/igreja.dart';
import '../models/instrumento.dart';
import '../models/integrante.dart';
import '../utils/estilos.dart';
import '../utils/mensagens.dart';
import '../utils/utils.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({Key? key}) : super(key: key);

  /* WIDGETS */
  Widget tituloSecao(titulo) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        titulo,
        style: Estilo.secaoTitulo,
      ),
    );
  }

  /* Widget _iconeComLegenda(IconData iconData, String legenda) {
    return Wrap(
      direction: Axis.vertical,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Icon(iconData),
        Text(legenda),
      ],
    );
  } */

  /* DIALOGS */

  /// Abre lista de igreja
  void _verIgrejas(BuildContext context) {
    bool verAtivas = true;
    Mensagem.bottomDialog(
        context: context,
        titulo: 'Igrejas e locais de culto',
        icon: Icons.church,
        conteudo: StatefulBuilder(builder: (innerContext, innerState) {
          return Column(
            //mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                child: Row(
                  children: [
                    const Text('Exibindo:'),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(verAtivas
                          ? 'Cadastros ativos'
                          : 'Cadastros inativos'),
                      selected: verAtivas,
                      selectedColor: Colors.green,
                      backgroundColor: Colors.red,
                      onSelected: (value) {
                        innerState((() {
                          verAtivas = !verAtivas;
                        }));
                      },
                    ),
                    const Expanded(child: SizedBox()),
                    const SizedBox(
                      height: 30,
                      child: VerticalDivider(),
                    ),
                    ActionChip(
                        avatar: const Icon(Icons.add_circle),
                        label: const Text('NOVA'),
                        onPressed: () {
                          _editarIgreja(context);
                        }),
                  ],
                ),
              ),
              FutureBuilder<QuerySnapshot<Igreja>>(
                future: MeuFirebase.obterListaIgrejas(ativo: verAtivas),
                builder: ((context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      heightFactor: 4,
                      child: CircularProgressIndicator(),
                    );
                  }
                  return snapshot.data!.docs.isEmpty
                      ? const Center(
                          heightFactor: 10,
                          child: Text('Nenhuma igreja cadastrada'),
                        )
                      : Expanded(
                          child: ListView(
                            shrinkWrap: true,
                            children:
                                List.generate(snapshot.data!.size, (index) {
                              Igreja igreja = snapshot.data!.docs[index].data();
                              DocumentReference reference =
                                  snapshot.data!.docs[index].reference;
                              return ListTile(
                                leading: CircleAvatar(
                                  child: const Icon(Icons.church),
                                  foregroundImage:
                                      MyNetwork.getImageFromUrl(igreja.fotoUrl)
                                          ?.image,
                                ),
                                title: Text(igreja.sigla),
                                subtitle: Text(igreja.nome),
                                // Botão mapa do google
                                trailing: igreja.endereco == null
                                    ? null
                                    : IconButton(
                                        onPressed: () =>
                                            MyActions.openGoogleMaps(
                                                street: igreja.endereco!),
                                        icon: const Icon(Icons.map,
                                            color: Colors.blue),
                                      ),
                                onTap: () => _editarIgreja(context,
                                    igreja: igreja, id: reference.id),
                              );
                            }),
                          ),
                        );
                }),
              ),
            ],
          );
        }));
  }

  /// Edita os metadados da igreja
  void _editarIgreja(BuildContext context, {Igreja? igreja, String? id}) {
    bool novoCadastro = false;
    if (igreja == null) {
      novoCadastro = true;
      igreja = Igreja(sigla: '', nome: '');
    }
    Mensagem.bottomDialog(
      context: context,
      titulo: novoCadastro ? 'Novo cadastro' : 'Editar Cadastro',
      icon: Icons.church,
      conteudo: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          Row(
            children: [
              // Foto
              StatefulBuilder(builder: (innerContext, StateSetter innerState) {
                return Stack(
                  alignment: AlignmentDirectional.bottomEnd,
                  children: [
                    CircleAvatar(
                      child: const Icon(Icons.church),
                      foregroundImage:
                          MyNetwork.getImageFromUrl(igreja?.fotoUrl)?.image,
                      backgroundColor: Colors.grey.withOpacity(0.5),
                      radius: 56,
                    ),
                    CircleAvatar(
                      radius: 16,
                      child: IconButton(
                          iconSize: 16,
                          onPressed: () async {
                            var url = await MeuFirebase.carregarFoto(context);
                            if (url != null && url.isNotEmpty) {
                              innerState(() {
                                igreja!.fotoUrl = url;
                              });
                            }
                          },
                          icon: const Icon(Icons.add_a_photo)),
                    ),
                  ],
                );
              }),
              const SizedBox(width: 24),
              Expanded(
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sigla
                  TextFormField(
                    initialValue: igreja.sigla,
                    decoration: const InputDecoration(labelText: 'Sigla'),
                    onChanged: (value) {
                      igreja!.sigla = value;
                    },
                  ),
                  // Nome
                  TextFormField(
                    initialValue: igreja.nome,
                    decoration:
                        const InputDecoration(labelText: 'Nome completo'),
                    onChanged: (value) {
                      igreja!.nome = value;
                    },
                  ),
                ],
              )),
            ],
          ),
          // Endereço
          TextFormField(
            initialValue: igreja.endereco,
            decoration: const InputDecoration(labelText: 'Endereço'),
            onChanged: (value) {
              igreja!.endereco = value;
            },
          ),
          // Responsável
          FutureBuilder<QuerySnapshot<Integrante>?>(
            future: MeuFirebase.obterListaIntegrantes(ativo: true),
            builder: ((context, snapshot) {
              // Chave para redefinir formulários
              final GlobalKey<FormFieldState> _key =
                  GlobalKey<FormFieldState>();
              // Lista dos integrantes ativos
              var lista = List.generate(
                snapshot.data?.size ?? 0,
                (index) => DropdownMenuItem(
                  value: snapshot.data?.docs[index],
                  child: Text(snapshot.data?.docs[index].data().nome ?? ''),
                ),
                growable: false,
              );
              // Define valor inicial para o campo
              dynamic initialData;
              try {
                var index = snapshot.data?.docs.indexWhere((element) =>
                    element.id == (igreja?.responsavel?.id ?? 'erro'));
                initialData = lista[index ?? 0].value;
              } catch (e) {
                dev.log('Exception ' + e.toString(), name: 'CarregarFoto');
              }
              return StatefulBuilder(builder: (_, innerState) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<
                          QueryDocumentSnapshot<Integrante>>(
                        key: _key,
                        value: initialData,
                        items: lista,
                        onChanged: (value) {
                          igreja!.responsavel = value?.reference;
                        },
                        decoration:
                            const InputDecoration(labelText: 'Responsável'),
                      ),
                    ),
                    CloseButton(
                      color: Colors.grey,
                      onPressed: () => innerState(
                        (() {
                          initialData = null;
                          igreja!.responsavel = null;
                          _key.currentState?.reset();
                        }),
                      ),
                    )
                  ],
                );
              });
            }),
          ),
          const SizedBox(height: 36),
          Row(
            children: [
              // Ativo
              novoCadastro
                  ? const SizedBox()
                  : StatefulBuilder(builder: (_, innerState) {
                      return ChoiceChip(
                          label: Text(igreja!.ativo
                              ? 'Desativar cadastro'
                              : 'Reativar cadastro'),
                          selected: igreja.ativo,
                          selectedColor: Colors.red,
                          disabledColor: Colors.green,
                          onSelected: (value) async {
                            innerState((() => igreja!.ativo = !igreja.ativo));
                            await MeuFirebase.salvarIgreja(igreja!, id: id);
                            Modular.to.pop(); // Fecha dialog
                          });
                    }),
              const Expanded(child: SizedBox()),
              // Botão criar
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('SALVAR'),
                onPressed: () async {
                  // Abre progresso
                  Mensagem.aguardar(context: context);
                  // Salva os dados no firebase
                  await MeuFirebase.salvarIgreja(igreja!, id: id);
                  Modular.to.pop(); // Fecha progresso
                  Modular.to.pop(); // Fecha dialog
                },
              ),
            ],
          ),

          const SizedBox(height: 36),
        ],
      ),
    );
  }

  /// Abre lista instrumentos
  void _verInstrumentos(BuildContext context) {
    bool verAtivos = true;
    Mensagem.bottomDialog(
      context: context,
      titulo: 'Instrumentos e equipamentos',
      icon: Icons.music_video,
      conteudo: StatefulBuilder(builder: (innerContext, innerState) {
        return Column(
          //mainAxisSize: MainAxisSize.min,
          //shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: Row(
                children: [
                  const Text('Exibindo:'),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(
                        verAtivos ? 'Cadastros ativos' : 'Cadastros inativos'),
                    selected: verAtivos,
                    selectedColor: Colors.green,
                    backgroundColor: Colors.red,
                    onSelected: (value) {
                      innerState((() {
                        verAtivos = !verAtivos;
                      }));
                    },
                  ),
                  const Expanded(child: SizedBox()),
                  const SizedBox(
                    height: 30,
                    child: VerticalDivider(),
                  ),
                  ActionChip(
                      avatar: const Icon(Icons.add_circle),
                      label: const Text('NOVO'),
                      onPressed: () {
                        _editarInstrumento(context);
                      }),
                ],
              ),
            ),
            // Ajuda
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Segure e arraste para reordenar.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            // Lista
            FutureBuilder<QuerySnapshot<Instrumento>>(
              future: MeuFirebase.obterListaInstrumentos(ativo: verAtivos),
              builder: ((context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    heightFactor: 4,
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return const Center(
                    heightFactor: 10,
                    child: Text('Falha ao buscar instrumentos'),
                  );
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(
                    heightFactor: 10,
                    child: Text('Nenhum instrumento cadastrado'),
                  );
                }
                List<DocumentReference> references = [];
                List<Widget> _list =
                    List.generate(snapshot.data!.size, (index) {
                  Instrumento instrumento = snapshot.data!.docs[index].data();
                  DocumentReference reference =
                      snapshot.data!.docs[index].reference;
                  references.add(reference);
                  return ListTile(
                    key: Key(reference.id),
                    leading: Image.asset(
                      instrumento.iconAsset,
                      width: 28,
                      color: Theme.of(context).colorScheme.onBackground,
                      colorBlendMode: BlendMode.srcATop,
                    ),
                    title: Text(instrumento.nome),
                    subtitle: Text(
                        'Composição: mínima ${instrumento.composMin} | máxima ${instrumento.composMax}'),
                    //trailing: Text(instrumento.ordem.toString()),
                    onTap: () => _editarInstrumento(context,
                        instrumento: instrumento, id: reference.id),
                  );
                });

                return Expanded(
                  child: ReorderableListView(
                    shrinkWrap: true,
                    children: _list,
                    onReorder: (int old, int current) async {
                      dev.log('${old.toString()} | ${current.toString()}');
                      // dragging from top to bottom
                      if (old < current) {
                        Widget startItem = _list[old];
                        // 0 para 4 (i = 0; i < 4-1 ; i++)
                        for (int i = old; i < current - 1; i++) {
                          _list[i] = _list[i + 1];
                          references[i + 1].update({'ordem': i});
                        }
                        _list[current - 1] = startItem;
                        references[old].update({'ordem': current - 1});
                      }
                      // dragging from bottom to top
                      else if (old > current) {
                        Widget startItem = _list[old];
                        // 4 para 0 (i = 4; i > 0 ; i--)
                        for (int i = old; i > current; i--) {
                          _list[i] = _list[i - 1];
                          references[i - 1].update({'ordem': i});
                        }
                        _list[current] = startItem;
                        references[old].update({'ordem': current});
                      }
                      //innerState(() {});
                    },
                  ),
                );
              }),
            ),
          ],
        );
      }),
    );
  }

  /// Edita os metadados do instrumento
  void _editarInstrumento(BuildContext context,
      {Instrumento? instrumento, String? id}) {
    bool novoCadastro = false;
    if (instrumento == null) {
      novoCadastro = true;
      instrumento =
          Instrumento(nome: '', iconAsset: 'assets/icons/music_voz.png');
    }
    Mensagem.bottomDialog(
      context: context,
      titulo: novoCadastro ? 'Novo cadastro' : 'Editar Cadastro',
      icon: Icons.music_video,
      conteudo: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          Row(
            children: [
              // Icone
              StatefulBuilder(builder: (innerContext, StateSetter innerState) {
                return CircleAvatar(
                  child: PopupMenuButton<String>(
                    icon: Image.asset(
                      instrumento?.iconAsset ?? 'assets/icons/music_voz.png',
                      color: Theme.of(context).colorScheme.onBackground,
                      colorBlendMode: BlendMode.srcATop,
                    ),
                    itemBuilder: (context) {
                      List<String> assets = [
                        'assets/icons/music_baixo.png',
                        'assets/icons/music_bateria.png',
                        'assets/icons/music_coordenador.png',
                        'assets/icons/music_dirigente.png',
                        'assets/icons/music_guitarra.png',
                        'assets/icons/music_percussao.png',
                        'assets/icons/music_sonorizacao.png',
                        'assets/icons/music_sopro.png',
                        'assets/icons/music_teclado.png',
                        'assets/icons/music_transmissao.png',
                        'assets/icons/music_violao.png',
                        'assets/icons/music_voz.png',
                      ];
                      return List.generate(
                        assets.length,
                        (index) => PopupMenuItem(
                          value: assets[index],
                          padding: const EdgeInsets.symmetric(
                              horizontal: 36, vertical: 8),
                          child: Image.asset(
                            assets[index],
                            width: 36,
                            color: Theme.of(context).colorScheme.onBackground,
                            colorBlendMode: BlendMode.srcATop,
                          ),
                        ),
                      );
                    },
                    iconSize: 36,
                    onSelected: (value) {
                      innerState((() => instrumento!.iconAsset = value));
                    },
                  ),
                  radius: 48,
                );
              }),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nome
                    TextFormField(
                      initialValue: instrumento.nome,
                      decoration: const InputDecoration(labelText: 'Nome'),
                      onChanged: (value) {
                        instrumento!.nome = value;
                      },
                    ),

                    // Min Composição
                    TextFormField(
                      initialValue: instrumento.composMin.toString(),
                      decoration:
                          const InputDecoration(labelText: 'Composição mínima'),
                      onChanged: (value) {
                        value.isEmpty
                            ? instrumento!.composMin = 0
                            : instrumento!.composMin = int.parse(value);
                      },
                    ),
                    // Max Composição
                    TextFormField(
                      initialValue: instrumento.composMax.toString(),
                      decoration:
                          const InputDecoration(labelText: 'Composição máxima'),
                      onChanged: (value) {
                        value.isEmpty
                            ? instrumento!.composMax = 0
                            : instrumento!.composMax = int.parse(value);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          Row(
            children: [
              // Ativo
              novoCadastro
                  ? const SizedBox()
                  : StatefulBuilder(builder: (_, innerState) {
                      return ChoiceChip(
                          label: Text(instrumento!.ativo
                              ? 'Desativar cadastro'
                              : 'Reativar cadastro'),
                          selected: instrumento.ativo,
                          selectedColor: Colors.red,
                          disabledColor: Colors.green,
                          onSelected: (value) async {
                            innerState((() =>
                                instrumento!.ativo = !instrumento.ativo));
                            await MeuFirebase.salvarInstrumento(instrumento!,
                                id: id);
                            Modular.to.pop(); // Fecha dialog
                          });
                    }),
              const Expanded(child: SizedBox()),
              // Botão criar
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('SALVAR'),
                onPressed: () async {
                  // Abre progresso
                  Mensagem.aguardar(context: context);
                  // Salva os dados no firebase
                  await MeuFirebase.salvarInstrumento(instrumento!, id: id);
                  Modular.to.pop(); // Fecha progresso
                  Modular.to.pop(); // Fecha dialog
                },
              ),
            ],
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  /// Abre lista de igreja
  void _verIntegrantes(BuildContext context) {
    bool verAtivos = true;
    Mensagem.bottomDialog(
        context: context,
        titulo: 'Integrantes da equipe',
        icon: Icons.groups,
        conteudo: StatefulBuilder(builder: (innerContext, innerState) {
          return Column(
            //mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                child: Row(
                  children: [
                    const Text('Exibindo:'),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(verAtivos
                          ? 'Cadastros ativos'
                          : 'Cadastros inativos'),
                      selected: verAtivos,
                      selectedColor: Colors.green,
                      backgroundColor: Colors.red,
                      onSelected: (value) {
                        innerState((() {
                          verAtivos = !verAtivos;
                        }));
                      },
                    ),
                    const Expanded(child: SizedBox()),
                    const SizedBox(
                      height: 30,
                      child: VerticalDivider(),
                    ),
                    ActionChip(
                        avatar: const Icon(Icons.add_circle),
                        label: const Text('NOVO'),
                        onPressed: () {
                          _editarIntegrante(context);
                        }),
                  ],
                ),
              ),
              StreamBuilder<QuerySnapshot<Integrante>>(
                stream: MeuFirebase.escutarIntegrantes(ativos: verAtivos),
                builder: ((context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      heightFactor: 4,
                      child: CircularProgressIndicator(),
                    );
                  }
                  return snapshot.data!.docs.isEmpty
                      ? const Center(
                          heightFactor: 10,
                          child: Text('Nenhum integrante cadastrado'),
                        )
                      : Expanded(
                          child: ListView(
                            shrinkWrap: true,
                            children:
                                List.generate(snapshot.data!.size, (index) {
                              Integrante integrante =
                                  snapshot.data!.docs[index].data();
                              DocumentReference reference =
                                  snapshot.data!.docs[index].reference;
                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text(MyStrings.getUserInitials(
                                      integrante.nome)),
                                  foregroundImage: MyNetwork.getImageFromUrl(
                                          integrante.fotoUrl)
                                      ?.image,
                                ),
                                title: Text(integrante.nome),
                                subtitle: Text(integrante.email),
                                trailing: integrante.telefone == null ||
                                        integrante.telefone!.isEmpty
                                    ? null
                                    : IconButton(
                                        onPressed: () => MyActions.openWhatsApp(
                                            integrante.telefone!),
                                        icon: const Icon(Icons.whatsapp,
                                            color: Colors.green),
                                      ),
                                onTap: () => _editarIntegrante(context,
                                    integrante: integrante, id: reference.id),
                              );
                            }),
                          ),
                        );
                }),
              ),
            ],
          );
        }));
  }

  /// Edita os metadados do instrumento
  void _editarIntegrante(BuildContext context,
      {Integrante? integrante, String? id}) {
    bool novoCadastro = false;
    if (integrante == null) {
      novoCadastro = true;
      integrante = Integrante(nome: '', email: '');
    }
    Mensagem.bottomDialog(
      context: context,
      titulo: novoCadastro ? 'Novo cadastro' : 'Editar Cadastro',
      icon: Icons.person,
      conteudo: ViewIntegrante(
        id: id,
        integrante: integrante,
        novoCadastro: novoCadastro,
        editMode: true,
      ),
    );
  }

  /* SISTEMA */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Administração do sistema',
          style: Estilo.appBarTitulo,
        ),
        titleSpacing: 0,
      ),
      body: Scrollbar(
        isAlwaysShown: true,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          children: [
            tituloSecao('Cadastros'),
            // Igrejas
            ListTile(
              leading: const Icon(Icons.church),
              title: const Text('Igrejas e locais de culto'),
              subtitle: FutureBuilder<int>(
                future:
                    MeuFirebase.totalCadastros(Igreja.collection, ativo: true),
                builder: ((context, snapshot) {
                  if (!snapshot.hasData) return const Text('verificando...');
                  int total = snapshot.data!;
                  String plural = MyStrings.isPlural(total);
                  return Text('$total cadastro$plural ativo$plural');
                }),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.add_circle),
                color: Theme.of(context).colorScheme.primary,
                onPressed: () => _editarIgreja(context),
              ),
              onTap: () => _verIgrejas(context),
            ),
            // Instrumentos
            ListTile(
              leading: const Icon(Icons.music_video),
              title: const Text('Instrumentos e equipamentos'),
              subtitle: FutureBuilder<int>(
                future: MeuFirebase.totalCadastros(Instrumento.collection,
                    ativo: true),
                builder: ((context, snapshot) {
                  if (!snapshot.hasData) return const Text('verificando...');
                  int total = snapshot.data!;
                  String plural = MyStrings.isPlural(total);
                  return Text('$total cadastro$plural ativo$plural');
                }),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.add_circle),
                color: Theme.of(context).colorScheme.primary,
                onPressed: () => _editarInstrumento(context),
              ),
              onTap: () => _verInstrumentos(context),
            ),
            // Integrantes
            ListTile(
              leading: const Icon(Icons.groups),
              title: const Text('Integrantes da equipe'),
              subtitle: FutureBuilder<int>(
                future: MeuFirebase.totalCadastros(Integrante.collection,
                    ativo: true),
                builder: ((context, snapshot) {
                  if (!snapshot.hasData) return const Text('verificando...');
                  int total = snapshot.data!;
                  String plural = MyStrings.isPlural(total);
                  return Text('$total cadastro$plural ativo$plural');
                }),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.add_circle),
                color: Theme.of(context).colorScheme.primary,
                onPressed: () => _editarIntegrante(context),
              ),
              onTap: () => _verIntegrantes(context),
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }
}
