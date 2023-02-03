import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../sliver_offset.dart';
import 'custom_boxy_base.dart';
import 'inflating_element.dart';

/// The [ParentData] used for [RenderBox] children of [CustomBoxy].
///
/// An unfortunate design decision made on the first release was using
/// the [LayoutId] widget to identify children of the boxy, similar to
/// [CustomMultiChildLayout]. The issue with using [LayoutId] is that it
/// requires the child to have [MultiChildLayoutParentData] which extends
/// [ContainerBoxParentData]<[RenderBox]>, preventing the child from being a
/// [RenderSliver].
///
/// To mitigate this issue we now implement [MultiChildLayoutParentData] on only
/// the [RenderBox] parentData, and recommend users use [BoxyId] instead of
/// [LayoutId].
///
/// Until [LayoutId] support is removed from boxy, the library will fail to
/// compile if/when [MultiChildLayoutParentData] adds any new methods :(
class BoxyParentData extends BaseBoxyParentData<RenderBox>
    implements MultiChildLayoutParentData {}

/// A handle used by [CustomBoxy] widgets to change how it lays out, paints, and
/// hit tests its children.
///
/// This class should not be instantiated directly, instead access children with
/// [BoxyDelegate.getChild].
///
/// See also:
///
///  * [CustomBoxy]
///  * [BoxyDelegate]
class BoxyChild extends BaseBoxyChild {
  /// Constructs a child associated with a parent [InflatingRenderObjectMixin],
  /// this should not be used directly, instead access one with
  /// [BoxyDelegate.getChild].
  BoxyChild({
    required Object id,
    required InflatingRenderObjectMixin parent,
    RenderBox? render,
    Widget? widget,
    Element? context,
  }) : super(
          id: id,
          parent: parent,
          render: render,
          widget: widget,
          context: context,
        );

  /// The [RenderBox] representing this child.
  ///
  /// This getter is useful to access properties and methods that the child
  /// handle does not provide.
  ///
  /// Be mindful of using this without checking [BoxyDelegate.isDryLayout]
  /// first, confusing errors can occur in debug mode as the framework
  /// continuously validates dry and intrinsic layouts.
  @override
  RenderBox get render => super.render as RenderBox;

  BoxyParentData get _parentData => render.parentData! as BoxyParentData;

  RenderBoxyMixin get _parent => render.parent! as RenderBoxyMixin;

  /// The size of this child, should only be accessed after calling [layout].
  ///
  /// During a dry layout this represents the last size calculated by [layout],
  /// not the child's actual size.
  ///
  /// See also:
  ///
  ///  * [offset]
  ///  * [rect]
  @override
  SliverSize get size => _parent.wrapSize(_parentData.drySize ?? render.size);

  /// Lays out the child with the specified constraints and returns its size.
  ///
  /// This method should only be called inside [BoxyDelegate.layout].
  ///
  /// See also:
  ///
  ///  * [layoutWithoutSize], which is more efficient if you don't need the
  ///    child's size.
  ///  * [layoutRect], which positions the child so that it fits in a rect.
  ///  * [layoutFit], which positions and scales the child given a [BoxFit].
  SliverSize layout(BoxConstraints constraints) {
    if (_parent.isDryLayout) {
      if (_parentData.drySize != null) {
        throw FlutterError(
            'The ${_parent.delegate} boxy delegate tried to lay out the child with id "$id" more than once.\n'
            'Each child must be laid out exactly once.');
      }
      _parentData.drySize = render.getDryLayout(constraints);
      return _parent.wrapSize(_parentData.drySize!);
    }

    _checkConstraints(constraints);

    render.layout(constraints, parentUsesSize: true);

    return _parent.wrapSize(render.size);
  }

  /// Like [layout] but does not return the child's size, this is usually more
  /// efficient because the boxy doesn't need to be laid out when the child's
  /// size changes.
  ///
  /// If [useSize] is true, this boxy will re-layout when the child changes
  /// size regardless.
  ///
  /// See also:
  ///
  ///  * [layout], which does the same but returns a size.
  ///  * [layoutRect], which positions the child so that it fits in a rect.
  ///  * [layoutFit], which positions and scales the child given a [BoxFit].
  void layoutWithoutSize(BoxConstraints constraints, {bool useSize = false}) {
    if (_parent.isDryLayout) {
      // Do nothing since the delegate doesn't need a size.
      return;
    }
    _checkConstraints(constraints);
    render.layout(constraints);
  }

  void _checkConstraints(BoxConstraints constraints) {
    assert(() {
      if (_parent.debugPhase != BoxyDelegatePhase.layout) {
        throw FlutterError(
            'The ${_parent.delegate} boxy delegate tried to lay out a child outside of the layout method.\n');
      }

      if (!_parent.debugChildrenNeedingLayout.remove(id)) {
        throw FlutterError(
            'The ${_parent.delegate} boxy delegate tried to lay out the child with id "$id" more than once.\n'
            'Each child must be laid out exactly once.');
      }

      try {
        assert(constraints.debugAssertIsValid(isAppliedConstraint: true));
      } on AssertionError catch (exception) {
        throw FlutterError(
            'The ${_parent.delegate} boxy delegate provided invalid box constraints for the child with id "$id".\n'
            '$exception\n'
            'The minimum width and height must be greater than or equal to zero.\n'
            'The maximum width must be greater than or equal to the minimum width.\n'
            'The maximum height must be greater than or equal to the minimum height.');
      }

      return true;
    }());
  }

  /// Lays out and positions the child so that it fits in [rect].
  ///
  /// If the [alignment] argument is provided, the child is loosely constrained
  /// and aligned into [rect], otherwise it is tightly constrained.
  ///
  /// See also:
  ///
  ///  * [layout], which lays out the child given raw [BoxConstraints].
  ///  * [layoutFit], which positions and scales the child given a [BoxFit].
  void layoutRect(Rect rect, {Alignment? alignment, bool useSize = true}) {
    if (alignment != null) {
      final size = layout(BoxConstraints.loose(rect.size));
      position(alignment.inscribe(size, rect).topLeft);
    } else {
      layoutWithoutSize(BoxConstraints.tight(rect.size), useSize: useSize);
      position(rect.topLeft);
    }
  }

  /// Lays out, positions, and scales the child so that it fits in [rect]
  /// provided a [fit] and [alignment].
  ///
  ///  * [BoxFit], the enum with each possible fit type.
  ///  * [FittedBox], a widget that has similar behavior.
  ///  * [layout], which lays out the child given raw [BoxConstraints].
  ///  * [layoutRect], which positions the child so that it fits in a rect.
  void layoutFit(
    Rect rect, {
    BoxFit fit = BoxFit.contain,
    Alignment alignment = Alignment.center,
  }) {
    final childSize = layout(const BoxConstraints());
    final sizes = applyBoxFit(fit, childSize, rect.size);
    final scaleX = sizes.destination.width / sizes.source.width;
    final scaleY = sizes.destination.height / sizes.source.height;
    final sourceRect =
        alignment.inscribe(sizes.source, Offset.zero & childSize);
    final destinationRect = alignment.inscribe(sizes.destination, rect);

    setTransform(
      Matrix4.translationValues(destinationRect.left, destinationRect.top, 0.0)
        ..scale(scaleX, scaleY, 1.0)
        ..translate(-sourceRect.left, -sourceRect.top),
    );
  }

  @override
  bool hitTest({
    Matrix4? transform,
    Offset? offset,
    Offset? position,
    bool checkBounds = true,
  }) {
    if (isIgnored) {
      return false;
    }

    if (offset != null) {
      assert(transform == null,
          'BoxyChild.hitTest only expects either transform or offset to be provided');
      transform = Matrix4.translationValues(offset.dx, offset.dy, 0.0);
    }

    return _parent.hitTestBoxChild(
      child: render,
      position: position ?? _parent.hitPosition!,
      transform: transform ?? this.transform,
      checkBounds: checkBounds,
    );
  }
}
