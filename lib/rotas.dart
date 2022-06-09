// ignore_for_file: constant_identifier_names

import 'package:escala_louvor/models/integrante.dart';
import 'package:escala_louvor/screens/home/pagina_igreja.dart';
import 'package:escala_louvor/utils/global.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'app.dart';
import 'screens/admin/tela_admin.dart';
import 'screens/home/pagina_agenda.dart';
import 'screens/home/pagina_avisos.dart';
import 'screens/home/pagina_canticos.dart';
import 'screens/home/tela_home.dart';
import 'screens/secondaries/tela_cantico.dart';
import 'screens/secondaries/tela_culto.dart';
import 'screens/secondaries/tela_pdf_view.dart';
import 'screens/secondaries/tela_selecao.dart';
import 'screens/user/tela_login.dart';
import 'screens/user/tela_perfil.dart';

class AppRotas extends Module {
  static const String HOME = '/';
  static const String LOGIN = '/login';
  static const String CONTEXTO = '/contexto';
  static const String PERFIL = '/perfil';
  static const String ADMIN = '/admin';
  static const String ARQUIVOS = '/arquivos';
  static const String CANTICO = '/cantico';
  static const String CULTO = '/culto';

  @override
  List<Bind> get binds => [];

  @override
  final List<ModularRoute> routes = [
    ChildRoute(
      HOME,
      child: (_, args) => const App(),
      guards: [AuthGuard()],
      children: [
        ChildRoute(
          '/${Paginas.agenda.name}',
          child: (context, args) => const PaginaAgenda(),
          transition: TransitionType.downToUp,
        ),
        ChildRoute(
          '/${Paginas.canticos.name}',
          child: (context, args) => const PaginaCanticos(),
          transition: TransitionType.downToUp,
        ),
        ChildRoute(
          '/${Paginas.avisos.name}',
          child: (context, args) => const PaginaAvisos(),
          transition: TransitionType.downToUp,
        ),
        ChildRoute(
          '/${Paginas.equipe.name}',
          child: (context, args) => const PaginaEquipe(),
          transition: TransitionType.downToUp,
        ),
      ],
    ),
    ChildRoute(
      LOGIN,
      child: (_, __) => const TelaLogin(),
      guards: [LoginGuard()],
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
      guards: [AuthGuard(), QueryGuard()],
    ),
    ChildRoute(
      CULTO,
      child: (_, args) => TelaDetalhesEscala(
        id: args.queryParams['id'] ?? '',
        snapCulto: args.data,
      ),
      guards: [AuthGuard(), QueryGuard()],
    ),
    ChildRoute(
      ADMIN,
      child: (_, __) => const TelaAdmin(),
      guards: [AuthGuard()],
    ),
    ChildRoute(
      ARQUIVOS,
      child: (_, args) => TelaPdfView(
        fileUrl: args.data[0],
        fileName: args.data[1],
      ),
      transition: TransitionType.downToUp,
      guards: [AuthGuard()],
    ),
    ChildRoute(
      CANTICO,
      child: (_, args) =>
          TelaLetrasView(id: args.queryParams['id'] ?? '', snapshot: args.data),
      transition: TransitionType.downToUp,
      guards: [AuthGuard(), QueryGuard()],
    ),
    WildcardRoute(child: (_, __) => const Home()),
  ];
}

class AuthGuard extends RouteGuard {
  AuthGuard() : super(redirectTo: AppRotas.LOGIN);

  @override
  // ignore: avoid_renaming_method_parameters
  Future<bool> canActivate(String path, ModularRoute router) async {
    var test = Modular.get<FirebaseAuth>(defaultValue: FirebaseAuth.instance)
            .currentUser !=
        null;
    print('AuthGuard: $test');
    return test;
    //return FirebaseAuth.instance.currentUser != null;
  }
}

class LoginGuard extends RouteGuard {
  //LoginGuard() : super(redirectTo: '/${Paginas.values[0].name}');
  LoginGuard() : super(redirectTo: Modular.initialRoute);

  @override
  // ignore: avoid_renaming_method_parameters
  Future<bool> canActivate(String path, ModularRoute router) async {
    var test = Modular.get<FirebaseAuth>(defaultValue: FirebaseAuth.instance)
            .currentUser ==
        null;
    print('LoginGuard: $test');
    return test;
  }
}

class QueryGuard extends RouteGuard {
  //QueryGuard() : super(redirectTo: '/${Paginas.values[0].name}');
  QueryGuard() : super(redirectTo: Modular.initialRoute);

  @override
  // ignore: avoid_renaming_method_parameters
  Future<bool> canActivate(String path, ModularRoute router) async {
    return router.uri.hasQuery;
  }
}
