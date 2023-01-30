import 'dart:math';

import 'package:flutter/material.dart'
    hide
        SlottedContainerRenderObjectMixin,
        SlottedMultiChildRenderObjectWidgetMixin;
import 'package:flutter/rendering.dart';

import 'axis_utils.dart';
import 'sliver_card.dart';
import 'slotted_render_object_widget.dart';

/// A sliver container that gives its sliver a foreground or background
/// consisting of box widgets, this is useful if you want a sliver to look and
/// feel like the child of a regular widget.
///
/// The [foreground] and [background] widgets are positioned out so that they
/// cover the visible space of [sliver], it also applies [clipper] with these
/// dimensions.
///
/// [bufferExtent] is the amount of space the foreground and background will
/// extend off-screen in each direction if portions of [sliver] are out of view.
/// To maintain consistent decorations, this should be greater or equal to the
/// size of any features drawn at the border.
///
/// The total main axis size of box widgets will never be smaller than
/// [bufferExtent] * 2 or the main axis size of [sliver], whichever is lowest.
///
/// See also:
///
///   * [SliverCard], which gives the sliver a card look.
class SliverContainer extends StatelessWidget {
  /// The child sliver that this container will wrap.
  final Widget? sliver;

  /// The child box widget that is layed out so that it covers the visual space
  /// of [sliver], and painted above it.
  final Widget? foreground;

  /// The child box widget that is layed out so that it covers the visual space
  /// of [sliver], and painted below it.
  final Widget? background;

  /// The amount of space [foreground] and [background] will extend off-screen
  /// in each direction if portions of [sliver] are out of view.
  final double bufferExtent;

  /// How much padding to apply to [sliver].
  final EdgeInsetsGeometry? padding;

  /// How much padding to apply to the container itself.
  final EdgeInsetsGeometry? margin;

  /// A custom clipper that defines the path to clip [sliver], [foreground], and
  /// [background.
  final CustomClipper<Path>? clipper;

  /// The clip behavior of [clipper], defaults to none.
  final Clip clipBehavior;

  /// Whether or not to ignore clipping on [foreground] and [background].
  final bool clipSliverOnly;

  /// Constructs a SliverContainer with the specified arguments.
  SliverContainer({
    Key? key,
    required this.sliver,
    this.foreground,
    this.background,
    this.bufferExtent = 0.0,
    this.padding,
    this.margin,
    CustomClipper<Path>? clipper,
    this.clipBehavior = Clip.antiAlias,
    this.clipSliverOnly = false,
    BorderRadiusGeometry? borderRadius,
  })  : assert(clipper == null || borderRadius == null,
            'clipper cannot be used with borderRadius'),
        clipper = borderRadius != null
            ? ShapeBorderClipper(
                shape: RoundedRectangleBorder(borderRadius: borderRadius))
            : clipper,
        super(key: key);

  @override
  Widget build(context) {
    var current = sliver;
    if (padding != null) {
      current = SliverPadding(
        sliver: current,
        padding: padding!,
      );
    }
    current = _BaseSliverContainer(
      sliver: current,
      foreground: foreground,
      background: background,
      bufferExtent: bufferExtent,
      clipper: clipper,
      clipBehavior: clipBehavior,
      clipSliverOnly: clipSliverOnly,
    );
    if (margin != null) {
      current = SliverPadding(
        sliver: current,
        padding: margin!,
      );
    }
    return current;
  }
}

enum _SliverOverlaySlot {
  foreground,
  sliver,
  background,
}

class _BaseSliverContainer extends RenderObjectWidget
    with SlottedMultiChildRenderObjectWidgetMixin<_SliverOverlaySlot> {
  final Widget? sliver;
  final Widget? foreground;
  final Widget? background;
  final double bufferExtent;
  final CustomClipper<Path>? clipper;
  final Clip clipBehavior;
  final bool clipSliverOnly;

  const _BaseSliverContainer({
    Key? key,
    required this.sliver,
    this.foreground,
    this.background,
    this.bufferExtent = 0.0,
    this.clipper,
    this.clipBehavior = Clip.antiAlias,
    this.clipSliverOnly = false,
  }) : super(key: key);

  @override
  Iterable<_SliverOverlaySlot> get slots => _SliverOverlaySlot.values;

  @override
  Widget? childForSlot(_SliverOverlaySlot slot) {
    switch (slot) {
      case _SliverOverlaySlot.foreground:
        return foreground;
      case _SliverOverlaySlot.sliver:
        return sliver;
      case _SliverOverlaySlot.background:
        return background;
    }
  }

  @override
  RenderSliverContainer createRenderObject(context) {
    return RenderSliverContainer(
      bufferExtent: bufferExtent,
      clipper: clipper,
      clipBehavior: clipBehavior,
      clipSliverOnly: clipSliverOnly,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderSliverContainer renderObject) {
    renderObject.bufferExtent = bufferExtent;
    renderObject.clipper = clipper;
    renderObject.clipBehavior = clipBehavior;
    renderObject.clipSliverOnly = clipSliverOnly;
  }
}

/// A sliver container that gives its sliver a foreground or background
/// consisting of boxes.
///
/// See also:
///
///   * [SliverContainer], the widget equivalent.
class RenderSliverContainer extends RenderSliver
    with
        RenderSliverHelpers,
        SlottedContainerRenderObjectMixin<_SliverOverlaySlot> {
  /// Constructs a RenderSliverContainer with the specified arguments.
  RenderSliverContainer({
    double bufferExtent = 0.0,
    Clip clipBehavior = Clip.antiAlias,
    CustomClipper<Path>? clipper,
    bool clipSliverOnly = false,
  })  : _clipBehavior = clipBehavior,
        _clipper = clipper,
        _bufferExtent = bufferExtent,
        _clipSliverOnly = clipSliverOnly;

  /// A custom clipper that defines the path to clip [sliver], [foreground], and
  /// [background.
  CustomClipper<Path>? get clipper => _clipper;
  CustomClipper<Path>? _clipper;
  set clipper(CustomClipper<Path>? newClipper) {
    if (_clipper == newClipper) {
      return;
    }

    final didNeedCompositing = alwaysNeedsCompositing;
    final oldClipper = _clipper;
    _clipper = newClipper;

    if (didNeedCompositing != alwaysNeedsCompositing) {
      markNeedsCompositingBitsUpdate();
    }

    assert(newClipper != null || oldClipper != null);
    if (newClipper == null ||
        oldClipper == null ||
        newClipper.runtimeType != oldClipper.runtimeType ||
        newClipper.shouldReclip(oldClipper)) {
      _markNeedsClip();
    }

    if (attached) {
      oldClipper?.removeListener(_markNeedsClip);
      newClipper?.addListener(_markNeedsClip);
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _clipper?.addListener(_markNeedsClip);
  }

  @override
  void detach() {
    super.detach();
    _clipper?.removeListener(_markNeedsClip);
  }

  /// Adopts a new child, drops the previous one.
  void updateChild(RenderObject? oldChild, RenderObject? newChild) {
    if (oldChild != null) {
      dropChild(oldChild);
    }
    if (newChild != null) {
      adoptChild(newChild);
    }
  }

  Path? _clipPath;
  void _markNeedsClip() {
    _clipPath = null;
    markNeedsPaint();
  }

  void _updateClip() {
    if (_clipper == null || _clipPath != null) {
      return;
    }
    _clipPath = _clipper?.getClip(_bufferRect!.size);
    assert(_clipPath != null);
  }

  /// Whether or not we need to clip the child.
  bool get shouldClip => _clipper != null && _clipBehavior != Clip.none;

  double _bufferExtent;

  /// The amount of space [foreground] and [background] will extend off-screen
  /// in each direction if portions of [sliver] are out of view.
  double get bufferExtent => _bufferExtent;
  set bufferExtent(double value) {
    if (value == _bufferExtent) {
      return;
    }
    markNeedsLayout();
    _bufferExtent = value;
  }

  Clip _clipBehavior;

  /// The clip behavior of [clipper], defaults to none.
  Clip get clipBehavior => _clipBehavior;
  set clipBehavior(Clip value) {
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
    }
  }

  bool _clipSliverOnly;

  /// Whether or not to ignore clipping on [foreground] and [background].
  bool get clipSliverOnly => _clipSliverOnly;
  set clipSliverOnly(bool value) {
    if (value != clipSliverOnly) {
      _clipSliverOnly = value;
      markNeedsPaint();
    }
  }

  /// The foreground's [RenderBox].
  RenderBox? get foreground =>
      childForSlot(_SliverOverlaySlot.foreground) as RenderBox?;

  /// The containing sliver's [RenderSliver].
  RenderSliver? get sliver =>
      childForSlot(_SliverOverlaySlot.sliver) as RenderSliver?;

  /// The background's [RenderBox].
  RenderBox? get background =>
      childForSlot(_SliverOverlaySlot.background) as RenderBox?;

  Offset _getBufferOffset(double mainAxisPosition, double mainAxisSize) {
    var delta = mainAxisPosition;
    switch (constraints.axis) {
      case Axis.horizontal:
        if (!_rightWayUp) {
          delta = geometry!.paintExtent - mainAxisSize - delta;
        }
        return Offset(delta, 0);
      case Axis.vertical:
        if (!_rightWayUp) {
          delta = geometry!.paintExtent - mainAxisSize - delta;
        }
        return Offset(0, delta);
    }
  }

  Rect? _bufferRect;
  late bool _rightWayUp;
  late double _bufferMainSize;

  @override
  void performLayout() {
    final SliverGeometry geometry;
    if (sliver != null) {
      sliver!.layout(constraints, parentUsesSize: true);
      geometry = sliver!.geometry!;
    } else {
      geometry = SliverGeometry.zero;
    }
    this.geometry = geometry;

    final maxBufferExtent = min(
      bufferExtent,
      geometry.maxPaintExtent / 2,
    );

    var start = -min(constraints.scrollOffset, maxBufferExtent);
    var end = min(geometry.maxPaintExtent - constraints.scrollOffset,
        geometry.paintExtent + maxBufferExtent);

    if (constraints.scrollOffset > 0) {
      start = min(start, end - maxBufferExtent * 2);
    } else {
      end = max(end, start + maxBufferExtent * 2);
    }

    switch (constraints.axisDirection) {
      case AxisDirection.up:
      case AxisDirection.left:
        _rightWayUp = false;
        break;
      case AxisDirection.down:
      case AxisDirection.right:
        _rightWayUp = true;
        break;
    }

    switch (constraints.growthDirection) {
      case GrowthDirection.reverse:
        _rightWayUp = !_rightWayUp;
        break;
      default:
        break;
    }

    _bufferMainSize = end - start;
    final boxConstraints = BoxConstraintsAxisUtil.tightFor(
      constraints.axis,
      cross: constraints.crossAxisExtent,
      main: _bufferMainSize,
    );

    final newRect =
        _getBufferOffset(start, _bufferMainSize) & boxConstraints.biggest;
    if (_bufferRect == null || newRect.size != _bufferRect!.size) {
      _markNeedsClip();
    }
    _bufferRect = newRect;

    if (foreground != null) {
      foreground!.layout(boxConstraints);
    }

    if (background != null) {
      background!.layout(boxConstraints);
    }
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    if (identical(child, sliver)) {
      return;
    }
    transform.translate(_bufferRect!.left, _bufferRect!.top);
  }

  @override
  bool get needsCompositing => shouldClip;

  @override
  void paint(PaintingContext context, Offset offset) {
    _updateClip();
    if (shouldClip) {
      if (clipSliverOnly && background != null) {
        context.paintChild(background!, offset + _bufferRect!.topLeft);
      }

      if (_bufferRect!.left == 0.0 && _bufferRect!.top == 0.0) {
        context.pushClipPath(needsCompositing, offset,
            Offset.zero & _bufferRect!.size, _clipPath!, (context, offset) {
          if (!clipSliverOnly && background != null) {
            context.paintChild(background!, offset);
          }
          if (sliver != null) {
            context.paintChild(sliver!, offset);
          }
          if (!clipSliverOnly && foreground != null) {
            context.paintChild(foreground!, offset);
          }
        });
      } else {
        final transform =
            Matrix4.translationValues(_bufferRect!.left, _bufferRect!.top, 0);
        context.pushTransform(needsCompositing, Offset.zero, transform,
            (context, newOffset) {
          context.pushClipPath(
            needsCompositing,
            offset,
            Offset.zero & _bufferRect!.size,
            _clipPath!,
            (context, offset) {
              offset -= _bufferRect!.topLeft;
              if (!clipSliverOnly && background != null) {
                context.paintChild(background!, offset + _bufferRect!.topLeft);
              }
              if (sliver != null) {
                context.paintChild(sliver!, offset);
              }
              if (!clipSliverOnly && foreground != null) {
                context.paintChild(foreground!, offset + _bufferRect!.topLeft);
              }
            },
            clipBehavior: clipBehavior,
            oldLayer: layer as ClipPathLayer?,
          );
        });
      }

      if (clipSliverOnly && foreground != null) {
        context.paintChild(foreground!, offset + _bufferRect!.topLeft);
      }
    } else {
      if (background != null) {
        context.paintChild(background!, offset + _bufferRect!.topLeft);
      }
      if (sliver != null) {
        context.paintChild(sliver!, offset);
      }
      if (foreground != null) {
        context.paintChild(foreground!, offset + _bufferRect!.topLeft);
      }
    }
  }

  bool _hitTestBoxChild(
    BoxHitTestResult result,
    RenderBox? child, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    final transformedPosition = OffsetAxisUtil.create(
        constraints.axis, crossAxisPosition, mainAxisPosition);
    return result.addWithPaintOffset(
      offset: _bufferRect!.topLeft,
      position: transformedPosition,
      hitTest: (BoxHitTestResult result, Offset position) =>
          child!.hitTest(result, position: position),
    );
  }

  @override
  bool hitTestChildren(
    SliverHitTestResult result, {
    double? mainAxisPosition,
    double? crossAxisPosition,
  }) {
    return (foreground != null &&
            _hitTestBoxChild(
              BoxHitTestResult.wrap(result),
              foreground,
              mainAxisPosition: mainAxisPosition!,
              crossAxisPosition: crossAxisPosition!,
            )) ||
        (sliver != null &&
            sliver!.geometry!.hitTestExtent > 0 &&
            sliver!.hitTest(
              result,
              mainAxisPosition: mainAxisPosition!,
              crossAxisPosition: crossAxisPosition!,
            )) ||
        (background != null &&
            _hitTestBoxChild(
              BoxHitTestResult.wrap(result),
              background,
              mainAxisPosition: mainAxisPosition!,
              crossAxisPosition: crossAxisPosition!,
            ));
  }

  @override
  double childMainAxisPosition(RenderObject child) {
    return identical(child, sliver) ? 0 : _bufferMainSize;
  }
}
