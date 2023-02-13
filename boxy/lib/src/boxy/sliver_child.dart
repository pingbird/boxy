import 'package:flutter/rendering.dart';

import '../axis_utils.dart';
import '../sliver_offset.dart';
import 'custom_boxy_base.dart';
import 'inflating_element.dart';

/// An error that indicates [SliverBoxyChild.layout] was called during a dry
/// layout.
///
/// Slivers in Flutter do not support dry layouts, so it is not possible to lay
/// them out during a dry layout pass.
class CannotLayoutSliverError extends FlutterError {
  /// The delegate that caused the error.
  final BaseBoxyDelegate delegate;

  /// The RenderObject associated with the delegate.
  final RenderBoxyMixin<RenderObject, BaseBoxyParentData, BaseBoxyChild> render;

  /// The child that the delegate tried to lay out.
  final BaseBoxyChild child;

  /// Constructs an inflation error given the delegate and RenderObject.
  CannotLayoutSliverError({
    required this.delegate,
    required this.render,
    required this.child,
  }) : super.fromParts([
          ErrorSummary(
              'The $delegate boxy attempted to lay out a sliver during a dry layout.'),
          ErrorDescription(
            'Slivers in Flutter do not support dry layouts, so it is not possible to '
            'lay them out during a dry layout pass.',
          ),
          ErrorDescription(
            "If your boxy's size does not depend on the size of the sliver you "
            'can skip calling layout when `isDryLayout` is true.',
          ),
        ]);
}

/// The [ParentData] used for [RenderSliver] children of [CustomBoxy].
///
/// See also:
///   * [BoxyParentData]
class SliverBoxyParentData extends BaseBoxyParentData<RenderSliver> {}

/// A handle used by [CustomBoxy] widgets to change how it lays out, paints, and
/// hit tests its children.
///
/// This class should not be instantiated directly, instead access children with
/// [BoxyDelegate.getChild].
///
/// See also:
///
///  * [BoxyChild]
class SliverBoxyChild extends BaseBoxyChild {
  /// Constructs a child associated with a parent [InflatingRenderObjectMixin],
  /// this should not be used directly, instead access one with
  /// [BoxyDelegate.getChild].
  SliverBoxyChild({
    required super.id,
    required super.parent,
    RenderSliver? super.render,
    super.context,
    super.widget,
  });

  /// The [RenderBox] representing this child.
  ///
  /// This getter is useful to access properties and methods that the child
  /// handle does not provide.
  ///
  /// Be mindful of using this without checking [BoxyDelegate.isDryLayout]
  /// first, confusing errors can occur in debug mode as the framework
  /// continuously validates dry and intrinsic layouts.
  @override
  RenderSliver get render => super.render as RenderSliver;

  RenderBoxyMixin get _parent {
    return render.parent! as RenderBoxyMixin;
  }

  /// Describes the amount of space occupied by a [RenderSliver].
  SliverGeometry get geometry => render.geometry!;

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
  SliverSize get size {
    final constraints = render.constraints;
    return _parent.wrapSize(Size(
      constraints.crossAxisExtent,
      geometry.layoutExtent,
    ).rotateWithAxis(constraints.axis));
  }

  /// Lays out the child with the specified constraints and returns its
  /// geometry.
  ///
  /// If [useSize] is true or absent, this boxy will re-layout when the child
  /// changes size.
  ///
  /// This method should only be called inside [BoxyDelegate.layout].
  SliverGeometry layout(SliverConstraints constraints, {bool useSize = true}) {
    if (_parent.isDryLayout) {
      _parent.debugThrowLayout(
        CannotLayoutSliverError(
          delegate: _parent.delegate,
          render: _parent,
          child: this,
        ),
      );
    }

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

    render.layout(constraints, parentUsesSize: useSize);

    return render.geometry!;
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

    return _parent.hitTestSliverChild(
      child: render,
      position: position ?? _parent.hitPosition!,
      transform: transform ?? this.transform,
      checkBounds: checkBounds,
    );
  }
}
