import 'package:escala_louvor/resources/animations/bouncing.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class RawLoading extends StatelessWidget {
  final String mensagem;
  const RawLoading({Key? key, required this.mensagem}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      color: MediaQueryData.fromWindow(WidgetsBinding.instance.window)
                  .platformBrightness ==
              Brightness.dark
          ? const Color(0xFF303030)
          : const Color(0xFF2094f3),
      child: Column(children: [
        const Expanded(child: SizedBox()),
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            AnimacaoPulando(
                objectToAnimate: Image.asset('assets/icons/ic_launcher.png')),
          ]),
        ),
        Expanded(
          child: Column(children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                mensagem,
                style: const TextStyle(
                    color: Color(0xFFE0E0E0), fontFamily: 'Ubuntu'),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
