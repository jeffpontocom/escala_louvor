// ignore_for_file: constant_identifier_names

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'my_app.dart';
import 'screens/admin/tela_admin.dart';
import 'screens/home/pagina_agenda.dart';
import 'screens/home/pagina_avisos.dart';
import 'screens/home/pagina_canticos.dart';
import 'screens/home/pagina_igreja.dart';
import 'screens/home/tela_home.dart';
import 'screens/secondaries/tela_cantico.dart';
import 'screens/secondaries/tela_culto.dart';
import 'screens/secondaries/tela_pdf_view.dart';
import 'screens/secondaries/tela_selecao.dart';
import 'screens/user/tela_login.dart';
import 'screens/user/tela_perfil.dart';
import 'utils/global.dart';
import 'views/scaffold_404.dart';

class AppModule extends Module {
  static const String ADMIN = '/admin';
  static const String ARQUIVOS = '/arquivos';
  static const String CANTICO = '/cantico';
  static const String CONTEXTO = '/contexto';
  static const String CULTO = '/culto';
  static const String HOME = '/home';
  static const String LOGIN = '/login';
  static const String PERFIL = '/perfil';

  @override
  List<Bind> get binds => [];

  @override
  List<ModularRoute> get routes => [
        // RAIZ
        ChildRoute(
          '/',
          child: (_, args) => const MyApp(),
        ),

        // HOME + Paginas
        ChildRoute(
          HOME,
          child: (_, args) => const MyApp(),
          children: [
            ChildRoute(
              '/${HomePages.agenda.name}',
              child: (context, args) => const PaginaAgenda(),
              transition: TransitionType.downToUp,
            ),
            ChildRoute(
              '/${HomePages.canticos.name}',
              child: (context, args) => const PaginaCanticos(),
              transition: TransitionType.downToUp,
            ),
            ChildRoute(
              '/${HomePages.avisos.name}',
              child: (context, args) => const PaginaAvisos(),
              transition: TransitionType.downToUp,
            ),
            ChildRoute(
              '/${HomePages.equipe.name}',
              child: (context, args) => const PaginaEquipe(),
              transition: TransitionType.downToUp,
            ),
          ],
        ),

        // CONTEXTO
        ChildRoute(
          CONTEXTO,
          child: (_, __) => const TelaContexto(),
        ),

        // LOGIN
        ChildRoute(
          LOGIN,
          child: (_, __) => const TelaLogin(),
          guards: [InverseAuthGuard()],
        ),

        // PERFIL
        ChildRoute(
          PERFIL,
          child: (_, args) => TelaPerfil(
            id: args.queryParams['id'] ?? '',
            hero: args.queryParams['hero'],
            snapIntegrante: args.data,
          ),
          guards: [QueryGuard()],
        ),

        // CULTO
        ChildRoute(
          CULTO,
          child: (_, args) => TelaDetalhesEscala(
            id: args.queryParams['id'] ?? '',
            snapCulto: args.data,
          ),
          guards: [QueryGuard()],
        ),

        // CANTICOS
        ChildRoute(
          CANTICO,
          child: (_, args) => TelaCantico(
              id: args.queryParams['id'] ?? '', snapshot: args.data),
          transition: TransitionType.downToUp,
          guards: [QueryGuard()],
        ),

        // ARQUIVOS PDF
        ChildRoute(
          ARQUIVOS,
          child: (_, args) => TelaPdfView(
            fileUrl: args.data[0],
            name: args.data[1],
          ),
          transition: TransitionType.downToUp,
        ),

        // ADMIN
        ChildRoute(
          ADMIN,
          child: (_, __) => const TelaAdmin(),
        ),

        // WILDCARD (em caso de rota inexistente - Erro 404)
        WildcardRoute(child: (_, __) => const View404()),
      ];
}

class InverseAuthGuard extends RouteGuard {
  InverseAuthGuard() : super(redirectTo: Global.rotaInicial);

  @override
  Future<bool> canActivate(String path, ModularRoute route) async {
    return FirebaseAuth.instance.currentUser == null;
  }
}

class QueryGuard extends RouteGuard {
  QueryGuard() : super(redirectTo: Global.rotaInicial);

  @override
  Future<bool> canActivate(String path, ModularRoute route) async {
    return route.uri.hasQuery;
  }
}
