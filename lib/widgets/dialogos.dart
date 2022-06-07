import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../functions/metodos_firebase.dart';
import '../../utils/global.dart';
import '../../models/cantico.dart';
import '../../models/culto.dart';
import '../../utils/mensagens.dart';
import '../screens/home/tela_home.dart';

class Dialogos {
  static void editarCulto(BuildContext context, Culto culto,
      {DocumentReference<Culto>? reference}) async {
    List<String> ocasioes = ['EBD', 'Culto vespertino', 'Evento especial'];

    return Mensagem.bottomDialog(
      context: context,
      titulo: 'Editar culto/evento',
      conteudo: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        children: [
          StatefulBuilder(builder: (_, innerState) {
            return Wrap(
              spacing: 8,
              children: [
                // Igreja
                CircleAvatar(
                  radius: 24,
                  child: Text(
                    Global.igrejaSelecionada.value?.data()?.sigla ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Offside',
                      fontSize: 14,
                      letterSpacing: 0,
                    ),
                  ),
                ),
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
            );
          }),
          const SizedBox(height: 12),

          // Ocasiao
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
                focusNode: focus,
                decoration: const InputDecoration(
                  labelText: 'Ocasião',
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

          //Obs
          TextFormField(
            initialValue: culto.obs,
            minLines: 5,
            maxLines: 15,
            decoration: const InputDecoration(
              labelText: 'Observações (pontos de atenção para a equipe)',
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
            onChanged: (value) {
              culto.obs = value;
            },
          ),

          const SizedBox(height: 64),
        ],
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
                    Mensagem.aguardar(context: context);
                    await MeuFirebase.apagarCulto(culto, id: reference.id);
                    Modular.to.pop(); // Fecha progresso
                    Modular.to.maybePop(); // Fecha dialog
                    Modular.to.navigate('/${Paginas.values[0].name}');
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

  /// Editar Cantico
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
                          prefixIcon: Icon(Icons.scatter_plot_sharp),
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
                        ? 'Carregar arquivo em PDF'
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
                            hint: const Text('Selecione o tema'),
                            isDense: true,
                            items: const [
                              DropdownMenuItem(
                                  value: 'Contrição', child: Text('Contrição')),
                              DropdownMenuItem(
                                  value: 'Jubilo', child: Text('Jubilo')),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Tema',
                              isDense: true,
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                            ),
                            onChanged: (value) {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tipo (é hino?)
                    Flexible(
                      flex: 2,
                      child: CheckboxListTile(
                          title: const Text('É hino'),
                          activeColor: Theme.of(context).colorScheme.primary,
                          tileColor: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32)),
                          value: cantico.isHino,
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
                            'Deseja apagar definitivamente "${cantico.nome}".',
                        onPressed: (ok) async {
                          if (ok) {
                            Mensagem.aguardar(context: context);
                            await MeuFirebase.apagarCantico(cantico,
                                id: reference.id);
                            Modular.to.pop(); // Fecha progresso
                            Modular.to.maybePop();
                          }
                        }); // Fecha dialog
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
