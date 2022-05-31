import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/models/integrante.dart';
import 'package:flutter/material.dart';

class TileIntegrante extends StatefulWidget {
  final Integrante integrante;
  final DocumentReference<Integrante> reference;
  const TileIntegrante(
      {Key? key, required this.integrante, required this.reference})
      : super(key: key);

  @override
  State<TileIntegrante> createState() => _TileIntegranteState();
}

class _TileIntegranteState extends State<TileIntegrante> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.integrante.nome),
    );
  }
}
