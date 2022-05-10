import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'functions/metodos_firebase.dart';
import 'global.dart';

class Preferencias {
  static SharedPreferences? preferences;

  /// Recupera os dados salvos na seção anterior
  static Future<void> carregarInstancia() async {
    preferences = await SharedPreferences.getInstance();
    await _carregarIgrejaPreSelecionada();
  }

  // PREFERENCIAS PRINCIPAIS

  /// Igreja em contexto
  static String? get igreja => preferences?.getString('igreja_atual');
  static set igreja(String? id) {
    if (id != null && id.isNotEmpty) {
      preferences?.setString('igreja_atual', id);
    } else {
      preferences?.remove('igreja_atual');
    }
  }

  /// Mostrar todos os eventos
  static bool get mostrarTodosOsCultos =>
      preferences?.getBool('mostrar_todos_cultos') ?? false;
  static set mostrarTodosOsCultos(bool value) {
    preferences?.setBool('mostrar_todos_cultos', value);
  }

  static _carregarIgrejaPreSelecionada() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    var value = await MeuFirebase.obterSnapshotIgreja(igreja);
    Global.igrejaSelecionada.value = value;
  }
}
