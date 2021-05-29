import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Extension on [BoxConstraints] that provides various axis-dependant utilities.
extension BoxConstraintsAxisUtil on BoxConstraints {
  /// Creates box constraints with the given constraints.
  static BoxConstraints create(Axis axis, {
    double minCross = 0.0,
    double maxCross = double.infinity,
    double minMain = 0.0,
    double maxMain = double.infinity,
  }) {
    return axis == Axis.vertical ?
      BoxConstraints(
        minWidth: minCross,
        maxWidth: maxCross,
        minHeight: minMain,
        maxHeight: maxMain,
      ) :
      BoxConstraints(
        minWidth: minMain,
        maxWidth: maxMain,
        minHeight: minCross,
        maxHeight: maxCross,
      );
  }

  /// Creates box constraints that expand to fill another box constraints.
  ///
  /// If [cross] or [main] is given, the constraints will require exactly the
  /// given value in the given dimension.SliverConstraintsUtil
  static BoxConstraints expand(Axis axis, {
    double? cross,
    double? main,
  }) {
    return axis == Axis.vertical ?
      BoxConstraints.expand(width: cross, height: main) :
      BoxConstraints.expand(width: main, height: cross);
  }

  /// Creates box constraints that require the given cross or main size.
  ///
  /// See also:
  ///
  ///  * [axisTightForFinite], which is similar but instead of being tight if
  ///    the value is non-null, is tight if the value is not infinite.
  static BoxConstraints tightFor(Axis axis, {
    double? cross,
    double? main,
  }) {
    return axis == Axis.vertical ?
      BoxConstraints.tightFor(width: cross, height: main) :
      BoxConstraints.tightFor(width: main, height: cross);
  }

  /// Creates box constraints that require the given cross or main size, except
  /// if they are infinite.
  ///
  /// See also:
  ///
  ///  * [axisTightFor], which is similar but instead of being tight if the
  ///    value is not infinite, is tight if the value is non-null.
  static BoxConstraints tightForFinite(Axis axis, {
    double cross = double.infinity,
    double main = double.infinity,
  }) {
    return axis == Axis.vertical ?
      BoxConstraints.tightForFinite(width: cross, height: main) :
      BoxConstraints.tightForFinite(width: main, height: cross);
  }

  /// Whether there is exactly one value that satisfies the constraints on the
  /// given axis.
  bool hasTightAxis(Axis axis) {
    return axis == Axis.vertical ? hasTightHeight : hasTightWidth;
  }

  /// Whether there is exactly one value that satisfies the constraints crossing
  /// the given axis.
  bool hasTightCrossAxis(Axis axis) {
    return axis == Axis.vertical ? hasTightWidth : hasTightHeight;
  }

  /// Whether there is an upper bound on the maximum extent of the given axis.
  bool hasBoundedAxis(Axis axis) {
    return axis == Axis.vertical ? hasBoundedHeight : hasBoundedWidth;
  }

  /// Whether there is an upper bound on the maximum extent crossing the given
  /// axis.
  bool hasBoundedCrossAxis(Axis axis) {
    return axis == Axis.vertical ? hasBoundedWidth : hasBoundedHeight;
  }

  /// Whether the constraint for the given axis is infinite.
  bool hasInfiniteAxis(Axis axis) {
    return axis == Axis.vertical ? hasInfiniteHeight : hasInfiniteWidth;
  }

  /// Whether the constraint crossing the given axis is infinite.
  bool hasInfiniteCrossAxis(Axis axis) {
    return axis == Axis.vertical ? hasInfiniteWidth : hasInfiniteHeight;
  }

  /// The maximum value that satisfies the constraints on the given axis.
  ///
  /// Might be [double.infinity].
  double maxAxis(Axis axis) {
    return axis == Axis.vertical ? maxHeight : maxWidth;
  }

  /// The minimum value that satisfies the constraints on the given axis.
  double minAxis(Axis axis) {
    return axis == Axis.vertical ? minHeight : minWidth;
  }

  /// The maximum value that satisfies the constraints crossing the given axis.
  ///
  /// Might be [double.infinity].
  double maxCrossAxis(Axis axis) {
    return axis == Axis.vertical ? maxWidth : maxHeight;
  }

  /// The minimum value that satisfies the constraints crossing the given axis.
  double minCrossAxis(Axis axis) {
    return axis == Axis.vertical ? minWidth : minHeight;
  }

  /// Returns new box constraints with a tight main and/or cross axes.
  BoxConstraints tightenAxis(Axis axis, {double? cross, double? main}) {
    return axis == Axis.vertical ?
      tighten(width: cross, height: main) :
      tighten(width: main, height: cross);
  }

  /// Returns the size that both satisfies the constraints and is as close as
  /// possible to the given cross and main size.
  ///
  /// When you already have a [Size], prefer [constrain], which applies the same
  /// algorithm to a [Size] directly.
  Size constrainAxisDimensions(Axis axis, double cross, double main) {
    return axis == Axis.vertical ?
      constrainDimensions(cross, main) :
      constrainDimensions(main, cross);
  }

  /// Returns the value that both satisfies the constraints and is as close as
  /// possible to the given extent on [axis].
  double constrainAxis(Axis axis, [double extent = double.infinity]) {
    return axis == Axis.vertical ?
      constrainHeight(extent) :
      constrainWidth(extent);
  }

  /// Returns the value that both satisfies the constraints and is as close as
  /// possible to the given extent crossing [axis].
  double constrainCrossAxis(Axis axis, [double extent = double.infinity]) {
    return axis == Axis.vertical ?
      constrainWidth(extent) :
      constrainHeight(extent);
  }

  /// Creates a copy of this box constraints but with the given fields replaced
  /// with the new values.
  BoxConstraints copyWithAxis(Axis axis, {
    double? minCross,
    double? maxCross,
    double? minMain,
    double? maxMain,
  }) {
    return axis == Axis.vertical ?
      copyWith(
        minWidth: minCross,
        maxWidth: maxCross,
        minHeight: minMain,
        maxHeight: maxMain,
      ) :
      copyWith(
        minWidth: minMain,
        maxWidth: maxMain,
        minHeight: minCross,
        maxHeight: maxCross,
      );
  }

  /// Returns box constraints with the same [axis] constraints but with
  /// an unconstrained cross axis.
  BoxConstraints axisConstraints(Axis axis) {
    return axis == Axis.vertical ?
    heightConstraints() : widthConstraints();
  }

  /// Returns box constraints with the same cross axis constraints but with
  /// an unconstrained main axis.
  BoxConstraints crossAxisConstraints(Axis axis) {
    return axis == Axis.vertical ?
      widthConstraints() : heightConstraints();
  }
}

/// Extension on [Axis] that provides various directional utilities.
extension AxisUtil on Axis {
  /// Gets the axis that this one crosses.
  Axis get cross => this == Axis.vertical ?
    Axis.horizontal : Axis.vertical;

  /// Gets the down or right [AxisDirection] of this axis.
  AxisDirection get direction => this == Axis.vertical ?
    AxisDirection.down : AxisDirection.right;

  /// Gets the down or right [AxisDirection] of the cross axis.
  AxisDirection get crossDirection => this == Axis.vertical ?
    AxisDirection.right : AxisDirection.down;
}

/// Extension on [VerticalDirection] that provides various directional utilities.
extension VerticalDirectionUtil on VerticalDirection {
  /// Gets the reverse of this direction.
  VerticalDirection get reversed => this == VerticalDirection.up ?
    VerticalDirection.down : VerticalDirection.up;

  /// Gets the up or down [AxisDirection] of this direction.
  AxisDirection get direction => this == VerticalDirection.up ?
    AxisDirection.up : AxisDirection.down;
}

/// Extension on [AxisDirection] that provides various directional utilities.
extension AxisDirectionUtil on AxisDirection {
  /// Gets the vertical or horizontal [Axis] of this direction.
  Axis get axis => this == AxisDirection.up || this == AxisDirection.down ?
    Axis.vertical : Axis.horizontal;

  /// Gets the vertical or horizontal cross [Axis] of this direction.
  Axis get crossAxis => this == AxisDirection.up || this == AxisDirection.down ?
    Axis.horizontal : Axis.vertical;

  /// Whether this direction is opposite of the forward direction of [axis].
  bool get isReverse => this == AxisDirection.up || this == AxisDirection.left;

  /// Whether this direction is the forward direction of [axis].
  bool get isForward => this == AxisDirection.down || this == AxisDirection.right;

  /// Gets the reverse of this direction.
  AxisDirection get reversed => const [
    AxisDirection.down, AxisDirection.left,
    AxisDirection.up, AxisDirection.right,
  ][index];

  /// Gets the direction counter-clockwise to this one.
  AxisDirection get ccw => const [
    AxisDirection.left, AxisDirection.up,
    AxisDirection.right, AxisDirection.down,
  ][index];

  /// Gets the direction clockwise to this one.
  AxisDirection get cw => const [
    AxisDirection.right, AxisDirection.down,
    AxisDirection.left, AxisDirection.up,
  ][index];

  /// Rotates this direction, where [AxisDirection.up] is the origin.
  AxisDirection operator+(AxisDirection direction) =>
    AxisDirection.values[(index + direction.index) % 4];

  /// Counter rotates this direction, where [AxisDirection.up] is the origin.
  AxisDirection operator-(AxisDirection direction) =>
    AxisDirection.values[(index - direction.index) % 4];
}

/// Extension on [RenderBox] that provides various directional utilities.
extension RenderBoxAxisUtil on RenderBox {
  /// Returns the minimum extent on [axis] that this box could be without
  /// failing to correctly paint its contents within itself, without clipping.
  double getMinIntrinsicAxis(Axis axis, double cross) {
    return axis == Axis.vertical ?
      getMinIntrinsicHeight(cross) :
      getMinIntrinsicWidth(cross);
  }

  /// Returns the minimum extent crossing [axis] that this box could be without
  /// failing to correctly paint its contents within itself, without clipping.
  double getMinIntrinsicCrossAxis(Axis axis, double main) {
    return axis == Axis.vertical ?
      getMinIntrinsicWidth(main) :
      getMinIntrinsicHeight(main);
  }

  /// Returns the smallest extent on [axis] beyond which increasing the extent
  /// never decreases the preferred cross extent. The preferred cross extent is
  /// the value that would be returned by [getMinIntrinsicCrossAxis] for that
  /// main extent.
  double getMaxIntrinsicAxis(Axis axis, double cross) {
    return axis == Axis.vertical ?
      getMaxIntrinsicHeight(cross) :
      getMaxIntrinsicWidth(cross);
  }

  /// Returns the smallest cross extent on [axis] beyond which increasing the
  /// cross extent never decreases the preferred main extent. The preferred main
  /// extent is the value that would be returned by [getMinIntrinsicAxis] for
  /// that cross extent.
  double getMaxIntrinsicCrossAxis(Axis axis, double main) {
    return axis == Axis.vertical ?
      getMaxIntrinsicWidth(main) :
      getMaxIntrinsicHeight(main);
  }
}

/// Extension on [Offset] that provides various directional utilities.
extension OffsetAxisUtil on Offset {
  /// Creates an offset with the specified [cross] and [main] components.
  static Offset create(Axis axis, double cross, double main) {
    return axis == Axis.vertical ?
      Offset(cross, main) :
      Offset(main, cross);
  }

  /// Creates an offset where [main] is the extent on [direction] and [cross]
  /// is the extent counter-clockwise to [direction].
  static Offset direction(AxisDirection direction, double cross, double main) {
    if (direction == AxisDirection.up) return Offset(cross, -main);
    else if (direction == AxisDirection.right) return Offset(main, -cross);
    else if (direction == AxisDirection.down) return Offset(cross, main);
    else return Offset(-main, cross);
  }

  /// Gets the component of this offset on [axis].
  double axisOffset(Axis axis) {
    return axis == Axis.vertical ? dy : dx;
  }

  /// Gets the component of this offset crossing [axis].
  double crossAxisOffset(Axis axis) {
    return axis == Axis.vertical ? dx : dy;
  }

  /// Returns the extent from origin towards [direction].
  double directionExtent(AxisDirection direction) {
    if (direction == AxisDirection.up) return -dy;
    else if (direction == AxisDirection.right) return dx;
    else if (direction == AxisDirection.down) return dy;
    else return -dx;
  }

  /// Rotates this offset with [axis] where `dx` becomes the cross axis extent
  /// and `dy` becomes the main axis extent.
  Offset rotateWithAxis(Axis axis) {
    return axis == Axis.vertical ? this : Offset(dy, dx);
  }

  /// Rotates this offset with [crossAxis] where `dx` becomes the cross axis
  /// extent and `dy` becomes the main axis extent.
  Offset rotateWithCrossAxis(Axis crossAxis) {
    return crossAxis == Axis.horizontal ? this : Offset(dy, dx);
  }
}

/// Extension on [Size] that provides various directional utilities.
extension SizeAxisUtil on Size {
  /// Creates a [Size] with the given [cross] and [main] extents.
  static Size create(Axis axis, double cross, double main) {
    return axis == Axis.vertical ?
      Size(cross, main) :
      Size(main, cross);
  }

  /// Creates a [Size] with the given main axis [extent] and an infinite cross
  /// axis extent.
  static Size from(Axis axis, double extent) {
    return axis == Axis.vertical ?
      Size(double.infinity, extent) :
      Size(extent, double.infinity);
  }

  /// Creates a [Size] with the given cross axis [extent] and an infinite main
  /// axis extent.
  static Size crossFrom(Axis axis, double extent) {
    return axis == Axis.vertical ?
      Size(extent, double.infinity) :
      Size(double.infinity, extent);
  }

  /// Gets the extent of this size on the given axis.
  double axisSize(Axis axis) {
    return axis == Axis.vertical ? height : width;
  }

  /// Gets the extent of this size crossing the given axis.
  double crossAxisSize(Axis axis) {
    return axis == Axis.vertical ? width : height;
  }

  /// Rotates this size with [axis] where `width` becomes the cross axis extent
  /// and `height` becomes the main axis extent.
  Size rotateWithAxis(Axis axis) {
    return axis == Axis.vertical ? this : Size(height, width);
  }

  /// Rotates this size with [crossAxis] where `width` becomes the cross axis
  /// extent and `height` becomes the main axis extent.
  Size rotateWithCrossAxis(Axis crossAxis) {
    return crossAxis == Axis.horizontal ? this : Size(height, width);
  }
}

/// Extension on [EdgeInsets] that provides various directional utilities.
extension EdgeInsetsAxisUtil on EdgeInsets {
  /// Creates edge insets given the begin and end extents on the given axis.
  static EdgeInsets create(Axis axis, {
    double mainBegin = 0.0, double mainEnd = 0.0,
    double crossBegin = 0.0, double crossEnd = 0.0,
  }) {
    if (axis == Axis.vertical) {
      return EdgeInsets.only(
        top: mainBegin,
        bottom: mainEnd,
        left: crossBegin,
        right: crossEnd,
      );
    } else {
      return EdgeInsets.only(
        left: mainBegin,
        right: mainEnd,
        top: crossBegin,
        bottom: crossEnd,
      );
    }
  }

  /// Creates symmetric edge insets on the given axis.
  static EdgeInsets symmetric(Axis axis, {
    double main = 0.0, double cross = 0.0,
  }) {
    if (axis == Axis.vertical) {
      return EdgeInsets.symmetric(
        vertical: main,
        horizontal: cross,
      );
    } else {
      return EdgeInsets.symmetric(
        horizontal: main,
        vertical: cross,
      );
    }
  }

  /// Creates edge insets towards [direction].
  static EdgeInsets direction(AxisDirection direction, {
    double mainBegin = 0.0, double mainEnd = 0.0,
    double crossBegin = 0.0, double crossEnd = 0.0,
  }) {
    if (direction == AxisDirection.up) {
      return EdgeInsets.only(
        bottom: mainBegin,
        top: mainEnd,
        right: crossBegin,
        left: crossEnd,
      );
    } else if (direction == AxisDirection.right) {
      return EdgeInsets.only(
        left: mainBegin,
        right: mainEnd,
        top: crossBegin,
        bottom: crossEnd,
      );
    } else if (direction == AxisDirection.down) {
      return EdgeInsets.only(
        top: mainBegin,
        bottom: mainEnd,
        left: crossBegin,
        right: crossEnd,
      );
    } else {
      return EdgeInsets.only(
        right: mainBegin,
        left: mainEnd,
        bottom: crossBegin,
        top: crossEnd,
      );
    }
  }

  /// Gets the extent of the inset facing [direction].
  double directionExtent(AxisDirection direction) {
    if (direction == AxisDirection.up) return top;
    else if (direction == AxisDirection.right) return right;
    else if (direction == AxisDirection.down) return bottom;
    else return left;
  }
}

/// A box with a specified size.
///
/// Identical to [SizedBox] but sizes its child based on the cross and main
/// dimensions on the specified axis.
class AxisSizedBox extends SizedBox {
  /// Creates a fixed size box. The [cross] and [main] parameters can be null
  /// to indicate that the size of the box should not be constrained in
  /// the corresponding dimension.
  const AxisSizedBox({
    Key? key,
    required Axis axis,
    double? cross,
    double? main,
  }) : super(
    key: key,
    width: axis == Axis.vertical ? cross : main,
    height: axis == Axis.vertical ? main : cross,
  );
}