import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '/functions/metodos_firebase.dart';
import '/models/integrante.dart';
import '/screens/views/view_integrante.dart';
import '/utils/mensagens.dart';
import 'home.dart';

class TelaPerfil extends StatefulWidget {
  final String id;
  final String? hero;
  final DocumentSnapshot<Integrante>? snapIntegrante;
  const TelaPerfil({Key? key, required this.id, this.hero, this.snapIntegrante})
      : super(key: key);

  @override
  State<TelaPerfil> createState() => _TelaPerfilState();
}

class _TelaPerfilState extends State<TelaPerfil> {
  /* VARIÁVEIS */
  //late DocumentReference _documentReference;
  //late Integrante _integrante;
  late bool _ehMeuPerfil;

  /* SISTEMA */
  @override
  void initState() {
    // Ao visitar o próprio perfil o usuário habilita o modo de edição.
    _ehMeuPerfil = (widget.id == FirebaseAuth.instance.currentUser?.uid);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // APP BAR
      appBar: AppBar(
        title: const Text('Perfil'),
        titleSpacing: 0,
        actions: [
          _ehMeuPerfil
              ? TextButton.icon(
                  onPressed: _sair,
                  icon: const Icon(Icons.logout),
                  style: TextButton.styleFrom(primary: Colors.white),
                  label: const Text('SAIR'))
              : const SizedBox()
        ],
      ),
      // CONTEÚDO
      body: widget.snapIntegrante != null
          ? ViewIntegrante(
              id: widget.snapIntegrante!.id,
              integrante: widget.snapIntegrante!.data()!,
              editMode: _ehMeuPerfil,
              novoCadastro: false,
              hero: widget.hero ?? 'fotoPerfil',
            )
          : FutureBuilder<DocumentSnapshot<Integrante>?>(
              future: MeuFirebase.obterSnapshotIntegrante(widget.id),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.data!.exists || snap.data!.data() == null) {
                  return const Center(
                      child: Text('Falha ao obter dados do integrante.'));
                }
                var integrante = snap.data!.data()!;
                var documentReference = snap.data!.reference;
                // Tela com retorno preenchido
                return ViewIntegrante(
                  id: documentReference.id,
                  integrante: integrante,
                  editMode: _ehMeuPerfil,
                  novoCadastro: false,
                  hero: widget.hero ?? 'fotoPerfil',
                );
              }),
    );
  }

  Future _sair() async {
    Mensagem.aguardar(context: context, mensagem: 'Saindo...');
    await FirebaseAuth.instance.signOut();
    Modular.to.navigate('/${Paginas.values[0].name}');
  }
}
