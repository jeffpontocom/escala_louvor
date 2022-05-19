// ignore_for_file: constant_identifier_names

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'app.dart';
import 'screens/admin/tela_admin.dart';
import 'screens/home/pagina_agenda.dart';
import 'screens/home/pagina_avisos.dart';
import 'screens/home/pagina_canticos.dart';
import 'screens/home/tela_home.dart';
import 'screens/secondaries/tela_cantico.dart';
import 'screens/secondaries/tela_pdf_view.dart';
import 'screens/secondaries/tela_selecao.dart';
import 'screens/user/tela_login.dart';
import 'screens/user/tela_perfil.dart';
import 'deprecated/home_escalas.dart';

class AppRotas extends Module {
  static const String HOME = '/';
  static const String LOGIN = '/login';
  static const String CONTEXTO = '/contexto';
  static const String PERFIL = '/perfil';
  static const String ADMIN = '/admin';
  static const String ARQUIVOS = '/arquivos';
  static const String CANTICO = '/cantico';

  @override
  final List<Bind> binds = [];

  @override
  final List<ModularRoute> routes = [
    ChildRoute(
      HOME,
      child: (_, args) => const App(),
      guards: [NotAuthGuard()],
      children: [
        ChildRoute(
          '/${Paginas.escalas.name}',
          child: (context, args) => TelaEscalas(id: args.queryParams['id']),
          transition: TransitionType.upToDown,
        ),
        ChildRoute(
          '/${Paginas.agenda.name}',
          child: (context, args) => const PaginaAgenda(),
          transition: TransitionType.upToDown,
        ),
        ChildRoute(
          '/${Paginas.avisos.name}',
          child: (context, args) => const PaginaAvisos(),
          transition: TransitionType.upToDown,
        ),
        ChildRoute(
          '/${Paginas.canticos.name}',
          child: (context, args) => const PaginaCanticos(),
          transition: TransitionType.upToDown,
        ),
      ],
    ),
    ChildRoute(
      LOGIN,
      child: (_, __) => const TelaLogin(),
      guards: [AuthGuard()],
    ),
    ChildRoute(
      CONTEXTO,
      child: (_, __) => const TelaContexto(),
    ),
    ChildRoute(
      PERFIL,
      child: (_, args) => TelaPerfil(
        id: args.queryParams['id'] ?? '',
        hero: args.queryParams['hero'],
        snapIntegrante: args.data,
      ),
      guards: [NotAuthGuard(), HasQueryGuard()],
    ),
    ChildRoute(
      ADMIN,
      child: (_, __) => const TelaAdmin(),
      guards: [NotAuthGuard()],
    ),
    ChildRoute(
      ARQUIVOS,
      child: (_, args) => TelaPdfView(arquivos: args.data),
      transition: TransitionType.downToUp,
    ),
    ChildRoute(
      CANTICO,
      child: (_, args) => TelaLetrasView(canticos: args.data),
      transition: TransitionType.downToUp,
    ),
    WildcardRoute(child: (_, __) => const App()),
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
