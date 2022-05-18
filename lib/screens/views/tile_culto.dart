import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '/global.dart';
import '/functions/metodos_firebase.dart';
import '/models/culto.dart';
import '/models/igreja.dart';
import '/models/integrante.dart';
import '/utils/utils.dart';

class TileCulto extends StatelessWidget {
  final Culto culto;
  final DocumentReference<Culto> reference;
  const TileCulto({Key? key, required this.culto, required this.reference})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      // Coluna 1: Dados Básicos
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // Linha 1: Ocasião e Igreja
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  iconDayNight,
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        diaDaSemana,
                        ocasiao,
                      ],
                    ),
                  ),
                  igreja,
                ],
              ),
              const SizedBox(height: 4),
              // Linha 2: Data e Horário
              Row(
                children: [
                  const SizedBox(width: 28),
                  diaDoMes,
                  const SizedBox(width: 8),
                  horario,
                ],
              ),
              // Linhas 3: Escalados e Cânticos
              Row(
                children: [
                  Expanded(child: equipe),
                  const SizedBox(
                    width: 8,
                    height: kMinInteractiveDimension,
                  ),
                  precisaAtencao,
                  const SizedBox(width: 4),
                  canticos,
                ],
              ),
            ],
          ),
        ),
      ),
      //const SizedBox(width: 16),
      // Coluna 2: Botão
      Container(child: botaoDisponibilidade),
    ]);
  }

  /// Icone manhã/noite
  get iconDayNight {
    DateTime data = culto.dataCulto.toDate();
    return Icon(
      data.hour >= 6 && data.hour < 18 ? Icons.sunny : Icons.dark_mode,
      size: 20,
    );
  }

  /// Dia da Semana
  get diaDaSemana {
    DateTime data = culto.dataCulto.toDate();
    var diaSemana = DateFormat(DateFormat.WEEKDAY, 'pt_BR').format(data);
    return Text(
      diaSemana,
      style: const TextStyle(color: Colors.grey, fontSize: 12),
    );
  }

  /// Ocasião
  get ocasiao {
    return Text(
      culto.ocasiao ?? '',
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
  }

  /// Dia do Mês
  get diaDoMes {
    DateTime data = culto.dataCulto.toDate();
    var diaMes = DateFormat(DateFormat.ABBR_MONTH_DAY, 'pt_BR').format(data);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.today, size: 20),
        const SizedBox(width: 4),
        Text(
          diaMes,
          style: const TextStyle(fontSize: 15),
        ),
      ],
    );
  }

  /// Horário
  get horario {
    DateTime data = culto.dataCulto.toDate();
    var hora = DateFormat(DateFormat.HOUR24_MINUTE, 'pt_BR').format(data);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.access_time, size: 20),
        const SizedBox(width: 4),
        Text(
          hora,
          style: const TextStyle(fontSize: 15),
        ),
      ],
    );
  }

  /// Igreja
  get igreja {
    return FutureBuilder<DocumentSnapshot<Igreja>?>(
      future: MeuFirebase.obterSnapshotIgreja(culto.igreja.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }
        Igreja? igreja = snapshot.data!.data();
        return Chip(
          avatar: CircleAvatar(
            radius: 10,
            foregroundImage: MyNetwork.getImageFromUrl(igreja?.fotoUrl)?.image,
          ),
          label: Text(igreja?.sigla ?? ''),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        );
      },
    );
  }

  /// Integrantes Escalados
  get equipe {
    return FutureBuilder<List<Integrante>>(
      future: equipeEscalada(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }
        if (snapshot.data?.isEmpty ?? true) {
          return const Text(
            'Ninguém escalado ainda!',
            textScaleFactor: 0.8,
            style: TextStyle(color: Colors.grey),
          );
        }
        var escalados = snapshot.data;
        return Stack(
          children: List.generate(escalados?.length ?? 0, (index) {
            return Padding(
              padding: EdgeInsets.only(left: index * 18),
              child: CircleAvatar(
                radius: 13,
                backgroundColor: Colors.grey,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: Color.fromARGB(255, 0, 150, index * 30 + 30),
                  foregroundImage:
                      MyNetwork.getImageFromUrl(escalados?[index].fotoUrl)
                          ?.image,
                  child: Text(
                    MyStrings.getUserInitials(escalados?[index].nome ?? ''),
                    textScaleFactor: 0.75,
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ),
            );
          }).reversed.toList(),
        );
      },
    );
  }

  Future<List<Integrante>> equipeEscalada() async {
    List<Integrante> escalados = [];
    // Dirigente
    if (culto.dirigente != null) {
      var integrante =
          (await MeuFirebase.obterSnapshotIntegrante(culto.dirigente!.id))
              ?.data();
      if (integrante != null) {
        escalados.add(integrante);
      }
    }
    // Coordenador
    if (culto.coordenador != null) {
      var integrante =
          (await MeuFirebase.obterSnapshotIntegrante(culto.coordenador!.id))
              ?.data();
      if (integrante != null &&
          !escalados.map((e) => e.nome).contains(integrante.nome)) {
        escalados.add(integrante);
      }
    }
    // Equipe
    if (culto.equipe != null && culto.equipe!.isNotEmpty) {
      for (var integrantes in culto.equipe!.values) {
        for (var referencia in integrantes) {
          var integrante =
              (await MeuFirebase.obterSnapshotIntegrante(referencia.id))
                  ?.data();
          if (integrante != null &&
              !escalados.map((e) => e.nome).contains(integrante.nome)) {
            escalados.add(integrante);
          }
        }
      }
    }
    return escalados;
  }

  /// Icone de atenção
  get precisaAtencao {
    return culto.obs != null && culto.obs!.isNotEmpty
        ? const Tooltip(
            message: 'Possui ponto de atenção!',
            child: Icon(Icons.report, color: Colors.amber, size: 20),
          )
        : const SizedBox();
  }

  /// Quantidade de cânticos
  get canticos {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.library_music, size: 20),
        const SizedBox(width: 4),
        Text(
          culto.canticos?.length.toString() ?? '0',
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  /// Botão de disponibilidade
  get botaoDisponibilidade {
    bool alterar = false;
    return StatefulBuilder(builder: (context, setState) {
      bool escalado = culto.usuarioEscalado(Global.integranteLogado?.reference);
      bool disponivel =
          culto.usuarioDisponivel(Global.integranteLogado?.reference);
      bool restrito = culto.usuarioRestrito(Global.integranteLogado?.reference);
      return OutlinedButton(
        onPressed: escalado || restrito
            ? () {}
            : () async {
                setState(() {
                  alterar = true;
                });
                await MeuFirebase.definirDisponibilidadeParaOCulto(reference);
              },
        onLongPress: escalado || disponivel
            ? () {}
            : () async {
                setState(() {
                  alterar = true;
                });
                await MeuFirebase.definirRestricaoParaOCulto(reference);
              },
        style: OutlinedButton.styleFrom(
          maximumSize: const Size.fromWidth(92),
          padding: const EdgeInsets.all(12),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(8))),
          backgroundColor: escalado
              ? Colors.green
              : disponivel
                  ? Colors.blue
                  : restrito
                      ? Colors.red
                      : Colors.grey,
          primary: Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            alterar
                ? const Center(
                    child: SizedBox.square(
                      dimension: 36,
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Image.asset(
                    escalado
                        ? 'assets/icons/ic_escalado.png'
                        : disponivel
                            ? 'assets/icons/ic_disponivel.png'
                            : restrito
                                ? 'assets/icons/ic_restrito.png'
                                : 'assets/icons/ic_indeciso.png',
                    height: 36,
                  ),
            const SizedBox(height: 4),
            Text(
              escalado
                  ? 'Estou escalado'
                  : disponivel
                      ? 'Estou disponível'
                      : restrito
                          ? 'Estou restrito'
                          : 'Ainda não decidi',
              textAlign: TextAlign.center,
              softWrap: true,
            ),
          ],
        ),
      );
    });
  }
}
