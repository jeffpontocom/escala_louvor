// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:rxdart/rxdart.dart';

import '/utils/global.dart';
import '/utils/mensagens.dart';

class Notificacoes {
  BuildContext context; // Para abrir dialogos em primeiro plano

  // Construtor (somente interno)
  Notificacoes._(this.context);
  static Notificacoes? instancia;

  /// Create a [AndroidNotificationChannel] for heads up notifications
  late AndroidNotificationChannel channel;

  /// Initialize the [FlutterLocalNotificationsPlugin] package.
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  // TODO: Streams
  late Stream<String> _tokenStream;
  late BehaviorSubject<RemoteMessage> _messageStreamController;

  /// Método principal
  static Future carregarInstancia(BuildContext context) async {
    instancia = Notificacoes._(context);
    final messaging = FirebaseMessaging.instance;

    // Requisitar permissão
    final settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    print('Permissão para notificar aceita: ${settings.authorizationStatus}');

    // Registrar token no FCM (Firebase Cloud Messaging)
    String? token;
    try {
      if (kIsWeb) {
        var vapidKey = dotenv.env['FCM_VapidKey'];
        token = await messaging.getToken(vapidKey: vapidKey);
      } else {
        token = await messaging.getToken();
      }
      print('Token registrado com sucesso');
    } catch (error) {
      print('Erro ao registrar token: $error');
      return;
    }
    instancia!.saveToken(token);
    instancia!._tokenStream = messaging.onTokenRefresh;
    instancia!._tokenStream.listen(instancia!.saveToken);

    // Ouvir mensagens em primeiro plano
    // Set up foreground message handler
    // used to pass messages from event handler to the UI
    instancia!._ouvirMensagens();

    // Configurar tratamento para mensagens em segundo plano

    if (!kIsWeb) {
      // Set the background messaging handler early on, as a named top-level function
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Definições do Canal de Notificações para Android
      instancia!.channel = const AndroidNotificationChannel(
        'canal_escala_louvor', // id
        'Notificações do App Escala do Louvor', // title
        description:
            'Esse canal é utilizado para notificações referentes ao App Escala do Louvor.', // description
        importance: Importance.high,
      );

      instancia!.flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      /// Create an Android Notification Channel.
      /// We use this channel in the `AndroidManifest.xml` file to override the
      /// default FCM channel to enable heads up notifications.
      await instancia!.flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(instancia!.channel);

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

  /// Salvar o token do usuário no banco de dados
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

  /// Tratamento para escutar mensagens recebidas
  void _ouvirMensagens() {
    dev.log('O app está atento a novas mensagens', name: 'FCM');

    instancia?._messageStreamController = BehaviorSubject<RemoteMessage>();

    // Recebimentos em primeiro plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      dev.log('Mensagem em primeiro plano recebida!', name: 'FCM');

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = notification?.android;

      dev.log('Título da mensagem: ${notification?.title}', name: 'FCM');

      instancia?._messageStreamController.sink.add(message);

      // Apresentar uma notificação para sistema Android
      if (notification != null && android != null && !kIsWeb) {
        instancia?.flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              instancia!.channel.id,
              instancia!.channel.name,
              channelDescription: instancia!.channel.description,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          payload: notification.android?.clickAction,
        );
      }

      // Apresentar mensagem na tela
      Mensagem.bottomDialog(
        context: context,
        titulo: 'Mensagem recebida',
        conteudo: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(notification?.title ?? '',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Text(notification?.body ?? 'Sem conteúdo'),
              const SizedBox(height: 12),
              notification?.android?.clickAction != null
                  ? ElevatedButton(
                      onPressed: () => Modular.to
                          .pushNamed(notification!.android!.clickAction!),
                      child: const Text('Ir para'))
                  : const SizedBox(),
            ],
          ),
        ),
      );
      // FIM do recebimento em primeiro plano.
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
        dev.log('Acessando o caminho: /$pagina?id=$conteudo', name: 'FCM');
        Global.prefIgrejaId = contexto;
        Modular.to.navigate('/$pagina?id=$conteudo');
      }
    });

    /// Tratamento para ao clicar na notificação e abrir o app.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      dev.log('Mensagem ao abrir o app: ${message.messageId}', name: 'FCM');
      String contexto = message.data['contexto'];
      String pagina = message.data['pagina'];
      String conteudo = message.data['conteudo'];
      dev.log('Acessando o caminho: /$pagina?id=$conteudo', name: 'FCM');
      Global.prefIgrejaId = contexto;
      Modular.to.navigate('/$pagina?id=$conteudo');
    });
  }

  /// Tratamento para mensagens segundo plano (não funciona para web)
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    /* try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    } catch (e) {
      dev.log('Notificações: A Firebase App named "[DEFAULT]" already exists');
    }
    dev.log('Tratando notificação em segundo plano: ${message.messageId}'); */
  }

  // Notificar
  // [para] pode ser um token de usuário, se nulo envia para todos
  static Future<bool> enviarMensagemPush({
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
