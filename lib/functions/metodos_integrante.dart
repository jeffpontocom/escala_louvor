import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/utils/medidas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';

import '../models/integrante.dart';
import '../utils/mensagens.dart';
import '../utils/utils.dart';
import 'metodos_firebase.dart';

class MetodosIntegrante {
  final BuildContext context;
  final DocumentSnapshot<Integrante> snapshot;

  MetodosIntegrante(this.context, this.snapshot);

  Future salvarDados(Map<String, Object?> dados) async {
    // Abre progresso
    Mensagem.aguardar(context: context, mensagem: 'Atualizando...');
    await snapshot.reference.update(dados);
    Modular.to.pop(); // Fecha progresso
  }

  void editarDados() async {
    if (snapshot.data() == null) {
      return Mensagem.simples(
        context: context,
        titulo: 'Falha',
        mensagem:
            'Houve um erro ao tentar executar a ação. Tente mais tarde novamente.',
      );
    }
    Integrante integrante = snapshot.data()!;
    // Foto
    var widgetFoto =
        StatefulBuilder(builder: (innerContext, StateSetter innerState) {
      return Stack(
        alignment: AlignmentDirectional.bottomEnd,
        children: [
          CircleAvatar(
            child: Text(
              MyStrings.getUserInitials(integrante.nome),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            foregroundImage:
                MyNetwork.getImageFromUrl(integrante.fotoUrl)?.image,
            backgroundColor: Colors.grey.withOpacity(0.5),
            radius: 56,
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

    // observações
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

    // Diálogo
    await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return OrientationBuilder(builder: (context, orientation) {
            return Container(
              constraints:
                  BoxConstraints(maxHeight: MediaQuery.of(context).size.height),
              padding: EdgeInsets.symmetric(
                  horizontal: Medidas.bodyPadding(context), vertical: 24),
              child: Wrap(
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
                  )
                ],
              ),
            );
          });
        });
  }
}
