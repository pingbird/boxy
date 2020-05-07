import 'dart:math';

import 'package:boxy/src/sliver_container.dart';
import 'package:flutter/material.dart';

/// A sliver container that makes its child look like its inside of a [Card].
///
/// To clip the child, add `clipBehavior: Clip.antiAlias`.
///
/// See also:
///
///   [SliverContainer], the sliver this is based on.
class SliverCard extends StatelessWidget {
  final Color color;
  final Color shadowColor;
  final double elevation;
  final ShapeBorder shape;
  final Clip clipBehavior;
  final EdgeInsetsGeometry margin;
  final Widget sliver;
  final double bufferExtent;

  SliverCard({
    this.color,
    this.shadowColor,
    this.elevation,
    this.shape,
    this.margin,
    this.clipBehavior,
    this.sliver,
    this.bufferExtent,
  });

  build(context) {
    var textDirection = Directionality.of(context);
    var cardTheme = CardTheme.of(context);
    var appliedClip = clipBehavior ?? cardTheme.clipBehavior ?? Clip.none;
    var appliedMargin = (
      margin ?? cardTheme.margin ?? const EdgeInsets.all(4.0)
    ).resolve(textDirection);
    var appliedShape = shape ?? cardTheme.shape ?? const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
    );
    var appliedBufferExtent = bufferExtent ?? 12.0;

    var card = Material(
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