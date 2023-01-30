import 'package:flutter/rendering.dart';
import 'sliver_offset.dart';

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
