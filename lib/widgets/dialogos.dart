import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_quill/flutter_quill.dart' as rich;
import 'package:intl/intl.dart';

import 'cached_circle_avatar.dart';
import '/functions/metodos_firebase.dart';
import '/models/cantico.dart';
import '/models/culto.dart';
import '/utils/global.dart';
import '/utils/mensagens.dart';

class Dialogos {
  /// DIÁLOGO
  /// Editar Culto
  static void editarCulto(
    BuildContext context, {
    required Culto culto,
    DocumentReference<Culto>? reference,
  }) async {
    var titulo = 'Editar Culto';
    if (reference == null) {
      titulo = 'Novo Culto';
    }
    List<String> ocasioes = ['EBD', 'Culto vespertino', 'Evento especial'];

    return Mensagem.bottomDialog(
      context: context,
      titulo: titulo,
      leading: Chip(
        avatar: CachedAvatar(
          url: Global.igrejaSelecionada.value?.data()?.fotoUrl,
          icone: Icons.church,
          maxRadius: 10,
        ),
        label: Text(Global.igrejaSelecionada.value?.data()?.sigla ?? '',
            style: Theme.of(context).textTheme.caption),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      conteudo: StatefulBuilder(builder: (context, innerState) {
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // DATA E HORA
            Row(
              children: [
                // Data
                ActionChip(
                  avatar: const Icon(Icons.edit_calendar),
                  label: Text(
                    DateFormat.yMEd('pt_BR').format(culto.dataCulto.toDate()),
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  labelPadding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  onPressed: () async {
                    var dataPrevia = culto.dataCulto.toDate();
                    showDatePicker(
                      context: context,
                      initialDate: dataPrevia,
                      firstDate: DateTime(DateTime.now().year - 2),
                      lastDate: DateTime(DateTime.now().year + 2, 12, 0),
                    ).then((dia) {
                      if (dia != null) {
                        innerState(() {
                          culto.dataCulto = Timestamp.fromDate(
                            DateTime(dia.year, dia.month, dia.day,
                                dataPrevia.hour, dataPrevia.minute),
                          );
                        });
                      }
                    });
                  },
                ),
                const SizedBox(width: 8),
                // Hora
                ActionChip(
                  avatar: const Icon(Icons.access_time_outlined),
                  label: Text(
                    DateFormat.Hm('pt_BR').format(culto.dataCulto.toDate()),
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  labelPadding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  onPressed: () async {
                    var dataPrevia = culto.dataCulto.toDate();
                    showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(dataPrevia))
                        .then((hora) {
                      if (hora != null) {
                        innerState(() {
                          culto.dataCulto = Timestamp.fromDate(
                            DateTime(dataPrevia.year, dataPrevia.month,
                                dataPrevia.day, hora.hour, hora.minute),
                          );
                        });
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ocasião
            Autocomplete(
              initialValue: TextEditingValue(text: culto.ocasiao ?? ''),
              optionsBuilder: (textEditingValue) {
                List<String> matches = <String>[];
                matches.addAll(ocasioes);
                matches.retainWhere((s) {
                  return s
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase());
                });
                return matches;
              },
              fieldViewBuilder: (context, controller, focus, onSubmit) {
                return TextFormField(
                  controller: controller,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  focusNode: focus,
                  decoration: const InputDecoration(
                    labelText: 'Ocasião',
                    isDense: true,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  onChanged: (value) {
                    culto.ocasiao = value;
                  },
                  onFieldSubmitted: (value) => onSubmit,
                );
              },
              onSelected: (String value) {
                culto.ocasiao = value;
              },
            ),
            const SizedBox(height: 8),

            // Atenção
            TextFormField(
              initialValue: culto.obs,
              minLines: 5,
              maxLines: 15,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Observações (pontos de atenção para a equipe)',
                isDense: true,
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              onChanged: (value) {
                culto.obs = value;
              },
            ),
            const SizedBox(height: 8),
          ],
        );
      }),
      rodape: Row(
        children: [
          reference == null
              ? const SizedBox()
              : ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('APAGAR'),
                  style: ElevatedButton.styleFrom(primary: Colors.red),
                  onPressed: () async {
                    Mensagem.decisao(
                        context: context,
                        titulo: 'Apagar',
                        mensagem:
                            'Deseja apagar definitivamente o registro deste culto?',
                        onPressed: (ok) async {
                          if (ok) {
                            Modular.to.pop(); // Fecha dialog
                            Mensagem.aguardar(
                                context: context); // Abre progresso
                            await reference.delete();
                            Modular.to.pop(); // Fecha progresso
                            Modular.to.maybePop(); // Volta para página anterior
                          }
                        });
                  },
                ),
          const Expanded(child: SizedBox()),
          // Botão criar
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: Text(reference == null ? 'CRIAR' : 'ATUALIZAR'),
            onPressed: () async {
              // Salva os dados no firebase
              if (reference == null) {
                await MeuFirebase.criarCulto(culto);
              } else {
                await MeuFirebase.atualizarCulto(culto, reference);
              }
              Modular.to.pop(); // Fecha dialog
            },
          ),
        ],
      ),
    );
  }

  /// DIÁLOGO
  /// Editar Liturgia do Culto
  static void editarLiturgia(
    BuildContext context, {
    required DocumentReference<Culto> reference,
    required String texto,
  }) async {
    rich.QuillController controller;
    // Tratamento para texto vazio ou fora dos parâmetros JSON
    try {
      final doc = rich.Document.fromJson(jsonDecode(texto));
      controller = rich.QuillController(
          document: doc, selection: const TextSelection.collapsed(offset: 0));
    } catch (error) {
      final doc = rich.Document()..insert(0, '');
      controller = rich.QuillController(
          document: doc, selection: const TextSelection.collapsed(offset: 0));
    }
    return Mensagem.bottomDialog(
      context: context,
      titulo: 'Editar Liturgia',
      arrasteParaFechar: false,
      conteudo: StatefulBuilder(builder: (context, innerState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            rich.QuillToolbar.basic(
              controller: controller,
              toolbarIconAlignment: WrapAlignment.start,
              locale: const Locale('pt', 'BR'),
              iconTheme: rich.QuillIconTheme(
                  iconSelectedFillColor: Theme.of(context).colorScheme.primary),
              fontSizeValues: const {
                'Título': '26',
                'Subtítulo': '20',
                'Padrão': '0',
                'Legenda': '12',
              },
              multiRowsDisplay: false,
              showHeaderStyle: false,
              showColorButton: false,
              showBackgroundColorButton: false,
              showImageButton: false,
              showVideoButton: false,
              showListCheck: false,
              showListNumbers: false,
              showCameraButton: false,
              showAlignmentButtons: true,
              showCodeBlock: false,
              showInlineCode: false,
              showQuote: false,
              showIndent: false,
              showStrikeThrough: false,
            ),
            Expanded(
              child: Container(
                color: Colors.grey.withOpacity(0.12),
                padding: const EdgeInsets.all(16),
                child: rich.QuillEditor.basic(
                  controller: controller,
                  readOnly: false,
                ),
              ),
            )
          ],
        );
      }),
      rodape: ElevatedButton.icon(
        icon: const Icon(Icons.save),
        label: const Text('SALVAR'),
        onPressed: () async {
          // Salva os dados no firebase
          await reference.update(
              {'liturgia': jsonEncode(controller.document.toDelta().toJson())});
          Modular.to.pop(); // Fecha dialog
        },
      ),
    );
  }

  /// DIÁLOGO
  /// Editar Cântico
  static void editarCantico(
    BuildContext context, {
    required Cantico cantico,
    DocumentReference<Cantico>? reference,
  }) async {
    var titulo = 'Editar Cântico';
    if (reference == null) {
      titulo = 'Novo Cântico';
    }
    return Mensagem.bottomDialog(
      context: context,
      titulo: titulo,
      conteudo: StatefulBuilder(
        builder: (context, innerState) {
          return ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // TÍTULO
                TextFormField(
                  initialValue: cantico.nome,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    prefixIcon: Icon(Icons.subtitles),
                    isDense: true,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  onChanged: (value) {
                    cantico.nome = value;
                  },
                ),
                const SizedBox(height: 8),

                // AUTOR(ES)
                TextFormField(
                  initialValue: cantico.autor,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Autor(es)',
                    prefixIcon: Icon(Icons.person),
                    isDense: true,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  onChanged: (value) {
                    cantico.autor = value;
                  },
                ),
                const SizedBox(height: 8),

                // TOM e COMPASSO
                Row(
                  children: [
                    Flexible(
                      flex: 2,
                      child: TextFormField(
                        initialValue: cantico.tom,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Tom',
                          prefixIcon: Icon(Icons.music_note),
                          isDense: true,
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                        onChanged: (value) {
                          cantico.tom = value;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 3,
                      child: TextFormField(
                        initialValue: cantico.compasso,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Compasso',
                          prefixIcon: Icon(Icons.compass_calibration),
                          isDense: true,
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                        onChanged: (value) {
                          cantico.compasso = value;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // LINK DO VIDEO
                TextFormField(
                  initialValue: cantico.youTubeUrl,
                  textCapitalization: TextCapitalization.none,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Link do vídeo',
                    prefixIcon: Icon(Icons.live_tv),
                    isDense: true,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  onChanged: (value) {
                    cantico.youTubeUrl = value;
                  },
                ),
                const SizedBox(height: 8),

                // CIFRA
                TextFormField(
                  focusNode: FocusNode(canRequestFocus: false),
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Cifra',
                    prefixIcon: const Icon(Icons.queue_music),
                    isDense: true,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    hintText: cantico.cifraUrl == null
                        ? 'Carregar arquivo PDF >>>'
                        : cantico.cifraUrl?.split('=').last ??
                            'Arquivo sem nome!',
                    hintStyle: Theme.of(context).textTheme.caption,
                    suffixIcon: cantico.cifraUrl == null
                        // Ação para carregar arquivo
                        ? IconButton(
                            icon: Icon(Icons.upload_file,
                                color: Theme.of(context).colorScheme.primary),
                            onPressed: () async {
                              String? url =
                                  await MeuFirebase.carregarArquivoPdf(context,
                                      pasta: 'cifras');
                              if (url != null && url.isNotEmpty) {
                                innerState(() => cantico.cifraUrl = url);
                              }
                            },
                          )
                        // Ação para remover o arquivo
                        : IconButton(
                            icon: const Icon(
                              Icons.delete_forever,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              innerState(() => cantico.cifraUrl = null);
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 8),

                // TEMA e TIPO
                Row(
                  children: [
                    // Tema
                    Flexible(
                      flex: 3,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<String>(
                            hint: Text(
                              'Em breve',
                              style: Theme.of(context).textTheme.caption,
                            ),
                            isDense: true,
                            items: const [],
                            decoration: const InputDecoration(
                              labelText: 'Tema',
                              isDense: true,
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                            ),
                            onChanged: null),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tipo (é hino?)
                    Flexible(
                      flex: 2,
                      child: CheckboxListTile(
                          title: const Text('É hino'),
                          activeColor: Theme.of(context).colorScheme.primary,
                          tileColor: Theme.of(context).hoverColor,
                          selectedTileColor: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.25),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32)),
                          value: cantico.isHino,
                          selected: cantico.isHino,
                          onChanged: (value) {
                            innerState((() => cantico.isHino = value ?? false));
                          }),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // LETRA
                TextFormField(
                  initialValue: cantico.letra,
                  minLines: 5,
                  maxLines: 15,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    labelText: 'Letra',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  onChanged: (value) {
                    cantico.letra = value;
                  },
                ),
              ]);
        },
      ),
      rodape: Row(
        children: [
          reference == null
              ? const SizedBox()
              : ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('APAGAR'),
                  style: ElevatedButton.styleFrom(primary: Colors.red),
                  onPressed: () async {
                    // Abre progresso
                    Mensagem.decisao(
                        context: context,
                        titulo: 'Apagar',
                        mensagem:
                            'Deseja apagar definitivamente "${cantico.nome}"?',
                        onPressed: (ok) async {
                          if (ok) {
                            Modular.to.pop(); // Fecha dialog
                            Mensagem.aguardar(context: context);
                            await reference.delete();
                            Modular.to.pop(); // Fecha progresso
                            Modular.to.maybePop(); // Volta para pagina anterior
                          }
                        });
                  },
                ),
          const Expanded(child: SizedBox()),
          // Botão criar
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: Text(reference == null ? 'CRIAR' : 'ATUALIZAR'),
            onPressed: () async {
              // Salva os dados no firebase
              Mensagem.aguardar(context: context); // Abre progresso
              if (reference == null) {
                await MeuFirebase.criarCantico(cantico);
              } else {
                await MeuFirebase.atualizarCantico(cantico, reference);
              }
              Modular.to.pop(); // Fecha progresso
              Modular.to.pop(); // Fecha dialog
            },
          ),
        ],
      ),
    );
  }
}
