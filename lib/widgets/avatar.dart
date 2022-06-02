import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '/utils/utils.dart';

class CachedAvatar extends StatelessWidget {
  final IconData? icone;
  final String? nome;
  final String? url;
  final double? maxRadius;
  const CachedAvatar(
      {Key? key, this.nome, this.url, this.maxRadius, this.icone})
      : assert(nome != null || icone != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      maxRadius: maxRadius,
      foregroundImage: url == null ? null : CachedNetworkImageProvider(url!),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(shape: BoxShape.circle),
        clipBehavior: Clip.hardEdge,
        child: FittedBox(
          fit: BoxFit.contain,
          child: icone != null
              ? Icon(icone)
              : Text(
                  MyStrings.getUserInitials(nome ?? ''),
                  style: TextStyle(fontSize: maxRadius),
                ),
        ),
      ),
    );
  }
}
