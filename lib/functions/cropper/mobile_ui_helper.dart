import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

List<PlatformUiSettings>? buildUiSettings(BuildContext context) {
  return [
    AndroidUiSettings(
      toolbarTitle: 'Ajustar imagem',
      toolbarColor: Colors.deepOrange,
      toolbarWidgetColor: Colors.white,
      initAspectRatio: CropAspectRatioPreset.square,
      lockAspectRatio: true,
      hideBottomControls: true,
    ),
    IOSUiSettings(
      title: 'Ajustar imagem',
    ),
  ];
}
