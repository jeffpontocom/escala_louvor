import 'package:flutter/material.dart';

class Medidas {
  static const double maxWidth = 860.0;

  /// Margem ou Padding vertical padrão (min 32)
  static double margemV(context) {
    double minPad = 32;
    var mesure = ((MediaQuery.of(context).size.height - maxWidth) / 2) + minPad;
    return mesure > minPad ? mesure : minPad;
  }

  /// Margem ou Padding horizontal padrão (min 24)
  static double margemH(context) {
    double minPad = 24;
    var mesure = ((MediaQuery.of(context).size.width - maxWidth) / 2) + minPad;
    return mesure > minPad ? mesure : minPad;
  }

  /// Margem ou Padding horizontal padrão (min 0)
  static double paddingListH(context) {
    double minPad = 0;
    var mesure = ((MediaQuery.of(context).size.width - maxWidth) / 2) + minPad;
    return mesure > minPad ? mesure : minPad;
  }

  /// Margem ou Padding horizontal padrão (min 24)
  static double bodyPadding(context) {
    const double min = 16;
    double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth <= maxWidth
        ? min
        : ((screenWidth - maxWidth) * 0.5) + min;
  }
}
