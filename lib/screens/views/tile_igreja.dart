import 'package:flutter/material.dart';

import '../../models/igreja.dart';
import '../../utils/utils.dart';

class TileIgrejaSmall extends StatelessWidget {
  final Igreja igreja;
  const TileIgrejaSmall({Key? key, required this.igreja}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(top: 8, right: 8),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.withOpacity(0.5)),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // Foto da igreja
        SizedBox(
          height: 56,
          width: 64,
          child: MyNetwork.getImageFromUrl(igreja.fotoUrl) ??
              const Icon(Icons.church),
        ),
        // Sigla
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            igreja.sigla.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ]),
    );
  }
}
