import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/global.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';

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
    TextEditingController nascimento = TextEditingController();
    return Column(
      children: [
        Expanded(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // Funções
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: LayoutBuilder(builder: (context, constraints) {
                  return StatefulBuilder(
                    builder: (context, innerState) {
                      return ToggleButtons(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8)),
                        constraints: BoxConstraints(
                            minWidth: (constraints.maxWidth - 6) / 5,
                            maxWidth: (constraints.maxWidth - 6) / 5,
                            minHeight: 56),
                        color: Colors.grey,
                        selectedColor: Colors.orange,
                        fillColor: Colors.orange.withOpacity(0.15),
                        children: List.generate(
                          Funcao.values.length,
                          (index) => _iconeComLegenda(
                            funcaoGetIcon(Funcao.values[index]),
                            funcaoGetString(Funcao.values[index]),
                          ),
                        ).toList(),
                        isSelected: List.generate(
                            Funcao.values.length,
                            (index) =>
                                integrante.funcoes
                                    ?.contains(Funcao.values[index]) ??
                                false),
                        onPressed: (Global.integranteLogado?.data()?.adm ??
                                    false) &&
                                editMode
                            ? (index) {
                                innerState(
                                  (() {
                                    var funcao = Funcao.values[index];
                                    integrante.funcoes ??= [];
                                    integrante.funcoes!.isEmpty
                                        ? integrante.funcoes?.add(funcao)
                                        : integrante.funcoes!.contains(funcao)
                                            ? integrante.funcoes!.remove(funcao)
                                            : integrante.funcoes!.add(funcao);
                                  }),
                                );
                              }
                            : (index) {},
                      );
                    },
                  );
                }),
              ),
              // Informações básicas
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatefulBuilder(
                      builder: (innerContext, StateSetter innerState) {
                    // preencha data de nascimento
                    nascimento.text = integrante.dataNascimento == null
                        ? ''
                        : DateFormat.MMMd('pt_BR')
                            .format(integrante.dataNascimento!.toDate());
                    // interface
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Foto
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
                        // Data de Nascimento
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 3,
                          child: TextFormField(
                            controller: nascimento,
                            enabled: editMode,
                            readOnly: true,
                            decoration: InputDecoration(
                                labelText: 'Aniversário',
                                disabledBorder: InputBorder.none,
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                prefixIcon: integrante.dataNascimento == null ||
                                        !editMode
                                    ? const Icon(Icons.cake)
                                    : IconButton(
                                        onPressed: (() => innerState(() =>
                                            integrante.dataNascimento = null)),
                                        icon: const Icon(Icons.clear))),
                            onTap: editMode
                                ? () async {
                                    final DateTime? pick = await showDatePicker(
                                        context: context,
                                        initialDate: integrante.dataNascimento
                                                ?.toDate() ??
                                            DateTime.now(),
                                        firstDate: DateTime(1930),
                                        lastDate: DateTime(
                                            DateTime.now().year, 12, 31));
                                    if (pick != null) {
                                      innerState(() =>
                                          integrante.dataNascimento =
                                              Timestamp.fromDate(pick));
                                    }
                                  }
                                : () {},
                          ),
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
                          decoration: InputDecoration(
                            labelText: editMode ? 'Nome' : null,
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
                  child: _verInstrumentos(context)),

              // Igrejas
              const Text('IGREJAS (em que pode ser escalado)'),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: _verIgrejas(context),
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
                    !novoCadastro &&
                            (Global.integranteLogado?.data()?.adm ?? false)
                        ? StatefulBuilder(builder: (_, innerState) {
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
                          })
                        : const SizedBox(),
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
                          Modular.to.pop(); // Fecha progresso
                          Modular.to.maybePop(); // Fecha dialog ou tela
                        }
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
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData),
          const SizedBox(height: 4),
          Text(
            legenda,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _verInstrumentos(BuildContext context) {
    return FutureBuilder<QuerySnapshot<Instrumento>>(
      future: MeuFirebase.obterListaInstrumentos(ativo: true),
      builder: ((context, snapshot) {
        var instrumentos = snapshot.data?.docs;
        if (instrumentos == null || instrumentos.isEmpty) {
          return Text(
            'Nenhum instrumento cadastrado!',
            style: Theme.of(context).textTheme.bodySmall,
          );
        }
        if (!editMode) {
          instrumentos.removeWhere((element) {
            if (integrante.instrumentos == null ||
                integrante.instrumentos!.isEmpty) {
              return true;
            }
            if (integrante.instrumentos!
                .map((e) => e.toString())
                .contains(element.reference.toString())) {
              return false;
            } else {
              return true;
            }
          });
          if (instrumentos.isEmpty) {
            return Text(
              'Nenhum instrumento selecionado',
              style: Theme.of(context).textTheme.bodySmall,
            );
          }
        }
        return StatefulBuilder(builder: (_, innerState) {
          return Wrap(
            spacing: 8,
            children: List.generate(instrumentos.length, (index) {
              var snapInstrumento = instrumentos[index];
              return ChoiceChip(
                label: Text(snapInstrumento.data().nome),
                avatar:
                    Image.asset(snapInstrumento.data().iconAsset, width: 12),
                selectedColor: Colors.blue,
                disabledColor: Colors.grey.withOpacity(0.1),
                pressElevation: 0,
                selected: integrante.instrumentos
                        ?.map((e) => e.toString())
                        .contains(snapInstrumento.reference.toString()) ??
                    false,
                onSelected: editMode
                    ? (check) {
                        integrante.instrumentos ??= [];
                        check
                            ? integrante.instrumentos
                                ?.add(snapInstrumento.reference)
                            : integrante.instrumentos?.removeWhere((element) =>
                                element.toString() ==
                                snapInstrumento.reference.toString());
                        innerState(() {});
                      }
                    : (check) {},
              );
            }).toList(),
          );
        });
      }),
    );
  }

  Widget _verIgrejas(BuildContext context) {
    return FutureBuilder<QuerySnapshot<Igreja>>(
        future: MeuFirebase.obterListaIgrejas(ativo: true),
        builder: ((context, snapshot) {
          var igrejas = snapshot.data?.docs;
          if (igrejas == null || igrejas.isEmpty) {
            return Text(
              'Nenhuma igreja cadastrada!',
              style: Theme.of(context).textTheme.bodySmall,
            );
          }
          if (!editMode) {
            igrejas.removeWhere((element) {
              if (integrante.igrejas == null || integrante.igrejas!.isEmpty) {
                return true;
              }
              if (integrante.igrejas!
                  .map((e) => e.toString())
                  .contains(element.reference.toString())) {
                return false;
              } else {
                return true;
              }
            });
            if (igrejas.isEmpty) {
              return Text(
                'Nenhuma igreja selecionada',
                style: Theme.of(context).textTheme.bodySmall,
              );
            }
          }
          return StatefulBuilder(builder: (context, innerState) {
            return Wrap(
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
                    onTap: editMode
                        ? () {
                            integrante.igrejas ??= [];
                            innerState(() {
                              inscrito
                                  ? integrante.igrejas?.removeWhere((element) =>
                                      element.toString() ==
                                      igrejas[index].reference.toString())
                                  : integrante.igrejas
                                      ?.add(igrejas[index].reference);
                            });
                          }
                        : null,
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
                                          igrejas[index].data().fotoUrl,
                                          null) ??
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
            );
          });
        }));
  }
}
