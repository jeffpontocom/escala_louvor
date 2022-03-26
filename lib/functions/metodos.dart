import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../global.dart';
import '/models/culto.dart';
import '/models/igreja.dart';
import '/models/instrumento.dart';
import '/models/integrante.dart';

class Metodo {
  // Obter Integrante Logado
  static StreamSubscription<User?> escutarIntegranteLogado() {
    return FirebaseAuth.instance.userChanges().listen((user) {
      if (user == null || user.uid.isEmpty) {
        Global.integranteLogado = null;
        dev.log(
            'ALTERAÇÃO Integrante logado: ${Global.integranteLogado?.data()?.nome ?? ''}');
      } else {
        FirebaseFirestore.instance
            .collection(Integrante.collection)
            .doc(user.uid)
            .withConverter<Integrante>(
                fromFirestore: (snapshot, _) =>
                    Integrante.fromJson(snapshot.data()!),
                toFirestore: (pacote, _) => pacote.toJson())
            .get()
            .asStream()
            .listen((snapshot) {
          Global.integranteLogado = snapshot;
          dev.log(
              'ALTERAÇÃO Integrante logado: ${Global.integranteLogado?.data()?.nome ?? ''}');
        });
      }
    });
  }

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

  /// Atualizar ou Criar Instrumento
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

  /// Atualizar ou Criar Integrante
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

  /// Atualizar ou Criar Culto
  static Future salvarCulto(Culto culto, {String? id}) async {
    FirebaseFirestore.instance
        .collection(Culto.collection)
        .withConverter<Culto>(
          fromFirestore: (snapshot, _) => Culto.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .doc(id)
        .set(culto);
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
      dev.log(e.toString());
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
        .where('funcoes', arrayContains: funcao)
        .orderBy('nome')
        .withConverter<Integrante>(
          fromFirestore: (snapshot, _) => Integrante.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .get();
  }

  /// Lista de Instrumento
  static Future<QuerySnapshot<Instrumento>> getInstrumentos(
      {required bool ativo}) async {
    return FirebaseFirestore.instance
        .collection(Instrumento.collection)
        .where('ativo', isEqualTo: ativo)
        .withConverter<Instrumento>(
          fromFirestore: (snapshot, _) =>
              Instrumento.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .get();
  }

  /// Igreja especifica
  static Future<DocumentSnapshot<Igreja>?> obterSnapshotIgreja(
      String? id) async {
    if (id == null) {
      return null;
    }
    return await FirebaseFirestore.instance
        .collection(Igreja.collection)
        .doc(id)
        .withConverter<Igreja>(
          fromFirestore: (snapshot, _) => Igreja.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .get();
  }

  /// Culto especifica
  static Future<DocumentSnapshot<Culto>?> obterSnapshotCulto(String? id) async {
    if (id == null) {
      return null;
    }
    return await FirebaseFirestore.instance
        .collection(Culto.collection)
        .doc(id)
        .withConverter<Culto>(
          fromFirestore: (snapshot, _) => Culto.fromJson(snapshot.data()!),
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
        onFileLoading: (FilePickerStatus status) => dev.log('$status'),
        //allowedExtensions: ['xlsx'],
      );
      if (result != null && result.files.isNotEmpty) {
        final fileBytes = result.files.first.bytes;
        final fileName = result.files.first.name;
        final fileExtension = result.files.first.extension;
        dev.log(fileName);
        // Salvar na Cloud Firestore
        var ref = FirebaseStorage.instance.ref('fotos/$fileName');
        if (kIsWeb) {
          await ref.putData(fileBytes!,
              SettableMetadata(contentType: 'image/$fileExtension'));
        } else {
          var file = File(result.files.first.path!);
          await ref.putFile(file);
        }

        fotoUrl = await ref.getDownloadURL();
      }
    } on PlatformException catch (e) {
      dev.log('Unsupported operation: ' + e.toString(), name: 'CarregarFoto');
    } on firebase_core.FirebaseException catch (e) {
      dev.log('FirebaseException code: ' + e.code, name: 'CarregarFoto');
    } catch (e) {
      dev.log('Catch Exception: ' + e.toString(), name: 'CarregarFoto');
    }
    // Retorno
    return fotoUrl;
  }

  /// Carregar arquivo PDF
  static Future<String?> carregarArquivoPdf() async {
    String url = '';
    // Abrir seleção de foto
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        onFileLoading: (FilePickerStatus status) => dev.log('$status'),
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.isNotEmpty) {
        final fileBytes = result.files.first.bytes;
        final fileName = result.files.first.name;
        final fileExtension = result.files.first.extension;
        dev.log(fileName);
        // Salvar na Cloud Firestore
        var ref = FirebaseStorage.instance.ref('liturgias/$fileName');
        if (kIsWeb) {
          await ref.putData(fileBytes!,
              SettableMetadata(contentType: 'application/$fileExtension'));
        } else {
          var file = File(result.files.first.path!);
          await ref.putFile(file);
        }

        url = await ref.getDownloadURL();
      }
    } on PlatformException catch (e) {
      dev.log('Unsupported operation: ' + e.toString(), name: 'CarregarFoto');
    } on firebase_core.FirebaseException catch (e) {
      dev.log('FirebaseException code: ' + e.code, name: 'CarregarFoto');
    } catch (e) {
      dev.log('Catch Exception: ' + e.toString(), name: 'CarregarFoto');
    }
    // Retorno
    return url;
  }

  /// Abrir arquivo PDF
  static void abrirArquivoPdf(String? url) {
    if (url == null || url.isEmpty) return;
    dev.log('TODO: abrir PDF');
  }

  static Future<bool> definirDisponibiliadeParaOCulto(
      DocumentReference<Culto> reference) async {
    if (Global.integranteLogado == null) {
      dev.log('Valores nulos');
      return false;
    }
    var culto = await obterSnapshotCulto(reference.id);
    if (culto == null) return false;
    bool exist = culto
            .data()!
            .disponiveis
            ?.map((e) => e.toString())
            .contains(Global.integranteLogado!.reference.toString()) ??
        false;
    if (exist) {
      try {
        await culto.reference.update({
          'disponiveis':
              FieldValue.arrayRemove([Global.integranteLogado!.reference])
        });
        dev.log('Removido com Sucesso');
        return true;
      } catch (e) {
        dev.log('Erro: ${e.toString()}');
        return false;
      }
    } else {
      try {
        await culto.reference.update({
          'disponiveis':
              FieldValue.arrayUnion([Global.integranteLogado!.reference])
        });
        dev.log('Adicionado com Sucesso');
        return true;
      } catch (e) {
        dev.log('Erro: ${e.toString()}');
        return false;
      }
    }
  }

  static Future<bool> definirDataHoraDoEnsaio(
      DocumentReference<Culto> reference, Timestamp dataHora) async {
    try {
      await reference.update({'dataEnsaio': dataHora});
      dev.log('Data definida com sucesso');
      return true;
    } catch (e) {
      dev.log('Erro: ${e.toString()}');
      return false;
    }
  }

  static Future<bool> escalarDirigente(DocumentReference<Culto> reference,
      DocumentReference<Integrante> integrante) async {
    try {
      await reference.update({'dirigente': integrante});
      dev.log('Sucesso!');
      return true;
    } catch (e) {
      dev.log('Erro: ${e.toString()}');
      return false;
    }
  }

  static Future<bool> atualizarCampoDoCulto({
    required DocumentReference<Culto> reference,
    required String campo,
    required dynamic valor,
  }) async {
    try {
      await reference.update({campo: valor});
      dev.log('Sucesso!');
      return true;
    } catch (e) {
      dev.log('Erro: ${e.toString()}');
      return false;
    }
  }
}
