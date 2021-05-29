import 'package:flutter/rendering.dart';

/// Extension on [SliverConstraints] that provides various utilities.
extension SliverConstraintsUtil on SliverConstraints {
  /// Whether or not growth happens on the forward direction of [axis].
  bool get growsForward => normalizedGrowthDirection == GrowthDirection.forward;

  /// Whether or not growth happens on the reverse direction of [axis].
  bool get growsReverse => normalizedGrowthDirection == GrowthDirection.reverse;

  /// Returns the relative offset given a cross position, main position, and
  /// size.
  SliverOffset unwrap(double cross, double main, Size size) {
    switch (axis) {
      case Axis.horizontal:
        if (growsReverse) {
          main = size.width - main;
        }
        return SliverOffset(main, cross, cross, main);
      case Axis.vertical:
        if (growsReverse) {
          main = size.height - main;
        }
        return SliverOffset(cross, main, cross, main);
    }
  }

  /// Returns the sliver offset given a regular offset and size.
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

  /// Computes the portion of the region from `from` to `to` that is visible.
  ///
  /// This method is identical to [RenderSliver.calculatePaintOffset].
  double paintOffset(double from, double to) {
    assert(from <= to);
    final minOffset = scrollOffset;
    final maxOffset = scrollOffset + remainingPaintExtent;
    from = from.clamp(minOffset, maxOffset);
    to = to.clamp(minOffset, maxOffset);
    return (to - from).clamp(0.0, remainingPaintExtent);
  }

  /// Computes the portion of the region from `from` to `to` that is within
  /// the cache extent of the viewport.
  ///
  /// This method is identical to [RenderSliver.calculateCacheOffset].
  double cacheOffset(double from, double to) {
    assert(from <= to);
    final minOffset = scrollOffset + cacheOrigin;
    final maxOffset = scrollOffset + remainingCacheExtent;
    from = from.clamp(minOffset, maxOffset);
    to = to.clamp(minOffset, maxOffset);
    // the clamp on the next line is to avoid floating point rounding errors
    return (to - from).clamp(0.0, remainingCacheExtent);
  }
}

/// Extension on [RenderSliver] that provides various utilities.
extension RenderSliverUtil on RenderSliver {
  /// The current layout size of this sliver.
  SliverSize get layoutSize => SliverSize.axis(
    constraints.crossAxisExtent,
    geometry!.layoutExtent,
    constraints.axis,
  );

  /// The current hit testing size of this sliver.
  SliverSize get hitTestSize => SliverSize.axis(
    constraints.crossAxisExtent,
    geometry!.hitTestExtent,
    constraints.axis,
  );
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