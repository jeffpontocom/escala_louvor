import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

List<PlatformUiSettings>? buildUiSettings(BuildContext context) {
  return [
    AndroidUiSettings(
        toolbarTitle: 'Recortar',
        toolbarColor: Colors.deepOrange,
        toolbarWidgetColor: Colors.white,
        initAspectRatio: CropAspectRatioPreset.original,
        lockAspectRatio: false),
    IOSUiSettings(
      title: 'Recortar',
    ),
  ];
}
