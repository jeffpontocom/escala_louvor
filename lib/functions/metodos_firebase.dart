import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/models/cantico.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';

import '/global.dart';
import '/models/culto.dart';
import '/models/igreja.dart';
import '/models/instrumento.dart';
import '/models/integrante.dart';
import '/utils/mensagens.dart';

class MeuFirebase {
  /* STREAMS  */

  static Stream<DocumentSnapshot<Integrante>?> escutarIntegranteLogado() {
    var userId = FirebaseAuth.instance.currentUser?.uid;
    //
    return FirebaseFirestore.instance
        .collection(Integrante.collection)
        .doc(userId)
        .withConverter<Integrante>(
            fromFirestore: (snapshot, _) =>
                Integrante.fromJson(snapshot.data()!),
            toFirestore: (pacote, _) => pacote.toJson())
        .snapshots();
  }

  /* static void escutarIntegranteLogado(String? id) {
    if (id == null) {
      Global.integranteLogado.value = null;
    }
    FirebaseFirestore.instance
        .collection(Integrante.collection)
        .doc(id)
        .withConverter<Integrante>(
            fromFirestore: (snapshot, _) =>
                Integrante.fromJson(snapshot.data()!),
            toFirestore: (pacote, _) => pacote.toJson())
        .snapshots()
        .listen((event) async {
      dev.log('Integrante logado alterado: ${event.id}');
      /* if (Global.integranteLogado.value?.data()?.funcoes !=
          event.data()?.funcoes) {
        dev.log('Funções alteradas');
        Global.integranteLogado.value = event;
        Global.integranteLogado.notifyListeners();
      } else {
        Global.integranteLogado.value = event;
      } */
      Global.integranteLogado.value = event;
      // Se não houver mais igrejas vinculadas, então redefinir igreja selecionada.
      var igrejas = event.data()?.igrejas;
      if (igrejas == null || igrejas.isEmpty) {
        Global.igrejaSelecionada.value = null;
      } else {
        // Se nas igrejas inscritas não houver a igreja selecionada, então redefinir a igreja selecionada.
        if (!(igrejas
            .map((e) => e.toString())
            .contains(Global.igrejaSelecionada.value?.reference.toString()))) {
          if (Global.igrejaSelecionada.value == null) {
            Global.igrejaSelecionada.value = await igrejas[0].get();
          } else {
            Global.igrejaSelecionada.value = null;
          }
        } else {}
      }
    });
  } */

  /// Stream para escutar base de dados das Igrejas
  static Stream<QuerySnapshot<Igreja>> escutarIgrejas({bool? ativas}) {
    return FirebaseFirestore.instance
        .collection(Igreja.collection)
        .where('ativo', isEqualTo: ativas)
        .orderBy('sigla')
        .withConverter<Igreja>(
          fromFirestore: (snapshot, _) => Igreja.fromJson(snapshot.data()!),
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

  /// Lista de Igrejas
  static Future<QuerySnapshot<Culto>> obterListaCultos({
    DocumentReference? igreja,
    Timestamp? dataMinima,
    Timestamp? dataMaxima,
  }) async {
    return FirebaseFirestore.instance
        .collection(Culto.collection)
        .where('igreja', isEqualTo: igreja)
        .where('dataCulto', isGreaterThanOrEqualTo: dataMinima)
        .where('dataCulto', isLessThanOrEqualTo: dataMaxima)
        .orderBy('dataCulto')
        .withConverter<Culto>(
          fromFirestore: (snapshot, _) => Culto.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .get();
  }

  /// Stream para escutar base de dados das Igrejas
  static Stream<QuerySnapshot<Culto>> escutarCultos({
    DocumentReference? igreja,
    Timestamp? dataMinima,
    Timestamp? dataMaxima,
  }) {
    return FirebaseFirestore.instance
        .collection(Culto.collection)
        .where('igreja', isEqualTo: igreja)
        .where('dataCulto', isGreaterThanOrEqualTo: dataMinima)
        .where('dataCulto', isLessThanOrEqualTo: dataMaxima)
        .orderBy('dataCulto')
        .withConverter<Culto>(
          fromFirestore: (snapshot, _) => Culto.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .snapshots();
  }

  /// Stream para escutar base de dados das Igrejas
  static Stream<QuerySnapshot<Cantico>> escutarCanticos(bool? somenteHinos) {
    return FirebaseFirestore.instance
        .collection(Cantico.collection)
        .where('isHino', isEqualTo: somenteHinos)
        .orderBy('nome')
        .withConverter<Cantico>(
          fromFirestore: (snapshot, _) => Cantico.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .snapshots();
  }

  /* SNAPSHOTS */

  /// Lista de Igrejas
  static Future<QuerySnapshot<Igreja>> obterListaIgrejas(
      {required bool ativo}) async {
    return FirebaseFirestore.instance
        .collection(Igreja.collection)
        .where('ativo', isEqualTo: ativo)
        .orderBy('sigla')
        .withConverter<Igreja>(
          fromFirestore: (snapshot, _) => Igreja.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .get();
  }

  /// Igreja específica
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

  /// Lista de Instrumento
  static Future<QuerySnapshot<Instrumento>> obterListaInstrumentos(
      {required bool ativo}) async {
    return FirebaseFirestore.instance
        .collection(Instrumento.collection)
        .where('ativo', isEqualTo: ativo)
        .orderBy('ordem')
        .withConverter<Instrumento>(
          fromFirestore: (snapshot, _) =>
              Instrumento.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .get();
  }

  /// Lista de Integrantes
  static Future<QuerySnapshot<Integrante>> obterListaIntegrantes(
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

  /// Integrante específico
  static Future<DocumentSnapshot<Integrante>?> obterSnapshotIntegrante(
      String? id) async {
    if (id == null) {
      return null;
    }
    return FirebaseFirestore.instance
        .collection(Integrante.collection)
        .doc(id)
        .withConverter<Integrante>(
            fromFirestore: (snapshot, _) =>
                Integrante.fromJson(snapshot.data()!),
            toFirestore: (pacote, _) => pacote.toJson())
        .get();
  }

  /// Culto especifico
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

  /* CÁLCULOS */

  /// Identifica o total de cadastros de determinada coleção, conforme filtro de cadastros ativo ou não
  static Future<int> totalCadastros(String colecao, {bool? ativo}) async {
    var snap = await FirebaseFirestore.instance
        .collection(colecao)
        .where('ativo', isEqualTo: ativo)
        .get();
    return snap.docs.length;
  }

  /* SETS E UPDATES */

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

  /// Criar Culto
  static Future criarCulto(Culto culto) async {
    FirebaseFirestore.instance
        .collection(Culto.collection)
        .withConverter<Culto>(
          fromFirestore: (snapshot, _) => Culto.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .doc()
        .set(culto);
  }

  /// Atualizar Culto
  static Future atualizarCulto(
      Culto culto, DocumentReference<Culto> reference) async {
    reference.update({
      'dataCulto': culto.dataCulto,
      'ocasiao': culto.ocasiao,
      'obs': culto.obs
    });
  }

  /// Atualizar ou Criar Culto
  static Future apagarCulto(Culto culto, {String? id}) async {
    FirebaseFirestore.instance
        .collection(Culto.collection)
        .withConverter<Culto>(
          fromFirestore: (snapshot, _) => Culto.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .doc(id)
        .delete();
  }

  /// Criar Culto
  static Future criarCantico(Cantico cantico) async {
    FirebaseFirestore.instance
        .collection(Cantico.collection)
        .withConverter<Cantico>(
          fromFirestore: (snapshot, _) => Cantico.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .doc()
        .set(cantico);
  }

  /// Atualizar Culto
  static Future atualizarCantico(
      Cantico cantico, DocumentReference<Cantico> reference) async {
    reference.update({
      'nome': cantico.nome,
      'autor': cantico.autor,
      'cifraUrl': cantico.cifraUrl,
      'youTubeUrl': cantico.youTubeUrl,
      'letra': cantico.letra,
      'isHino': cantico.isHino,
    });
  }

  /// Atualizar ou Criar Culto
  static Future apagarCantico(Cantico culto, {String? id}) async {
    FirebaseFirestore.instance
        .collection(Cantico.collection)
        .withConverter<Cantico>(
          fromFirestore: (snapshot, _) => Cantico.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .doc(id)
        .delete();
  }

  /// Criar novo usuário
  static Future<UserCredential?> criarUsuario(
      {required String email, required String senha}) async {
    FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'AppTemp', options: Firebase.app().options);
    UserCredential? userCredential;
    try {
      userCredential = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(email: email, password: senha);
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      dev.log(e.toString());
    }
    await tempApp.delete();
    return Future.sync(() => userCredential);
  }

  /* UPDATES ESPECÍFICOS */

  static Future<bool> definirDisponibilidadeParaOCulto(
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

  static Future<bool> definirRestricaoParaOCulto(
      DocumentReference<Culto> reference) async {
    if (Global.integranteLogado == null) {
      dev.log('Valores nulos');
      return false;
    }
    var culto = await obterSnapshotCulto(reference.id);
    if (culto == null) return false;
    bool exist = culto
            .data()!
            .restritos
            ?.map((e) => e.toString())
            .contains(Global.integranteLogado!.reference.toString()) ??
        false;
    if (exist) {
      try {
        await culto.reference.update({
          'restritos':
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
          'restritos':
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

  /* static Future<bool> atualizarCampo({
    required DocumentReference reference,
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
  } */

  /* CLOUD FIRESTORE */

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
    } on FirebaseException catch (e) {
      dev.log('FirebaseException code: ' + e.code, name: 'CarregarFoto');
    } catch (e) {
      dev.log('Catch Exception: ' + e.toString(), name: 'CarregarFoto');
    }
    // Retorno
    return fotoUrl;
  }

  /// Carregar arquivo PDF
  static Future<String?> carregarArquivoPdf({required String pasta}) async {
    String url = '';
    // Abrir seleção
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
        var ref = FirebaseStorage.instance.ref('$pasta/$fileName');
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
    } on FirebaseException catch (e) {
      dev.log('FirebaseException code: ' + e.code, name: 'CarregarFoto');
    } catch (e) {
      dev.log('Catch Exception: ' + e.toString(), name: 'CarregarFoto');
    }
    // Retorno
    return url;
  }

  /// Abrir arquivo PDF
  static void abrirArquivoPdf(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) return;
    dev.log('TODO: abrir PDF');
    try {
      var data = await http.get(Uri.parse(url));
      Mensagem.showPdf(
        context: context,
        titulo: 'Arquivo',
        conteudo: PdfPreview(
          build: (format) {
            return data.bodyBytes;
          },
          canDebug: false,
          canChangeOrientation: false,
          canChangePageFormat: false,
        ),
      );
    } catch (e) {
      throw Exception("Error opening url file");
    }
  }
}
