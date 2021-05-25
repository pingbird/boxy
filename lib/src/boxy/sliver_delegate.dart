import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../axis_utils.dart';
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

  @override
  bool get isDryLayout => false;

  @override
  bool hitTest(
    SliverHitTestResult result, {
    required double crossAxisPosition,
    required double mainAxisPosition,
  }) {
    hitTestResult = result;
    paintOffset = Offset(crossAxisPosition, mainAxisPosition);
    try {
      return wrapPhase(BoxyDelegatePhase.hitTest, () {
        return delegate.hitTest(
          Offset(
            crossAxisPosition,
            mainAxisPosition,
          ).rotateWithAxis(constraints.axis),
        );
      });
    } finally {
      hitTestResult = null;
      paintOffset = null;
    }
  }

  @override
  bool hitTestBoxChild({required RenderBox child, required Offset position, required Matrix4 transform}) {
    return hitTestResult!.addWithAxisOffset(
      transform: transform,
      position: position,
      hitTest: (result, position) {
        return child.hitTest(result, position: position);
      },
    );
  }

  @override
  bool hitTestSliverChild({required RenderSliver child, required Offset position, required Matrix4 transform}) {
    position = position.rotateWithAxis(child.constraints.axis);
    return hitTestResult!.addWithPaintTransform(
      transform: transform,
      position: position,
      hitTest: (result, position) {
        return child.hitTest(
          SliverHitTestResult.wrap(result),
          crossAxisPosition: position.dx,
          mainAxisPosition: position.dy,
        );
      },
    );
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

  SliverGeometry layout() {
    return const SliverGeometry();
  }

  @override
  void addHit() {
    hitTestResult.add(
      SliverHitTestEntry(
        render,
        crossAxisPosition: render.paintOffset!.dx,
        mainAxisPosition: render.paintOffset!.dy,
      ),
    );
  }
}