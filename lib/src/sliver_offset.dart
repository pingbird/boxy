import 'package:flutter/rendering.dart';

/// Subclass of [Offset] that is also aware of its main and cross axis extent.
class SliverOffset extends Offset {
  /// The cross axis position of this offset.
  final double cross;

  /// The main axis position of this offset.
  final double main;

  /// Creates an offset with cross and main extents.
  const SliverOffset(double dx, double dy, this.cross, this.main)
    : super(dx, dy);

  /// Creates an offset with cross and main extents.
  SliverOffset.from(Offset offset, {Axis axis = Axis.vertical})
    : cross = axis == Axis.vertical ? offset.dx : offset.dy,
      main = axis == Axis.vertical ? offset.dy : offset.dx,
      super(offset.dx, offset.dy);
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