import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

import '/models/igreja.dart';

class Metodo {
  /// Stream para escutar base de dados das Igrejas
  static Stream<QuerySnapshot<Igreja>> escutarIgrejas() {
    return FirebaseFirestore.instance
        .collection('igrejas')
        .withConverter<Igreja>(
          fromFirestore: (snapshot, _) => Igreja.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .snapshots();
  }

  /// Atualizar ou Criar nova igreja
  static Future salvarIgreja(Igreja igreja, {String? id}) async {
    FirebaseFirestore.instance
        .collection('igrejas')
        .withConverter<Igreja>(
          fromFirestore: (snapshot, _) => Igreja.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .doc(id)
        .set(igreja);
  }

  /// Trocar foto
  static Future<String?> carregarFoto() async {
    String fotoUrl = '';
    PlatformFile? file;
    // Abrir seleção de foto
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        onFileLoading: (FilePickerStatus status) =>
            dev.log('$status', name: 'CarregarFoto'),
        //allowedExtensions: ['xlsx'],
      );
      if (result != null && result.files.isNotEmpty) {
        final fileBytes = result.files.first.bytes;
        final fileName = result.files.first.name;
        final fileExtension = result.files.first.extension;
        dev.log(fileName, name: 'CarregarFoto');
        // Salvar na Cloud Firestore
        var ref = FirebaseStorage.instance.ref('fotos/$fileName');
        await ref.putData(
            fileBytes!, SettableMetadata(contentType: 'image/$fileExtension'));
        fotoUrl = await ref.getDownloadURL();
      }
    } on PlatformException catch (e) {
      dev.log('Unsupported operation: ' + e.toString(), name: 'CarregarFoto');
    } on firebase_core.FirebaseException catch (e) {
      dev.log(e.code, name: 'CarregarFoto');
    } catch (e) {
      dev.log('Catch Exception: ' + e.toString(), name: 'CarregarFoto');
    }
    // Retorno
    return fotoUrl;
  }
}
