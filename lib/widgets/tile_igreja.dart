import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '/models/igreja.dart';

class TileIgrejaSmall extends StatelessWidget {
  final Igreja igreja;
  const TileIgrejaSmall({Key? key, required this.igreja}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.withOpacity(0.5)),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Foto da igreja
          SizedBox(
            height: 56,
            width: 64,
            child: igreja.fotoUrl != null
                ? CachedNetworkImage(
                    fit: BoxFit.cover, imageUrl: igreja.fotoUrl!)
                : const Icon(Icons.church),
          ),
          // Sigla
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              igreja.sigla.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
