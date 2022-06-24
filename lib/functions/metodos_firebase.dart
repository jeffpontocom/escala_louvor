import 'dart:async';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
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
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'notificacoes.dart';
import '/models/cantico.dart';
import '/models/culto.dart';
import '/models/igreja.dart';
import '/models/instrumento.dart';
import '/models/integrante.dart';
import '/modulos.dart';
import '/utils/global.dart';
import '/utils/mensagens.dart';
import '/utils/utils.dart';

import 'cropper/ui_helper.dart'
    if (dart.library.io) 'cropper/mobile_ui_helper.dart'
    if (dart.library.html) 'cropper/web_ui_helper.dart';

class MeuFirebase {
  /*
  *** STREAMS ***
  */

  /// Stream para obter dados do integrante e ouvir alterações
  /// Utilizado nas classes [AuthGuardView] e [TelaPerfil]
  static Stream<DocumentSnapshot<Integrante>> ouvinteIntegrante({
    required String id,
  }) {
    return FirebaseFirestore.instance
        .collection(Integrante.collection)
        .doc(id)
        .withConverter<Integrante>(
            fromFirestore: (snapshot, _) =>
                Integrante.fromJson(snapshot.data()),
            toFirestore: (pacote, _) => pacote.toJson())
        .snapshots();
  }

  /// Stream para obter dados da igreja e ouvir alterações
  /// Utilizado nas classes [PaginaIgreja]
  static Stream<DocumentSnapshot<Igreja>> ouvinteIgreja({
    required String id,
  }) {
    return FirebaseFirestore.instance
        .collection(Igreja.collection)
        .doc(id)
        .withConverter<Igreja>(
            fromFirestore: (snapshot, _) => Igreja.fromJson(snapshot.data()!),
            toFirestore: (pacote, _) => pacote.toJson())
        .snapshots();
  }

  /// Stream para obter dados dos cultos e ouvir alterações
  /// Utilizado nas classes [PaginaAgenda]
  static Stream<QuerySnapshot<Culto>> ouvinteCultos({
    List<DocumentReference?>? igrejas,
    Timestamp? dataMinima,
    Timestamp? dataMaxima,
  }) {
    return FirebaseFirestore.instance
        .collection(Culto.collection)
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

  /// Stream para obter dados de um culto específico e ouvir alterações
  /// Utilizado nas classes [TelaCulto]
  static Stream<DocumentSnapshot<Culto>> ouvinteCulto({
    required String id,
  }) {
    return FirebaseFirestore.instance
        .collection(Culto.collection)
        .doc(id)
        .withConverter<Culto>(
            fromFirestore: (snapshot, _) => Culto.fromJson(snapshot.data()!),
            toFirestore: (pacote, _) => pacote.toJson())
        .snapshots();
  }

  /// Stream para obter dados dos cânticos e ouvir alterações
  /// Utilizado nas classes [PaginaCanticos]
  static Stream<QuerySnapshot<Cantico>> ouvinteCanticos({
    bool? somenteHinos,
    String ordenarPor = 'nome',
  }) {
    return FirebaseFirestore.instance
        .collection(Cantico.collection)
        .where('isHino', isEqualTo: somenteHinos)
        .orderBy(ordenarPor)
        .withConverter<Cantico>(
          fromFirestore: (snapshot, _) => Cantico.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .snapshots();
  }

  /// Stream para obter dados de um cântico específico e ouvir alterações
  /// Utilizado nas classes [TelaCantico]
  static Stream<DocumentSnapshot<Cantico>> ouvinteCantico({
    required String id,
  }) {
    return FirebaseFirestore.instance
        .collection(Cantico.collection)
        .doc(id)
        .withConverter<Cantico>(
            fromFirestore: (snapshot, _) => Cantico.fromJson(snapshot.data()!),
            toFirestore: (pacote, _) => pacote.toJson())
        .snapshots();
  }

  /* 
  *** SNAPSHOTS (Listas) *** 
  */

  /// Lista de Igrejas
  static Future<QuerySnapshot<Igreja>> obterListaIgrejas({
    required bool ativo,
  }) async {
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
  static Future<QuerySnapshot<Instrumento>> obterListaInstrumentos({
    required bool ativo,
  }) async {
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
  /// TODO: Definir assert para ou função ou igreja
  static Future<QuerySnapshot<Integrante>> obterListaIntegrantes({
    bool ativo = true,
    int? funcao,
    DocumentReference<Igreja>? igreja,
  }) async {
    return FirebaseFirestore.instance
        .collection(Integrante.collection)
        .where('ativo', isEqualTo: ativo)
        .where('funcoes', arrayContains: funcao)
        .where('igrejas', arrayContains: igreja)
        .orderBy('nome')
        .withConverter<Integrante>(
          fromFirestore: (snapshot, _) => Integrante.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .get();
  }

  /// Lista de Administradores do sistema
  static Future<QuerySnapshot<Integrante>> obterListaDeAdministradores() async {
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

  /* 
  *** SNAPSHOT (Individual) *** 
  */

  /// Dados de um Integrante específico
  static Future<DocumentSnapshot<Integrante>> obterIntegrante({
    required String id,
  }) async {
    return FirebaseFirestore.instance
        .collection(Integrante.collection)
        .doc(id)
        .withConverter<Integrante>(
            fromFirestore: (snapshot, _) =>
                Integrante.fromJson(snapshot.data()!),
            toFirestore: (pacote, _) => pacote.toJson())
        .get();
  }

  /// Dados de uma Igreja específica
  static Future<DocumentSnapshot<Igreja>> obterIgreja({
    required String id,
  }) async {
    return await FirebaseFirestore.instance
        .collection(Igreja.collection)
        .doc(id)
        .withConverter<Igreja>(
          fromFirestore: (snapshot, _) => Igreja.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .get();
  }

  /// Dados de um Instrumento específico
  static Future<DocumentSnapshot<Instrumento>> obterInstrumento({
    required String id,
  }) async {
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

  /// Dados de um Cântico específico
  static Future<DocumentSnapshot<Cantico>> obterCantico({
    required String id,
  }) async {
    return await FirebaseFirestore.instance
        .collection(Cantico.collection)
        .doc(id)
        .withConverter<Cantico>(
          fromFirestore: (snapshot, _) => Cantico.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .get();
  }

  /* 
  *** NOTIFICAÇÕES *** 
  */

  /// Token do integrante
  static Future<String?> obterTokenDoIntegrante(String id) async {
    var snap =
        await FirebaseFirestore.instance.collection('tokens').doc(id).get();
    return snap.data()?['token'] as String?;
  }

  /// Notificar integrante escalado
  static Future<void> notificarEscalado({
    required String token,
    required String igreja,
    required Culto culto,
    required String cultoId,
  }) async {
    await Notificacoes.enviarMensagemPush(
      para: token,
      titulo: 'Você está escalado!',
      corpo:
          '${culto.ocasiao}: ${DateFormat("EEE, d/MMM 'às' HH:mm", "pt_BR").format(culto.dataCulto.toDate())}\nVerifique a data de ensaio e estude os cânticos selecionados 😉',
      conteudo: cultoId,
      pagina: AppModule.CULTO,
    );
  }

  /// Notificar integrante indeciso
  static Future<void> notificarIndeciso({
    required String token,
    required String igreja,
    required Culto culto,
    required String cultoId,
  }) async {
    await Notificacoes.enviarMensagemPush(
      para: token,
      titulo: 'Marque a sua disponibilidade!',
      corpo:
          '${culto.ocasiao}: ${DateFormat("EEE, d/MMM 'às' HH:mm", "pt_BR").format(culto.dataCulto.toDate())}\nClique aqui para abrir o app do Louvor 😉',
      conteudo: cultoId,
      pagina: AppModule.CULTO,
    );
  }

  /* 
  *** SETS E UPDATES *** 
  */

  /// Atualizar ou Criar Integrante
  static Future salvarIntegrante(Integrante integrante, {String? id}) async {
    FirebaseFirestore.instance
        .collection(Integrante.collection)
        .withConverter<Integrante>(
          fromFirestore: (snapshot, _) => Integrante.fromJson(snapshot.data()),
          toFirestore: (model, _) => model.toJson(),
        )
        .doc(id)
        .set(integrante);
  }

  /// Atualizar ou Criar Igreja
  static Future salvarIgreja(Igreja igreja, {String? id}) async {
    FirebaseFirestore.instance
        .collection(Igreja.collection)
        .withConverter<Igreja>(
          fromFirestore: (snapshot, _) => Igreja.fromJson(snapshot.data()),
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
          fromFirestore: (snapshot, _) => Instrumento.fromJson(snapshot.data()),
          toFirestore: (model, _) => model.toJson(),
        )
        .doc(id)
        .set(instrumento);
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

  /// Criar Cântico
  static Future criarCantico(Cantico cantico) async {
    FirebaseFirestore.instance
        .collection(Cantico.collection)
        .withConverter<Cantico>(
          fromFirestore: (snapshot, _) => Cantico.fromJson(snapshot.data()),
          toFirestore: (model, _) => model.toJson(),
        )
        .doc()
        .set(cantico);
  }

  /// Atualizar Cântico
  static Future atualizarCantico(
      Cantico cantico, DocumentReference<Cantico> reference) async {
    reference.set(cantico);
  }

  /// Criar novo usuário do sistema
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

  /* 
  *** UPDATES ESPECÍFICOS *** 
  */

  /// Culto especifico
  /// TODO: Tentar remover a necessidade dessa função
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

  static Future<bool> definirDisponibilidadeParaOCulto(
      DocumentReference<Culto> reference) async {
    if (Global.logadoSnapshot == null) {
      dev.log('Erro: Usuário não está logado');
      return false;
    }
    var culto = await obterSnapshotCulto(reference.id);
    if (culto == null) return false;
    bool exist = culto
            .data()!
            .disponiveis
            ?.map((e) => e.toString())
            .contains(Global.logadoReference.toString()) ??
        false;
    if (exist) {
      try {
        await culto.reference.update({
          'disponiveis': FieldValue.arrayRemove([Global.logadoReference])
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
          'disponiveis': FieldValue.arrayUnion([Global.logadoReference])
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
    if (Global.logadoSnapshot == null) {
      dev.log('Erro: Usuário não está logado');
      return false;
    }
    var culto = await obterSnapshotCulto(reference.id);
    if (culto == null) return false;
    bool exist = culto
            .data()!
            .restritos
            ?.map((e) => e.toString())
            .contains(Global.logadoReference.toString()) ??
        false;
    if (exist) {
      try {
        await culto.reference.update({
          'restritos': FieldValue.arrayRemove([Global.logadoReference])
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
          'restritos': FieldValue.arrayUnion([Global.logadoReference])
        });
        dev.log('Adicionado com Sucesso');
        return true;
      } catch (e) {
        dev.log('Erro: ${e.toString()}');
        return false;
      }
    }
  }

  /* 
  *** CLOUD FIRESTORE ***
  */

  /// Carregar foto do integrante
  static Future<String?> carregarFoto(BuildContext context) async {
    try {
      // Abrir a galeria para seleção
      final pickedImage =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        // Abrir imagem para edição
        final croppedImage = await ImageCropper().cropImage(
          sourcePath: pickedImage.path,
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 100,
          // ignore: use_build_context_synchronously
          uiSettings: buildUiSettings(
            context,
          ),
        );
        if (croppedImage != null) {
          // Salvar na Cloud Firestore
          Mensagem.aguardar(context: context, mensagem: 'Carregando foto...');
          var ref = FirebaseStorage.instance
              .ref('fotos/${MyInputs.randomString(6)}_${pickedImage.name}');
          if (kIsWeb) {
            var bytes = await croppedImage.readAsBytes();
            await ref.putData(
                bytes, SettableMetadata(contentType: pickedImage.mimeType));
          } else {
            var file = File(croppedImage.path);
            await ref.putFile(file);
          }
          final fotoUrl = await ref.getDownloadURL();
          Modular.to.pop(); // fecha progresso
          return fotoUrl;
        } else {
          dev.log('Ação cancelada pelo usuário', name: 'CarregarFoto');
          return null;
        }
      } else {
        dev.log('Ação cancelada pelo usuário', name: 'CarregarFoto');
        return null;
      }
    } on PlatformException catch (e) {
      dev.log('Operação não suportada: ${e.toString()}', name: 'CarregarFoto');
    } on FirebaseException catch (e) {
      dev.log('FirebaseException code: ${e.code}', name: 'CarregarFoto');
    } catch (e) {
      dev.log('Falha: ${e.toString()}', name: 'CarregarFoto');
    }
    // Retorno após falhas
    Mensagem.simples(
      context: context,
      titulo: 'Falha!',
      mensagem: 'Não foi possível carregar a imagem.',
    );
    return null;
  }

  /// Carregar arquivo PDF
  static Future<String?> carregarArquivoPdf(BuildContext context,
      {required String pasta}) async {
    // Abrir seleção
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        onFileLoading: (FilePickerStatus status) => dev.log('$status'),
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.single;
        dev.log(pickedFile.name);
        // Salvar na Cloud Firestore
        Mensagem.aguardar(context: context, mensagem: 'Carregando arquivo...');
        var ref = FirebaseStorage.instance
            .ref('$pasta/${MyInputs.randomString(6)}_${pickedFile.name}');
        if (kIsWeb) {
          await ref.putData(
              pickedFile.bytes!,
              SettableMetadata(
                  contentType: 'application/${pickedFile.extension}'));
        } else {
          var file = File(pickedFile.path!);
          await ref.putFile(file);
        }
        final url = await ref.getDownloadURL();
        Modular.to.pop(); // fecha progresso
        return url;
      } else {
        dev.log('Ação cancelada pelo usuário', name: 'CarregarPDF');
        return null;
      }
    } on PlatformException catch (e) {
      dev.log('Operação não suportada: ${e.toString()}', name: 'CarregarPDF');
    } on FirebaseException catch (e) {
      dev.log('FirebaseException code: ${e.code}', name: 'CarregarPDF');
    } catch (e) {
      dev.log('Falha: ${e.toString()}', name: 'CarregarPDF');
    }
    // Retorno após falhas
    Mensagem.simples(
      context: context,
      titulo: 'Falha!',
      mensagem: 'Não foi possível carregar o arquivo.',
    );
    return null;
  }

  /* DEPRECAR
  TODO: Remover essa funções quando puder */

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

  /// Identifica o total de cadastros de determinada coleção, conforme filtro de cadastros ativo ou não
  static Future<int> totalCadastros(String colecao, {bool? ativo}) async {
    var snap = await FirebaseFirestore.instance
        .collection(colecao)
        .where('ativo', isEqualTo: ativo)
        .get();
    return snap.docs.length;
  }
}
