import 'package:cached_network_image/cached_network_image.dart';
import 'package:escala_louvor/models/integrante.dart';
import 'package:escala_louvor/utils/global.dart';
import 'package:flutter/material.dart';

import '../utils/utils.dart';

class AvatarIntegrante extends StatelessWidget {
  final Integrante integrante;
  final double? radius;
  const AvatarIntegrante({Key? key, required this.integrante, this.radius})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      //backgroundColor: Colors.grey.withOpacity(0.38),
      foregroundImage: integrante.fotoUrl == null
          ? null
          : CachedNetworkImageProvider(integrante.fotoUrl!),
      //foregroundImage: MyNetwork.getImageFromUrl(integrante.fotoUrl)?.image,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Text(
          MyStrings.getUserInitials(integrante.nome),
          textScaleFactor: 0.7,
        ),
      ),
    );
  }
}
