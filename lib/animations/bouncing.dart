import 'dart:async';
import 'package:flutter/material.dart';

class AnimacaoPulando extends StatefulWidget {
  final Widget objectToAnimate;
  const AnimacaoPulando({Key? key, required this.objectToAnimate})
      : super(key: key);
  @override
  _AnimacaoPulandoState createState() => _AnimacaoPulandoState();
}

class _AnimacaoPulandoState extends State<AnimacaoPulando> {
  late String direction;
  late double marginTop;
  late double increment;
  late double start;
  late double end;
  late Duration duration;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    marginTop = 0;
    direction = 'down';
    increment = 2;
    start = 0;
    end = 50;
    duration = const Duration(milliseconds: 20);

    timer = Timer.periodic(duration, bounce);
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  void setDirection() {
    if (marginTop == end) {
      setState(() {
        direction = 'up';
      });
    }

    if (marginTop == start) {
      setState(() {
        direction = 'down';
      });
    }
  }

  void bounce(Timer t) {
    setDirection();
    setState(() {
      if (direction == 'down') {
        marginTop += increment;
      } else {
        marginTop -= increment;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: marginTop),
      child: SizedBox(
        width: 48,
        height: 48,
        child: widget.objectToAnimate,
      ),
    );
  }
}
