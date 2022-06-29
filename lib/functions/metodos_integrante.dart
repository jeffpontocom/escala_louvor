import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';

import 'metodos_firebase.dart';
import '/models/igreja.dart';
import '/models/instrumento.dart';
import '/models/integrante.dart';
import '/utils/mensagens.dart';
import '/utils/global.dart';
import '../widgets/cached_circle_avatar.dart';
import '/widgets/tile_igreja.dart';

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

  void editarDados() {
    if (checarNulidade()) return;

    Integrante integrante = snapshot.data()!;

    // Foto
    var widgetFoto =
        StatefulBuilder(builder: (innerContext, StateSetter innerState) {
      return Stack(alignment: AlignmentDirectional.bottomEnd, children: [
        // Foto do integrante
        CachedAvatar(
          nome: integrante.nome,
          url: integrante.fotoUrl,
          maxRadius: 56,
        ),
        // Botão para substituir foto
        CircleAvatar(
          radius: 18,
          backgroundColor: Theme.of(context).colorScheme.background,
          child: CircleAvatar(
            radius: 16,
            backgroundColor: integrante.fotoUrl != null ? Colors.red : null,
            child: integrante.fotoUrl == null || integrante.fotoUrl!.isEmpty
                ? IconButton(
                    icon: const Icon(Icons.add_a_photo),
                    iconSize: 16,
                    onPressed: () async {
                      var url = await MeuFirebase.carregarFoto(context);
                      if (url != null && url.isNotEmpty) {
                        innerState(() {
                          integrante.fotoUrl = url;
                        });
                      }
                    },
                  )
                : IconButton(
                    icon: const Icon(Icons.no_photography),
                    iconSize: 16,
                    color: Colors.white,
                    onPressed: () async {
                      innerState(() {
                        integrante.fotoUrl = null;
                      });
                    },
                  ),
          ),
        ),
      ]);
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
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Nome Completo',
        floatingLabelBehavior: FloatingLabelBehavior.always,
        isDense: true,
      ),
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
      decoration: const InputDecoration(
        labelText: 'WhatsApp',
        floatingLabelBehavior: FloatingLabelBehavior.always,
        isDense: true,
      ),
      onChanged: (value) {
        integrante.telefone = value.trim();
      },
    );

    // Observações
    var widgetObs = TextFormField(
      initialValue: integrante.obs,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      minLines: 5,
      maxLines: 10,
      decoration: const InputDecoration(
        labelText: 'Observações',
        floatingLabelBehavior: FloatingLabelBehavior.always,
        isDense: true,
      ),
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
    var conteudo = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          widgetFoto,
          widgetDataNascimento,
          const SizedBox(width: double.infinity),
          widgetNome,
          widgetTelefone,
          widgetObs,
        ],
      ),
    );

    Mensagem.bottomDialog(
        context: context,
        titulo: 'Editar dados',
        conteudo: conteudo,
        rodape: btnAtualizar);
  }

  /// Editar funções
  void editarFuncoes() {
    if (checarNulidade()) return;

    Integrante integrante = snapshot.data()!;

    // Conteúdo organizado
    var conteudo = StatefulBuilder(builder: (context, innerState) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Selecione um ou mais funções para o integrante.',
            textAlign: TextAlign.center,
          ),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 16),
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
        ),
      ]);
    });

    Mensagem.bottomDialog(
        context: context, titulo: 'Editar funções', conteudo: conteudo);
  }

  /// Editar instrumentos e habilidades
  void editarInstrumentos(
      List<QueryDocumentSnapshot<Instrumento>> instrumentos) {
    if (checarNulidade()) return;

    Integrante integrante = snapshot.data()!;

    // Conteúdo organizado
    var conteudo = StatefulBuilder(builder: (context, innerState) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Selecione um ou mais instrumentos, equipamentos ou habilidades em que pode ser escalado.',
            textAlign: TextAlign.center,
          ),
        ),
        Flexible(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            shrinkWrap: true,
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
                        Image.asset(
                          instrumentos[index].data().iconAsset,
                          width: 20,
                          color: Theme.of(context).colorScheme.onBackground,
                          colorBlendMode: BlendMode.srcATop,
                        ),
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
        ),
      ]);
    });

    Mensagem.bottomDialog(
        context: context, titulo: 'Editar instrumentos', conteudo: conteudo);
  }

  /// Editar igrejas inscritas
  void editarIgrejas(List<QueryDocumentSnapshot<Igreja>> igrejas) {
    if (checarNulidade()) return;

    Integrante integrante = snapshot.data()!;

    // Conteúdo organizado
    var conteudo = StatefulBuilder(builder: (context, innerState) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Selecione uma ou mais igrejas em que pode ser escalado.',
            textAlign: TextAlign.center,
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Wrap(
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
                      // Caso seja o integrante logado e
                      // se a igreja indicado já estiver inscrita
                      if (snapshot.reference.toString() ==
                              Global.logadoReference.toString() &&
                          (Global.igrejaSelecionada.value?.reference
                                  .toString() ==
                              igrejas[index].reference.toString())) {
                        Mensagem.decisao(
                            context: context,
                            titulo: 'Atenção',
                            mensagem:
                                'Deseja remover a inscrição da igreja atualmente selecionada?',
                            onPressed: (ok) async {
                              if (ok) {
                                innerState(() {
                                  inscrito
                                      ? integrante.igrejas?.removeWhere(
                                          (element) =>
                                              element.toString() ==
                                              igrejas[index]
                                                  .reference
                                                  .toString())
                                      : integrante.igrejas
                                          ?.add(igrejas[index].reference);
                                });
                                await snapshot.reference
                                    .update({'igrejas': integrante.igrejas});
                                Global.igrejaSelecionada.value = null;
                              }
                            });
                      } else {
                        innerState(() {
                          inscrito
                              ? integrante.igrejas?.removeWhere((element) =>
                                  element.toString() ==
                                  igrejas[index].reference.toString())
                              : integrante.igrejas
                                  ?.add(igrejas[index].reference);
                        });
                        await snapshot.reference
                            .update({'igrejas': integrante.igrejas});
                        if (snapshot.reference.toString() ==
                            Global.logadoReference.toString()) {
                          Global.igrejaSelecionada.notifyListeners();
                        }
                      }
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
          ),
        ),
      ]);
    });

    Mensagem.bottomDialog(
        context: context, titulo: 'Editar igrejas', conteudo: conteudo);
  }
}
