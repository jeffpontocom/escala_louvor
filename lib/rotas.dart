// ignore_for_file: constant_identifier_names

import 'package:escala_louvor/screens/pages/home_agenda.dart';
import 'package:escala_louvor/screens/pages/home_canticos.dart';
import 'package:escala_louvor/screens/pages/home_chats.dart';
import 'package:escala_louvor/screens/pages/home_escalas.dart';
import 'package:escala_louvor/screens/tela_notificacoes.dart';
import 'package:escala_louvor/screens/tela_pdf_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_modular/flutter_modular.dart';

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
      child: (_, args) => const HomeInit(),
      guards: [NotAuthGuard()],
      children: [
        ChildRoute(
          '/${Paginas.escalas.name}',
          child: (context, args) => TelaEscalas(id: args.queryParams['id']),
          transition: TransitionType.scale,
        ),
        ChildRoute(
          '/${Paginas.agenda.name}',
          child: (context, args) => const TelaAgenda(),
          transition: TransitionType.scale,
        ),
        ChildRoute(
          '/${Paginas.chats.name}',
          child: (context, args) => const TelaChat(),
          transition: TransitionType.scale,
        ),
        ChildRoute(
          '/${Paginas.canticos.name}',
          child: (context, args) => const TelaCanticos(),
          transition: TransitionType.scale,
        ),
      ],
    ),
    ChildRoute(
      LOGIN,
      child: (_, __) => const LoginPage(),
      guards: [AuthGuard()],
    ),
    ChildRoute(
      PERFIL,
      child: (_, args) => TelaPerfil(id: args.queryParams['id'] ?? ''),
      guards: [NotAuthGuard(), HasQueryGuard()],
    ),
    ChildRoute(
      ADMIN,
      child: (_, __) => const AdminPage(),
      guards: [NotAuthGuard()],
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
    WildcardRoute(child: (_, __) => const HomeInit()),
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
  AuthGuard() : super(redirectTo: '/${Paginas.values[0].name}');

  @override
  // ignore: avoid_renaming_method_parameters
  Future<bool> canActivate(String path, ModularRoute router) async {
    return FirebaseAuth.instance.currentUser == null;
  }
}

class HasQueryGuard extends RouteGuard {
  HasQueryGuard() : super(redirectTo: '/${Paginas.values[0].name}');

  @override
  // ignore: avoid_renaming_method_parameters
  Future<bool> canActivate(String path, ModularRoute router) async {
    return router.uri.hasQuery;
  }
}
