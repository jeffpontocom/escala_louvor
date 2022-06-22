import 'dart:convert';
import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:rxdart/rxdart.dart';

import '/firebase_options.dart';
import '/utils/global.dart';
import '/utils/mensagens.dart';

class Notificacoes {
  // Construtor (somente interno)
  Notificacoes._();
  static late Notificacoes instancia;

  /// Contexto para abrir dialogos em primeiro plano
  late BuildContext context;

  /// Create a [AndroidNotificationChannel] for heads up notifications
  late AndroidNotificationChannel channel;

  /// Initialize the [FlutterLocalNotificationsPlugin] package.
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  // Streams
  late Stream<String> _tokenStream;
  late BehaviorSubject<RemoteMessage> _messageStreamController;

  void saveToken(String? token) async {
    if (FirebaseAuth.instance.currentUser == null) {
      dev.log('Token não foi salvo - Usuário não logado', name: 'FCM');
      return;
    }
    await FirebaseFirestore.instance
        .collection('tokens')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .set({'token': token});
    dev.log('Token salvo no Firebase', name: 'FCM');
  }

  static Future carregarInstancia(BuildContext context) async {
    instancia = Notificacoes._();
    instancia.context = context;

    // NOVAS INSTRUÇÕES
    final messaging = FirebaseMessaging.instance;

    // Request permission
    final settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    dev.log('Permissão aceita: ${settings.authorizationStatus}', name: 'FCM');

    // Register with FCM
    String? vapidKey = dotenv.env['FCM_VapidKey'];
    String? token = await messaging.getToken(vapidKey: vapidKey);
    if (kDebugMode) {
      print('Registration Token=$token');
    }
    instancia.saveToken(token);
    instancia._tokenStream = messaging.onTokenRefresh;
    instancia._tokenStream.listen(instancia.saveToken);

    // Ouvir mensagens em primeiro plano
    // Set up foreground message handler
    // used to pass messages from event handler to the UI
    instancia._messageStreamController = BehaviorSubject<RemoteMessage>();
    instancia._ouvirMensagens();

    // Set up background message handler

    // FIM DAS NOVAS INSTRUÇÕES

    // Obter token
    /* var fcmToken = await FirebaseMessaging.instance
        .getToken(vapidKey: dotenv.env['FCM_VapidKey'] ?? '');
    instancia.saveToken(fcmToken);
    instancia._tokenStream = FirebaseMessaging.instance.onTokenRefresh;
    instancia._tokenStream.listen(instancia.saveToken); */

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
    dev.log('Ouvindo mensagens', name: 'FCM');

    // Recebimentos em primeiro plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      dev.log('Mensagem em primeiro plano recebida!', name: 'FCM');

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      dev.log('Título da mensagem: ${notification?.title}', name: 'FCM');
      instancia._messageStreamController.sink.add(message);

      if (notification != null && android != null && !kIsWeb) {
        instancia.flutterLocalNotificationsPlugin.show(
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

      // Apresentar mensagem na tela
      Mensagem.bottomDialog(
        context: context,
        titulo: notification?.title ?? 'Mensagem',
        conteudo: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(notification?.body ?? 'Sem conteúdo'),
        ),
      );
    });

    // Verifica se há alguma mensagem ao abrir o app
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) async {
      dev.log('Mensagem inicial: ${message?.messageId}', name: 'FCM');
      if (message != null) {
        String contexto = message.data['contexto'];
        String pagina = message.data['pagina'];
        String conteudo = message.data['conteudo'];
        dev.log('Abrindo app pela mensagem: /$pagina?id=$conteudo',
            name: 'FCM');
        Global.prefIgrejaId = contexto;
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
      dev.log('Abrindo app pela mensagem: /$pagina?id=$conteudo', name: 'FCM');
      Global.prefIgrejaId = contexto;
      //Global.igrejaSelecionada.value =
      //    await MeuFirebase.obterSnapshotIgreja(contexto);
      Modular.to.navigate('/$pagina?id=$conteudo');
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
      dev.log('Solicitação de FCM enviada com sucesso!', name: 'FCM');
      return true;
    } else {
      dev.log('Erro ao enviar solicitação de FCM', name: 'FCM');
      return false;
    }
  }
}
