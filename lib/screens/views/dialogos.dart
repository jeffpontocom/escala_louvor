import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/rotas.dart';
import 'package:escala_louvor/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';

import '../../functions/metodos_firebase.dart';
import '../../global.dart';
import '../../models/cantico.dart';
import '../../models/culto.dart';
import '../../utils/mensagens.dart';

class Dialogos {
  static void editarCulto(BuildContext context, Culto culto,
      {DocumentReference<Culto>? reference}) async {
    List<String> ocasioes = ['EBD', 'Culto vespertino', 'Evento especial'];

    return Mensagem.bottomDialog(
      context: context,
      titulo: 'Editar registro do culto',
      conteudo: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        children: [
          StatefulBuilder(builder: (_, innerState) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Igreja
                CircleAvatar(
                  radius: 24,
                  child: const Icon(Icons.church),
                  foregroundImage: MyNetwork.getImageFromUrl(
                          Global.igrejaSelecionada.value?.data()?.fotoUrl, null)
                      ?.image,
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
              labelText: 'Observações',
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
                    Modular.to.navigate(AppRotas.HOME);
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
  static void editarCantico(BuildContext context, Cantico cantico,
      {DocumentReference<Cantico>? reference}) async {
    return Mensagem.bottomDialog(
      context: context,
      titulo: 'Editar Cântico/Hino',
      conteudo: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          children: [
            StatefulBuilder(builder: (_, innerState) {
              return Row(
                children: [
                  // Cifra
                  const Text('CIFRA:'),
                  const SizedBox(width: 12),
                  // Botão para abrir arquivo
                  cantico.cifraUrl == null
                      ? Text(
                          'Nenhum arquivo carregado',
                          style: Theme.of(context).textTheme.caption,
                        )
                      : TextButton(
                          child: const Text('Ver arquivo'),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          onPressed: () => MeuFirebase.abrirArquivoPdf(
                              context, cantico.cifraUrl)),
                  const SizedBox(width: 24),
                  // Botão de ação limpar
                  cantico.cifraUrl == null
                      ? const SizedBox()
                      : IconButton(
                          onPressed: () async {
                            innerState(() => cantico.cifraUrl = null);
                          },
                          icon: const Icon(Icons.clear, color: Colors.grey),
                        ),
                  // Botão de ação carregar arquivo
                  IconButton(
                    onPressed: () async {
                      String? url =
                          await MeuFirebase.carregarArquivoPdf(pasta: 'cifras');
                      if (url != null && url.isNotEmpty) {
                        innerState(() => cantico.cifraUrl = url);
                      }
                    },
                    icon: const Icon(Icons.upload_file),
                  ),
                  // Espaço
                  const Expanded(child: SizedBox()),
                  // é hino
                  const Text('É HINO?'),
                  Checkbox(
                      tristate: false,
                      value: cantico.isHino,
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (value) {
                        innerState((() => cantico.isHino = value ?? false));
                      }),
                ],
              );
            }),
            const SizedBox(height: 12),
            // Nome ou título
            TextFormField(
              initialValue: cantico.nome,
              decoration: const InputDecoration(
                labelText: 'Título',
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              onChanged: (value) {
                cantico.nome = value;
              },
            ),
            // Autor(es)
            TextFormField(
              initialValue: cantico.autor,
              decoration: const InputDecoration(
                labelText: 'Autor(es)',
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              onChanged: (value) {
                cantico.autor = value;
              },
            ),
            // YouTube Url
            TextFormField(
              initialValue: cantico.youTubeUrl,
              decoration: const InputDecoration(
                labelText: 'Link do vídeo',
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              onChanged: (value) {
                cantico.youTubeUrl = value;
              },
            ),
            // Letra
            TextFormField(
              initialValue: cantico.letra,
              minLines: 5,
              maxLines: 15,
              decoration: const InputDecoration(
                labelText: 'Letra',
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              onChanged: (value) {
                cantico.letra = value;
              },
            ),
          ]),
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
                    await MeuFirebase.apagarCantico(cantico, id: reference.id);
                    Modular.to.pop(); // Fecha progresso
                    Modular.to.maybePop(); // Fecha dialog
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
                await MeuFirebase.criarCantico(cantico);
              } else {
                await MeuFirebase.atualizarCantico(cantico, reference);
              }
              Modular.to.pop(); // Fecha dialog
            },
          ),
        ],
      ),
    );
  }
}
