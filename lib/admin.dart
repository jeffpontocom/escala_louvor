import 'package:cloud_firestore/cloud_firestore.dart';
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
      titulo: 'Igrejas',
      icon: Icons.business,
      conteudo: StreamBuilder<QuerySnapshot<Igreja>>(
        stream: FirebaseFirestore.instance
            .collection('igrejas')
            .withConverter<Igreja>(
              fromFirestore: (snapshot, _) => Igreja.fromJson(snapshot.data()!),
              toFirestore: (model, _) => model.toJson(),
            )
            .snapshots(),
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
                      _addIgreja(context);
                    }),
              ),
              snapshot.data!.docs.isEmpty
                  ? const Text('Nenhuma igreja cadastrada')
                  : ListView(
                      shrinkWrap: true,
                      children: List.generate(
                        snapshot.data!.size,
                        (index) => ListTile(
                          title: Text(snapshot.data!.docs[index].data().alias),
                          subtitle:
                              Text(snapshot.data!.docs[index].data().nome),
                          trailing: const IconButton(
                            onPressed: null,
                            icon: Icon(Icons.map),
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 24),
            ],
          );
        }),
      ),
    );
  }

  void _addIgreja(BuildContext context) {
    Igreja novaIgreja = Igreja(ativa: true, nome: '', alias: '');
    Mensagem.bottomDialog(
      context: context,
      titulo: 'Nova Igreja/Local de Culto',
      conteudo: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          // Sigla
          TextFormField(
            decoration: const InputDecoration(labelText: 'Sigla'),
            onChanged: (value) {
              novaIgreja.alias = value;
            },
          ),
          // Nome
          TextFormField(
            decoration: const InputDecoration(labelText: 'Nome completo'),
            onChanged: (value) {
              novaIgreja.nome = value;
            },
          ),
          // Nome
          TextFormField(
            decoration: const InputDecoration(labelText: 'Endereço'),
            onChanged: (value) {
              novaIgreja.endereco = value;
            },
          ),
          const SizedBox(height: 48),
          // Botão criar
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('CRIAR'),
            onPressed: () async {
              // Abre progresso
              Mensagem.aguardar(context: context);
              // Salva os dados no firebase
              await FirebaseFirestore.instance
                  .collection('igrejas')
                  .withConverter<Igreja>(
                    fromFirestore: (snapshot, _) =>
                        Igreja.fromJson(snapshot.data()!),
                    toFirestore: (model, _) => model.toJson(),
                  )
                  .doc()
                  .set(novaIgreja);
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
                onPressed: () => _addIgreja(context),
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
