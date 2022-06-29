import 'package:flutter/widgets.dart';
import 'dart:math';

import 'package:flutter/rendering.dart';

/// [SliverPinnedBox] keeps its child pinned to the leading edge of the viewport.
class SliverPinnedBox extends SingleChildRenderObjectWidget {
  const SliverPinnedBox({
    Key? key,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  RenderSliverPinnedBox createRenderObject(BuildContext context) {
    return RenderSliverPinnedBox();
  }
}

class RenderSliverPinnedBox extends RenderSliverSingleBoxAdapter {
  @override
  void performLayout() {
    child!.layout(constraints.asBoxConstraints(), parentUsesSize: true);
    double childExtent;
    switch (constraints.axis) {
      case Axis.horizontal:
        childExtent = child!.size.width;
        break;
      case Axis.vertical:
        childExtent = child!.size.height;
        break;
    }
    final paintedChildExtent = min(
      childExtent,
      constraints.remainingPaintExtent - constraints.overlap,
    );
    geometry = SliverGeometry(
      paintExtent: paintedChildExtent,
      maxPaintExtent: childExtent,
      maxScrollObstructionExtent: childExtent,
      paintOrigin: constraints.overlap,
      scrollExtent: childExtent,
      layoutExtent: max(0.0, paintedChildExtent - constraints.scrollOffset),
      hasVisualOverflow: paintedChildExtent < childExtent,
    );
  }

  @override
  double childMainAxisPosition(RenderBox child) {
    return 0;
  }
}
