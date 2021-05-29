import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../axis_utils.dart';
import '../sliver_axis_utils.dart';
import 'box_child.dart';
import 'custom_boxy_base.dart';
import 'inflating_element.dart';

/// The [RenderObject] of [CustomBoxy], delegates control of layout to a
/// [BoxyDelegate].
///
/// See also:
///   * [CustomBoxy]
///   * [BoxyDelegate]
class RenderSliverBoxy<ChildHandleType extends BaseBoxyChild> extends RenderSliver with
  ContainerRenderObjectMixin<RenderObject, BoxyParentData>,
  InflatingRenderObjectMixin<RenderObject, BoxyParentData, ChildHandleType>,
  RenderBoxyMixin<RenderObject, BoxyParentData, ChildHandleType> {
  SliverBoxyDelegate<Object> _delegate;

  @override
  final InflatedChildHandleFactory childFactory;

  /// Creates a RenderBoxy with a delegate.
  RenderSliverBoxy({
    required SliverBoxyDelegate<Object> delegate,
    required this.childFactory,
  }) : _delegate = delegate;

  @override
  SliverHitTestResult? hitTestResult;

  @override
  void prepareChild(ChildHandleType child) {
    super.prepareChild(child);
    final parentData = child.render.parentData as BoxyParentData;
    parentData.drySize = null;
    parentData.dryTransform = null;
  }

  @override
  SliverBoxyDelegate<Object> get delegate => _delegate;

  @override
  set delegate(SliverBoxyDelegate<Object> newDelegate) {
    final oldDelegate = delegate;
    _delegate = newDelegate;
    notifyChangedDelegate(oldDelegate);
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxyParentData)
      child.parentData = BoxyParentData();
  }

  @override
  void performInflatingLayout() {
    wrapPhase(BoxyDelegatePhase.layout, () {
      geometry = delegate.layout();
    });
  }

  /// The current size of the sliver.
  SliverSize get size => SliverSize.axis(
    constraints.crossAxisExtent,
    geometry!.layoutExtent,
    constraints.axis,
  );

  @override
  bool get isDryLayout => false;

  @override
  bool hitTest(
    SliverHitTestResult result, {
    required double crossAxisPosition,
    required double mainAxisPosition,
  }) {
    hitTestResult = result;
    hitPosition = constraints.unwrap(crossAxisPosition, mainAxisPosition, size);
    try {
      return wrapPhase(BoxyDelegatePhase.hitTest, () {
        return delegate.hitTest(hitPosition!);
      });
    } finally {
      hitTestResult = null;
      hitPosition = null;
    }
  }

  @override
  bool hitTestBoxChild({
    required RenderBox child,
    required Offset position,
    required Matrix4 transform,
    required bool checkBounds,
  }) {
    return BoxHitTestResult.wrap(hitTestResult!).addWithPaintTransform(
      transform: transform,
      position: position,
      hitTest: (result, position) {
        if (checkBounds && !(Offset.zero & child.size).contains(position)) {
          return false;
        }
        return child.hitTest(result, position: position);
      },
    );
  }

  @override
  bool hitTestSliverChild({
    required RenderSliver child,
    required Offset position,
    required Matrix4 transform,
    required bool checkBounds,
  }) {
    final sliverResult = _SliverBoxyHitTestResult.wrap(hitTestResult!);
    return sliverResult.addWithPaintTransform(
      transform: transform,
      position: position,
      hitTest: (result, position) {
        if (checkBounds && !(Offset.zero & child.hitTestSize).contains(position)) {
          return false;
        }
        final sliverPosition = wrapOffset(
          position,
          Size(
            child.constraints.crossAxisExtent,
            child.geometry!.layoutExtent,
          ).rotateWithAxis(child.constraints.axis),
        );
        return child.hitTest(
          SliverHitTestResult.wrap(result),
          crossAxisPosition: sliverPosition.cross,
          mainAxisPosition: sliverPosition.main,
        );
      },
    );
  }

  @override
  SliverSize wrapSize(Size size) {
    return SliverSize(size.width, size.height, constraints.axis);
  }

  @override
  SliverOffset wrapOffset(Offset offset, Size size) {
    double main;
    final double cross;
    var reversed = false;
    switch (constraints.axisDirection) {
      case AxisDirection.up:
        cross = offset.dx;
        main = offset.dy;
        reversed = true;
        break;
      case AxisDirection.down:
        cross = offset.dx;
        main = offset.dy;
        reversed = false;
        break;
      case AxisDirection.right:
        cross = offset.dy;
        main = offset.dx;
        reversed = false;
        break;
      case AxisDirection.left:
        cross = offset.dy;
        main = offset.dx;
        reversed = true;
        break;
    }
    if (constraints.growthDirection == GrowthDirection.reverse) {
      reversed = !reversed;
    }
    if (reversed) {
      switch (constraints.axis) {
        case Axis.horizontal:
          main = size.width - main;
          break;
        case Axis.vertical:
          main = size.height - main;
          break;
      }
    }
    return SliverOffset(offset.dx, offset.dy, cross, main);
  }

  @override
  Offset unwrapOffset(double cross, double main, Size size) {
    return constraints.unwrap(cross, main, size);
  }
}

/// A delegate that controls the layout and paint of child widgets, used by
/// [CustomBoxy].
abstract class SliverBoxyDelegate<LayoutData extends Object>
  extends BaseBoxyDelegate<LayoutData, BaseBoxyChild> {
  /// Constructs a BoxyDelegate with optional [relayout] and [repaint]
  /// [Listenable]s.
  SliverBoxyDelegate({
    Listenable? relayout,
    Listenable? repaint,
  }) : super(
    relayout: relayout,
    repaint: repaint,
  );

  @override
  RenderSliverBoxy<BaseBoxyChild> get render => super.render as RenderSliverBoxy<BaseBoxyChild>;

  /// The most recent constraints given to this boxy by its parent.
  @override
  SliverConstraints get constraints {
    return render.constraints;
  }

  /// Override this method to lay out children and return the final geometry of
  /// the boxy.
  ///
  /// This method should call [BaseBoxyChild.layout] for each child. It should
  /// also specify the position of each child with [BaseBoxyChild.position].
  SliverGeometry layout() {
    return const SliverGeometry();
  }

  @override
  void addHit() {
    hitTestResult.add(
      SliverHitTestEntry(
        render,
        crossAxisPosition: render.hitPosition!.cross,
        mainAxisPosition: render.hitPosition!.main,
      ),
    );
  }
}

typedef _HitTestCallback = bool Function(_SliverBoxyHitTestResult result, Offset position);

/// [SliverHitTestResult] is missing [BoxHitTestResult.addWithPaintTransform],
/// [HitTestResult.pushTransform] is also protected, oof.
class _SliverBoxyHitTestResult extends SliverHitTestResult {
  _SliverBoxyHitTestResult.wrap(HitTestResult result) : super.wrap(result);

  bool addWithRawTransform({
    required Matrix4? transform,
    required Offset position,
    required _HitTestCallback hitTest,
  }) {
    final Offset transformedPosition = transform == null ?
      position : MatrixUtils.transformPoint(transform, position);
    if (transform != null) {
      pushTransform(transform);
    }
    final bool isHit = hitTest(this, transformedPosition);
    if (transform != null) {
      popTransform();
    }
    return isHit;
  }

  bool addWithPaintTransform({
    required Matrix4? transform,
    required Offset position,
    required _HitTestCallback hitTest,
  }) {
    if (transform != null) {
      transform = Matrix4.tryInvert(PointerEvent.removePerspectiveTransform(transform));
      if (transform == null) {
        // Objects are not visible on screen and cannot be hit-tested.
        return false;
      }
    }
    return addWithRawTransform(
      transform: transform,
      position: position,
      hitTest: hitTest,
    );
  }
}