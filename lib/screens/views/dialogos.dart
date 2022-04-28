import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../functions/metodos_firebase.dart';
import '../../global.dart';
import '../../models/cantico.dart';
import '../../models/culto.dart';
import '../../utils/mensagens.dart';
import '../home.dart';

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
  static void editarCantico(BuildContext context, Cantico cantico,
      {DocumentReference<Cantico>? reference}) async {
    return Mensagem.bottomDialog(
      context: context,
      titulo: 'Editar cântico',
      conteudo: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          children: [
            // É hino
            StatefulBuilder(builder: (_, innerState) {
              return Row(
                children: [
                  // Cifra
                  Flexible(
                    flex: 3,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      horizontalTitleGap: 0,
                      leading:
                          const Icon(Icons.queue_music, color: Colors.green),
                      title: const Text('Cifra'),
                      trailing: cantico.cifraUrl == null
                          ? const Icon(Icons.upload_file)
                          : IconButton(
                              // Ação para remover o arquivo
                              onPressed: () async {
                                innerState(() => cantico.cifraUrl = null);
                              },
                              icon: const Icon(Icons.delete_forever)),
                      onTap: cantico.cifraUrl == null
                          ?
                          // Ação para carregar arquivo
                          () async {
                              String? url =
                                  await MeuFirebase.carregarArquivoPdf(context,
                                      pasta: 'cifras');
                              if (url != null && url.isNotEmpty) {
                                innerState(() => cantico.cifraUrl = url);
                              }
                            }
                          :
                          // Ação para abrir o arquivo
                          () => MeuFirebase.abrirArquivosPdf(
                              context, [cantico.cifraUrl!]),
                    ),
                  ),
                  const VerticalDivider(width: 12),
                  // Tipo (é hino?)
                  Flexible(
                    flex: 2,
                    child: CheckboxListTile(
                        title: const Text('Hino', textAlign: TextAlign.center),
                        activeColor: Theme.of(context).colorScheme.primary,
                        contentPadding: EdgeInsets.zero,
                        tileColor: Colors.grey.withOpacity(0.18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        value: cantico.isHino,
                        onChanged: (value) {
                          innerState((() => cantico.isHino = value ?? false));
                        }),
                  ),
                ],
              );
            }),
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
                icon: Icon(Icons.co_present_rounded),
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
                  icon: FaIcon(FontAwesomeIcons.youtube, color: Colors.red)),
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

  static void verLetraDoCantico(BuildContext context, Cantico cantico) {
    ValueNotifier<double> fontSize = ValueNotifier(20);
    var minFontSize = 15.0;
    var maxFontSize = 50.0;
    late double _textSizeBefore;
    late double _textSizeAfter;
    return Mensagem.bottomDialog(
      context: context,
      titulo: cantico.nome,
      conteudo: GestureDetector(
        // Captura de gestos para alterar tamanho da fonte
        onScaleStart: (details) {
          _textSizeAfter = fontSize.value;
          _textSizeBefore = fontSize.value;
        },
        onScaleUpdate: (details) {
          _textSizeAfter = _textSizeBefore * details.verticalScale;
          if (_textSizeAfter > minFontSize && _textSizeAfter < maxFontSize) {
            fontSize.value = _textSizeAfter;
          }
        },
        onScaleEnd: (details) {
          if (_textSizeAfter < minFontSize) {
            _textSizeAfter = minFontSize;
          }
          if (_textSizeAfter > maxFontSize) {
            _textSizeAfter = maxFontSize;
          }
          fontSize.value = _textSizeAfter;
        },
        // Pagina principal
        child: ValueListenableBuilder<double>(
            valueListenable: fontSize,
            builder: (context, size, _) {
              return ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                shrinkWrap: true,
                children: [
                  // Autor
                  Text(cantico.autor ?? ''),
                  // Letra
                  const SizedBox(height: 24),
                  Text(
                    cantico.letra ?? '',
                    style: TextStyle(fontSize: size),
                  ),
                  const SizedBox(height: 48),
                ],
              );
            }),
      ),
    );
  }
}
