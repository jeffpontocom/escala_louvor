import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/main.dart';
import 'package:escala_louvor/models/culto.dart';
import 'package:escala_louvor/models/instrumento.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ViewCulto extends StatefulWidget {
  const ViewCulto({Key? key}) : super(key: key);

  @override
  State<ViewCulto> createState() => _ViewCultoState();
}

class _ViewCultoState extends State<ViewCulto> {
  Culto mCulto = Culto(
    dataCulto: Timestamp.fromDate(DateTime(2022, 3, 13, 19, 30)),
    ocasiao: 'culto vespertino',
  );

  /* WIDGETS */

  Widget get _cultoData {
    DateTime data = mCulto.dataCulto.toDate();
    var diaSemana = DateFormat(DateFormat.WEEKDAY, 'pt_BR').format(data);
    var diaMes = DateFormat(DateFormat.ABBR_MONTH_DAY, 'pt_BR').format(data);
    var hora = DateFormat(DateFormat.HOUR24_MINUTE, 'pt_BR').format(data);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icone dia/noite
        Icon(
          data.hour >= 6 && data.hour < 18 ? Icons.sunny : Icons.dark_mode,
          size: 20,
        ),
        const VerticalDivider(width: 8),
        // Coluna
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(diaSemana, style: Theme.of(context).textTheme.labelSmall),
            Text(diaMes + ', ' + hora,
                style: Theme.of(context).textTheme.headline5),
            const SizedBox(height: 4),
            Text((mCulto.ocasiao ?? '').toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall)
          ],
        ),
      ],
    );
  }

  Widget _secao(String titulo) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        titulo,
        style: Theme.of(context)
            .textTheme
            .titleMedium!
            .copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _iconPessoaInstrumento(Image foto, Instrumento instrumento) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Foto da pessoa
        CircleAvatar(
          child: const Icon(Icons.account_circle),
          backgroundColor: Colors.grey.withOpacity(0.2),
        ),
        // Instrumento
        Icon(
          instrumento.icone,
          size: 18,
        ),
      ],
    );
  }

  /* FUNCOES */
  bool get _usuarioEscalado {
    if (auth.currentUser == null) return false;
    if (mCulto.dirigente == auth.currentUser ||
        mCulto.coordenador == auth.currentUser) return true;
    if (mCulto.equipe == null || mCulto.equipe!.isEmpty) return false;
    for (var integrante in mCulto.equipe!.values) {
      if (integrante == auth.currentUser) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _usuarioEscalado ? Colors.yellow.withOpacity(0.5) : null,
      child: Column(
        children: [
          // Cabeçalho
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(child: _cultoData),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.hail_rounded),
                  label: const Text('Estou disponível'),
                ),
              ],
            ),
          ),
          const Divider(),
          ListView(
            shrinkWrap: true,
            children: [
              // Dirigente
              _secao('Dirigente'),
              ListTile(
                leading: _iconPessoaInstrumento(Image.asset(''),
                    Instrumento(ativo: true, nome: 'Voz', icone: Icons.mic)),
                title:
                    Text(mCulto.dirigente?.displayName ?? 'Nome do dirigente'),
              ),
              // Coordenador
              _secao('Coordenador técnico'),
              ListTile(
                leading: _iconPessoaInstrumento(
                    Image.asset(''),
                    Instrumento(
                        ativo: true, nome: 'Voz', icone: Icons.library_music)),
                title: Text(
                    mCulto.dirigente?.displayName ?? 'Nome do coordenador'),
              ),
              // Equipe
              _secao('Equipe'),
              ListTile(
                leading: _iconPessoaInstrumento(Image.asset(''),
                    Instrumento(ativo: true, nome: 'Voz', icone: Icons.mic)),
                title: Text(mCulto.dirigente?.displayName ?? 'Fulano de Tal'),
                subtitle: const Text('Vocal'),
              ),
              ListTile(
                leading: _iconPessoaInstrumento(
                    Image.asset(''),
                    Instrumento(
                        ativo: true, nome: 'Voz', icone: Icons.music_note)),
                title:
                    Text(mCulto.dirigente?.displayName ?? 'Cicrano de Souza'),
                subtitle: const Text('Guitarra'),
              ),
              ListTile(
                leading: _iconPessoaInstrumento(
                    Image.asset(''),
                    Instrumento(
                        ativo: true, nome: 'Voz', icone: Icons.keyboard)),
                title: Text(mCulto.dirigente?.displayName ?? 'Beltrano Ortiz'),
                subtitle: const Text('Teclado'),
              ),
              const Divider(),
              _secao('ENSAIO'),
              const Divider(),
              _secao('Canticos'),
              const Divider(),
              _secao('Ver Liturgia'),
              _secao('Observações:')
            ],
          )
        ],
      ),
    );
  }
}
