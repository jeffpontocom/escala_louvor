import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:url_strategy/url_strategy.dart';

import 'app.dart';
import 'rotas.dart';
import 'screens/home/tela_home.dart';

void main() async {
  setPathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  // Rota inicial
  Modular.setInitialRoute('/${Paginas.values[0].name}');
  runApp(ModularApp(module: AppRotas(), child: const LoadApp()));
}
