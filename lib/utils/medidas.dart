import 'package:flutter/material.dart';

class Medidas {
  /// Margem ou Padding vertical padrão (min 32)
  static double margemV(context) {
    double minPad = 32;
    var mesure = ((MediaQuery.of(context).size.height - 860) / 2) + minPad;
    return mesure > minPad ? mesure : minPad;
  }

  /// Margem ou Padding horizontal padrão (min 24)
  static double margemH(context) {
    double minPad = 24;
    var mesure = ((MediaQuery.of(context).size.width - 860) / 2) + minPad;
    return mesure > minPad ? mesure : minPad;
  }

  /// Margem ou Padding horizontal padrão (min 0)
  static double paddingListH(context) {
    double minPad = 0;
    var mesure = ((MediaQuery.of(context).size.width - 860) / 2) + minPad;
    return mesure > minPad ? mesure : minPad;
  }
}
