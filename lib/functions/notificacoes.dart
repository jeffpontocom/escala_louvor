import 'dart:convert';
import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/preferencias.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:http/http.dart' as http;

import '/firebase_options.dart';
import '/utils/mensagens.dart';

class Notificacoes {
  // Construtor (somente interno)
  Notificacoes._();
  static late Notificacoes instancia;

  /// Create a [AndroidNotificationChannel] for heads up notifications
  late AndroidNotificationChannel channel;

  /// Initialize the [FlutterLocalNotificationsPlugin] package.
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  //String? _token;
  late Stream<String> _tokenStream;

  void setToken(String? token) async {
    dev.log('FCM Token: $token');
    //instancia._token = token;
    FirebaseFirestore.instance
        .collection('tokens')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .set({'token': token}).then(
            (value) => dev.log('Token salvo no firebase'));
  }

  static Future carregarInstancia() async {
    instancia = Notificacoes._();

    // Set the background messaging handler early on, as a named top-level function
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    if (!kIsWeb) {
      // Definições do Canal de Notificações para Android
      instancia.channel = const AndroidNotificationChannel(
        'canal_escala_louvor', // id
        'Notificações do App Escala do Louvor', // title
        description:
            'Esse canal é utilizado para notificações referentes ao App Escala do Louvor.', // description
        importance: Importance.high,
      );

      instancia.flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      /// Create an Android Notification Channel.
      ///
      /// We use this channel in the `AndroidManifest.xml` file to override the
      /// default FCM channel to enable heads up notifications.
      await instancia.flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(instancia.channel);

      /// Update the iOS foreground notification presentation options to allow
      /// heads up notifications.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Get APNs token (apenas IOS)
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        dev.log('FlutterFire Messaging Example: Getting APNs token...');
        String? token = await FirebaseMessaging.instance.getAPNSToken();
        dev.log('FlutterFire Messaging Example: Got APNs token: $token');
      } else {
        dev.log(
            'FlutterFire Messaging Example: Getting an APNs token is only supported on iOS and macOS platforms.');
      }

      // Inscrever usuário no tópico
      FirebaseMessaging.instance
          .subscribeToTopic('escala_louvor')
          .then((_) => dev.log('Usuário inscrito no tópico: escala_louvor'));
    }

    // Obter token
    var vapidKey = await FirebaseMessaging.instance.getToken();
    instancia.setToken(vapidKey);
    instancia._tokenStream = FirebaseMessaging.instance.onTokenRefresh;
    instancia._tokenStream.listen(instancia.setToken);

    // Ouvir mensagens
    instancia._ouvirMensagens();
  }

  /// Tratamento para segundo plano
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    } catch (e) {
      dev.log('Notificações: A Firebase App named "[DEFAULT]" already exists');
    }
    dev.log('Tratando notificação em segundo plano: ${message.messageId}');
  }

  /// Ouvir
  void _ouvirMensagens() {
    dev.log('Ouvindo mensagens');

    // Recebimentos em primeiro plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      dev.log('Recebeu uma mensagem enquanto estava em primeiro plano!');
      dev.log('Dados da mensagem: ${message.data}');

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null && !kIsWeb) {
        dev.log(
            'A mensagem também contém uma notificação: ${message.notification?.body}');
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          payload: notification.android?.clickAction,
        );
      }
      //if (kIsWeb) {
      DialogoMensagem(
          titulo: notification?.title ?? 'Mensagem',
          corpo: notification?.body ?? 'Sem conteúdo');
      //}
    });

    // Verifica se há alguma mensagem ao abrir o app
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) async {
      dev.log('Mensagem inicial: ${message?.messageId}');
      if (message != null) {
        String contexto = message.data['contexto'];
        String pagina = message.data['pagina'];
        String conteudo = message.data['conteudo'];
        dev.log('Abrindo app pela mensagem: /$pagina?id=$conteudo');
        Preferencias.igreja = contexto;
        //Global.igrejaSelecionada.value =
        //    await MeuFirebase.obterSnapshotIgreja(contexto);
        Modular.to.navigate('/$pagina?id=$conteudo');
      }
    });

    /// Recebimento em segundo plano
    /// Tratamento para ao clicar na notificação e abrir o app.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      String contexto = message.data['contexto'];
      String pagina = message.data['pagina'];
      String conteudo = message.data['conteudo'];
      dev.log('Abrindo app pela mensagem: /$pagina?id=$conteudo');
      Preferencias.igreja = contexto;
      //Global.igrejaSelecionada.value =
      //    await MeuFirebase.obterSnapshotIgreja(contexto);
      Modular.to.navigate('/$pagina?id=$conteudo');
      /* Modular.to.pushNamed('/notificacoes',
          arguments: MessageArguments(message, true)); */
    });
  }

  // Notificar
  // [para] pode ser um token de usuário, se nulo envia para todos
  Future<bool> enviarMensagemPush({
    String? para,
    required String titulo,
    required String corpo,
    String? contexto,
    String? pagina,
    String? conteudo,
  }) async {
    const postUrl = 'https://fcm.googleapis.com/fcm/send';

    final headers = {
      "content-type": "application/json",
      "Authorization": "key=${dotenv.env['FCM_ServerKey'] ?? ''}"
    };

    final data = {
      "to": para,
      "notification": {
        "title": titulo,
        "body": corpo,
      },
      "data": {
        "contexto": contexto ?? '',
        "pagina": pagina ?? '',
        "conteudo": conteudo ?? '',
        "click_action": "ABRIR_APP_LOUVOR",
      }
    };

    final response = await http.post(
      Uri.parse(postUrl),
      headers: headers,
      body: json.encode(data),
      encoding: Encoding.getByName('utf-8'),
    );

    if (response.statusCode == 200) {
      dev.log('Solicitação de FCM enviada com sucesso!');
      return true;
    } else {
      dev.log('Erro ao enviar solicitação de FCM');
      return false;
    }
  }
}

  /// Permitir
  /* Future<void> _obterPermissao() async {
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    dev.log('Usuário cedeu permissão: ${settings.authorizationStatus}');
  } */