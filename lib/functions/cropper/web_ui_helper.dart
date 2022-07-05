import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
// ignore: depend_on_referenced_packages
import 'package:image_cropper_for_web/image_cropper_for_web.dart';

List<PlatformUiSettings>? buildUiSettings(BuildContext context) {
  int size = (MediaQuery.of(context).size.shortestSide / (3 / 2)).round();
  return [
    WebUiSettings(
      context: context,
      presentStyle: CropperPresentStyle.dialog,
      boundary: Boundary(width: size, height: size),
      viewPort: ViewPort(width: size - 4, height: size - 4, type: 'square'),
      enableExif: true,
      enableZoom: true,
    ),
  ];
}
