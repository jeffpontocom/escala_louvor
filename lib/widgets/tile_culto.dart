import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '/functions/metodos_firebase.dart';
import '/models/culto.dart';
import '/models/igreja.dart';
import '/models/integrante.dart';
import '/resources/animations/shimmer.dart';
import '/utils/global.dart';
import '/widgets/avatar.dart';

class TileCulto extends StatelessWidget {
  final Culto culto;
  final DocumentReference<Culto> reference;
  final ThemeData theme;
  final bool showResumo;

  const TileCulto(
      {Key? key,
      required this.culto,
      required this.reference,
      required this.theme,
      this.showResumo = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: slidableButtons,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(children: [
            // Coluna 1: Dados Básicos
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  children: [
                    // Linha 1: Ocasião e Igreja
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        iconDayNight,
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ocasiao,
                            const SizedBox(height: 4),
                            diaDaSemana,
                          ],
                        ),
                        const Expanded(child: SizedBox()),
                        showResumo
                            ? chipStatusDisponibilidade
                            : const SizedBox(),
                        igreja,
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Linha 2: Data e Horário
                    Row(
                      children: [
                        const SizedBox(width: 26),
                        diaDoMes,
                        const SizedBox(width: 8),
                        horario,
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                    // Linha 3: Escalados e Cânticos
                    Row(
                      children: [
                        Expanded(child: equipe),
                        const SizedBox(
                          width: 8,
                          height: 36,
                        ),
                        precisaAtencao,
                        const SizedBox(width: 4),
                        canticos,
                      ],
                    ),
                    // Linha 4: Resumo
                    showResumo
                        ? Row(
                            children: [
                              dataEnsaio,
                            ],
                          )
                        : const SizedBox(),
                  ],
                ),
              ),
            ),
            // Coluna 2: Botão
            Container(
                child: _podeSerEscalado && !showResumo
                    ? botaoDisponibilidade
                    : null),
          ]);
        },
      ),
    );
  }

  get chipStatusDisponibilidade {
    var child;
    var style = theme.textTheme.caption;
    if (_estouEscalado) {
      child = Image.asset(
        'assets/icons/ic_escalado.png',
        height: 20,
        color: Colors.green,
        colorBlendMode: BlendMode.srcATop,
      );
    } else if (_estouDisponivel) {
      child = Image.asset(
        'assets/icons/ic_disponivel.png',
        height: 20,
        color: Colors.blue,
        colorBlendMode: BlendMode.srcATop,
      );
    } else if (_estouRestrito) {
      child = Image.asset(
        'assets/icons/ic_restrito.png',
        height: 20,
        color: Colors.red,
        colorBlendMode: BlendMode.srcATop,
      );
    } else {
      child = Image.asset(
        'assets/icons/ic_indeciso.png',
        height: 20,
        color: Colors.grey,
        colorBlendMode: BlendMode.srcATop,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(4),
      child: child,
    );
  }

  void doNothing(BuildContext context) {}

  get slidableButtons {
    if (_estouEscalado) {
      return [
        CustomSlidableAction(
          flex: 1,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          onPressed: doNothing,
          child: sliderChild(
            asset: 'assets/icons/ic_escalado.png',
            label: 'Estou\nEscalado',
          ),
        ),
      ];
    }
    if (_estouDisponivel) {
      return [
        CustomSlidableAction(
          flex: 1,
          backgroundColor: Colors.grey,
          foregroundColor: Colors.white,
          onPressed: (context) async {
            await MeuFirebase.definirDisponibilidadeParaOCulto(reference);
          },
          child: sliderChild(
            asset: 'assets/icons/ic_disponivel.png',
            label: 'Remover\nDisponibilidade',
          ),
        ),
      ];
    }
    if (_estouRestrito) {
      return [
        CustomSlidableAction(
          flex: 1,
          backgroundColor: Colors.grey,
          foregroundColor: Colors.white,
          onPressed: (context) async {
            await MeuFirebase.definirRestricaoParaOCulto(reference);
          },
          child: sliderChild(
            asset: 'assets/icons/ic_restrito.png',
            label: 'Remover\nRestrição',
          ),
        ),
      ];
    }
    return [
      CustomSlidableAction(
        flex: 1,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        onPressed: (context) async {
          await MeuFirebase.definirDisponibilidadeParaOCulto(reference);
        },
        child: sliderChild(
          asset: 'assets/icons/ic_disponivel.png',
          label: 'Estou\nDisponível',
        ),
      ),
      CustomSlidableAction(
        flex: 1,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        onPressed: (context) async {
          await MeuFirebase.definirRestricaoParaOCulto(reference);
        },
        child: sliderChild(
          asset: 'assets/icons/ic_restrito.png',
          label: 'Estou\nRestrito',
        ),
      ),
    ];
  }

  Widget sliderChild({required String asset, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Image.asset(asset, height: 36)),
        const SizedBox(height: 8),
        Flexible(
            child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
        )),
      ],
    );
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
      style: theme.textTheme.bodySmall,
    );
  }

  /// Ocasião
  get ocasiao {
    return Text(
      culto.ocasiao ?? '',
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  /// Dia do Mês
  get diaDoMes {
    DateTime data = culto.dataCulto.toDate();
    var diaMes = DateFormat(DateFormat.ABBR_MONTH_DAY, 'pt_BR').format(data);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.today, size: 18),
        const SizedBox(width: 4),
        Text(
          diaMes,
          style: theme.textTheme.headline6,
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
        const Icon(Icons.access_time, size: 18),
        const SizedBox(width: 4),
        Text(
          hora,
          style: theme.textTheme.headline6,
        ),
      ],
    );
  }

  /// Igreja
  get igreja {
    return FutureBuilder<DocumentSnapshot<Igreja>?>(
      future: MeuFirebase.obterSnapshotIgreja(culto.igreja.id),
      builder: (context, snapshot) {
        // Shimmer de carregamento
        if (!snapshot.hasData) {
          var cor = Theme.of(context).chipTheme.backgroundColor ?? Colors.grey;
          return SizedBox(
            height: 22,
            child: Shimmer.fromColors(
              baseColor: cor.withOpacity(0.5),
              highlightColor: cor.withOpacity(0.25),
              child: const RawChip(label: SizedBox(width: 48)),
            ),
          );
        }
        Igreja? igreja = snapshot.data!.data();
        return Chip(
          avatar: CachedAvatar(
            icone: Icons.church,
            url: igreja?.fotoUrl,
            maxRadius: 10,
          ),
          label: Text(igreja?.sigla ?? '',
              style: Theme.of(context).textTheme.caption),
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
          return SizedBox(
            height: 24,
            child: Stack(
              children: List.generate(culto.equipe?.length ?? 0, (index) {
                int c = (Theme.of(context).brightness == Brightness.dark
                        ? 90
                        : 190) +
                    index * 5;
                return Padding(
                  padding: EdgeInsets.only(left: index * 18),
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Theme.of(context).cardColor,
                    child: Shimmer.fromColors(
                      baseColor: Color.fromRGBO(c, c, c, 1),
                      highlightColor: Color.fromRGBO(c, c, c, 0.5),
                      child: const CircleAvatar(radius: 10),
                    ),
                  ),
                );
              }).reversed.toList(),
            ),
          );
        }
        if (snapshot.data?.isEmpty ?? true) {
          return Text(
            'Ninguém escalado ainda!',
            style: theme.textTheme.bodySmall,
          );
        }
        var escalados = snapshot.data;
        return Stack(
          children: List.generate(escalados?.length ?? 0, (index) {
            return Padding(
              padding: EdgeInsets.only(left: index * 18),
              child: CircleAvatar(
                radius: 12,
                backgroundColor: Theme.of(context).cardColor,
                child: CachedAvatar(
                  nome: escalados?[index].nome ?? '',
                  url: escalados?[index].fotoUrl,
                  maxRadius: 10,
                  backgroundColor: Colors.grey.withOpacity(0.38),
                ),
              ),
            );
          }).reversed.toList(),
        );
      },
    );
  }

  /// Icone de atenção
  Widget get precisaAtencao {
    return culto.obs != null && culto.obs!.isNotEmpty
        ? Tooltip(
            message: 'Possui ponto de atenção!',
            child: Icon(
              Icons.report_problem_rounded,
              size: 16,
              color: theme.colorScheme.secondary,
            ),
          )
        : const SizedBox();
  }

  /// Quantidade de cânticos
  get canticos {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.queue_music, size: 16, color: Colors.grey),
        const SizedBox(width: 2),
        Text(
          culto.canticos?.length.toString() ?? '0',
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  /// Data do ensaios
  get dataEnsaio {
    if (culto.dataEnsaio == null) return const SizedBox();
    DateTime data = culto.dataEnsaio!.toDate();
    var dataFormatada = DateFormat('EEE, HH:mm', 'pt_BR').format(data);
    return Text(
      '• Ensaio: $dataFormatada',
      style: theme.textTheme.bodySmall,
    );
  }

  /// Botão de disponibilidade
  get botaoDisponibilidade {
    bool alterar = false;
    return StatefulBuilder(builder: (context, setState) {
      bool escalado = culto.usuarioEscalado(Global.logadoReference);
      bool disponivel = culto.usuarioDisponivel(Global.logadoReference);
      bool restrito = culto.usuarioRestrito(Global.logadoReference);
      var colorVar =
          Theme.of(context).brightness == Brightness.dark ? 800 : 600;
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
          fixedSize: const Size(92, 92),
          padding: const EdgeInsets.all(12),
          side: const BorderSide(style: BorderStyle.none),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(8))),
          backgroundColor: escalado
              ? Colors.green[colorVar]
              : disponivel
                  ? Colors.blue[colorVar]
                  : restrito
                      ? Colors.red[colorVar]
                      : Colors.grey[colorVar],
          primary: Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            alterar
                ? const Center(
                    child: SizedBox.square(
                      dimension: 32,
                      child: CircularProgressIndicator(strokeWidth: 2),
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
                    height: 32,
                    color: Colors.white,
                    colorBlendMode: BlendMode.srcATop,
                  ),
            const SizedBox(height: 4),
            Text(
              escalado
                  ? 'Estou ESCALADO'
                  : disponivel
                      ? 'Estou DISPONÍVEL'
                      : restrito
                          ? 'Estou RESTRITO'
                          : 'Ainda não decidi',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    });
  }

  /// Usuário pode ser escalado
  bool get _podeSerEscalado =>
      (Global.logado?.ehDirigente ?? false) ||
      (Global.logado?.ehCoordenador ?? false) ||
      (Global.logado?.ehComponente ?? false);

  bool get _estouEscalado => culto.usuarioEscalado(Global.logadoReference);

  bool get _estouDisponivel => culto.usuarioDisponivel(Global.logadoReference);

  bool get _estouRestrito => culto.usuarioRestrito(Global.logadoReference);

  /// Equipe escalada
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
}
