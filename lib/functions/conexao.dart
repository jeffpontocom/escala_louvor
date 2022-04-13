import 'dart:io';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class MinhaConexao {
  final ValueNotifier<bool> isOnline = ValueNotifier(true);

  MinhaConexao();

  void initialize() {
    Connectivity _connectivity = Connectivity();
    _connectivity.onConnectivityChanged.listen((event) async {
      print('home $event');
      checkStatus(event);
    });
  }

  void checkStatus(ConnectivityResult result) async {
    if (result == ConnectivityResult.none) {
      isOnline.value = false;
    } else {
      try {
        final result = await InternetAddress.lookup('example.com');
        isOnline.value = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } on SocketException catch (_) {
        isOnline.value = false;
      }
    }
  }
}
