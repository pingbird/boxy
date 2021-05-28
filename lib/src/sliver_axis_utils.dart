import 'package:flutter/rendering.dart';

/// Extension on [SliverConstraints] that provides various utilities.
extension SliverConstraintsUtil on SliverConstraints {
  /// Whether or not growth happens on the forward direction of [axis].
  bool get growsForward => normalizedGrowthDirection == GrowthDirection.forward;

  /// Whether or not growth happens on the reverse direction of [axis].
  bool get growsReverse => normalizedGrowthDirection == GrowthDirection.reverse;

  /// Returns the relative offset given a cross position, main position, and
  /// size.
  Offset unwrap(double cross, double main, Size size) {
    switch (axis) {
      case Axis.horizontal:
        if (growsReverse) {
          main = size.width - main;
        }
        return Offset(main, cross);
      case Axis.vertical:
        if (growsReverse) {
          main = size.height - main;
        }
        return Offset(cross, main);
    }
  }

  /// Returns the sliver offset given a regular offset, and size where `dx`
  /// becomes the cross axis position and `dy` becomes the main axis position.
  SliverOffset wrap(Offset offset, Size size) {
    switch (axis) {
      case Axis.horizontal:
        final main = growsReverse ? size.width - offset.dx : offset.dx;
        return SliverOffset(offset.dx, offset.dy, offset.dx, main);
      case Axis.vertical:
        final main = growsReverse ? size.height - offset.dy : offset.dy;
        return SliverOffset(offset.dx, offset.dy, offset.dy, main);
    }
  }
}

/// Subclass of [Offset] that is also aware of its main and cross axis extent.
class SliverOffset extends Offset {
  /// The cross axis position of this offset.
  final double cross;

  /// The main axis position of this offset.
  final double main;

  /// Creates an offset with cross and main extents.
  const SliverOffset(double dx, double dy, this.cross, this.main)
    : super(dx, dy);
}

/// Subclass of [Size] that is also aware of its main and cross axis extent.
class SliverSize extends Size {
  /// An empty size, one with a zero width and a zero height.
  static const zero = SliverSize(0.0, 0.0, Axis.vertical);

  /// The axis of this size.
  final Axis axis;

  /// Creates a size with a width, height, and axis.
  const SliverSize(double width, double height, this.axis)
    : super(width, height);

  /// Creates a size with cross and main extents.
  const SliverSize.axis(double cross, double main, this.axis)
    : super(
      axis == Axis.vertical ? cross : main,
      axis == Axis.vertical ? main : cross,
    );

  /// The cross axis extent of this size.
  double get cross => axis == Axis.vertical ? width : height;

  /// The main axis extent of this size.
  double get main => axis == Axis.vertical ? height : width;
}