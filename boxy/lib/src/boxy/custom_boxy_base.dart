import 'dart:collection';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../sliver_offset.dart';
import 'inflating_element.dart';

/// Base class for the [ParentData] provided by [RenderBoxyMixin] clients.
///
/// See also:
///
///  * [RenderBoxyMixin]
///  * [BoxyId]
///  * [BaseBoxyDelegate]
class BaseBoxyParentData<ChildType extends RenderObject>
    extends ContainerBoxParentData<ChildType>
    implements InflatingParentData<ChildType> {
  /// An id provided by [BoxyId] or inflation methods on the delegate.
  @override
  Object? id;

  /// Data provided by [BoxyId] or intermediate storage for delegates.
  dynamic userData;

  /// The paint transform that is used by the default paint, hitTest, and
  /// applyPaintTransform implementations.
  Matrix4 transform = Matrix4.identity();

  /// The dry transform of this RenderObject, set during a dry layout by
  /// [BoxyChild.position] or [BoxyChild.setTransform].
  Matrix4? dryTransform;

  /// The dry size of this RenderObject, set during a dry layout by
  /// [BoxyChild.layout].
  Size? drySize;
}

/// Base mixin of [CustomBoxy]'s [RenderObject] logic, this extends
/// [InflatingRenderObjectMixin] to manage a [BaseBoxyDelegate] delegate.
///
/// This mixin is typically not used directly, instead consider using the
/// [CustomBoxy] widget.
///
///  * [BaseBoxyDelegate]
///  * [BaseBoxyParentData]
///  * [BoxyId]
mixin RenderBoxyMixin<
        ChildType extends RenderObject,
        ParentDataType extends BaseBoxyParentData<ChildType>,
        ChildHandleType extends BaseBoxyChild> on RenderObject
    implements
        ContainerRenderObjectMixin<ChildType, ParentDataType>,
        InflatingRenderObjectMixin<ChildType, ParentDataType, ChildHandleType> {
  BoxyDelegatePhase _debugPhase = BoxyDelegatePhase.none;

  /// A variable that can be used by [delegate] to store data between layout.
  dynamic layoutData;

  /// The current painting context, only valid during paint.
  PaintingContext? paintingContext;

  /// The current paint offset passed to [paint], only valid during paint.
  Offset? paintOffset;

  /// The current hit test offset, only valid during hit testing.
  SliverOffset? hitPosition;

  /// The current hit test result, only valid during hit testing.
  HitTestResult? get hitTestResult;

  /// The current phase in the render pipeline that this boxy is performing.
  BoxyDelegatePhase get debugPhase => _debugPhase;
  set debugPhase(BoxyDelegatePhase state) {
    assert(() {
      _debugPhase = state;
      return true;
    }());
  }

  @override
  void prepareChild(ChildHandleType child) {
    child._ignore = false;
  }

  /// Wraps [func] with a new [debugPhase].
  ///
  /// This is used by subclasses to indicate what phase in the render pipeline
  /// the boxy is performing.
  T wrapPhase<T>(
    BoxyDelegatePhase phase,
    T Function() func,
  ) {
    // A particular delegate could be called reentrantly, e.g. if it used
    // by both a parent and a child. So, we must restore the context when
    // we return.
    final prevRender = this;
    delegate._render = this;
    debugPhase = phase;
    try {
      return func();
    } finally {
      debugPhase = BoxyDelegatePhase.none;
      delegate._render = prevRender;
    }
  }

  /// Throws an error as a result of an incorrect layout phase e.g. calling
  /// inflate during a dry layout.
  ///
  /// Override to improve the reporting of these kinds of errors.
  void debugThrowLayout(FlutterError error) {
    throw error;
  }

  /// Whether this Boxy is currently performing a dry layout.
  bool get isDryLayout => false;

  @override
  void performLayout() {
    super.performLayout();
    assert(() {
      if (debugChildrenNeedingLayout.isNotEmpty) {
        if (debugChildrenNeedingLayout.length > 1) {
          throw FlutterError(
              'The $delegate boxy delegate forgot to lay out the following children:\n'
              '  ${debugChildrenNeedingLayout.map(debugDescribeChild).join("\n  ")}\n'
              'Each child must be laid out exactly once.');
        } else {
          throw FlutterError(
              'The $delegate boxy delegate forgot to lay out the following child:\n'
              '  ${debugDescribeChild(debugChildrenNeedingLayout.single)}\n'
              'Each child must be laid out exactly once.');
        }
      }
      return true;
    }());
  }

  /// Describes a child managed by this boxy.
  String debugDescribeChild(Object id) =>
      'BoxyChild($id: ${childHandleMap[id]!.id})';

  /// The current delegate of this boxy.
  BaseBoxyDelegate get delegate;
  set delegate(covariant BaseBoxyDelegate newDelegate);

  /// Hit tests a [RenderBox] child at [position] with a [transform].
  bool hitTestBoxChild({
    required RenderBox child,
    required Offset position,
    required Matrix4 transform,
    required bool checkBounds,
  });

  /// Hit tests a [RenderSliver] child at [position] with a [transform].
  bool hitTestSliverChild({
    required RenderSliver child,
    required Offset position,
    required Matrix4 transform,
    required bool checkBounds,
  });

  /// Marks the object for needing layout, paint, build. or compositing bits
  /// update as a result of the delegate changing.
  void notifyChangedDelegate(BaseBoxyDelegate oldDelegate) {
    if (delegate == oldDelegate) {
      return;
    }

    final neededCompositing = oldDelegate.needsCompositing;

    if (delegate.runtimeType != oldDelegate.runtimeType ||
        delegate.shouldRelayout(oldDelegate)) {
      markNeedsLayout();
    } else if (delegate.shouldRepaint(oldDelegate)) {
      markNeedsPaint();
    }

    if (neededCompositing != delegate.needsCompositing) {
      markNeedsCompositingBitsUpdate();
    }

    if (attached) {
      oldDelegate._relayout?.removeListener(markNeedsLayout);
      oldDelegate._repaint?.removeListener(markNeedsPaint);
      delegate._relayout?.addListener(markNeedsLayout);
      delegate._repaint?.addListener(markNeedsPaint);
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    delegate._relayout?.addListener(markNeedsLayout);
    delegate._repaint?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    delegate._relayout?.removeListener(markNeedsLayout);
    delegate._repaint?.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    paintingContext = context;
    try {
      wrapPhase(BoxyDelegatePhase.paint, () {
        context.canvas.save();
        context.canvas.translate(offset.dx, offset.dy);
        paintOffset = Offset.zero;
        delegate.paint();
        context.canvas.restore();
        paintOffset = offset;
        delegate.paintChildren();
        context.canvas.save();
        context.canvas.translate(offset.dx, offset.dy);
        paintOffset = Offset.zero;
        delegate.paintForeground();
        context.canvas.restore();
      });
    } finally {
      paintingContext = null;
      paintOffset = null;
    }
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    final parentData = child.parentData! as BaseBoxyParentData;
    transform.multiply(parentData.transform);
  }

  @override
  bool get alwaysNeedsCompositing => delegate.needsCompositing;

  /// Wraps a [Size] into a [SliverSize] using the sliver constraints of this
  /// boxy.
  ///
  /// If this boxy is not a [RenderSliver], assume the axis is vertical.
  SliverSize wrapSize(Size size) {
    return SliverSize(size.width, size.height, Axis.vertical);
  }

  /// Wraps an [Offset] into a [SliverOffset] using the sliver constraints of
  /// this boxy.
  ///
  /// If this boxy is not a [RenderSliver], assume the axis is vertical.
  SliverOffset wrapOffset(Offset offset, Size size) {
    return SliverOffset(offset.dx, offset.dy, offset.dx, offset.dy);
  }

  /// Gets the offset at the specified cross and main axis extents.
  ///
  /// If this boxy is not a [RenderSliver], assume the axis is vertical.
  Offset unwrapOffset(double cross, double main, Size size) {
    return Offset(cross, main);
  }
}

/// The current phase in the render pipeline that the boxy is in.
///
/// See also:
///
///  * [BoxyDelegate]
enum BoxyDelegatePhase {
  /// The delegate is not performing work.
  none,

  /// Layout is being performed.
  layout,

  /// Intrinsic layouts are currently being performed.
  intrinsics,

  /// A dry layout pass is currently being performed.
  dryLayout,

  /// The boxy is currently painting.
  paint,

  /// The boxy is currently being hit test.
  hitTest,
}

/// Cache for [Layer] objects, used by [BoxyLayerContext] methods.
///
/// Preserving [Layer]s between paints can significantly improve performance
/// in some cases, this class provides a convenient way of identifying them.
///
/// See also:
///
///  * [BoxyDelegate]
///  * [BoxyLayerContext]
class LayerKey<T extends Layer> {
  /// The current cached layer.
  T? get layer => handle.layer;
  set layer(T? newLayer) => handle.layer = newLayer;

  /// The underlying handle that prevents the layer from being disposed
  /// prematurely.
  final handle = LayerHandle<T>();
}

/// A convenient wrapper to [PaintingContext], provides methods to push
/// compositing [Layer]s from the paint methods of [BoxyDelegate].
///
/// You can obtain a layer context in a delegate through the
/// [BoxyDelegate.layers] getter.
///
/// See also:
///
///  * [BoxyDelegate], which has an example on how to use layers.
class BoxyLayerContext {
  final RenderBoxyMixin _render;

  BoxyLayerContext._(this._render);

  /// Pushes a [ContainerLayer] to the current recording, calling [paint] to
  /// paint on top of the layer.
  ///
  /// {@template boxy.custom_boxy.BoxyLayerContext.push.bounds}
  /// The [bounds] argument defines the bounds in which the [paint] should
  /// paint, this is useful for debugging tools and does not affect rendering.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///  * [PaintingContext.pushLayer]
  void push({
    required VoidCallback paint,
    ContainerLayer? layer,
    Rect? bounds,
    Offset offset = Offset.zero,
  }) {
    final oldContext = _render.paintingContext;
    final oldOffset = _render.paintOffset;
    try {
      if (layer == null) {
        paint();
      } else {
        oldContext!.pushLayer(
          layer,
          (context, offset) {
            _render.paintingContext = context;
            _render.paintOffset = offset;
            paint();
          },
          offset + _render.paintOffset!,
          childPaintBounds: bounds,
        );
      }
    } finally {
      _render.paintingContext = oldContext;
      _render.paintOffset = oldOffset;
    }
  }

  /// Pushes a [Layer] to the compositing tree similar to [push], but can't
  /// paint anything on top of it.
  ///
  /// See also:
  ///
  ///  * [PaintingContext.addLayer]
  void add({required Layer layer}) {
    _render.paintingContext!.addLayer(layer);
  }

  /// Pushes a [ClipPathLayer] to the compositing tree, calling [paint] to paint
  /// on top of the layer.
  ///
  /// {@macro boxy.custom_boxy.BoxyLayerContext.push.bounds}
  ///
  /// See also:
  ///
  ///  * [PaintingContext.pushClipPath]
  void clipPath({
    required Path path,
    required VoidCallback paint,
    Clip clipBehavior = Clip.antiAlias,
    Offset offset = Offset.zero,
    Rect? bounds,
    LayerKey? key,
  }) {
    final offsetClipPath = path.shift(offset + _render.paintOffset!);
    ClipPathLayer layer;
    if (key?.layer is ClipPathLayer) {
      layer = (key!.layer! as ClipPathLayer)
        ..clipPath = offsetClipPath
        ..clipBehavior = clipBehavior;
    } else {
      layer = ClipPathLayer(
        clipPath: offsetClipPath,
        clipBehavior: clipBehavior,
      );
      key?.layer = layer;
    }
    push(layer: layer, paint: paint, offset: offset, bounds: bounds);
  }

  /// Pushes a [ClipRectLayer] to the compositing tree, calling [paint] to paint
  /// on top of the layer.
  ///
  /// {@macro boxy.custom_boxy.BoxyLayerContext.push.bounds}
  ///
  /// See also:
  ///
  ///  * [PaintingContext.pushClipRect]
  void clipRect({
    required Rect rect,
    required VoidCallback paint,
    Clip clipBehavior = Clip.antiAlias,
    Offset offset = Offset.zero,
    Rect? bounds,
    LayerKey? key,
  }) {
    final offsetClipRect = rect.shift(offset + _render.paintOffset!);
    ClipRectLayer layer;
    if (key?.layer is ClipRectLayer) {
      layer = (key!.layer! as ClipRectLayer)
        ..clipRect = offsetClipRect
        ..clipBehavior = clipBehavior;
    } else {
      layer = ClipRectLayer(
        clipRect: offsetClipRect,
        clipBehavior: clipBehavior,
      );
      key?.layer = layer;
    }
    push(layer: layer, paint: paint, offset: offset, bounds: bounds);
  }

  /// Pushes a [ClipRRectLayer] to the compositing tree, calling [paint] to
  /// paint on top of the layer.
  ///
  /// {@macro boxy.custom_boxy.BoxyLayerContext.push.bounds}
  ///
  /// See also:
  ///
  ///  * [PaintingContext.pushClipRRect]
  void clipRRect({
    required RRect rrect,
    required VoidCallback paint,
    Clip clipBehavior = Clip.antiAlias,
    Offset offset = Offset.zero,
    Rect? bounds,
    LayerKey? key,
  }) {
    final offsetClipRRect = rrect.shift(offset + _render.paintOffset!);
    ClipRRectLayer layer;
    if (key?.layer is ClipRRectLayer) {
      layer = (key!.layer! as ClipRRectLayer)
        ..clipRRect = offsetClipRRect
        ..clipBehavior = clipBehavior;
    } else {
      layer = ClipRRectLayer(
        clipRRect: offsetClipRRect,
        clipBehavior: clipBehavior,
      );
      key?.layer = layer;
    }
    push(layer: layer, paint: paint, offset: offset, bounds: bounds);
  }

  /// Pushes a [ColorFilterLayer] to the compositing tree, calling [paint] to
  /// paint on top of the layer.
  ///
  /// {@macro boxy.custom_boxy.BoxyLayerContext.push.bounds}
  ///
  /// See also:
  ///
  ///  * [PaintingContext.pushColorFilter]
  void colorFilter({
    required ColorFilter colorFilter,
    required VoidCallback paint,
    Rect? bounds,
    LayerKey? key,
  }) {
    ColorFilterLayer layer;
    if (key?.layer is ColorFilterLayer) {
      layer = (key!.layer! as ColorFilterLayer)..colorFilter = colorFilter;
    } else {
      layer = ColorFilterLayer(colorFilter: colorFilter);
      key?.layer = layer;
    }
    push(layer: layer, paint: paint, bounds: bounds);
  }

  /// Pushes a [ImageFilterLayer] to the compositing tree, calling [paint] to
  /// paint on top of the layer.
  ///
  /// {@macro boxy.custom_boxy.BoxyLayerContext.push.bounds}
  void imageFilter({
    required ImageFilter imageFilter,
    required VoidCallback paint,
    Rect? bounds,
    LayerKey? key,
  }) {
    ImageFilterLayer layer;
    if (key?.layer is ImageFilterLayer) {
      layer = (key!.layer! as ImageFilterLayer)..imageFilter = imageFilter;
    } else {
      layer = ImageFilterLayer(imageFilter: imageFilter);
      key?.layer = layer;
    }
    push(layer: layer, paint: paint, bounds: bounds);
  }

  /// Pushes an [OffsetLayer] to the compositing tree, calling [paint] to paint
  /// on top of the layer.
  ///
  /// {@macro boxy.custom_boxy.BoxyLayerContext.push.bounds}
  ///
  /// See also:
  ///
  ///  * [PaintingContext.pushTransform]
  void offset({
    required Offset offset,
    required VoidCallback paint,
    Rect? bounds,
    LayerKey? key,
  }) {
    OffsetLayer layer;
    if (key?.layer is OffsetLayer) {
      layer = (key!.layer! as OffsetLayer)..offset = offset;
    } else {
      layer = OffsetLayer(offset: offset);
      key?.layer = layer;
    }
    push(layer: layer, paint: paint, bounds: bounds);
  }

  /// Pushes an [TransformLayer] to the compositing tree, calling [paint] to
  /// paint on top of the layer.
  ///
  /// {@macro boxy.custom_boxy.BoxyLayerContext.push.bounds}
  ///
  /// See also:
  ///
  ///  * [PaintingContext.pushTransform]
  void transform({
    required Matrix4 transform,
    required VoidCallback paint,
    Offset offset = Offset.zero,
    Rect? bounds,
    LayerKey? key,
  }) {
    final layerOffset = _render.paintOffset! + offset;
    TransformLayer layer;
    if (key?.layer is TransformLayer) {
      layer = (key!.layer! as TransformLayer)
        ..transform = transform
        ..offset = layerOffset;
    } else {
      layer = TransformLayer(
        transform: transform,
        offset: layerOffset,
      );
      key?.layer = layer;
    }
    push(
        layer: layer,
        paint: paint,
        offset: -_render.paintOffset!,
        bounds: bounds);
  }

  /// Pushes an [OpacityLayer] to the compositing tree, calling [paint] to paint
  /// on top of the layer.
  ///
  /// The `alpha` argument is the alpha value to use when blending. An alpha
  /// value of 0 means the painting is fully transparent and an alpha value of
  /// 255 means the painting is fully opaque.
  ///
  /// {@macro boxy.custom_boxy.BoxyLayerContext.push.bounds}
  ///
  /// See also:
  ///
  ///  * [PaintingContext.pushOpacity]
  void alpha({
    required int alpha,
    required VoidCallback paint,
    Offset offset = Offset.zero,
    Rect? bounds,
    LayerKey? key,
  }) {
    OpacityLayer layer;
    if (key?.layer is OffsetLayer) {
      layer = (key!.layer! as OpacityLayer)..alpha = alpha;
    } else {
      layer = OpacityLayer(alpha: alpha);
      key?.layer = layer;
    }
    push(layer: layer, paint: paint, offset: offset, bounds: bounds);
  }

  /// Pushes an [OpacityLayer] to the compositing tree, calling [paint] to paint
  /// on top of the layer.
  ///
  /// This is the same as [alpha] but takes a fraction instead of an integer,
  /// where 0.0 means the painting is fully transparent and an opacity value of
  //  1.0 means the painting is fully opaque.
  ///
  /// See also:
  ///
  ///  * [PaintingContext.pushOpacity]
  void opacity({
    required double opacity,
    required VoidCallback paint,
    Offset offset = Offset.zero,
    Rect? bounds,
    LayerKey? key,
  }) {
    return alpha(
      alpha: (opacity * 255).round(),
      paint: paint,
      offset: offset,
      bounds: bounds,
      key: key,
    );
  }
}

/// Base class of child handles managed by [RenderBoxyMixin] clients.
///
/// This should typically not be used directly, instead obtain a child handle
/// from BoxyDelegate.getChild.
///
/// If the child was recently inflated with [BaseBoxyDelegate.inflate], the
/// associated [RenderObject] may not exist yet. Accessing [render] directly or
/// indirectly will flush the inflation queue and bring it alive.
class BaseBoxyChild extends InflatedChildHandle {
  /// Constructs a handle to children managed by [RenderBoxyMixin] clients.
  BaseBoxyChild({
    required Object id,
    required InflatingRenderObjectMixin parent,
    RenderObject? render,
    Element? context,
    Widget? widget,
  })  : assert(render == null || render.parentData != null),
        super(
          id: id,
          parent: parent,
          render: render,
          widget: widget,
          context: context,
        );

  bool _ignore = false;

  BaseBoxyParentData get _parentData =>
      render.parentData! as BaseBoxyParentData;

  /// The size of this child in the child's coordinate space, only valid after
  /// calling [BoxyChild.layout].
  ///
  /// This method returns Size.zero if this handle is neither a [RenderBox]
  /// or [RenderSliver], since sizing is dependant on the render protocol.
  SliverSize get size => SliverSize.zero;

  /// The rect of this child relative to the boxy, this is only valid after
  /// [BoxyChild.layout] and [position] have been called.
  ///
  /// This getter may return erroneous values if a [transform] is applied to the
  /// child since the coordinate space would be skewed.
  ///
  /// See also:
  ///
  ///  * [offset]
  ///  * [size]
  Rect get rect {
    final offset = this.offset;
    final size = this.size;
    return Rect.fromLTWH(
      offset.dx,
      offset.dy,
      size.width,
      size.height,
    );
  }

  /// Sets the position of this child relative to the parent, this should only
  /// be called during layout or paint.
  ///
  /// See also:
  ///
  ///  * [positionOnAxis]
  ///  * [positionAligned]
  ///  * [offset]
  ///  * [rect]
  void position(Offset newOffset) {
    setTransform(Matrix4.translationValues(newOffset.dx, newOffset.dy, 0));
  }

  /// Sets the position of this child relative to the parent, this should only
  /// be called after [BoxyChild.layout] is called.
  ///
  /// See also:
  ///
  ///  * [position]
  ///  * [positionAligned]
  ///  * [offset]
  ///  * [rect]
  void positionOnAxis(double cross, double main) {
    position(_parent.unwrapOffset(cross, main, size));
  }

  /// Position a child inside a [Rect] with an [Alignment], this should only
  /// be called after [BoxyChild.layout].
  ///
  /// See also:
  ///
  ///  * [position]
  ///  * [positionOnAxis]
  void positionRect(Rect rect, [Alignment alignment = Alignment.center]) {
    position(alignment.inscribe(size, rect).topLeft);
  }

  /// The offset to this child relative to the parent, can be set during layout
  /// or paint with [position].
  ///
  /// This getter may return erroneous values if a [transform] is applied to the
  /// child since the coordinate space would be skewed.
  ///
  /// If the parent is not a sliver, the axis direction of the offset is assumed
  /// to be down, such that dx is the cross axis and dy is the main axis.
  SliverOffset get offset {
    return _parent.wrapOffset(Offset(transform[12], transform[13]), size);
  }

  set offset(Offset newOffset) => position(offset);

  /// The matrix transformation applied to this child, used by [paint] and
  /// [hitTest].
  Matrix4 get transform => _parentData.transform;

  /// Sets the paint [transform] of this child, should only be called during
  /// layout or paint.
  void setTransform(Matrix4 newTransform) {
    if (_parent.isDryLayout) {
      _parentData.dryTransform = newTransform;
      return;
    }

    assert(() {
      if (_parent.debugPhase != BoxyDelegatePhase.layout &&
          _parent.debugPhase != BoxyDelegatePhase.paint) {
        throw FlutterError(
            'The $this boxy delegate tried to position a child outside of the layout or paint methods.\n');
      }

      return true;
    }());

    _parentData.transform = newTransform;
  }

  /// A variable that can store arbitrary data by the [BoxyDelegate] during
  /// layout, may also be set by [BoxyId].
  ///
  /// See also:
  ///
  ///  * [ParentData]
  dynamic get parentData => _parentData.userData;

  set parentData(dynamic value) {
    _parentData.userData = value;
  }

  RenderBoxyMixin get _parent => render.parent! as RenderBoxyMixin;

  /// Paints the child in the current paint context, this should only be called
  /// in [BoxyDelegate.paintChildren].
  ///
  /// Note that [offset] and [transform] will not transform hit tests, you may
  /// want to use [BoxyChild.position] or [BoxyChild.setTransform] instead.
  ///
  /// Implementers of [BoxyDelegate.paintChildren] should draw at
  /// [BoxyDelegate.paintOffset] and restore the canvas before painting a child.
  /// This is required by the framework because a child might need to insert its
  /// own compositing [Layer] between two other [PictureLayer]s.
  void paint({Offset? offset, Matrix4? transform}) {
    assert(
      offset == null || transform == null,
      'Only one of offset and transform can be provided at the same time',
    );

    if (_ignore) {
      return;
    }
    assert(() {
      if (_parent.debugPhase != BoxyDelegatePhase.paint) {
        throw FlutterError(
            'The $this boxy delegate tried to paint a child outside of the paint method.');
      }

      return true;
    }());

    if (offset == null && transform == null) {
      transform = _parentData.transform;
    }

    if (transform != null) {
      offset = MatrixUtils.getAsTranslation(transform);
      if (offset == null) {
        _parent.delegate.layers.transform(
          transform: transform,
          paint: () {
            _parent.paintingContext!.paintChild(render, _parent.paintOffset!);
          },
        );
        return;
      }
    }

    final paintOffset = _parent.paintOffset!;

    _parent.paintingContext!.paintChild(
      render,
      offset == null ? paintOffset : paintOffset + offset,
    );
  }

  /// Whether or not this child should be ignored by [paint] and
  /// [BoxyChild.hitTest].
  bool get isIgnored => _ignore;

  /// Sets whether or not this child should be ignored by [paint] and
  /// [BoxyChild.hitTest].
  ///
  /// The child still needs to be laid out while ignored.
  void ignore([bool value = true]) {
    _ignore = value;
  }

  /// Hit tests this child, returns true if the hit was a success. This should
  /// only be called in [BoxyDelegate.hitTest].
  ///
  /// The [transform] argument overrides the paint transform of the child,
  /// defaults to [BoxyChild.transform].
  ///
  /// The [offset] argument specifies the position of this child relative to the
  /// boxy, defaults to the offset given to it during layout.
  ///
  /// The [position] argument specifies the position of the hit test relative
  /// to the boxy, defaults to the position given to [BoxyDelegate.hitTest].
  ///
  /// This method returns false if this handle is neither a [RenderBox] or
  /// [RenderSliver], since hit testing is dependant on the render protocol.
  bool hitTest(
      {Matrix4? transform,
      Offset? offset,
      Offset? position,
      bool checkBounds = true}) {
    return false;
  }

  @override
  String toString() => 'BoxyChild(id: $id)';
}

/// An error that indicates [BaseBoxyDelegate.inflate] was called during a dry
/// layout.
class CannotInflateError<DelegateType extends BaseBoxyDelegate>
    extends FlutterError {
  /// The delegate that caused the error.
  final BaseBoxyDelegate delegate;

  /// The associated RenderObject.
  final RenderBoxyMixin<RenderObject, BaseBoxyParentData, BaseBoxyChild> render;

  /// Constructs an inflation error given the delegate and RenderObject.
  CannotInflateError({
    required this.delegate,
    required this.render,
  }) : super.fromParts([
          ErrorSummary(
              'The $delegate boxy attempted to inflate a widget during a dry layout.'),
          ErrorDescription(
            'This happens if an ancestor of the boxy (e.g. Wrap) requires a '
            'dry layout, but your size also depends on an inflated widget.',
          ),
          ErrorDescription(
            "If your boxy's size does not depend on the size of this widget you "
            'can skip the call to `inflate` when `isDryLayout` is true',
          ),
        ]);
}

/// Base class for delegates that control the layout and paint of multiple
/// children.
///
/// This class is typically not used directly, instead consider using
/// [BoxyDelegate] with a [CustomBoxy] widget.
///
/// See also:
///
///  * [BaseBoxyChild]
///  * [RenderBoxyMixin]
abstract class BaseBoxyDelegate<LayoutData extends Object,
    ChildHandleType extends BaseBoxyChild> {
  /// Constructs a BaseBoxyDelegate with optional [relayout] and [repaint]
  /// [Listenable]s.
  BaseBoxyDelegate({
    Listenable? relayout,
    Listenable? repaint,
  })  : _relayout = relayout,
        _repaint = repaint;

  final Listenable? _relayout;
  final Listenable? _repaint;

  RenderBoxyMixin<RenderObject, BaseBoxyParentData, ChildHandleType>? _render;

  /// The current phase in the render pipeline that this boxy is performing,
  /// only valid in debug mode.
  BoxyDelegatePhase get debugPhase =>
      _render == null ? BoxyDelegatePhase.none : _render!.debugPhase;

  /// A variable to hold additional data created during layout which can be
  /// used while painting and hit testing.
  LayoutData? get layoutData => render.layoutData as LayoutData?;

  set layoutData(LayoutData? data) {
    assert(() {
      if (debugPhase != BoxyDelegatePhase.layout) {
        throw FlutterError(
            'The $this boxy delegate attempted to set layout data outside of the layout method.\n');
      }
      return true;
    }());
    _render!.layoutData = data;
  }

  /// The [RenderBoxyMixin] of the current context.
  RenderBoxyMixin<RenderObject, BaseBoxyParentData, ChildHandleType>
      get render {
    assert(() {
      if (debugPhase == BoxyDelegatePhase.none) {
        throw FlutterError(
            'The $this boxy delegate attempted to get the context outside of its normal lifecycle.\n'
            'You should only access the BoxyDelegate from its overridden methods.');
      }
      return true;
    }());
    return _render!;
  }

  /// A list of each [BoxyChild] handle associated with the boxy, the list
  /// itself should not be modified by the delegate.
  List<ChildHandleType> get children {
    var out = render.childHandles;
    assert(() {
      out = UnmodifiableListView(out);
      return true;
    }());
    return out;
  }

  /// The most recent constraints given to this boxy by its parent.
  Constraints get constraints;

  /// The last size returned by layout.
  Size get renderSize;

  /// Returns true if a child exists with the specified [id].
  bool hasChild(Object id) => render.childHandleMap.containsKey(id);

  /// Gets the child handle with the specified [id].
  T getChild<T extends ChildHandleType>(Object id) {
    final child = render.childHandleMap[id];
    assert(() {
      if (child == null) {
        throw FlutterError(
            'The $this boxy delegate attempted to get a nonexistent child.\n'
            'There is no child with the id "$id".');
      }
      return true;
    }());
    return child! as T;
  }

  /// Gets the [BuildContext] of this boxy.
  BuildContext get buildContext => render.context;

  /// The number of children that have not been given a [BoxyId], this
  /// guarantees there are child ids between 0 (inclusive) and indexedChildCount
  /// (exclusive).
  int get indexedChildCount => render.indexedChildCount;

  /// The current canvas, should only be accessed from paint methods.
  Canvas get canvas {
    assert(() {
      if (debugPhase != BoxyDelegatePhase.paint) {
        throw FlutterError(
            'The $this boxy delegate attempted to access the canvas outside of a paint method.');
      }
      return true;
    }());
    return paintingContext.canvas;
  }

  /// The offset of the current paint context.
  ///
  /// This offset applies to to [paint] and [paintForeground] by default, you
  /// should translate by this in [paintChildren] if you paint to [canvas].
  Offset get paintOffset {
    assert(() {
      if (debugPhase != BoxyDelegatePhase.paint) {
        throw FlutterError(
            'The $this boxy delegate attempted to access the paint offset outside of a paint method.');
      }
      return true;
    }());
    return render.paintOffset!;
  }

  /// The current painting context, should only be accessed from paint methods.
  PaintingContext get paintingContext {
    assert(() {
      if (debugPhase != BoxyDelegatePhase.paint) {
        throw FlutterError(
            'The $this boxy delegate attempted to access the paint context outside of a paint method.');
      }
      return true;
    }());
    return render.paintingContext!;
  }

  BoxyLayerContext? _layers;

  /// The current layer context, useful for pushing [Layer]s to the scene during
  /// [paintChildren].
  ///
  /// Delegates that push layers should override [needsCompositing] to return
  /// true.
  BoxyLayerContext get layers => _layers ??= BoxyLayerContext._(render);

  /// Paints a [ContainerLayer] compositing layer in the current painting
  /// context with an optional [painter] callback, this should only be called in
  /// [paintChildren].
  ///
  /// This is useful if you wanted to apply filters to your children, for example:
  ///
  /// ```dart
  /// paintLayer(
  ///   OpacityLayer(alpha: 127),
  ///   painter: getChild(#title).paint,
  /// );
  /// ```
  @Deprecated('Use layers.push instead')
  void paintLayer(
    ContainerLayer layer, {
    VoidCallback? painter,
    Offset? offset,
    Rect? debugBounds,
  }) {
    final render = this.render;
    paintingContext.pushLayer(layer, (context, offset) {
      final lastContext = render.paintingContext;
      final lastOffset = render.paintOffset;
      render.paintingContext = context;
      render.paintOffset = lastOffset;
      if (painter != null) {
        painter();
      }
      render.paintingContext = lastContext;
      render.paintOffset = lastOffset;
    }, offset ?? render.paintOffset!, childPaintBounds: debugBounds);
  }

  /// Dynamically inflates a widget as a child of this boxy, should only be
  /// called in [BoxyChild.layout].
  ///
  /// If [id] is not provided the resulting child has an id of [indexedChildCount]
  /// which gets incremented.
  ///
  /// After calling this method the child becomes available with [getChild], it
  /// is removed before the next call to [BoxyChild.layout].
  ///
  /// A child's state will only be preserved if inflated with the same id as the
  /// previous layout.
  ///
  /// Unlike children passed to the widget, [Key]s cannot be used to move state
  /// from one child id to another. You may hit duplicate [GlobalKey] assertions
  /// from children inflated during the previous layout.
  T inflate<T extends ChildHandleType>(Widget widget, {Object? id}) {
    final render = this.render;
    assert(() {
      if (debugPhase == BoxyDelegatePhase.dryLayout) {
        render.debugThrowLayout(
            CannotInflateError(delegate: this, render: render));
      } else if (debugPhase != BoxyDelegatePhase.layout) {
        throw FlutterError(
            'The $this boxy attempted to inflate a widget outside of the layout method.\n'
            'You should only call `inflate` from its overridden methods.');
      }
      return true;
    }());
    return render.inflate<T>(widget, id: id);
  }

  /// Override this method to return true when the children need to be
  /// laid out.
  ///
  /// This should compare the fields of the current delegate and the given
  /// `oldDelegate` and return true if the fields are such that the layout would
  /// be different.
  bool shouldRelayout(covariant BaseBoxyDelegate oldDelegate) => false;

  /// Override this method to return true when the children need to be
  /// repainted.
  ///
  /// This should compare the fields of the current delegate and the given
  /// `oldDelegate` and return true if the fields are such that the paint would
  /// be different.
  ///
  /// This is only called if [shouldRelayout] returns false so it doesn't need
  /// to check fields that have already been checked by your [shouldRelayout].
  bool shouldRepaint(covariant BaseBoxyDelegate oldDelegate) => false;

  /// Override this method to return true if the [paint] method will push one or
  /// more layers to [paintingContext].
  ///
  /// It can be significantly more efficient to keep this false, otherwise if a
  /// delegate needs to interact with [layers], override this getter to return
  /// true.
  bool get needsCompositing => false;

  /// Override this method to include additional information in the
  /// debugging data printed by [debugDumpRenderTree] and friends.
  ///
  /// By default, returns the [runtimeType] of the class.
  @override
  String toString() => '$runtimeType';

  /// Override this method to paint above children.
  ///
  /// This method has access to [canvas] and [paintingContext] for painting.
  ///
  /// You can get the size of the widget with [renderSize].
  void paintForeground() {}

  /// Override this method to change how children get painted.
  ///
  /// This method has access to [canvas] and [paintingContext] for painting.
  ///
  /// The [canvas] available to this method is not transformed implicitly like
  /// [paint] and [paintForeground], implementers of this method should draw at
  /// [paintOffset] and restore the canvas before painting a child. This is
  /// required by the framework because a child might need to insert its own
  /// compositing [Layer] between two other [PictureLayer]s.
  void paintChildren() {
    for (final child in children) {
      child.paint();
    }
  }

  /// Override this method to paint below children.
  ///
  /// This method has access to [canvas] and [paintingContext] for painting.
  ///
  /// You can get the size of the widget with [renderSize].
  void paint() {}

  /// Adds the boxy to [hitTestResult], this should typically be called from
  /// [hitTest] when a hit succeeds.
  void addHit();

  /// The current hit test result, should only be accessed from [hitTest].
  HitTestResult get hitTestResult {
    assert(() {
      if (debugPhase != BoxyDelegatePhase.hitTest) {
        throw FlutterError(
            'The $this boxy delegate attempted to access hitTestResult outside of the hitTest method.');
      }
      return true;
    }());
    return render.hitTestResult!;
  }

  /// Override this method to change how the boxy gets hit tested.
  ///
  /// Return true to indicate a successful hit, false to let the parent continue
  /// testing other children.
  ///
  /// Call [addHit] to add the boxy to [hitTestResult].
  ///
  /// The default behavior is to hit test all children and call [addHit] if
  /// any succeeded.
  bool hitTest(SliverOffset position) {
    for (final child in children.reversed) {
      if (child.hitTest()) {
        addHit();
        return true;
      }
    }

    return false;
  }

  /// Override to handle pointer events that hit this boxy.
  ///
  /// See also:
  ///
  /// * [RenderObject.handleEvent], which has usage examples.
  void onPointerEvent(PointerEvent event, covariant HitTestEntry entry) {}
}

/// Widget that can provide data to the parent [CustomBoxy].
///
/// Similar to how [LayoutId] works, the parameters of this widget
/// can influence layout and paint behavior of its direct ancestor in the render
/// tree.
///
/// The [data] passed to this widget will be available to [BoxyDelegate] via
/// [BoxyChild.parentData].
///
/// See also:
///
///  * [CustomBoxy], which can use the data this widget provides.
///  * [ParentDataWidget], which has a more technical description of how this
///    works.
class BoxyId<T extends Object> extends ParentDataWidget<BaseBoxyParentData> {
  /// The object that identifies the child.
  final Object? id;

  /// Whether [data] was provided to this widget
  final bool hasData;

  final T? _data;
  final bool _alwaysRepaint;
  final bool _alwaysRelayout;

  /// Constructs a BoxyData with an optional id, data, and child.
  const BoxyId({
    this.id,
    Key? key,
    bool? hasData,
    T? data,
    required Widget child,
    bool alwaysRelayout = true,
    bool alwaysRepaint = true,
  })  : hasData = hasData ?? data != null,
        _data = data,
        _alwaysRelayout = alwaysRelayout,
        _alwaysRepaint = alwaysRepaint,
        super(
          key: key,
          child: child,
        );

  /// The data to provide to the parent.
  T get data {
    assert(hasData);
    return _data!;
  }

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is BaseBoxyParentData);
    final parentData = renderObject.parentData! as BaseBoxyParentData;
    final parent = renderObject.parent! as RenderObject;
    final dynamic oldUserData = parentData.userData;
    if (id != parentData.id) {
      parentData.id = id;
      parent.markNeedsLayout();
      if (hasData) {
        parentData.userData = data;
      }
    } else if (hasData) {
      if (
          // Avoid calling shouldRelayout if old data is null
          oldUserData == null || shouldRelayout(oldUserData as T)) {
        parent.markNeedsLayout();
      } else if (shouldRepaint(oldUserData)) {
        parent.markNeedsPaint();
      }
      parentData.userData = data;
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => LayoutInflatingWidget;

  /// Whether the difference in [data] should result in a relayout, defaults to
  /// the alwaysRelayout argument provided to our constructor.
  bool shouldRelayout(T oldData) => _alwaysRelayout;

  /// Whether the difference in [data] should result in a repaint, defaults to
  /// the alwaysRepaint argument provided to our constructor.
  bool shouldRepaint(T oldData) => _alwaysRepaint;
}
