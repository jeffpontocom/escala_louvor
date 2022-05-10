import 'dart:developer' as dev;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:url_strategy/url_strategy.dart';

import 'firebase_options.dart';
import 'global.dart';
import 'preferencias.dart';
import 'rotas.dart';
import 'temas.dart';
import '/animations/bouncing.dart';
import '/functions/notificacoes.dart';
import '/screens/home.dart';

void main() async {
  setPathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ModularApp(module: AppRotas(), child: const MyApp()));
}

Future<bool> iniciar(ValueNotifier<String> textoCarregamento) async {
  // Carregar o arquivo de chaves (extensão .txt para poder ser lida na web)
  await dotenv.load(fileName: 'dotenv.txt');
  textoCarregamento.value = 'Checando dados do aplicativo...';
  await Global.carregarAppInfo();
  // Inicializar o Firebase
  textoCarregamento.value = 'Verificando base de dados...';
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    dev.log('Main: Um App Firebase nomeado "[DEFAULT]" já existe!');
  }
  // Carregar preferências
  textoCarregamento.value = 'Aplicando preferências...';
  await Preferencias.carregarInstancia();
  textoCarregamento.value = 'Carregando aplicativo...';
  return true;
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ValueNotifier<String> textoCarregamento = ValueNotifier('Aguarde...');
    return FutureBuilder<bool>(
        future: iniciar(textoCarregamento),
        builder: (context, snapshot) {
          // TELA DE CARREGAMENTO
          if (!snapshot.hasData) {
            return MaterialApp(
              home: Scaffold(
                body: Container(
                  padding: const EdgeInsets.all(64),
                  alignment: Alignment.center,
                  color: Theme.of(context).primaryColor,
                  // Animação
                  child: AnimacaoPulando(
                    objectToAnimate:
                        Image.asset('assets/icons/ic_launcher.png'),
                  ),
                ),
              ),
            );
          }
          // PÓS CARREGAMENTO INICIAL
          // Rota inicial
          Modular.setInitialRoute('/${Paginas.values[0].name}');
          // Escuta alterações no usuário autenticado
          // pelas configurações de rota os usuários não logados são
          // direcionados a tela de login
          return StreamBuilder<User?>(
              stream: FirebaseAuth.instance.userChanges(),
              builder: (_, snapshotUser) {
                dev.log('MyApp: ${snapshotUser.connectionState.name}');
                if (snapshotUser.connectionState == ConnectionState.active) {
                  dev.log(
                      'Firebase Auth: ${snapshotUser.data?.email ?? 'não logado!'}');
                }
                if (snapshotUser.data?.email != null) {
                  // Carrega sistema de notificações
                  // Esse carregamento deve ser feito sempre após runApp() para evitar erros
                  Notificacoes.carregarInstancia();
                }
                // APP
                return MaterialApp.router(
                  title: 'Escala do Louvor',
                  // Tema claro
                  theme: temaClaro(),
                  // Tema Escuro
                  darkTheme: temaEscuro(),
                  // Behaviors
                  scrollBehavior: MyCustomScrollBehavior(),
                  // Suporte a lingua português nos elementos globais
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: const [Locale('pt')],
                  locale: const Locale('pt_BR'),
                  // Navegação Modular
                  routeInformationParser: Modular.routeInformationParser,
                  routerDelegate: Modular.routerDelegate,
                );
              });
        });
  }
}

/// Classe para emular as ações de gestos do dedo pelo mouse
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
