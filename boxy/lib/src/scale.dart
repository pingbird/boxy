import 'package:flutter/material.dart';

import '../boxy.dart';

/// Scales its child by a given factor.
///
/// Unlike [Transform], this widget will pass adjusted constraints to its child
/// so that it can be laid out at the correct size without overflowing.
class Scale extends StatelessWidget {
  const Scale({
    super.key,
    required this.child,
    required this.scale,
  });

  final Widget child;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return CustomBoxy(
      delegate: _ScaleBoxy(scale),
      children: [child],
    );
  }
}

class _ScaleBoxy extends BoxyDelegate {
  _ScaleBoxy(this.scale);

  final double scale;

  @override
  bool shouldRelayout(_ScaleBoxy oldDelegate) => scale != oldDelegate.scale;

  @override
  Size layout() {
    final child = children.single;
    if (scale == 0 || !scale.isFinite) {
      child.layout(BoxConstraints.tight(Size.zero));
      return Size.zero;
    }
    child.setTransform(Matrix4.identity()..scale(scale));
    return child.layout(constraints / scale) * scale;
  }
}
