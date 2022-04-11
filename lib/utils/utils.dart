import 'dart:io';
import 'dart:math';

import 'package:easy_mask/easy_mask.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class MyStrings {
  static String isPlural(int valor) {
    return valor <= 1 ? '' : 's';
  }

  static String getUserInitials(String name) {
    var split = name.split(' ');
    int count = split.length;
    var first = split.first.characters.first;
    var last = '';
    if (count > 1) {
      last = split.last.characters.first;
    }
    return first + last;
  }
}

class MyActions {
  // ignore: constant_identifier_names
  static const String STD_DDD = '45';
  // ignore: constant_identifier_names
  static const String STD_CITY = 'Foz do Iguaçu';

  /// Iniciar Whatsapp
  static void openWhatsApp(String value) async {
    value = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (value.length < 10) {
      value = STD_DDD + value;
    }
    var url = 'https://wa.me/55$value';
    if (!await launch(url)) {
      throw 'Não é possível abrir o Whatsapp';
    }
  }

  /// Iniciar Telefone
  static void openPhoneCall(String value) async {
    var url = 'tel:$value';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Não é possível realizar ligações nesse aparelho';
    }
  }

  /// Iniciar Site ou App web
  static void openSite(String url) async {
    if (!await launch(url)) {
      throw 'Não foi possível abrir o site';
    }
  }

  /// Iniciar Google Maps
  static void openGoogleMaps(
      {required String street, String? number, String? city}) {
    var query = street +
        (number != null ? ', $number' : '') +
        (city != null ? ', $city' : '');
    MapsLauncher.launchQuery(query);
  }
}

class MyNetwork {
  static Image? getImageFromUrl(String? url, {double? progressoSize}) {
    if (url == null) return null;
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loading) {
        if (loading == null) return child;
        return SizedBox(
          width: progressoSize,
          height: progressoSize,
          child: Center(
            child:
                CircularProgressIndicator(color: Colors.grey.withOpacity(0.5)),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Icon(
          Icons.error,
          color: Colors.red,
        ),
      ),
    );
  }
}

/// Classe para mascaras de texto
class MyInputs {
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
  static String randomString(int length) {
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

    String newText = MyInputs.mascaraMoeda.format(value / 100);

    return newValue.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length));
  }
}

class MapsLauncher {
  static String createQueryUrl(String query) {
    Uri uri;

    if (kIsWeb) {
      uri = Uri.https(
          'www.google.com', '/maps/search/', {'api': '1', 'query': query});
    } else if (Platform.isAndroid) {
      uri = Uri(scheme: 'geo', host: '0,0', queryParameters: {'q': query});
    } else if (Platform.isIOS) {
      uri = Uri.https('maps.apple.com', '/', {'q': query});
    } else {
      uri = Uri.https(
          'www.google.com', '/maps/search/', {'api': '1', 'query': query});
    }

    return uri.toString();
  }

  static String createCoordinatesUrl(double latitude, double longitude,
      [String? label]) {
    Uri uri;

    if (kIsWeb) {
      uri = Uri.https('www.google.com', '/maps/search/',
          {'api': '1', 'query': '$latitude,$longitude'});
    } else if (Platform.isAndroid) {
      var query = '$latitude,$longitude';

      if (label != null) query += '($label)';

      uri = Uri(scheme: 'geo', host: '0,0', queryParameters: {'q': query});
    } else if (Platform.isIOS) {
      var params = {'ll': '$latitude,$longitude'};

      if (label != null) params['q'] = label;

      uri = Uri.https('maps.apple.com', '/', params);
    } else {
      uri = Uri.https('www.google.com', '/maps/search/',
          {'api': '1', 'query': '$latitude,$longitude'});
    }

    return uri.toString();
  }

  static Future<bool> launchQuery(String query) {
    return launch(createQueryUrl(query));
  }

  static Future<bool> launchCoordinates(double latitude, double longitude,
      [String? label]) {
    return launch(createCoordinatesUrl(latitude, longitude, label));
  }
}
