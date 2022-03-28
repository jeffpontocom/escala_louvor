import 'dart:convert';
import 'dart:developer' as dev;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:http/http.dart' as http;

import '../firebase_options.dart';
import '../screens/tela_notificacoes.dart';

class Notificacoes {
  // Construtor (somente interno)
  Notificacoes._();
  static late Notificacoes instancia;

  /// Create a [AndroidNotificationChannel] for heads up notifications
  late AndroidNotificationChannel channel;

  /// Initialize the [FlutterLocalNotificationsPlugin] package.
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  String? _token;
  late Stream<String> _tokenStream;

  void setToken(String? token) async {
    dev.log('FCM TokenToken: $token');
    instancia._token = token;
  }

  static Future carregarInstancia(BuildContext context) async {
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
    //FirebaseMessaging.instance.getToken().then(instancia.setToken);
    var vapidKey = await FirebaseMessaging.instance.getToken();
    instancia.setToken(vapidKey);
    instancia._tokenStream = FirebaseMessaging.instance.onTokenRefresh;
    instancia._tokenStream.listen(instancia.setToken);

    instancia._ouvirMensagens(context);
  }

  /// Tratamento para segundo plano
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    dev.log('Tratando notificação em segundo plano: ${message.messageId}');
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

  /// Ouvir
  void _ouvirMensagens(BuildContext context) {
    dev.log('Ouvindo mensagens');

    // Verifica se há alguma mensagem ao abrir o app
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      dev.log('Mensagem inicial: ${message?.messageId}');
      if (message != null) {
        Modular.to.pushNamed('/notificacoes',
            arguments: MessageArguments(message, true));
      }
    });

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
        );
      }
      showDialog(
          context: context,
          builder: ((BuildContext context) {
            return DialogoMensagem(
                titulo: notification?.title ?? 'Mensagem',
                corpo: notification?.body ?? 'Sem conteúdo');
          }));
    });

    /// Recebimento em segundo plano
    /// Tratamento para ao clicar na notificação e abrir o app.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      dev.log('Um novo evento onMessageOpenedApp foi publicado!');
      Modular.to.pushNamed('/notificacoes',
          arguments: MessageArguments(message, true));
    });
  }

  // Notificar
  void enviarMensagemPush() async {
    if (_token == null) {
      dev.log('Não é possível enviar a mensagem FCM, não existe nenhum token.');
      return;
    }
    try {
      await http.post(
        Uri.parse('https://api.rnfirebase.io/messaging/send'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
        /* Uri.parse(
            'https://fcm.googleapis.com/v1/projects/escala-louvor-ipbfoz/messages:send'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer ' + (_token ?? ''),
        }, */
        body: _construirFCMPayload(_token),
      );
      dev.log('Solicitação de FCM enviada com sucesso!');
    } catch (e) {
      dev.log(e.toString());
    }
    /* try {
      await http
          .post(
            Uri.parse('https://fcm.googleapis.com/fcm/send'),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'key=YOUR SERVER KEY'
            },
            body: json.encode({
              'to': token,
              'message': {
                'token': token,
              },
              "notification": {
                "title": "Notificação Push",
                "body": "Teste de notificação push do Firebase"
              }
            }),
          )
          .then((value) => dev.log(value.body));
      dev.log('Solicitação de FCM para web enviada!');
    } catch (e) {
      dev.log(e.toString());
    } */
  }

  /// The API endpoint here accepts a raw FCM payload for demonstration purposes.
  static String _construirFCMPayload(String? token) {
    return jsonEncode({
      'token': token,
      'data': {
        'via': 'FlutterFire Cloud Messaging!!!',
        'count': 'Teste',
      },
      'notification': {
        'title': 'Notificação Push',
        'body': 'Teste de notificação push do Firebase',
      },
    });
  }
}

/// Caixa de diálogo de notificação por push para primeiro plano
class DialogoMensagem extends StatelessWidget {
  final String titulo;
  final String corpo;
  const DialogoMensagem({Key? key, required this.titulo, required this.corpo})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(titulo),
      content: Text(corpo),
      actions: [
        OutlinedButton.icon(
            label: const Text('Fechar'),
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close))
      ],
    );
  }
}
