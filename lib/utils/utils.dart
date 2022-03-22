import 'dart:math';

import 'package:easy_mask/easy_mask.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Texto {
  static String isPlural(int valor) {
    return valor <= 1 ? '' : 's';
  }
}

/// Classe para mascaras de texto
class Input {
  /// Para Telefones (formato (##) _####-####)
  static var textoFone = TextInputMask(
      mask: ['(99) 9999-9999', '(99) 99999-9999'], reverse: false);
  static var mascaraFone = MagicMask.buildMask(textoFone.mask);

  /// Para CEPs (formato #####-###)
  static var textoCEP = TextInputMask(mask: '99999-999');
  static var mascaraCEP = MagicMask.buildMask(textoCEP.mask);

  /// Para moeda (formato #.###,##)
  static var textoMoeda = TextInputMask(mask: '9+.999,99', reverse: true);
  static var mascaraMoeda =
      NumberFormat.currency(locale: 'pt_BR', customPattern: '###,###.##');

  /// Para datas (formato dd/MM/yyyy)
  static var textoData =
      TextInputMask(mask: '99/99/9999', placeholder: 'x', maxPlaceHolders: 10);
  static var mascaraData = DateFormat('dd/MM/yyyy');

  /// Validar texto tipo e-mail
  static String? validarEmail(String? value) {
    if (value != null) {
      final regExp = RegExp(
          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
      if (regExp.hasMatch(value)) return null;
      return 'Informe um e-mail válido';
    }
    return null;
  }

  /// Validar senha com no mínimo 5 caracteres
  static String? validarSenha(String? value) {
    if (value != null && value.isNotEmpty) {
      if (value.length >= 5) return null;
      return 'A senha deve ter no mínimo 5 caracteres';
    }
    return null;
  }

  /// Gerar string aleatória
  static String stringAleatoria(int length) {
    const ch = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz';
    Random r = Random();
    return String.fromCharCodes(
        Iterable.generate(length, (_) => ch.codeUnitAt(r.nextInt(ch.length))));
  }
}

/// Classe para input em formato de moedas
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    double value = double.parse(newValue.text);

    String newText = Input.mascaraMoeda.format(value / 100);

    return newValue.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length));
  }
}
