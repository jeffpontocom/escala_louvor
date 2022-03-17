import 'package:escala_louvor/screens/escalas/view_culto.dart';
import 'package:flutter/material.dart';

class TelaEscala extends StatelessWidget {
  const TelaEscala({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: TabBarView(
        children: List.generate(
          3,
          (index) => const ViewCulto(),
          growable: false,
        ).toList(),
      ),
    );
  }
}
