import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A padding widget similar to [Padding] but allows the child to overflow when
/// given negative insets.
///
/// This widget will consume the size of the child plus padding, allowing the
/// child to paint past the amount of space the [OverflowPadding] consumes.
///
/// The following example removes 16 units of padding from a child on the right:
///
/// ```dart
/// OverflowPadding(
///   padding: EdgeInsets.only(right: -16),
///   child: ...
/// )
/// ```
class OverflowPadding extends SingleChildRenderObjectWidget {
  /// Creates a widget that insets its child.
  ///
  /// The [padding] argument must not be null.
  const OverflowPadding({
    super.key,
    required this.padding,
    super.child,
  });

  /// The amount of space by which to inset the child.
  final EdgeInsetsGeometry padding;

  @override
  RenderOverflowPadding createRenderObject(BuildContext context) {
    return RenderOverflowPadding(
      padding: padding,
      textDirection: Directionality.maybeOf(context),
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderOverflowPadding renderObject) {
    renderObject
      ..padding = padding
      ..textDirection = Directionality.maybeOf(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding));
  }
}

/// Insets its child by the given padding, potentially allowing it to overflow
/// if they are negative.
///
/// This will consume the size of the child plus padding, allowing the
/// child to paint past the amount of space the [RenderOverflowPadding] consumes.
class RenderOverflowPadding extends RenderShiftedBox {
  /// Creates a render object that insets its child.
  ///
  /// The [padding] argument must not be null.
  RenderOverflowPadding({
    required EdgeInsetsGeometry padding,
    TextDirection? textDirection,
    RenderBox? child,
  })  : _textDirection = textDirection,
        _padding = padding,
        super(child);

  EdgeInsets? _resolvedPadding;

  void _resolve() {
    if (_resolvedPadding != null) {
      return;
    }
    _resolvedPadding = padding.resolve(textDirection);
  }

  void _markNeedResolution() {
    _resolvedPadding = null;
    markNeedsLayout();
  }

  /// The amount to pad the child in each dimension.
  ///
  /// If this is set to an [EdgeInsetsDirectional] object, then [textDirection]
  /// must not be null.
  EdgeInsetsGeometry get padding => _padding;
  EdgeInsetsGeometry _padding;
  set padding(EdgeInsetsGeometry value) {
    if (_padding == value) {
      return;
    }
    _padding = value;
    _markNeedResolution();
  }

  /// The text direction with which to resolve [padding].
  ///
  /// This may be changed to null, but only after the [padding] has been changed
  /// to a value that does not depend on the direction.
  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    _markNeedResolution();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    _resolve();
    final double totalHorizontalPadding =
        _resolvedPadding!.left + _resolvedPadding!.right;
    final double totalVerticalPadding =
        _resolvedPadding!.top + _resolvedPadding!.bottom;
    if (child != null) {
      return child!.getMinIntrinsicWidth(
              math.max(0.0, height - totalVerticalPadding)) +
          totalHorizontalPadding;
    }
    return totalHorizontalPadding;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    _resolve();
    final double totalHorizontalPadding =
        _resolvedPadding!.left + _resolvedPadding!.right;
    final double totalVerticalPadding =
        _resolvedPadding!.top + _resolvedPadding!.bottom;
    if (child != null) {
      return child!.getMaxIntrinsicWidth(
              math.max(0.0, height - totalVerticalPadding)) +
          totalHorizontalPadding;
    }
    return totalHorizontalPadding;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    _resolve();
    final double totalHorizontalPadding =
        _resolvedPadding!.left + _resolvedPadding!.right;
    final double totalVerticalPadding =
        _resolvedPadding!.top + _resolvedPadding!.bottom;
    if (child != null) {
      return child!.getMinIntrinsicHeight(
              math.max(0.0, width - totalHorizontalPadding)) +
          totalVerticalPadding;
    }
    return totalVerticalPadding;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    _resolve();
    final double totalHorizontalPadding =
        _resolvedPadding!.left + _resolvedPadding!.right;
    final double totalVerticalPadding =
        _resolvedPadding!.top + _resolvedPadding!.bottom;
    if (child != null) {
      return child!.getMaxIntrinsicHeight(
              math.max(0.0, width - totalHorizontalPadding)) +
          totalVerticalPadding;
    }
    return totalVerticalPadding;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    _resolve();
    assert(_resolvedPadding != null);
    if (child == null) {
      return constraints.constrain(Size(
        _resolvedPadding!.left + _resolvedPadding!.right,
        _resolvedPadding!.top + _resolvedPadding!.bottom,
      ));
    }
    final BoxConstraints innerConstraints =
        constraints.deflate(_resolvedPadding!);
    final Size childSize = child!.getDryLayout(innerConstraints);
    return constraints.constrain(Size(
      _resolvedPadding!.left + childSize.width + _resolvedPadding!.right,
      _resolvedPadding!.top + childSize.height + _resolvedPadding!.bottom,
    ));
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    _resolve();
    assert(_resolvedPadding != null);
    if (child == null) {
      size = constraints.constrain(Size(
        _resolvedPadding!.left + _resolvedPadding!.right,
        _resolvedPadding!.top + _resolvedPadding!.bottom,
      ));
      return;
    }
    final BoxConstraints innerConstraints =
        constraints.deflate(_resolvedPadding!);
    child!.layout(innerConstraints, parentUsesSize: true);
    final BoxParentData childParentData = child!.parentData! as BoxParentData;
    childParentData.offset =
        Offset(_resolvedPadding!.left, _resolvedPadding!.top);
    size = constraints.constrain(Size(
      _resolvedPadding!.left + child!.size.width + _resolvedPadding!.right,
      _resolvedPadding!.top + child!.size.height + _resolvedPadding!.bottom,
    ));
  }

  @override
  void debugPaintSize(PaintingContext context, Offset offset) {
    super.debugPaintSize(context, offset);
    assert(() {
      final Rect outerRect = offset & size;
      debugPaintPadding(context.canvas, outerRect,
          child != null ? _resolvedPadding!.deflateRect(outerRect) : null);
      return true;
    }());
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
        defaultValue: null));
  }
}
