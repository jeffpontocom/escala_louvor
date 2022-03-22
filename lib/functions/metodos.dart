import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/models/instrumento.dart';
import 'package:escala_louvor/models/integrante.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

import '../models/culto.dart';
import '/models/igreja.dart';

class Metodo {
  /// Stream para escutar base de dados das Igrejas
  static Stream<QuerySnapshot<Igreja>> escutarIgrejas({bool? ativos}) {
    return FirebaseFirestore.instance
        .collection(Igreja.collection)
        .where('ativo', isEqualTo: ativos)
        .orderBy('sigla')
        .withConverter<Igreja>(
          fromFirestore: (snapshot, _) => Igreja.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .snapshots();
  }

  /// Stream para escutar base de dados dos Instrumentos
  static Stream<QuerySnapshot<Instrumento>> escutarInstrumentos(
      {bool? ativos}) {
    return FirebaseFirestore.instance
        .collection(Instrumento.collection)
        .where('ativo', isEqualTo: ativos)
        .orderBy('nome')
        .withConverter<Instrumento>(
          fromFirestore: (snapshot, _) =>
              Instrumento.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .snapshots();
  }

  /// Stream para escutar base de dados dos Integrantes
  static Stream<QuerySnapshot<Integrante>> escutarIntegrantes({bool? ativos}) {
    return FirebaseFirestore.instance
        .collection(Integrante.collection)
        .where('ativo', isEqualTo: ativos)
        .orderBy('nome')
        .withConverter<Integrante>(
          fromFirestore: (snapshot, _) => Integrante.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .snapshots();
  }

  /// Stream para escutar base de dados das Igrejas
  static Stream<QuerySnapshot<Culto>> escutarCultos({
    Timestamp? dataMinima,
    Timestamp? dataMaxima,
    DocumentReference? integrante,
  }) {
    return FirebaseFirestore.instance
        .collection(Culto.collection)
        .where('dataCulto', isGreaterThanOrEqualTo: dataMinima)
        .where('dataCulto', isLessThanOrEqualTo: dataMaxima)
        .where('equipe', arrayContains: integrante)
        .orderBy('dataCulto')
        .withConverter<Culto>(
          fromFirestore: (snapshot, _) => Culto.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .snapshots();
  }

  /// Atualizar ou Criar nova igreja
  static Future salvarIgreja(Igreja igreja, {String? id}) async {
    FirebaseFirestore.instance
        .collection(Igreja.collection)
        .withConverter<Igreja>(
          fromFirestore: (snapshot, _) => Igreja.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .doc(id)
        .set(igreja);
  }

  /// Atualizar ou Criar no Instrumento
  static Future salvarInstrumento(Instrumento instrumento, {String? id}) async {
    FirebaseFirestore.instance
        .collection(Instrumento.collection)
        .withConverter<Instrumento>(
          fromFirestore: (snapshot, _) =>
              Instrumento.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .doc(id)
        .set(instrumento);
  }

  /// Atualizar ou Criar no Instrumento
  static Future salvarIntegrante(Integrante integrante, {String? id}) async {
    FirebaseFirestore.instance
        .collection(Integrante.collection)
        .withConverter<Integrante>(
          fromFirestore: (snapshot, _) => Integrante.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .doc(id)
        .set(integrante);
  }

  /// Criar novo usuário
  static Future<UserCredential?> criarUsuario(
      {required String email, required String senha}) async {
    FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'AppTemporario', options: Firebase.app().options);
    UserCredential? userCredential;
    try {
      userCredential = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(email: email, password: senha);
      userCredential.user?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      // Do something with exception. This try/catch is here to make sure
      // that even if the user creation fails, app.delete() runs, if is not,
      // next time Firebase.initializeApp() will fail as the previous one was
      // not deleted.
    }
    await tempApp.delete();
    return Future.sync(() => userCredential);
  }

  /// Identifica o total de cadastros de determinada coleção, conforme filtro de cadastros ativo ou não
  static Future<int> totalCadastros(String colecao, {bool? ativo}) async {
    var snap = await FirebaseFirestore.instance
        .collection(colecao)
        .where('ativo', isEqualTo: ativo)
        .get();
    return snap.docs.length;
  }

  /// Lista de Integrantes
  static Future<QuerySnapshot<Integrante>> getIntegrantes(
      {required bool ativo, int? funcao, DocumentReference? igreja}) async {
    return FirebaseFirestore.instance
        .collection(Integrante.collection)
        .where('ativo', isEqualTo: ativo)
        .orderBy('nome')
        .withConverter<Integrante>(
          fromFirestore: (snapshot, _) => Integrante.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .get();
  }

  /// Trocar foto
  static Future<String?> carregarFoto() async {
    String fotoUrl = '';
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
