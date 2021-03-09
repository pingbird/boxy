// @dart=2.9

import 'package:boxy/src/sliver_container.dart';
import 'package:flutter/material.dart';

/// A sliver container that makes its child look like its inside of a [Card].
///
/// To clip the child, add `clipBehavior: Clip.antiAlias`.
///
/// See also:
///
///  * [SliverContainer], the sliver this is based on.
class SliverCard extends StatelessWidget {
  /// The color of this card.
  final Color color;

  /// The color the cards shadow will cast.
  final Color shadowColor;

  /// The elevation of this card.
  final double elevation;

  /// The shape of this card's material.
  final ShapeBorder shape;

  /// The clip behavior this child will apply to its child, defaults to none.
  final Clip clipBehavior;

  /// The padding to apply around the card.
  final EdgeInsetsGeometry margin;

  /// The sliver child of this card.
  final Widget sliver;

  /// How far the card will extend off-screen when parts of [sliver] are not
  /// visible, this should be at least the size of any border effects.
  final double bufferExtent;

  /// Creates a SliverCard.
  const SliverCard({
    Key key,
    this.color,
    this.shadowColor,
    this.elevation,
    this.shape,
    this.margin,
    this.clipBehavior,
    this.sliver,
    this.bufferExtent,
  }) : super(key: key);

  @override
  Widget build(context) {
    final textDirection = Directionality.of(context);
    final cardTheme = CardTheme.of(context);
    final appliedClip = clipBehavior ?? cardTheme.clipBehavior ?? Clip.none;
    final appliedMargin = (
      margin ?? cardTheme.margin ?? const EdgeInsets.all(4.0)
    ).resolve(textDirection);
    final appliedShape = shape ?? cardTheme.shape ?? const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
    );
    final appliedBufferExtent = bufferExtent ?? 12.0;

    final card = Material(
      type: MaterialType.card,
      shadowColor: shadowColor ?? cardTheme.shadowColor ?? Colors.black,
      color: color ?? cardTheme.color ?? Theme.of(context).cardColor,
      elevation: elevation ?? cardTheme.elevation ?? 1.0,
      shape: appliedShape,
    );

    return SliverContainer(
      bufferExtent: appliedBufferExtent,
      sliver: sliver,
      background: card,
      margin: appliedMargin,
      clipper: appliedClip == Clip.none ? null : ShapeBorderClipper(shape: appliedShape),
      clipSliverOnly: true,
    );
  }
}