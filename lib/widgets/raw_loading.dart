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
          ? const Color(0xFF121212)
          : const Color(0xFF2094f3),
      // Animação
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icone da aplicação
          AnimacaoPulando(
            objectToAnimate: Image.asset(
              'assets/icons/ic_launcher.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 12),
          // Mensagem
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              mensagem,
              style: const TextStyle(color: Color.fromRGBO(255, 255, 255, 0.5)),
            ),
          ),
        ],
      ),
    );
  }
}
