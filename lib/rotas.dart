// ignore_for_file: constant_identifier_names

import 'package:escala_louvor/screens/tela_notificacoes.dart';
import 'package:escala_louvor/screens/tela_pdf_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:http/http.dart';

import 'screens/tela_admin.dart';
import 'screens/home.dart';
import 'screens/tela_login.dart';
import 'screens/tela_perfil.dart';

class AppRotas extends Module {
  static const String HOME = '/';
  static const String LOGIN = '/login';
  static const String PERFIL = '/perfil';
  static const String ADMIN = '/admin';
  static const String ARQUIVOS = '/arquivos';

  @override
  final List<Bind> binds = [];

  @override
  final List<ModularRoute> routes = [
    ChildRoute(
      HOME,
      //child: (_, args) => HomePage(escala: args.queryParams['escala']),
      child: (_, args) => HomePage(),
      guards: [NotAuthGuard()],
    ),
    ChildRoute(
      LOGIN,
      child: (_, __) => const LoginPage(),
      guards: [AuthGuard()],
      //transition: TransitionType.fadeIn,
    ),
    ChildRoute(
      PERFIL,
      child: (_, args) => TelaPerfil(id: args.queryParams['id'] ?? ''),
      guards: [NotAuthGuard(), HasQueryGuard()],
      //transition: TransitionType.rightToLeftWithFade,
    ),
    ChildRoute(
      ADMIN,
      child: (_, __) => const AdminPage(),
      guards: [NotAuthGuard()],
      //transition: TransitionType.downToUp,
    ),
    ChildRoute(
      ARQUIVOS,
      child: (_, args) => TelaPdfView(arquivos: args.data),
      transition: TransitionType.downToUp,
    ),
    ChildRoute(
      '/notificacoes',
      child: (_, arguments) => const MessageView(),
      //transition: TransitionType.fadeIn,
    ),
    /* ChildRoute(
      '/familia',
      child: (_, args) => FamiliaPage(id: args.queryParams['id'] ?? ''),
      transition: TransitionType.leftToRightWithFade,
      guards: [AuthGuard(), HasQueryGuard()],
    ), */
    WildcardRoute(child: (_, __) => HomePage()),
  ];
}

class NotAuthGuard extends RouteGuard {
  NotAuthGuard() : super(redirectTo: AppRotas.LOGIN);

  @override
  // ignore: avoid_renaming_method_parameters
  Future<bool> canActivate(String path, ModularRoute router) async {
    return FirebaseAuth.instance.currentUser != null;
  }
}

class AuthGuard extends RouteGuard {
  AuthGuard() : super(redirectTo: AppRotas.HOME);

  @override
  // ignore: avoid_renaming_method_parameters
  Future<bool> canActivate(String path, ModularRoute router) async {
    return FirebaseAuth.instance.currentUser == null;
  }
}

class HasQueryGuard extends RouteGuard {
  HasQueryGuard() : super(redirectTo: AppRotas.HOME);

  @override
  // ignore: avoid_renaming_method_parameters
  Future<bool> canActivate(String path, ModularRoute router) async {
    return router.uri.hasQuery;
  }
}
