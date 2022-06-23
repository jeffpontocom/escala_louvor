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
import 'cached_circle_avatar.dart';

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

  // DEFINIÇÕES SOBRE DISPONIBILIDADE

  // Usuário
  bool get _possoSerEscalado => culto.usuarioPodeSerEscalado(Global.logado);
  bool get _estouEscalado => culto.usuarioEscalado(Global.logadoReference);
  bool get _estouDisponivel => culto.usuarioDisponivel(Global.logadoReference);
  bool get _estouRestrito => culto.usuarioRestrito(Global.logadoReference);
  // Cores
  Color get _corEscalado => Colors.green.shade600;
  Color get _corDisponivel => Colors.blue.shade600;
  Color get _corRestrito => Colors.red.shade600;
  Color get _corIndeciso => Colors.grey.shade600;

  @override
  Widget build(BuildContext context) {
    return Slidable(
      startActionPane: _possoSerEscalado
          ? ActionPane(
              motion: const DrawerMotion(),
              children: slidableButtons,
            )
          : const ActionPane(
              extentRatio: 0.3,
              motion: DrawerMotion(),
              children: [
                SlidableAction(
                    label: 'Nenhuma\nação possível',
                    backgroundColor: Colors.grey,
                    onPressed: null)
              ],
            ),
      endActionPane: _possoSerEscalado
          ? ActionPane(
              motion: const DrawerMotion(),
              children: slidableButtons,
            )
          : const ActionPane(
              extentRatio: 0.3,
              motion: DrawerMotion(),
              children: [
                SlidableAction(
                    label: 'Nenhuma\nação possível',
                    backgroundColor: Colors.grey,
                    onPressed: null)
              ],
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
                        igreja,
                        showResumo && _possoSerEscalado
                            ? Padding(
                                padding: const EdgeInsets.only(left: 4, top: 2),
                                child: avatarDisponibilidade)
                            : const SizedBox(),
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
                    const SizedBox(height: 8),
                    // Linha 3: Escalados e Cânticos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(child: culto.emEdicao ? chipEmEdicao : equipe),
                        const SizedBox(width: 8),
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
                child: _possoSerEscalado && !showResumo
                    ? botaoDisponibilidade
                    : null),
          ]);
        },
      ),
    );
  }

  get avatarDisponibilidade {
    Image image;
    Color color;
    if (_estouEscalado) {
      image = Image.asset('assets/icons/ic_escalado.png');
      color = _corEscalado;
    } else if (_estouDisponivel) {
      image = Image.asset('assets/icons/ic_disponivel.png');
      color = _corDisponivel;
    } else if (_estouRestrito) {
      image = Image.asset('assets/icons/ic_restrito.png');
      color = _corRestrito;
    } else {
      image = Image.asset('assets/icons/ic_indeciso.png');
      color = _corIndeciso;
    }
    return CircleAvatar(
      radius: 12,
      backgroundColor: color,
      child: Padding(padding: const EdgeInsets.all(4), child: image),
    );
  }

  void doNothing(BuildContext context) {}

  get slidableButtons {
    if (_estouEscalado) {
      return [
        CustomSlidableAction(
          flex: 1,
          backgroundColor: _corEscalado,
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
        backgroundColor: _corDisponivel,
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
        backgroundColor: _corRestrito,
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
          return Shimmer.fromColors(
            baseColor: Colors.grey.withOpacity(0.38),
            highlightColor: Colors.grey.withOpacity(0.12),
            child: const RawChip(
              avatar: CircleAvatar(
                radius: 10,
                child: Icon(Icons.church),
              ),
              label: SizedBox(width: 20),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
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
          label: Text(igreja?.sigla ?? '', style: theme.textTheme.caption),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        );
      },
    );
  }

  get chipEmEdicao {
    return Wrap(
      children: [
        Chip(
          avatar: Icon(
            Icons.lock_open,
            size: 16,
            color: theme.colorScheme.secondary,
          ),
          label: Text('Em recrutamento', style: theme.textTheme.caption),
          backgroundColor: Colors.grey.withOpacity(0.12),
          padding: const EdgeInsets.only(right: 12),
          labelPadding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        )
      ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text('ENSAIO: $dataFormatada', style: theme.textTheme.bodySmall),
    );
  }

  /// Botão de disponibilidade
  get botaoDisponibilidade {
    bool alterar = false;
    return StatefulBuilder(builder: (context, setState) {
      return OutlinedButton(
        onPressed: _estouEscalado || _estouRestrito
            ? () {}
            : () async {
                setState(() {
                  alterar = true;
                });
                await MeuFirebase.definirDisponibilidadeParaOCulto(reference);
              },
        onLongPress: _estouEscalado || _estouDisponivel
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
          backgroundColor: _estouEscalado
              ? _corEscalado
              : _estouDisponivel
                  ? _corDisponivel
                  : _estouRestrito
                      ? _corRestrito
                      : _corIndeciso,
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
                    _estouEscalado
                        ? 'assets/icons/ic_escalado.png'
                        : _estouDisponivel
                            ? 'assets/icons/ic_disponivel.png'
                            : _estouRestrito
                                ? 'assets/icons/ic_restrito.png'
                                : 'assets/icons/ic_indeciso.png',
                    height: 32,
                    color: Colors.white,
                    colorBlendMode: BlendMode.srcATop,
                  ),
            const SizedBox(height: 4),
            Text(
              _estouEscalado
                  ? 'Estou ESCALADO'
                  : _estouDisponivel
                      ? 'Estou DISPONÍVEL'
                      : _estouRestrito
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
