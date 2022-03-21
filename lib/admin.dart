import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/functions/metodos.dart';
import 'package:escala_louvor/models/igreja.dart';
import 'package:escala_louvor/utils/mensagens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({Key? key}) : super(key: key);

  /* WIDGETS */
  Widget tituloSecao(titulo) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        titulo,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  /* DIALOGS */
  void _verIgrejas(BuildContext context) {
    Mensagem.bottomDialog(
      context: context,
      titulo: 'Igrejas / Locais de Culto',
      icon: Icons.business,
      conteudo: StreamBuilder<QuerySnapshot<Igreja>>(
        stream: Metodo.escutarIgrejas(),
        builder: ((context, snapshot) {
          if (!snapshot.hasData) {
            return Column(mainAxisSize: MainAxisSize.min, children: const [
              Center(
                child: CircularProgressIndicator(),
              )
            ]);
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: ActionChip(
                    label: const Text('Nova igreja'),
                    onPressed: () {
                      _abrirIgreja(
                        context,
                        igreja: Igreja(ativa: true, nome: '', sigla: ''),
                      );
                    }),
              ),
              snapshot.data!.docs.isEmpty
                  ? const Text('Nenhuma igreja cadastrada')
                  : ListView(
                      shrinkWrap: true,
                      children: List.generate(snapshot.data!.size, (index) {
                        Igreja igreja = snapshot.data!.docs[index].data();
                        DocumentReference reference =
                            snapshot.data!.docs[index].reference;
                        return ListTile(
                          leading: CircleAvatar(
                            child: const Icon(Icons.church),
                            foregroundImage: NetworkImage(igreja.fotoUrl ?? ''),
                          ),
                          title: Text(igreja.sigla),
                          subtitle: Text(igreja.nome),
                          trailing: const IconButton(
                            onPressed: null,
                            icon: Icon(Icons.map),
                          ),
                          onTap: () => _abrirIgreja(context,
                              igreja: igreja, id: reference.id),
                        );
                      }),
                    ),
              const SizedBox(height: 24),
            ],
          );
        }),
      ),
    );
  }

  void _abrirIgreja(BuildContext context,
      {required Igreja igreja, String? id}) {
    Mensagem.bottomDialog(
      context: context,
      titulo: 'Cadastro da Igreja',
      conteudo: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          Row(
            children: [
              // Foto
              StatefulBuilder(builder: (innerContext, StateSetter innerState) {
                return CircleAvatar(
                  child: IconButton(
                      onPressed: () async {
                        var url = await Metodo.carregarFoto();
                        if (url != null && url.isNotEmpty) {
                          innerState(() {
                            igreja.fotoUrl = url;
                          });
                        }
                      },
                      icon: const Icon(Icons.church)),
                  foregroundImage: NetworkImage(igreja.fotoUrl ?? ''),
                  radius: 48,
                );
              }),
              const SizedBox(width: 12),
              // Sigla
              Expanded(
                child: TextFormField(
                  initialValue: igreja.sigla,
                  decoration: const InputDecoration(labelText: 'Sigla'),
                  onChanged: (value) {
                    igreja.sigla = value;
                  },
                ),
              ),
            ],
          ),
          // Nome
          TextFormField(
            initialValue: igreja.nome,
            decoration: const InputDecoration(labelText: 'Nome completo'),
            onChanged: (value) {
              igreja.nome = value;
            },
          ),
          // Endereço
          TextFormField(
            initialValue: igreja.endereco,
            decoration: const InputDecoration(labelText: 'Endereço'),
            onChanged: (value) {
              igreja.endereco = value;
            },
          ),
          const SizedBox(height: 48),
          // Botão criar
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('SALVAR'),
            onPressed: () async {
              // Abre progresso
              Mensagem.aguardar(context: context);
              // Salva os dados no firebase
              await Metodo.salvarIgreja(igreja, id: id);
              Modular.to.pop(); // Fecha progresso
              Modular.to.pop(); // Fecha dialog
            },
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administração do sistema'),
      ),
      body: Scrollbar(
        isAlwaysShown: true,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          children: [
            tituloSecao('Cadastros'),
            // Igrejas
            ListTile(
              leading: const Icon(Icons.food_bank),
              title: const Text('Igrejas e Locais de Culto'),
              subtitle: FutureBuilder(builder: ((context, snapshot) {
                return Text('2 locais cadastrados');
              })),
              trailing: IconButton(
                icon: const Icon(Icons.add_business),
                color: Theme.of(context).colorScheme.primary,
                onPressed: () => _abrirIgreja(
                  context,
                  igreja: Igreja(ativa: true, nome: '', sigla: ''),
                ),
              ),
              onTap: () => _verIgrejas(context),
            ),
            // Instrumentos
            ListTile(
              leading: const Icon(Icons.music_video),
              title: const Text('Instrumentos e Equipamentos'),
              subtitle: FutureBuilder(builder: ((context, snapshot) {
                return Text('10 objetos cadastrados');
              })),
              trailing: IconButton(
                icon: const Icon(Icons.playlist_add),
                color: Theme.of(context).colorScheme.primary,
                onPressed: null,
              ),
              onTap: () {
                // abrir dialog
              },
            ),
            // Integrantes
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Integrantes'),
              subtitle: FutureBuilder(builder: ((context, snapshot) {
                return Text('40 ativos');
              })),
              trailing: IconButton(
                icon: const Icon(Icons.person_add_alt_1),
                color: Theme.of(context).colorScheme.primary,
                onPressed: null,
              ),
              onTap: () {
                // abrir dialog
              },
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }
}
