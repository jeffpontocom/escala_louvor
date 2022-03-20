import 'package:flutter_modular/flutter_modular.dart';

import 'admin.dart';
import 'global.dart';
import 'home.dart';
import 'login.dart';
import 'perfil.dart';

class AppNavigation extends Module {
  @override
  final List<Bind> binds = [];

  @override
  final List<ModularRoute> routes = [
    ChildRoute(
      '/',
      child: (_, __) => const HomePage(),
      guards: [AuthGuard()],
    ),
    ChildRoute(
      '/login',
      child: (_, __) => const LoginPage(),
      //transition: TransitionType.fadeIn,
    ),
    ChildRoute(
      '/perfil',
      child: (_, args) => PerfilPage(id: args.queryParams['id'] ?? ''),
      //transition: TransitionType.rightToLeftWithFade,
      guards: [AuthGuard(), HasQueryGuard()],
    ),
    ChildRoute(
      '/admin',
      child: (_, __) => const AdminPage(),
      //transition: TransitionType.downToUp,
      guards: [AuthGuard()],
    ),
    /* ChildRoute(
      '/familia',
      child: (_, args) => FamiliaPage(id: args.queryParams['id'] ?? ''),
      transition: TransitionType.leftToRightWithFade,
      guards: [AuthGuard(), HasQueryGuard()],
    ), */
    WildcardRoute(child: (_, __) => const HomePage()),
  ];
}

class AuthGuard extends RouteGuard {
  AuthGuard() : super(redirectTo: '/login');

  @override
  // ignore: avoid_renaming_method_parameters
  Future<bool> canActivate(String path, ModularRoute router) async {
    return Global.auth.currentUser != null;
  }
}

class HasQueryGuard extends RouteGuard {
  HasQueryGuard() : super(redirectTo: '/');

  @override
  // ignore: avoid_renaming_method_parameters
  Future<bool> canActivate(String path, ModularRoute router) async {
    return router.uri.hasQuery;
  }
}
