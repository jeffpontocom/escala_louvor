import 'package:flutter/material.dart';

class MySliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  MySliverAppBarDelegate(this._widget);

  final Widget _widget;

  @override
  double get minExtent => kTextTabBarHeight;
  @override
  double get maxExtent => kTextTabBarHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(elevation: 1, child: _widget);
  }

  @override
  bool shouldRebuild(MySliverAppBarDelegate oldDelegate) {
    return false;
  }
}
