import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

class RedirectPointer extends SingleChildRenderObjectWidget {
  const RedirectPointer({
    super.key,
    super.child,
    this.above = const [],
    this.below = const [],
  });

  final List<GlobalKey> below;
  final List<GlobalKey> above;

  @override
  RenderRedirectPointer createRenderObject(BuildContext context) {
    return RenderRedirectPointer(below: below, above: above);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderRedirectPointer renderObject,
  ) {
    renderObject
      ..below = below
      ..above = above;
  }
}

class RenderRedirectPointer extends RenderProxyBox {
  RenderRedirectPointer({
    RenderBox? child,
    this.below = const [],
    this.above = const [],
  }) : super(child);

  List<GlobalKey> below;
  List<GlobalKey> above;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final key in above.reversed) {
      final child = key.currentContext?.findRenderObject() as RenderBox?;
      if (child != null) {
        final hit = result.addWithPaintTransform(
          transform: child.getTransformTo(this),
          position: position,
          hitTest: (result, position) {
            return child.hitTest(result, position: position);
          },
        );
        if (hit) {
          return true;
        }
      }
    }
    if (super.hitTestChildren(result, position: position)) {
      return true;
    }
    for (final key in below.reversed) {
      final child = key.currentContext?.findRenderObject() as RenderBox?;
      if (child != null) {
        final hit = result.addWithPaintTransform(
          transform: child.getTransformTo(this),
          position: position,
          hitTest: (result, position) {
            return child.hitTest(result, position: position);
          },
        );
        if (hit) {
          return true;
        }
      }
    }
    return false;
  }
}
