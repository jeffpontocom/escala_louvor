import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'global.dart';
import 'models/integrante.dart';
import 'utils/estilos.dart';
import 'utils/medidas.dart';
import 'utils/mensagens.dart';
import 'utils/utils.dart';

/* 

  late bool ativo;
  late String nome;
  late String email;
  String? foto;
  String? fone;
  List<Funcao>? funcoes;
  List<Igreja>? igrejas;
  List<Grupo>? grupos;
  List<Instrumento>? instrumentos;
  List<DocumentReference>? disponibilidades;
  
   */

class PerfilPage extends StatefulWidget {
  final String id;
  const PerfilPage({Key? key, required this.id}) : super(key: key);

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  /* VARIÁVEIS */
  late Integrante _integrante;
  late DocumentReference _documentReference;
  late bool editMode;

  /* MÉTODOS */
  Future<DocumentSnapshot<Integrante>> get _firebaseSnapshot {
    return FirebaseFirestore.instance
        .collection(Integrante.collection)
        .doc(widget.id)
        .withConverter<Integrante>(
            fromFirestore: (snapshot, _) =>
                Integrante.fromJson(snapshot.data()!),
            toFirestore: (pacote, _) => pacote.toJson())
        .get();
  }

  Future _gravar() async {
    // Abre circulo de progresso
    Mensagem.aguardar(context: context, mensagem: 'Salvando dados...');
    _documentReference
        .withConverter<Integrante>(
          fromFirestore: (snapshot, _) => Integrante.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .set(_integrante)
        .then(
          (value) => Modular.to.pop(),
        )
        .onError(
      (error, stackTrace) {
        dev.log(error.toString(), name: 'PerfilPage');
        Modular.to.pop();
      },
    );
  }

  Future _sair() async {
    Mensagem.aguardar(context: context, mensagem: 'Saindo...');
    await Global.auth.signOut();
    Modular.to.navigate('/');
  }

  /* SISTEMA */
  @override
  void initState() {
    editMode = widget.id == Global.auth.currentUser?.uid;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Modular.to.navigate('/')),
        title: const Text('Perfil'),
        titleSpacing: 0,
      ),
      body: FutureBuilder<DocumentSnapshot<Integrante>>(
          future: _firebaseSnapshot,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snap.data!.exists || snap.data!.data() == null) {
              return const Center(child: Text('Erro!'));
            }
            _integrante = snap.data!.data()!;
            _documentReference = snap.data!.reference;
            // Tela com retorno preenchido
            return InkWell(
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
              child: Center(
                child: Scrollbar(
                  isAlwaysShown: true,
                  showTrackOnHover: true,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      vertical: Medidas.margemV(context),
                      horizontal: Medidas.margemH(context),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runAlignment: WrapAlignment.center,
                        runSpacing: 32,
                        spacing: 64,
                        children: [
                          Column(
                            children: [
                              // Foto do Integrante
                              Hero(
                                tag: widget.id,
                                child: const Icon(
                                  Icons.account_circle,
                                  size: 128.0,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Botão alterar foto
                              editMode
                                  ? ActionChip(
                                      label: const Text('Alterar foto'),
                                      onPressed: () {})
                                  : const SizedBox(),
                              const SizedBox(height: 8),
                              // E-mail do integrante
                              Text(
                                _integrante.email,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                                minWidth: 200, maxWidth: 450),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Nome do Integrante
                                TextFormField(
                                  enabled: editMode,
                                  initialValue: _integrante.nome,
                                  textCapitalization: TextCapitalization.words,
                                  keyboardType: TextInputType.name,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (value) {
                                    _integrante.nome = value;
                                  },
                                  decoration: Estilo.mInputDecoration
                                      .copyWith(labelText: 'Nome completo'),
                                ),
                                const SizedBox(height: 16),
                                // Telefone ou WhatsApp do Integrante
                                TextFormField(
                                  enabled: editMode,
                                  initialValue: Input.mascaraFone
                                      .getMaskedString(_integrante.fone ?? ''),
                                  inputFormatters: [Input.textoFone],
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  onSaved: (value) {
                                    _integrante.fone = Input.mascaraFone
                                        .clearMask(value ?? '');
                                  },
                                  decoration: Estilo.mInputDecoration
                                      .copyWith(labelText: 'WhatsApp'),
                                ),
                                SizedBox(height: editMode ? 32 : 0),
                                // Botões de Ação
                                editMode
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Sair
                                          OutlinedButton.icon(
                                            label: const Text('SAIR'),
                                            icon: const Icon(
                                                Icons.logout_rounded),
                                            style: OutlinedButton.styleFrom(
                                                primary: Colors.white,
                                                backgroundColor: Colors.red),
                                            onPressed: _sair,
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            // Salvar
                                            child: OutlinedButton.icon(
                                              label: const Text('ATUALIZAR'),
                                              icon: const Icon(
                                                  Icons.save_rounded),
                                              onPressed: () {
                                                _gravar();
                                              },
                                            ),
                                          ),
                                        ],
                                      )
                                    : const SizedBox(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
    );
  }
}
