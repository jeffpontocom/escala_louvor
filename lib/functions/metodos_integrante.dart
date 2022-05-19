import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';

import '../widgets/tile_igreja.dart';
import 'metodos_firebase.dart';
import '/models/igreja.dart';
import '/models/instrumento.dart';
import '/models/integrante.dart';
import '../resources/medidas.dart';
import '/utils/mensagens.dart';
import '/utils/utils.dart';

class MetodosIntegrante {
  final BuildContext context;
  final DocumentSnapshot<Integrante> snapshot;

  MetodosIntegrante(this.context, this.snapshot);

  bool checarNulidade() {
    if (snapshot.data() == null) {
      Mensagem.simples(
        context: context,
        titulo: 'Falha',
        mensagem:
            'Houve um erro ao tentar executar a ação. Tente mais tarde novamente.',
      );
      return true;
    }
    return false;
  }

  Future salvarDados(Map<String, Object?> dados) async {
    // Abre progresso
    Mensagem.aguardar(context: context, mensagem: 'Atualizando...');
    await snapshot.reference.update(dados);
    // Fecha progresso
    Modular.to.pop();
  }

  /// Caixa de diálogo padrão
  void mostrarDialogo(Widget conteudo) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        builder: (context) {
          return OrientationBuilder(builder: (context, orientation) {
            return Container(
              constraints:
                  BoxConstraints(maxHeight: MediaQuery.of(context).size.height),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).viewInsets.top + 16,
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: Medidas.bodyPadding(context),
                right: Medidas.bodyPadding(context),
              ),
              child: conteudo,
            );
          });
        });
  }

  void editarDados() {
    if (checarNulidade()) return;

    Integrante integrante = snapshot.data()!;

    // Foto
    var widgetFoto =
        StatefulBuilder(builder: (innerContext, StateSetter innerState) {
      return Stack(
        alignment: AlignmentDirectional.bottomEnd,
        children: [
          CircleAvatar(
            radius: 56,
            backgroundColor: Colors.grey.withOpacity(0.5),
            foregroundImage:
                MyNetwork.getImageFromUrl(integrante.fotoUrl)?.image,
            child: Text(
              MyStrings.getUserInitials(integrante.nome),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor:
                integrante.fotoUrl == null || integrante.fotoUrl!.isEmpty
                    ? null
                    : Colors.red,
            child: integrante.fotoUrl == null || integrante.fotoUrl!.isEmpty
                ? IconButton(
                    iconSize: 16,
                    onPressed: () async {
                      var url = await MeuFirebase.carregarFoto(context);
                      if (url != null && url.isNotEmpty) {
                        innerState(() {
                          integrante.fotoUrl = url;
                        });
                      }
                    },
                    icon: const Icon(Icons.add_a_photo))
                : IconButton(
                    iconSize: 16,
                    onPressed: () async {
                      innerState(() {
                        integrante.fotoUrl = null;
                      });
                    },
                    icon: const Icon(Icons.no_photography)),
          ),
        ],
      );
    });

    // Data de Nascimento
    var widgetDataNascimento =
        StatefulBuilder(builder: (innerContext, StateSetter innerState) {
      var nascimentoFormatado = integrante.dataNascimento == null
          ? 'Informe seu aniversário'
          : DateFormat.MMMd('pt_BR')
              .format(integrante.dataNascimento!.toDate());
      return OutlinedButton.icon(
          onPressed: () async {
            final DateTime? pick = await showDatePicker(
                context: context,
                initialDate:
                    integrante.dataNascimento?.toDate() ?? DateTime.now(),
                firstDate: DateTime(1930),
                lastDate: DateTime(DateTime.now().year, 12, 31));
            if (pick != null) {
              innerState(
                  () => integrante.dataNascimento = Timestamp.fromDate(pick));
            }
          },
          icon: const Icon(Icons.cake),
          label: Text(nascimentoFormatado));
    });

    // Nome
    var widgetNome = TextFormField(
      initialValue: integrante.nome,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.name],
      decoration: const InputDecoration(labelText: 'Nome Completo'),
      onChanged: (value) {
        integrante.nome = value.trim();
      },
    );

    // Telefone
    var widgetTelefone = TextFormField(
      initialValue: integrante.telefone,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.telephoneNumberLocal],
      decoration: const InputDecoration(labelText: 'WhatsApp'),
      onChanged: (value) {
        integrante.telefone = value.trim();
      },
    );

    // Observações
    var widgetObs = TextFormField(
      initialValue: integrante.obs,
      keyboardType: TextInputType.multiline,
      decoration: const InputDecoration(labelText: 'Observações'),
      onChanged: (value) {
        integrante.obs = value;
      },
    );

    // Botão atualizar
    var btnAtualizar = ElevatedButton.icon(
        onPressed: () async {
          await salvarDados({
            'fotoUrl': integrante.fotoUrl,
            'dataNascimento': integrante.dataNascimento,
            'nome': integrante.nome,
            'telefone': integrante.telefone,
            'obs': integrante.obs,
          });
          Modular.to.pop(); // Fecha diálogo
        },
        icon: const Icon(Icons.save),
        label: const Text('ATUALIZAR'));

    // Conteúdo organizado
    var conteudo = Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        widgetFoto,
        widgetDataNascimento,
        widgetNome,
        widgetTelefone,
        widgetObs,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            btnAtualizar,
          ],
        ),
        const SizedBox(),
      ],
    );

    // Mostrar diálogo
    mostrarDialogo(conteudo);
  }

  /// Editar funções
  void editarFuncoes() {
    if (checarNulidade()) return;

    Integrante integrante = snapshot.data()!;

    // Conteúdo organizado
    var conteudo = StatefulBuilder(builder: (context, innerState) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        const Text(
          'Selecione um ou mais funções para o integrante.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(
            Funcao.values.length,
            (index) {
              Funcao funcao = Funcao.values[index];
              bool inscrito = integrante.funcoes
                      ?.map((e) => e.index)
                      .contains(funcao.index) ??
                  false;
              return CheckboxListTile(
                  title: Row(
                    children: [
                      Icon(funcaoGetIcon(funcao)),
                      const SizedBox(width: 8),
                      Text(funcaoGetString(funcao)),
                    ],
                  ),
                  tristate: false,
                  value: inscrito,
                  onChanged: (value) async {
                    integrante.funcoes ??= [];
                    innerState(() {
                      value == false
                          ? integrante.funcoes
                              ?.removeWhere((element) => element == funcao)
                          : integrante.funcoes?.add(funcao);
                    });
                    await snapshot.reference.update(
                        {'funcoes': funcaoParseList(integrante.funcoes)});
                  });
            },
            growable: false,
          ),
        ),
        const SizedBox(height: 16),
      ]);
    });

    mostrarDialogo(conteudo);
  }

  /// Editar instrumentos e habilidades
  void editarInstrumentos(
      List<QueryDocumentSnapshot<Instrumento>> instrumentos) {
    if (checarNulidade()) return;

    Integrante integrante = snapshot.data()!;

    // Conteúdo organizado
    var conteudo = StatefulBuilder(builder: (context, innerState) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        const Text(
          'Selecione um ou mais instrumentos, equipamentos ou habilidades em que pode ser escalado.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(
            instrumentos.length,
            (index) {
              bool inscrito = integrante.instrumentos
                      ?.map((e) => e.toString())
                      .contains(instrumentos[index].reference.toString()) ??
                  false;
              return CheckboxListTile(
                  title: Row(
                    children: [
                      Image.asset(instrumentos[index].data().iconAsset,
                          width: 24),
                      const SizedBox(width: 8),
                      Text(instrumentos[index].data().nome),
                    ],
                  ),
                  tristate: false,
                  value: inscrito,
                  onChanged: (value) async {
                    integrante.instrumentos ??= [];
                    innerState(() {
                      value == false
                          ? integrante.instrumentos?.removeWhere((element) =>
                              element.toString() ==
                              instrumentos[index].reference.toString())
                          : integrante.instrumentos
                              ?.add(instrumentos[index].reference);
                    });
                    await snapshot.reference
                        .update({'instrumentos': integrante.instrumentos});
                  });
            },
            growable: false,
          ),
        ),
        const SizedBox(height: 16),
      ]);
    });

    mostrarDialogo(conteudo);
  }

  /// Editar igrejas inscritas
  void editarIgrejas(List<QueryDocumentSnapshot<Igreja>> igrejas) {
    if (checarNulidade()) return;

    Integrante integrante = snapshot.data()!;

    // Conteúdo organizado
    var conteudo = StatefulBuilder(builder: (context, innerState) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        const Text(
          'Selecione uma ou mais igrejas em que pode ser escalado.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
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
                  /* if (!(integrante.igrejas?.map((e) => e.toString()).contains(
                            Global.igrejaSelecionada.value?.reference
                                .toString()) ??
                        false)) {
                      Global.igrejaSelecionada.value = null;
                    } */
                  await snapshot.reference
                      .update({'igrejas': integrante.igrejas});
                },
                // Pilha
                child: Stack(
                  alignment: AlignmentDirectional.topEnd,
                  children: [
                    // Card da Igreja
                    Padding(
                      padding: const EdgeInsets.only(top: 4, right: 4),
                      child: TileIgrejaSmall(igreja: igrejas[index].data()),
                    ),
                    // Checkbox inscrito
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.white,
                      child: inscrito
                          ? Icon(Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary)
                          : const Icon(Icons.remove_circle, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
            growable: false,
          ).toList(),
        ),
        const SizedBox(height: 16),
      ]);
    });

    mostrarDialogo(conteudo);
  }
}
