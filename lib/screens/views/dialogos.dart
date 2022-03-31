import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/rotas.dart';
import 'package:escala_louvor/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';

import '../../functions/metodos_firebase.dart';
import '../../global.dart';
import '../../models/culto.dart';
import '../../utils/mensagens.dart';

class Dialogos {
  static void editarCulto(BuildContext context, Culto culto,
      {String? id, TaskCallback<bool>? callback}) async {
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
          id == null
              ? const SizedBox()
              : ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('APAGAR'),
                  style: ElevatedButton.styleFrom(primary: Colors.red),
                  onPressed: () async {
                    // Abre progresso
                    Mensagem.aguardar(context: context);
                    await MeuFirebase.apagarCulto(culto, id: id);
                    Modular.to.pop(); // Fecha progresso
                    Modular.to.maybePop(); // Fecha dialog
                    Modular.to.navigate(AppRotas.HOME);
                  },
                ),
          const Expanded(child: SizedBox()),
          // Botão criar
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('SALVAR'),
            onPressed: () async {
              Modular.to.pop(); // Fecha dialog
              // Abre progresso
              Mensagem.aguardar(context: context);
              // Salva os dados no firebase
              try {
                await FirebaseFirestore.instance
                    .collection(Culto.collection)
                    .doc(id)
                    .update({
                  'dataCulto': culto.dataCulto,
                  'ocasiao': culto.ocasiao,
                  'obs': culto.obs
                });
              } catch (e) {
                await MeuFirebase.salvarCulto(culto, id: id);
              }
              Modular.to.pop(); // Fecha progresso
            },
          ),
        ],
      ),
    );
  }
}
