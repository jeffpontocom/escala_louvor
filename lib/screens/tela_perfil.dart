import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '/rotas.dart';
import '/functions/metodos_firebase.dart';
import '/models/integrante.dart';
import '/screens/views/view_integrante.dart';
import '/utils/estilos.dart';
import '/utils/mensagens.dart';

class TelaPerfil extends StatefulWidget {
  final String id;
  const TelaPerfil({Key? key, required this.id}) : super(key: key);

  @override
  State<TelaPerfil> createState() => _TelaPerfilState();
}

class _TelaPerfilState extends State<TelaPerfil> {
  /* VARIÁVEIS */
  late DocumentReference _documentReference;
  late Integrante _integrante;
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
        title: Text('Perfil', style: Estilo.appBarTitulo),
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
      body: FutureBuilder<DocumentSnapshot<Integrante>?>(
          future: MeuFirebase.obterSnapshotIntegrante(widget.id),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snap.data!.exists || snap.data!.data() == null) {
              return const Center(
                  child: Text('Falha ao obter dados do integrante.'));
            }
            _integrante = snap.data!.data()!;
            _documentReference = snap.data!.reference;
            // Tela com retorno preenchido
            return ViewIntegrante(
                id: _documentReference.id,
                integrante: _integrante,
                editMode: _ehMeuPerfil,
                novoCadastro: false);
          }),
    );
  }

  Future _sair() async {
    Mensagem.aguardar(context: context, mensagem: 'Saindo...');
    await FirebaseAuth.instance.signOut();
    Modular.to.navigate(AppRotas.HOME);
  }
}
