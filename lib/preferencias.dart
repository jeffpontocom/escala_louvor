import 'package:shared_preferences/shared_preferences.dart';

class Preferencias {
  static SharedPreferences? preferences;

  /// Recupera os dados salvos na seção anterior
  static Future<void> carregarInstancia() async {
    preferences = await SharedPreferences.getInstance();
  }

  // PREFERENCIAS PRINCIPAIS

  /// Igreja em contexto
  static String? get igrejaAtual => preferences?.getString('igreja_atual');
  static set igrejaAtual(String? id) {
    if (id != null && id.isNotEmpty) {
      preferences?.setString('igreja_atual', id);
    } else {
      preferences?.remove('igreja_atual');
    }
  }
}
