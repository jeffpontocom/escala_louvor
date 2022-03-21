import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '/global.dart';
import '/models/culto.dart';
import '/models/instrumento.dart';
import '/models/integrante.dart';

class ViewCulto extends StatefulWidget {
  const ViewCulto({Key? key, required this.culto}) : super(key: key);
  final Culto culto;

  @override
  State<ViewCulto> createState() => _ViewCultoState();
}

class _ViewCultoState extends State<ViewCulto> {
  /* WIDGETS */

  /// Informações sobre a data do culto
  Widget get _cultoData {
    DateTime data = mCulto.dataCulto.toDate();
    var diaSemana = DateFormat(DateFormat.WEEKDAY, 'pt_BR').format(data);
    var diaMes = DateFormat(DateFormat.ABBR_MONTH_DAY, 'pt_BR').format(data);
    var hora = DateFormat(DateFormat.HOUR24_MINUTE, 'pt_BR').format(data);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ícone dia/noite
        Icon(
          data.hour >= 6 && data.hour < 18 ? Icons.sunny : Icons.dark_mode,
          size: 20,
        ),
        const VerticalDivider(width: 8),
        // Informações
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ocasião
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text((mCulto.ocasiao ?? '').toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall),
            ),
            // Dia da Semana
            Text(diaSemana, style: Theme.of(context).textTheme.labelMedium),
            // Data e Hora abreviados
            Text(diaMes + ' | ' + hora,
                style: Theme.of(context).textTheme.headline5),
          ],
        ),
      ],
    );
  }

  /// Dados sobre data e hora do ensaio
  Widget get _rowEnsaio {
    var dataFormatada = 'Sem horário definido';
    if (mCulto.dataEnsaio != null) {
      dataFormatada = DateFormat("EEE, d/MM/yyyy 'às' HH:mm", 'pt_BR')
          .format(mCulto.dataEnsaio!.toDate());
    }
    return Row(
      children: [
        const SizedBox(width: 12),
        const SizedBox(
          width: 80,
          child: Text('ENSAIO'),
        ),
        // Informação
        Expanded(
            child: Text(
          dataFormatada,
          style: Theme.of(context)
              .textTheme
              .labelLarge!
              .copyWith(fontWeight: FontWeight.bold),
        )),
        const SizedBox(width: 8),
        // Botão de ação para dirigentes
        IconButton(onPressed: () {}, icon: const Icon(Icons.more_time)),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget get _rowLiturgia {
    return Row(
      children: [
        const SizedBox(width: 12),
        const SizedBox(
          width: 80,
          child: Text('LITURGIA'),
        ),
        // Botão para abrir arquivo
        TextButton.icon(
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Abrir arquivo'),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            textStyle: Theme.of(context).textTheme.labelMedium,
          ),
          onPressed: null,
        ),
        const Expanded(
          child: SizedBox(),
        ),
        // Botão de ação para dirigentes
        IconButton(onPressed: () {}, icon: const Icon(Icons.upload_file)),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget get _rowOqueFalta {
    var resultado = _verificaEquipe();
    return Container(
      color: Colors.yellow.shade200,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        resultado,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }

  Widget get _observacoes {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextFormField(
        initialValue: mCulto.obs,
        enabled: false,
        minLines: 5,
        maxLines: 15,
        decoration: const InputDecoration(
          labelText: 'Observações',
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        onChanged: (value) {
          mCulto.obs = value;
        },
      ),
    );
  }

  Widget _secaoIntegrante(String titulo, Map<Instrumento, Integrante?> dados) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 16, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Título
              Text(
                titulo,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.more_horiz,
                  color: Colors.grey,
                  size: 18,
                ),
              ),
            ],
          ),
          // Integrantes
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              dados.length,
              (index) {
                var integrante = dados.values.elementAt(index);
                var instrumento = dados.entries.elementAt(index).key;
                return _pessoaInstrumento(integrante, instrumento);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _pessoaInstrumento(Integrante? integrante, Instrumento instrumento) {
    var nomeIntegrante = integrante?.nome ?? '[Sem nome]';
    var nomePrimeiro = nomeIntegrante.split(' ').first;
    var nomeSegundo = nomeIntegrante.split(' ').last;
    nomeIntegrante = nomePrimeiro == nomeSegundo
        ? nomePrimeiro
        : nomePrimeiro + ' ' + nomeSegundo;
    return Container(
      width: 112,
      height: 128,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(width: 1, color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: integrante == Global.integranteLogado
            ? Colors.amber.shade100
            : null,
      ),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Foto da pessoa
              CircleAvatar(
                child: const Icon(Icons.co_present),
                foregroundImage: NetworkImage(integrante?.fotoUrl ?? ''),
                backgroundColor: Colors.grey.shade200,
                radius: 28,
              ),
              const SizedBox(height: 8),
              Text(
                nomeIntegrante,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                instrumento.nome,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          // Instrumento
          Image.asset(
            instrumento.iconAsset,
            width: 24,
          ),
        ],
      ),
    );
  }

  /* FUNÇÕES */

  /// Verifica se usuário está escalado
  bool get _usuarioEscalado {
    if (mCulto.dirigente == Global.integranteLogado ||
        mCulto.coordenador == Global.integranteLogado) return true;
    if (mCulto.equipe == null || mCulto.equipe!.isEmpty) return false;
    for (var integrante in mCulto.equipe!.values) {
      if (integrante == Global.integranteLogado) return true;
    }
    return false;
  }

  /// Verifica na equipe se há no mínimo:
  /// - 1 dirigente
  /// - 1 vocal
  /// - 1 guitarra ou 1 violão
  /// - 1 baixo
  /// - 1 teclado
  /// - 1 sonoplasta
  /// - 1 transmissão
  String _verificaEquipe() {
    if (mCulto.equipe == null || mCulto.equipe!.isEmpty) {
      return 'Escalar equipe!';
    }
    List<Instrumento> lista = [];
    for (var instrumento in mCulto.equipe!.keys) {
      lista.add(instrumento);
    }
    // Regras
    if (lista.isEmpty) return 'Falta: Voz, Violão, Teclado, Sonorização';
    return 'Equipe completa!';
  }

  /* SISTEMA */
  late Culto mCulto;

  @override
  void initState() {
    // PREENCHIDO A PROPOSITO DE TESTES
    mCulto = widget.culto;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Cabeçalho
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Dados sobre o culto
              Expanded(child: _cultoData),
              // Botão de disponibilidade
              OutlinedButton(
                onPressed: () {},
                child: Wrap(
                  direction: Axis.vertical,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    const Icon(Icons.hail_rounded),
                    Text(_usuarioEscalado ? 'Escalado!' : 'disponível?'),
                  ],
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(12),
                  backgroundColor: _usuarioEscalado ? Colors.blue : null,
                  primary: _usuarioEscalado ? Colors.grey.shade100 : null,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            shrinkWrap: true,
            children: [
              _rowEnsaio,
              const Divider(height: 1),
              _rowLiturgia,
              const Divider(height: 1),
              _rowOqueFalta,
              const Divider(height: 1),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dirigente
                  _secaoIntegrante(
                      'Dirigente',
                      mCulto.dirigente == null
                          ? {}
                          : {
                              Instrumento(
                                nome: '',
                                iconAsset: 'assets/icons/music_dirigente.png',
                              ): mCulto.dirigente
                            }),
                  // Coordenador
                  _secaoIntegrante(
                      'Coordenador técnico',
                      mCulto.coordenador == null
                          ? {}
                          : {
                              Instrumento(
                                nome: '',
                                iconAsset: 'assets/icons/music_coordenador.png',
                              ): mCulto.coordenador
                            }),
                ],
              ),
              // Equipe
              _secaoIntegrante('Equipe', mCulto.equipe ?? {}),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Cânticos',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              _observacoes,
              Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton.icon(
                  onPressed: null,
                  label: const Text('Alterar dados do culto'),
                  icon: const Icon(Icons.edit_calendar),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ],
    );
  }
}
