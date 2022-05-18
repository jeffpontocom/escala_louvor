import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:intl/intl.dart';

import '../utils/utils.dart';
import 'notificacoes.dart';
import '/global.dart';
import '/models/cantico.dart';
import '/models/culto.dart';
import '/models/igreja.dart';
import '/models/instrumento.dart';
import '/models/integrante.dart';
import '/utils/mensagens.dart';
import '/rotas.dart';
import '/screens/home.dart';

class MeuFirebase {
  /* STREAMS  */

  /// Stream para escutar dados do integrante logado
  static Stream<DocumentSnapshot<Integrante>?> escutarIntegranteLogado() {
    var userId = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection(Integrante.collection)
        .doc(userId)
        .withConverter<Integrante>(
            fromFirestore: (snapshot, _) =>
                Integrante.fromJson(snapshot.data()),
            toFirestore: (pacote, _) => pacote.toJson())
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
    List<DocumentReference?>? igrejas,
    Timestamp? dataMinima,
    Timestamp? dataMaxima,
  }) {
    return FirebaseFirestore.instance
        .collection(Culto.collection)
        //.where('igreja', isEqualTo: igrejas)
        .where('igreja', whereIn: igrejas)
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

  /// Lista de Culto
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

  /// Lista de administradores
  static Future<QuerySnapshot<Integrante>>
      obterListaIntegrantesAdministradores() async {
    return FirebaseFirestore.instance
        .collection(Integrante.collection)
        .where('adm', isEqualTo: true)
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

  /// Integrante específico
  static Stream<DocumentSnapshot<Integrante>>? obterStreamIntegrante(
      String id) {
    return FirebaseFirestore.instance
        .collection(Integrante.collection)
        .doc(id)
        .withConverter<Integrante>(
            fromFirestore: (snapshot, _) =>
                Integrante.fromJson(snapshot.data()),
            toFirestore: (pacote, _) => pacote.toJson())
        .snapshots();
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

  /// Instrumento específico
  static Future<DocumentSnapshot<Instrumento>?> obterSnapshotInstrumento(
      String? id) async {
    if (id == null) {
      return null;
    }
    return await FirebaseFirestore.instance
        .collection(Instrumento.collection)
        .doc(id)
        .withConverter<Instrumento>(
          fromFirestore: (snapshot, _) =>
              Instrumento.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
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

  /// Cantico especifico
  static Future<DocumentSnapshot<Cantico>?> obterSnapshotCantico(
      String? id) async {
    if (id == null) {
      return null;
    }
    return await FirebaseFirestore.instance
        .collection(Cantico.collection)
        .doc(id)
        .withConverter<Cantico>(
          fromFirestore: (snapshot, _) => Cantico.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .get();
  }

  /* NOTIFICAÇÕES */

  /// Token do integrante
  static Future<String?> obterTokenDoIntegrante(String id) async {
    var snap =
        await FirebaseFirestore.instance.collection('tokens').doc(id).get();
    return snap.data()?['token'] as String?;
  }

  /// Notificar integrante escalado
  static Future<void> notificarEscalado(
      {required String token,
      required String igreja,
      required Culto culto,
      required String cultoId}) async {
    await Notificacoes.instancia.enviarMensagemPush(
      para: token,
      titulo: 'Você está escalado!',
      corpo:
          '${culto.ocasiao}: ${DateFormat("EEE, d/MMM 'às' HH:mm", "pt_BR").format(culto.dataCulto.toDate())}\nVerifique a data de ensaio e estude os cânticos selecionados 😉',
      conteudo: cultoId,
      pagina: Paginas.escalas.name,
    );
  }

  /// Notificar integrante escalado
  static Future<void> notificarIndecisos(
      {required String token,
      required String igreja,
      required Culto culto,
      required String cultoId}) async {
    await Notificacoes.instancia.enviarMensagemPush(
      para: token,
      titulo: 'Marque a sua disponibilidade!',
      corpo:
          '${culto.ocasiao}: ${DateFormat("EEE, d/MMM 'às' HH:mm", "pt_BR").format(culto.dataCulto.toDate())}\nClique aqui para abrir o app do Louvor 😉',
      conteudo: cultoId,
      pagina: Paginas.escalas.name,
    );
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
  static Future<String?> criarUsuario(
      {required String email, required String senha}) async {
    var tempName = MyInputs.randomString(6);
    FirebaseApp tempApp = await Firebase.initializeApp(
        name: tempName, options: Firebase.app().options);
    UserCredential? userCredential;
    try {
      userCredential = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(email: email, password: senha);
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      dev.log(e.code);
    }
    await tempApp.delete();
    return Future.sync(() => userCredential?.user?.uid);
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
  static Future<String?> carregarFoto(BuildContext context) async {
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
        Mensagem.aguardar(context: context, mensagem: 'Carregando foto..');
        var ref = FirebaseStorage.instance
            .ref('fotos/${MyInputs.randomString(6)}_$fileName');
        if (kIsWeb) {
          await ref.putData(fileBytes!,
              SettableMetadata(contentType: 'image/$fileExtension'));
        } else {
          var file = File(result.files.first.path!);
          await ref.putFile(file);
        }
        fotoUrl = await ref.getDownloadURL();
        Modular.to.pop(); // fecha progresso
      }
    } on PlatformException catch (e) {
      dev.log('Unsupported operation: ${e.toString()}', name: 'CarregarFoto');
    } on FirebaseException catch (e) {
      dev.log('FirebaseException code: ${e.code}', name: 'CarregarFoto');
    } catch (e) {
      dev.log('Catch Exception: ${e.toString()}', name: 'CarregarFoto');
    }
    // Retorno
    return fotoUrl;
  }

  /// Carregar arquivo PDF
  static Future<String?> carregarArquivoPdf(BuildContext context,
      {required String pasta}) async {
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
        Mensagem.aguardar(context: context, mensagem: 'Carregando arquivo...');
        var ref = FirebaseStorage.instance
            .ref('$pasta/${MyInputs.randomString(6)}_$fileName');
        if (kIsWeb) {
          await ref.putData(fileBytes!,
              SettableMetadata(contentType: 'application/$fileExtension'));
        } else {
          var file = File(result.files.first.path!);
          await ref.putFile(file);
        }
        url = await ref.getDownloadURL();
        Modular.to.pop(); // fecha progresso
      }
    } on PlatformException catch (e) {
      dev.log('Unsupported operation: ${e.toString()}', name: 'log:LoadPDF');
    } on FirebaseException catch (e) {
      dev.log('FirebaseException code: ${e.code}', name: 'log:LoadPDF');
    } catch (e) {
      dev.log('Catch Exception: ${e.toString()}', name: 'log:LoadPDF');
    }
    // Retorno
    return url;
  }

  /// Abrir arquivo PDF
  static void abrirArquivosPdf(BuildContext context, List<String>? urls) async {
    if (urls == null || urls.isEmpty) return;
    try {
      Mensagem.aguardar(context: context, mensagem: 'Abrindo arquivo...');
      List<Response> arquivos = [];
      for (var url in urls) {
        var data = await http.get(Uri.parse(url));
        arquivos.add(data);
      }
      Modular.to.pop(); // fecha progresso
      Modular.to.pushNamed(AppRotas.ARQUIVOS, arguments: arquivos);
    } catch (e) {
      Modular.to.maybePop(); // fecha progresso
      throw Exception("Error opening url file");
    }
  }
}
