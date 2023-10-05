import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Redirects pointer events to widgets anywhere else in the tree.
///
/// This is useful for widgets that overflow their parent such as from a
/// [Transform] and would otherwise not receive pointer events.
///
/// To use this widget, give the child you would like to receive pointer events
/// a [GlobalKey] and pass it to the [above] or [below] parameter.
///
/// Note that the RedirectPointer widget needs to encompass the entire widget
/// that should receive pointer events, we recommend wrapping the body of the
/// [Scaffold] so that it can receive pointer events for the whole screen.
///
/// You may also want to wrap the targets in an [IgnorePointer] so they aren't
/// hit tested more than once.
///
/// Hit testing is performed in the following order:
/// 1. The [above] widgets in reverse.
/// 2. The child.
/// 3. The [below] widgets in reverse.
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
