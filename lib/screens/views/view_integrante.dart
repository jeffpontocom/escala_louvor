import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../global.dart';
import '../../preferencias.dart';
import '/functions/metodos_firebase.dart';
import '/models/igreja.dart';
import '/models/instrumento.dart';
import '/models/integrante.dart';
import '/utils/mensagens.dart';
import '/utils/utils.dart';

class ViewIntegrante extends StatelessWidget {
  final String? id;
  final Integrante integrante;
  final bool novoCadastro;
  final bool editMode;
  const ViewIntegrante({
    Key? key,
    this.id,
    required this.integrante,
    required this.novoCadastro,
    required this.editMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              // Funções
              editMode
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      child: LayoutBuilder(builder: (context, constraints) {
                        return StatefulBuilder(
                          builder: (_, innerState) {
                            return ToggleButtons(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(8)),
                              constraints: BoxConstraints(
                                  minWidth: (constraints.maxWidth - 6) / 5,
                                  minHeight: 56),
                              color: Colors.grey,
                              children: [
                                _iconeComLegenda(
                                    Icons.admin_panel_settings, 'Adm'),
                                _iconeComLegenda(Icons.mic, 'Dirigente'),
                                _iconeComLegenda(
                                    Icons.music_note, 'Coordenador'),
                                _iconeComLegenda(
                                    Icons.emoji_people, 'Integrante'),
                                _iconeComLegenda(
                                    Icons.chrome_reader_mode, 'Leitor'),
                              ],
                              isSelected: [
                                integrante.funcoes
                                        ?.contains(Funcao.administrador) ??
                                    false,
                                integrante.funcoes
                                        ?.contains(Funcao.dirigente) ??
                                    false,
                                integrante.funcoes
                                        ?.contains(Funcao.coordenador) ??
                                    false,
                                integrante.funcoes
                                        ?.contains(Funcao.integrante) ??
                                    false,
                                integrante.funcoes?.contains(Funcao.leitor) ??
                                    false,
                              ],
                              onPressed: (index) {
                                innerState(
                                  (() {
                                    var funcao = Funcao.values[index];
                                    integrante.funcoes == null ||
                                            integrante.funcoes!.isEmpty
                                        ? integrante.funcoes?.add(funcao)
                                        : integrante.funcoes!.contains(funcao)
                                            ? integrante.funcoes!.remove(funcao)
                                            : integrante.funcoes!.add(funcao);
                                  }),
                                );
                              },
                            );
                          },
                        );
                      }),
                    )
                  : const SizedBox(height: 24),

              // Informações básicas
              Row(
                children: [
                  // Foto
                  StatefulBuilder(
                      builder: (innerContext, StateSetter innerState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          child: IconButton(
                              iconSize: 48,
                              onPressed: editMode
                                  ? () async {
                                      var url =
                                          await MeuFirebase.carregarFoto();
                                      if (url != null && url.isNotEmpty) {
                                        innerState(() {
                                          integrante.fotoUrl = url;
                                        });
                                      }
                                    }
                                  : null,
                              icon: integrante.fotoUrl == null
                                  ? Icon(editMode
                                      ? Icons.add_a_photo
                                      : Icons.person)
                                  : const CircularProgressIndicator()),
                          foregroundImage: MyNetwork.getImageFromUrl(
                                  integrante.fotoUrl, null)
                              ?.image,
                          backgroundColor: Colors.grey.withOpacity(0.5),
                          radius: 48,
                        ),
                        const SizedBox(height: 8),
                        // Data de Nascimento
                        ActionChip(
                          avatar: Icon(Icons.cake,
                              color: Theme.of(context).colorScheme.primary),
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              side: BorderSide(
                                  color: editMode
                                      ? Colors.grey.shade300
                                      : Colors.transparent)),
                          label: Text(
                            integrante.dataNascimento == null
                                ? editMode
                                    ? 'Selecionar'
                                    : 'Pergunte'
                                : MyInputs.mascaraData.format(
                                    integrante.dataNascimento!.toDate()),
                          ),
                          onPressed: editMode
                              ? () async {
                                  final DateTime? pick = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          integrante.dataNascimento?.toDate() ??
                                              DateTime.now(),
                                      firstDate: DateTime(1930),
                                      lastDate: DateTime(
                                          DateTime.now().year, 12, 31));
                                  if (pick != null) {
                                    innerState(() => integrante.dataNascimento =
                                        Timestamp.fromDate(pick));
                                  }
                                }
                              : () {},
                        ),
                      ],
                    );
                  }),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Nome
                        TextFormField(
                          initialValue: integrante.nome,
                          enabled: editMode,
                          style: editMode
                              ? null
                              : const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            labelText: 'Nome',
                            disabledBorder: InputBorder.none,
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                          ),
                          onChanged: (value) {
                            integrante.nome = value;
                          },
                        ),
                        // Email
                        TextFormField(
                          enabled: novoCadastro,
                          initialValue: integrante.email,
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            disabledBorder: InputBorder.none,
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                          ),
                          onChanged: (value) {
                            integrante.email = value;
                          },
                        ),
                        // Telefone
                        TextFormField(
                          enabled: editMode,
                          initialValue: integrante.telefone,
                          decoration: InputDecoration(
                            labelText: 'WhatsApp',
                            disabledBorder: InputBorder.none,
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            suffixIcon: IconButton(
                              onPressed: integrante.telefone == null ||
                                      integrante.telefone!.isEmpty
                                  ? null
                                  : () {},
                              icon: const Icon(
                                Icons.whatsapp,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            integrante.telefone = value;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Instrumentos
              const Text('INSTRUMENTOS (habilidades)'),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: StatefulBuilder(builder: (_, innerState) {
                  return FutureBuilder<QuerySnapshot<Instrumento>>(
                      future: MeuFirebase.obterListaInstrumentos(ativo: true),
                      builder: ((context, snapshot) {
                        return Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children:
                              List.generate(snapshot.data?.size ?? 0, (index) {
                            var snapInstrumento = snapshot.data!.docs[index];
                            return ChoiceChip(
                              label: Text(snapInstrumento.data().nome),
                              avatar: Image.asset(
                                  snapInstrumento.data().iconAsset,
                                  width: 12),
                              selectedColor: Colors.blue,
                              disabledColor: Colors.grey.withOpacity(0.1),
                              selected: integrante.instrumentos
                                      ?.map((e) => e.toString())
                                      .contains(snapInstrumento.reference
                                          .toString()) ??
                                  false,
                              onSelected: editMode
                                  ? (check) {
                                      integrante.instrumentos ??= [];
                                      check
                                          ? integrante.instrumentos
                                              ?.add(snapInstrumento.reference)
                                          : integrante.instrumentos
                                              ?.removeWhere((element) =>
                                                  element.toString() ==
                                                  snapInstrumento.reference
                                                      .toString());
                                      innerState(() {});
                                    }
                                  : null,
                            );
                          }).toList(),
                        );
                      }));
                }),
              ),

              // Igrejas
              const Text('IGREJAS (em que pode ser escalado)'),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: StatefulBuilder(builder: (_, innerState) {
                  return Row(
                    children: [
                      editMode
                          ? IconButton(
                              onPressed: () => _addIgreja(context),
                              icon: const Icon(Icons.add_circle),
                            )
                          : const SizedBox(),
                      Wrap(
                        children: List.generate(
                          integrante.igrejas?.length ?? 0,
                          (index) => FutureBuilder<DocumentSnapshot<Igreja>?>(
                              future: MeuFirebase.obterSnapshotIgreja(
                                  integrante.igrejas![index].id),
                              builder: (_, snap) {
                                if (snap.hasData) {
                                  if (snap.data == null) {
                                    return const SizedBox();
                                  }
                                  return RawChip(
                                    label:
                                        Text(snap.data?.data()?.sigla ?? '?'),
                                    avatar: const Icon(Icons.church),
                                  );
                                }
                                return const CircularProgressIndicator();
                              }),
                        ).toList(),
                      ),
                    ],
                  );
                }),
              ),

              // Obs
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: TextFormField(
                  initialValue: integrante.obs,
                  enabled: editMode,
                  minLines: 4,
                  maxLines: 15,
                  decoration: const InputDecoration(
                    labelText: 'Observações',
                    disabledBorder: InputBorder.none,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  onChanged: (value) {
                    integrante.obs = value;
                  },
                ),
              ),
            ],
          ),
        ),
        editMode
            ? Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    // Ativo
                    novoCadastro ||
                            (integrante.funcoes
                                    ?.contains(Funcao.administrador) ??
                                false)
                        ? const SizedBox()
                        : StatefulBuilder(builder: (_, innerState) {
                            return ChoiceChip(
                                label: Text(integrante.ativo
                                    ? 'Desativar cadastro'
                                    : 'Reativar cadastro'),
                                selected: integrante.ativo,
                                selectedColor: Colors.red,
                                disabledColor: Colors.green,
                                onSelected: (value) async {
                                  innerState((() =>
                                      integrante.ativo = !integrante.ativo));
                                  await MeuFirebase.salvarIntegrante(integrante,
                                      id: id);
                                  Modular.to.pop(); // Fecha dialog
                                });
                          }),
                    const Expanded(child: SizedBox()),
                    // Botão criar
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: Text(novoCadastro ? 'CRIAR' : 'SALVAR'),
                      onPressed: () async {
                        // Abre progresso
                        Mensagem.aguardar(context: context);
                        // Salva os dados no firebase
                        var integranteId = id;
                        if (novoCadastro) {
                          var auth = await MeuFirebase.criarUsuario(
                              email: integrante.email,
                              senha: MyInputs.randomString(10));
                          integranteId = auth?.user?.uid;
                        }
                        if (integranteId == null) {
                          Mensagem.simples(
                            context: context,
                            titulo: 'Falha',
                            mensagem:
                                'Não foi possível registrar o novo integrante. Tente mais tarde novamente!',
                          );
                        } else {
                          await MeuFirebase.salvarIntegrante(integrante,
                              id: integranteId);
                        }
                        Modular.to.pop(); // Fecha progresso
                        Modular.to.pop(); // Fecha dialog
                      },
                    ),
                  ],
                ),
              )
            : const SizedBox(height: 24),
      ],
    );
  }

  Widget _iconeComLegenda(IconData iconData, String legenda) {
    return Wrap(
      direction: Axis.vertical,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Icon(iconData),
        Text(legenda),
      ],
    );
  }

  void _addIgreja(BuildContext context) {
    var conteudo = Padding(
      padding: EdgeInsets.all(24),
      child: FutureBuilder<QuerySnapshot<Igreja>>(
          future: MeuFirebase.obterListaIgrejas(ativo: true),
          builder: ((context, snapshot) {
            var igrejas = snapshot.data?.docs;
            if (igrejas == null || igrejas.isEmpty) {
              return Text('Erro');
            }
            return Wrap(
              children: List.generate(
                igrejas.length,
                (index) {
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    // Card da Igreja
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      color: igrejas[index].reference.toString() ==
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
                          String? id = igrejas[index].reference.id;
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
                                        igrejas[index].data().fotoUrl, null) ??
                                    const Center(child: Icon(Icons.church)),
                              ),
                              // Sigla
                              const SizedBox(height: 8),
                              Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Text(
                                    igrejas[index].data().sigla.toUpperCase(),
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  )),

                              // Nome
                              const SizedBox(height: 4),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(igrejas[index].data().nome),
                              ),
                              const SizedBox(height: 12),
                            ]),
                      ),
                    ),
                  );
                },
                growable: false,
              ).toList(),
            );
          })),
    );
    return Mensagem.bottomDialog(
        context: context, titulo: 'Adicionar igreja', conteudo: conteudo);
  }
}
