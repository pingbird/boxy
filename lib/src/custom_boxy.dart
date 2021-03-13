import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A widget that uses a delegate to control the layout of multiple children.
///
/// This is basically a much more powerful version of [CustomMultiChildLayout],
/// it allows you to inflate, constrain, and lay out each child manually, it
/// also allows the size of the widget to depend on the layout of its children.
///
/// In most cases you do not need this much control over layout where some
/// combination of [Stack], [LayoutBuilder], and [Flow] is more suitable.
///
/// Children can be wrapped in a [LayoutId] widget to give them an arbitrary
/// [Object] id to be accessed by the [BoxyDelegate], otherwise they are given
/// an incrementing int id in the order they are provided, for example:
///
/// ```dart
/// Boxy(
///   delegate: MyBoxyDelegate(),
///   children: [
///     Container(color: Colors.red)), // Child 0
///     LayoutId(id: #green, child: Container(color: Colors.green)),
///     Container(color: Colors.green)), // Child 1
///   ],
/// );
/// ```
///
/// See also:
///
///  * [BoxyDelegate], the base class of a delegate.
class CustomBoxy extends RenderObjectWidget {
  /// Constructs a CustomBoxy with a delegate and optional set of children.
  const CustomBoxy({
    Key? key,
    required this.delegate,
    this.children = const <Widget>[],
  }) : super(key: key);

  /// The list of children this boxy is a parent of.
  final List<Widget> children;

  /// The delegate that controls the layout of the children.
  final BoxyDelegate delegate;

  @override
  _RenderBoxy createRenderObject(BuildContext context) =>
    _RenderBoxy(delegate: delegate);

  @override
  _RenderBoxyElement createElement() =>
    _RenderBoxyElement(this);

  @override
  void updateRenderObject(BuildContext context, _RenderBoxy renderObject) {
    renderObject.delegate = delegate;
  }
}

class _RenderBoxyElementEntry extends LinkedListEntry<_RenderBoxyElementEntry> {
  _RenderBoxyElementEntry(this.id, this.element);
  final Object id;
  Element element;
}

typedef _RenderBoxyInflater = RenderBox Function(Object, Widget);

/// An Element that uses a [CustomBoxy] as its configuration, this is similar to
/// [MultiChildRenderObjectElement] but allows multiple children to be inflated
/// during layout.
class _RenderBoxyElement extends RenderObjectElement {
  _RenderBoxyElement(CustomBoxy widget)
    : assert(!debugChildrenHaveDuplicateKeys(widget, widget.children)),
      super(widget);

  @override
  CustomBoxy get widget => super.widget as CustomBoxy;

  @override
  _RenderBoxy get renderObject => super.renderObject as _RenderBoxy;

  // Elements of children explicitly passed to the widget.
  List<Element>? _children;

  // Elements of widgets inflated at layout time, this is separate from
  // _children so we can leverage the performance of updateChildren without
  // touching ones inflated by the delegate.
  final LinkedList<_RenderBoxyElementEntry> _delegateChildren = LinkedList<_RenderBoxyElementEntry>();

  // Hash map of each entry in _delegateChildren
  final _delegateCache = HashMap<Object, _RenderBoxyElementEntry>();

  void wrapInflaterCallback(void Function(_RenderBoxyInflater) callback) {
    Set<Object> inflatedIds;

    inflatedIds = <Object>{};

    int index = 0;
    _RenderBoxyElementEntry? lastEntry;

    RenderBox inflateChild(Object id, Widget widget) {
      final slotIndex = index++;

      inflatedIds.add(id);

      var entry = _delegateCache[id];

      final children = _children!;

      void pushChild(Widget widget) {
        final newSlot = IndexedSlot(
          slotIndex, lastEntry == null ?
            (children.isEmpty ? null : children.last) : lastEntry!.element,
        );
        final newEntry = _RenderBoxyElementEntry(id, updateChild(null, widget, newSlot)!);
        entry = newEntry;
        _delegateCache[id] = newEntry;
        if (lastEntry == null) {
          _delegateChildren.addFirst(newEntry);
        } else {
          lastEntry!.insertAfter(newEntry);
        }
      }

      try {
        if (entry != null) {
          final movedTop = lastEntry == null && entry!.previous != null;
          final moved = movedTop || (lastEntry != null && entry!.previous?.id != lastEntry!.id);

          final newSlot = IndexedSlot(slotIndex, moved ?
            (movedTop ?
              (children.isEmpty ? null : children.last) :
              lastEntry!.element) :
            entry!.previous?.element ??
              (children.isEmpty ? null : children.last));

          entry!.element = updateChild(entry!.element, widget, newSlot)!;

          // Move child if it was inflated in a different order
          if (moved) {
            entry!.unlink();
            if (movedTop) {
              _delegateChildren.addFirst(entry!);
            } else {
              lastEntry!.insertAfter(entry!);
            }
            // oldSlot can be null because we don't use it
            moveRenderObjectChild(entry!.element.renderObject as RenderBox, null, newSlot);
          }
        } else {
          pushChild(widget);
        }
      } catch (e, stack) {
        final details = FlutterErrorDetails(
          context: ErrorDescription('building $widget'),
          exception: e,
          library: 'boxy library',
          stack: stack,
          informationCollector: () sync* {
            yield DiagnosticsDebugCreator(DebugCreator(this));
          }
        );

        FlutterError.reportError(details);

        pushChild(ErrorWidget.builder(details));
      }

      lastEntry = entry;

      assert(entry!.element.renderObject != null);

      return entry!.element.renderObject as RenderBox;
    }

    callback(inflateChild);

    // One or more cached children were not inflated, deactivate them.
    if (inflatedIds.length != _delegateCache.length) {
      assert(inflatedIds.length < _delegateCache.length);
      lastEntry = lastEntry == null ? _delegateChildren.first : lastEntry!.next;
      while (lastEntry != null) {
        final next = lastEntry!.next;
        assert(!inflatedIds.contains(lastEntry!.id));
        deactivateChild(lastEntry!.element);
        lastEntry!.unlink();
        _delegateCache.remove(lastEntry!.id);
        lastEntry = next;
      }
    }
  }

  // We keep a set of forgotten children to avoid O(n^2) work walking children
  // repeatedly to remove children.
  final Set<Element> _forgottenChildren = HashSet<Element>();

  @override
  void insertRenderObjectChild(RenderBox child, IndexedSlot<Element?>? slot) {
    final renderObject = this.renderObject;
    assert(renderObject.debugValidateChild(child));
    renderObject.insert(child, after: slot?.value?.renderObject as RenderBox?);
    assert(renderObject == this.renderObject);
  }

  @override
  void moveRenderObjectChild(RenderBox child, IndexedSlot<Element?>? oldSlot, IndexedSlot<Element?>? slot) {
    final renderObject = this.renderObject;
    assert(child.parent == renderObject);
    renderObject.move(child, after: slot?.value?.renderObject as RenderBox?);
    assert(renderObject == this.renderObject);
  }

  @override
  void removeRenderObjectChild(RenderBox child, IndexedSlot<Element?>? slot) {
    final renderObject = this.renderObject;
    assert(child.parent == renderObject);
    renderObject.remove(child);
    assert(renderObject == this.renderObject);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    for (final child in _children!) {
      if (!_forgottenChildren.contains(child))
        visitor(child);
    }

    for (final child in _delegateChildren) {
      visitor(child.element);
    }
  }

  @override
  void forgetChild(Element child) {
    bool inflated = false;
    for (final entry in _delegateChildren) {
      if (entry.element == child) {
        entry.unlink();
        _delegateCache.remove(entry.id);
        inflated = true;
        break;
      }
    }
    if (!inflated) {
      assert(!_forgottenChildren.contains(child));
      assert(_children!.contains(child));
      _forgottenChildren.add(child);
    }
    super.forgetChild(child);
  }

  @override
  void mount(Element? parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _children = List<Element?>.filled(widget.children.length, null) as List<Element>;

    Element? previousChild;
    for (int i = 0; i < _children!.length; i += 1) {
      final slot = IndexedSlot(i, previousChild);
      final newChild = inflateWidget(widget.children[i], slot);
      _children![i] = newChild;
      previousChild = newChild;
    }

    renderObject._element = this;
  }

  @override
  void unmount() {
    _delegateChildren.clear();
    _delegateCache.clear();
    _children = null;
    super.unmount();
  }

  @override
  void update(CustomBoxy newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);

    final children = updateChildren(_children ?? const [], widget.children, forgottenChildren: _forgottenChildren);
    _children = children;
    _forgottenChildren.clear();

    if (_delegateChildren.isNotEmpty) {
      final newSlot = children.isEmpty ?
        const IndexedSlot(0, null) :
        IndexedSlot(children.length, children.last);
      final childElement = _delegateChildren.first.element;
      if (childElement.slot != newSlot) {
        updateSlotForChild(childElement, newSlot);
      }
    }
  }

  @override
  void performRebuild() {
    // This gets called if markNeedsBuild() is called on us.
    // That might happen if, e.g., our delegate inflates InheritedWidgets.
    renderObject.markNeedsLayout();
    super.performRebuild(); // Calls widget.updateRenderObject (a no-op in this case).
  }
}

class _RenderBoxyParentData extends MultiChildLayoutParentData {
  dynamic userData;
}

class _RenderBoxy extends RenderBox with
  ContainerRenderObjectMixin<RenderBox, _RenderBoxyParentData> {

  _RenderBoxy({required BoxyDelegate delegate}) : _delegate = delegate;

  final _delegateContext = _BoxyDelegateContext();

  late _RenderBoxyElement _element;

  void flushInflateQueue() {
    _element.owner!.buildScope(_element, () {
      for (final child in _delegateContext.inflateQueue) {
        assert(child._widget != null);
        final childObject = _delegateContext.inflater!(child.id, child._widget!);
        child._render = childObject;
      }
      _delegateContext.inflateQueue.clear();
    });
  }

  @override
  void performLayout() {
    _delegateContext.render = this;
    _delegateContext.childrenMap.clear();

    assert(() {
      _delegateContext.debugChildrenNeedingLayout.clear();
      return true;
    }());

    int index = 0;
    int movingIndex = 0;
    RenderBox? child = firstChild;

    // Attempt to recycle existing child handles.
    final top = min(_element._children!.length, _delegateContext.children.length);
    while (index < top && child != null) {
      final parentData = child.parentData as _RenderBoxyParentData;
      var id = parentData.id;

      final oldChild = _delegateContext.children[index];
      if (oldChild.id != (id ?? movingIndex) || oldChild.render != child) break;

      // Assign the child an incrementing index if it does not already have one.
      id ??= movingIndex++;

      assert(() {
        _delegateContext.debugChildrenNeedingLayout.add(id);
        return true;
      }());

      _delegateContext.childrenMap[id] = _delegateContext.children[index++]
        .._ignore = false;
      child = parentData.nextSibling;
    }

    // Discard child handles that might be old
    for (int i = index; i < _delegateContext.children.length; i++) {
      _delegateContext.childrenMap.remove(_delegateContext.children[i].id);
    }
    _delegateContext.children.length = index;

    // Create new child handles
    while (child != null && index < _element._children!.length) {
      final parentData = child.parentData as _RenderBoxyParentData;
      var id = parentData.id;

      // Assign the child an incrementing index if it does not already have one.
      id ??= movingIndex++;

      assert(() {
        if (_delegateContext.childrenMap.containsKey(id)) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary('The $_delegate boxy delegate was given a child with a duplicate id.'),
            child!.describeForError('The following child has the duplicate id $id'),
          ]);
        }
        return true;
      }());

      final handle = BoxyChild._(
        context: _delegateContext,
        id: id,
        render: child,
      );

      assert(_delegateContext.children.length == index);
      index++;
      _delegateContext.childrenMap[id] = handle;
      _delegateContext.children.add(handle);

      assert(() {
        _delegateContext.debugChildrenNeedingLayout.add(id);
        return true;
      }());

      child = parentData.nextSibling;
    }

    _delegateContext.indexedChildCount = movingIndex;

    invokeLayoutCallback((BoxConstraints constraints) {
      _element.wrapInflaterCallback((inflater) {
        _delegateContext.inflater = inflater;
        delegate._callWithContext(_delegateContext, _BoxyDelegateState.Layout, () {
          try {
            size = delegate.layout();
          } finally {
            _delegateContext.render.flushInflateQueue();
          }
          size = constraints.constrain(size);
        });
        _delegateContext.inflater = null;
      });
    });

    assert(() {
      if (_delegateContext.debugChildrenNeedingLayout.isNotEmpty) {
        if (_delegateContext.debugChildrenNeedingLayout.length > 1) {
          throw FlutterError(
            'The $_delegate boxy delegate forgot to lay out the following children:\n'
            '  ${_delegateContext.debugChildrenNeedingLayout.map(_debugDescribeChild).join("\n  ")}\n'
            'Each child must be laid out exactly once.'
          );
        } else {
          throw FlutterError(
            'The $_delegate boxy delegate forgot to lay out the following child:\n'
            '  ${_debugDescribeChild(_delegateContext.debugChildrenNeedingLayout.single)}\n'
            'Each child must be laid out exactly once.'
          );
        }
      }
      return true;
    }());
  }

  @override
  Size computeDryLayout(BoxConstraints dryConstraints) {
    _delegateContext._dryConstraints = dryConstraints;
    Size? resultSize;
    try {
      delegate._callWithContext(_delegateContext, _BoxyDelegateState.DryLayout, () {
        resultSize = delegate.layout();
        assert(resultSize != null);
        resultSize = dryConstraints.constrain(resultSize!);
      });
    } on _CannotInflateError {
      return Size.zero;
    } finally {
      _delegateContext._dryConstraints = null;
    }
    return resultSize!;
  }

  String _debugDescribeChild(Object? id) =>
    '$id: ${_delegateContext.childrenMap[id!]!.render}';

  @override
  double computeMinIntrinsicWidth(double height) => _delegate._callWithContext(
    _delegateContext, _BoxyDelegateState.Intrinsics, () => _delegate.minIntrinsicWidth(height)
  );

  @override
  double computeMaxIntrinsicWidth(double height) => _delegate._callWithContext(
    _delegateContext, _BoxyDelegateState.Intrinsics, () => _delegate.maxIntrinsicWidth(height)
  );

  @override
  double computeMinIntrinsicHeight(double width) => _delegate._callWithContext(
    _delegateContext, _BoxyDelegateState.Intrinsics, () => _delegate.minIntrinsicHeight(width)
  );

  @override
  double computeMaxIntrinsicHeight(double width) => _delegate._callWithContext(
    _delegateContext, _BoxyDelegateState.Intrinsics, () => _delegate.maxIntrinsicHeight(width)
  );

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _RenderBoxyParentData)
      child.parentData = _RenderBoxyParentData();
  }

  /// The delegate that controls the layout of a set of children.
  BoxyDelegate _delegate;

  BoxyDelegate get delegate => _delegate;
  set delegate(BoxyDelegate newDelegate) {
    if (_delegate == newDelegate)
      return;

    final BoxyDelegate oldDelegate = _delegate;
    final neededCompositing = oldDelegate.needsCompositing;

    if (
      newDelegate.runtimeType != oldDelegate.runtimeType ||
      newDelegate.shouldRelayout(oldDelegate)
    ) {
      markNeedsLayout();
    } else if (newDelegate.shouldRepaint(oldDelegate)) {
      markNeedsPaint();
    }

    _delegate = newDelegate;

    if (neededCompositing != _delegate.needsCompositing) {
      markNeedsCompositingBitsUpdate();
    }

    if (attached) {
      oldDelegate._relayout?.removeListener(markNeedsLayout);
      oldDelegate._repaint?.removeListener(markNeedsPaint);
      newDelegate._relayout?.addListener(markNeedsLayout);
      newDelegate._repaint?.addListener(markNeedsPaint);
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _delegate._relayout?.addListener(markNeedsLayout);
    _delegate._repaint?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _delegate._relayout?.removeListener(markNeedsLayout);
    _delegate._repaint?.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _delegateContext.paintingContext = context;
    _delegate._callWithContext(
      _delegateContext, _BoxyDelegateState.Painting, () {
        context.canvas.save();
        context.canvas.translate(offset.dx, offset.dy);
        _delegateContext.offset = Offset.zero;
        _delegate.paint();
        context.canvas.restore();
        _delegateContext.offset = offset;
        _delegate.paintChildren();
        context.canvas.save();
        context.canvas.translate(offset.dx, offset.dy);
        _delegateContext.offset = Offset.zero;
        _delegate.paintForeground();
        context.canvas.restore();
      }
    );
    _delegateContext.paintingContext = null;
    _delegateContext.offset = null;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    _delegateContext.hitTestResult = result;
    _delegateContext.offset = position;
    try {
      return _delegate._callWithContext(
        _delegateContext, _BoxyDelegateState.HitTest, () {
          return _delegate.hitTest(position);
        }
      );
    } finally {
      _delegateContext.hitTestResult = null;
      _delegateContext.offset = null;
    }
  }

  @override
  bool get alwaysNeedsCompositing => _delegate.needsCompositing;
}

enum _BoxyDelegateState {
  None,
  Layout,
  Intrinsics,
  DryLayout,
  Painting,
  HitTest,
}

class _BoxyDelegateContext {
  _BoxyDelegateContext() {
    layers = BoxyLayerContext._(this);
  }

  late _RenderBoxy render;
  List<BoxyChild> inflateQueue = [];
  List<BoxyChild> children = [];
  Map<Object, BoxyChild> childrenMap = HashMap();
  int indexedChildCount = 0;
  PaintingContext? paintingContext;
  BoxHitTestResult? hitTestResult;
  Offset? offset;
  late BoxyLayerContext layers;
  Object? layoutData;
  _RenderBoxyInflater? inflater;
  BoxConstraints? _dryConstraints;

  final Set<Object?> debugChildrenNeedingLayout = {};

  _BoxyDelegateState _debugState = _BoxyDelegateState.None;
  _BoxyDelegateState get debugState => _debugState;
  set debugState(_BoxyDelegateState state) {
    assert(() {
      _debugState = state;
      return true;
    }());
  }
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
class LayerKey {
  /// The current cached layer.
  late Layer layer;
}

/// A convenient wrapper to [PaintingContext], provides methods to push
/// compositing [Layer]s from the paint methods of [BoxyDelegate].
///
/// See also:
///
///  * [BoxyDelegate]
class BoxyLayerContext {
  final _BoxyDelegateContext _context;

  BoxyLayerContext._(this._context);

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
    final oldContext = _context.paintingContext;
    final oldOffset = _context.offset;
    try {
      if (layer == null) {
        paint();
      } else {
        oldContext!.pushLayer(
          layer,
          (context, offset) {
            _context.paintingContext = context;
            _context.offset = offset;
            paint();
          },
          offset + _context.offset!,
          childPaintBounds: bounds,
        );
      }
    } finally {
      _context.paintingContext = oldContext;
      _context.offset = oldOffset;
    }
  }

  /// Pushes a [Layer] to the compositing tree similar to [push], but can't
  /// paint anything on top of it.
  ///
  /// {@macro boxy.custom_boxy.BoxyLayerContext.push.bounds}
  ///
  /// See also:
  ///
  ///  * [PaintingContext.addLayer]
  void add({required Layer layer}) {
    _context.paintingContext!.addLayer(layer);
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
    final offsetClipPath = path.shift(offset + _context.offset!);
    ClipPathLayer layer;
    if (key?.layer is ClipPathLayer) {
      layer = (key!.layer as ClipPathLayer)
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
    final offsetClipRect = rect.shift(offset + _context.offset!);
    ClipRectLayer layer;
    if (key?.layer is ClipRectLayer) {
      layer = (key!.layer as ClipRectLayer)
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
    final offsetClipRRect = rrect.shift(offset + _context.offset!);
    ClipRRectLayer layer;
    if (key?.layer is ClipRRectLayer) {
      layer = (key!.layer as ClipRRectLayer)
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
      layer = (key!.layer as ColorFilterLayer)..colorFilter = colorFilter;
    } else {
      layer = ColorFilterLayer(colorFilter: colorFilter);
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
      layer = (key!.layer as OffsetLayer)..offset = offset;
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
    final layerOffset = _context.offset! + offset;
    TransformLayer layer;
    if (key?.layer is TransformLayer) {
      layer = (key!.layer as TransformLayer)
        ..transform = transform
        ..offset = layerOffset;
    } else {
      layer = TransformLayer(
        transform: transform,
        offset: layerOffset,
      );
      key?.layer = layer;
    }
    push(layer: layer, paint: paint, offset: -_context.offset!, bounds: bounds);
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
      layer = (key!.layer as OpacityLayer)..alpha = alpha;
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

/// A handle used by a custom [BoxyDelegate] to lay out, paint, and hit test
/// its children.
///
/// This class cannot be instantiated directly, instead access children with
/// [BoxyDelegate.getChild].
///
/// See also:
///
///  * [CustomBoxy]
///  * [BoxyDelegate]
class BoxyChild {
  BoxyChild._({
    required _BoxyDelegateContext context,
    required this.id,
    RenderBox? render,
    Widget? widget,
  }) :
    _render = render,
    _widget = widget,
    _context = context,
    assert(render == null || render.parentData != null);

  final _BoxyDelegateContext _context;
  bool _ignore = false;
  final Widget? _widget;
  Offset? _dryOffset;
  Size? _drySize;

  /// The id of the child, will either be the id given by [LayoutId] or an
  /// incrementing int in the order provided to [CustomBoxy].
  final Object id;

  /// The RenderBox for this child in case you need to access intrinsic
  /// dimensions, size, constraints, etc.
  RenderBox get render {
    if (_render != null) return _render!;
    _context.render.flushInflateQueue();
    assert(_render != null);
    return _render!;
  }
  RenderBox? _render;

  _RenderBoxyParentData get _parentData =>
    render.parentData as _RenderBoxyParentData;

  /// A variable that can store arbitrary data by the [BoxyDelegate] during
  /// layout.
  ///
  /// See also:
  ///
  ///  * [ParentData]
  dynamic get parentData => _parentData.userData;

  set parentData(dynamic value) {
    _parentData.userData = value;
  }

  /// The offset to this child relative to the parent, this can be set by
  /// calling [position] from [BoxyDelegate.layout].
  Offset get offset => _dryOffset ?? _parentData.offset;

  /// The size of this child, should only be called after [layout].
  Size get size => _drySize ?? render.size;

  /// The rect of this child relative to the parent, this is only valid after
  /// [layout] and [position] have been called.
  Rect get rect {
    final offset = this.offset;
    final size = this.size;
    return Rect.fromLTWH(
      offset.dx, offset.dy,
      size.width, size.height,
    );
  }

  /// Sets the position of this child relative to the parent, this should only be
  /// called from [BoxyDelegate.layout].
  void position(Offset offset) {
    if (_context.debugState == _BoxyDelegateState.DryLayout) {
      _dryOffset = offset;
      return;
    }

    assert(() {
      if (_context.debugState != _BoxyDelegateState.Layout) {
        throw FlutterError(
          'The $this boxy delegate tried to position a child outside of the layout method.\n'
        );
      }

      return true;
    }());

    _parentData.offset = offset;
  }

  /// Lays out the child with the specified constraints and returns its size.
  ///
  /// If [useSize] is true, this boxy will re-layout when the child changes
  /// size.
  ///
  /// This should only be called in [BoxyDelegate.layout].
  Size layout(BoxConstraints constraints, {bool useSize = true}) {
    if (_context.debugState == _BoxyDelegateState.DryLayout) {
      _drySize = render.getDryLayout(constraints);
      return _drySize!;
    }

    assert(() {
      if (_context.debugState != _BoxyDelegateState.Layout) {
        throw FlutterError(
          'The $this boxy delegate tried to lay out a child outside of the layout method.\n'
        );
      }

      if (!_context.debugChildrenNeedingLayout.remove(id)) {
        throw FlutterError(
          'The $this boxy delegate tried to lay out the child with id "$id" more than once.\n'
          'Each child must be laid out exactly once.'
        );
      }

      try {
        assert(constraints.debugAssertIsValid(isAppliedConstraint: true));
      } on AssertionError catch (exception) {
        throw FlutterError(
          'The $this boxy delegate provided invalid box constraints for the child with id "$id".\n'
          '$exception\n'
          'The minimum width and height must be greater than or equal to zero.\n'
          'The maximum width must be greater than or equal to the minimum width.\n'
          'The maximum height must be greater than or equal to the minimum height.'
        );
      }

      return true;
    }());

    render.layout(constraints, parentUsesSize: useSize);

    return render.size;
  }

  /// Tightly lays out and positions the child so that it fits in [rect].
  void layoutRect(Rect rect) {
    layout(BoxConstraints.tight(rect.size));
    position(rect.topLeft);
  }

  /// Paints the child in the current paint context, this should only be called
  /// in [BoxyDelegate.paintChildren].
  ///
  /// This the canvas must be restored before calling this because the child
  /// might need its own [Layer] which is rendered in a separate context.
  void paint({Offset? offset}) {
    if (_ignore) return;
    assert(() {
      if (_context.debugState != _BoxyDelegateState.Painting) {
        throw FlutterError(
          'The $this boxy delegate tried to paint a child outside of the paint method.'
        );
      }

      return true;
    }());

    offset ??= _parentData.offset;
    _context.paintingContext!.paintChild(render, _context.offset! + offset);
  }

  /// Hit tests this child, returns true if the hit was a success. This should
  /// only be called in [BoxyDelegate.hitTest].
  ///
  /// The [offset] argument specifies the relative position of this child,
  /// defaults to the offset given to it during layout.
  ///
  /// The [position] argument specifies the relative position of the hit test,
  /// defaults to the position given to [BoxyDelegate.hitTest].
  bool hitTest({Offset? offset, Offset? position}) {
    if (_ignore) return false;
    return _context.hitTestResult!.addWithPaintOffset(
      offset: offset ?? this.offset,
      position: position ?? _context.offset!,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        return render.hitTest(result, position: transformed);
      },
    );
  }

  /// Whether or not this child should be ignored from painting and hit testing.
  bool get isIgnored => _ignore;

  /// Causes this child to be dropped from paint and hit testing, the child
  /// still needs to be layed out.
  void ignore([bool value = true]) {
    _ignore = value;
  }

  @override
  String toString() => 'BoxyChild(id: $id)';
}

class _CannotInflateError extends FlutterError {
  final BoxyDelegate delegate;

  _CannotInflateError(this.delegate) : super.fromParts([
    ErrorSummary(
      'The $delegate boxy attempted to inflate a widget during a dry layout.'
    ),
    ErrorDescription(
      'This happens if an ancestor of the boxy (e.g. Wrap) requires a '
      'dry layout, but your size also depends on an inflated widget.',
    ),
    ErrorDescription(
      'If your boxy\'s size does not depend on the size of this widget you '
      'can skip the call to `inflate` when `isDryLayout` is true',
    ),
  ]);
}

/// A delegate that controls the layout of multiple children, used with the
/// [CustomBoxy] widget.
///
/// Delegates must ensure an identical delegate would produce the same layout.
/// If your delegate takes arguments also make sure [shouldRelayout] and/or
/// [shouldRepaint] return true when those fields change.
///
/// Keep in mind a single delegate can be used by multiple widgets at a time and
/// should not keep any state. If you need to pass information from [layout] to
/// another method, store it in [layoutData] or [BoxyChild.parentData].
///
/// Delegates may access their children by id with [getChild], alternatively
/// they can be accessed through the [children] list.
///
/// The default constructor accepts [Listenable]s that can trigger a re-layout
/// and re-paint. For example during an animation it is more efficient to pass
/// the animation directly instead of having the parent rebuild [CustomBoxy] with a
/// new delegate.
///
/// ## Layout
///
/// Override [layout] to control the layout of children and return what size
/// the boxy should be.
///
/// This method must call [BoxyChild.layout] for each child. It should also
/// specify the final position of each child with [BoxyChild.position].
///
/// If you do not depend on the size of a particular child, pass useSize: false
/// to [BoxyChild.layout], this prevents a change in the size of the child from
/// causing a redundant re-layout.
///
/// The following example lays out two children like a column where the second
/// widget is the same width as the first:
///
/// ```dart
///   @override
///   Size layout() {
///     // Get both children by a Symbol id
///     var firstChild = getChild(#first);
///     var secondChild = getChild(#second);
///
///     // Lay out the first child with the incoming constraints
///     var firstSize = firstChild.layout(constraints);
///     firstChild.position(Offset.zero);
///
///     // Lay out the second child
///     var secondSize = secondChild.layout(
///       constraints.deflate(
///         // Subtract height consumed by the first child from the constraints
///         EdgeInsets.only(top: firstSize.height)
///       ).tighten(
///         // Force width to be the same as the first child
///         width: firstSize.width
///       )
///     );
///
///     // Position the second child below the first
///     secondChild.position(Offset(0, firstSize.height));
///
///     // Calculate the total size based on the size of each child
///     return Size(
///       firstSize.width,
///       firstSize.height + secondSize.height,
///     );
///   }
/// ```
///
/// ## Painting
///
/// Override [paint] to draw behind children, this is similar to
/// [CustomPainter.paint] where you get a [Canvas] to draw on.
///
/// The following example simply gives the widget a blue background:
///
/// ```dart
///   @override
///   void paint() {
///     canvas.drawRect(
///       Offset.zero & render.size,
///       Paint()..color = Colors.blue,
///     );
///   }
/// ```
///
/// You can draw above children by doing the same thing with [paintForeground].
///
/// Override [paintChildren] if you need to change the order children paint or
/// use the canvas between children.
///
/// The default behavior is to paint children at the offsets given to them
/// during [layout].
///
/// If you use the [canvas] in [paintChildren] you should draw at [paintOffset]
/// and make sure the canvas is restored before continuing to paint children.
/// This is required because a child might need its own compositing [Layer]
/// that is rendered in a separate context.
///
/// The following example draws a semi transparent rectangle between two
/// children:
///
/// ```dart
///   @override
///   void paintChildren() {
///     getChild(#first).paint();
///     canvas.drawRect(
///       paintOffset & render.size,
///       Paint()..color = Colors.blue.withOpacity(0.3),
///     );
///     getChild(#second).paint();
///   }
/// ```
///
/// ### Layers
///
/// In order to apply special effects to children such as transforms, opacity,
/// clipping, etc. you will need to interact with the compositing tree. Boxy
/// wraps this functionality conveniently with the [layers] getter.
///
/// Before your delegate can push layers make sure to override
/// [needsCompositing]. This getter can check the fields of the boxy to
/// determine if compositing will be necessary, returning true if that is the
/// case.
///
/// The following example paints its child with 50% opacity:
///
/// ```dart
///   @override
///   bool get needsCompositing => true;
///
///   @override
///   void paintChildren() {
///     layers.opacity(
///       opacity: 0.5,
///       paint: () {
///         getChild(#first).paint();
///       },
///     );
///   }
/// ```
///
/// ## Widget inflation
///
/// In [layout] you can inflate arbitrary widgets using the [inflate] method,
/// this enables complex layouts where the contents of widgets change depending
/// on the size and orientation of others in addition to the constraints.
///
/// After calling this method the child becomes available in [children] and
/// during further painting and hit testing, it is removed from the map before
/// the next call to [layout].
///
/// Unlike children explicitly passed to [CustomBoxy], keys are not managed for
/// widgets inflated during layout meaning a widgets state can only be
/// preserved if inflated with the same object id in the previous layout.
///
/// The following example places a text widget containing the size of the
/// first child below it:
///
/// ```dart
///   @override
///   Size layout() {
///     var firstChild = getChild(#first);
///
///     var firstSize = firstChild.layout(constraints);
///     firstChild.position(Offset.zero);
///
///     var text = Padding(child: Text(
///       "^ This guy is ${firstSize.width} x ${firstSize.height}",
///       textAlign: TextAlign.center,
///     ), padding: EdgeInsets.all(8));
///
///     // Inflate the text widget
///     var secondChild = inflate(text, id: #second);
///
///     var secondSize = secondChild.layout(
///       constraints.deflate(
///         EdgeInsets.only(top: firstSize.height)
///       ).tighten(
///         width: firstSize.width
///       )
///     );
///
///     secondChild.position(Offset(0, firstSize.height));
///
///     return Size(
///       firstSize.width,
///       firstSize.height + secondSize.height,
///     );
///   }
abstract class BoxyDelegate<T extends Object> {
  /// Constructs a BoxyDelegate with optional [relayout] and [repaint]
  /// [Listenable]s.
  BoxyDelegate({
    Listenable? relayout,
    Listenable? repaint,
  }) : _relayout = relayout, _repaint = repaint;

  final Listenable? _relayout;
  final Listenable? _repaint;

  _BoxyDelegateContext? _context;

  _BoxyDelegateContext _getContext() {
    assert(() {
      if (_context == null || _context!.debugState == _BoxyDelegateState.None) {
        throw FlutterError(
          'The $this boxy delegate attempted to get the context outside of its normal lifecycle.\n'
          'You should only access the BoxyDelegate from its overriden methods.'
        );
      }
      return true;
    }());
    return _context!;
  }

  /// A slot to hold additional data created during [layout] which can be used
  /// while painting and hit testing.
  T? get layoutData => _getContext().layoutData as T?;

  set layoutData(T? data) {
    assert(() {
      if (_context == null || _context!.debugState != _BoxyDelegateState.Layout) {
        throw FlutterError(
          'The $this boxy delegate attempted to set layout data outside of the layout method.\n'
        );
      }
      return true;
    }());
    _context!.layoutData = data;
  }

  /// The RenderBox of the current context.
  _RenderBoxy get render => _getContext().render;

  /// A list of each [BoxyChild] handle, this should not be modified in any way.
  List<BoxyChild> get children => _getContext().children;

  /// Returns true if a child exists with the specified [id].
  bool hasChild(Object id) => _getContext().childrenMap.containsKey(id);

  /// Gets the child handle with the specified [id].
  BoxyChild getChild(Object id) {
    final context = _getContext();
    final child = context.childrenMap[id];
    assert(() {
      if (child == null) {
        throw FlutterError(
          'The $this boxy delegate attempted to get a nonexistent child.\n'
          'There is no child with the id "$id".'
        );
      }
      return true;
    }());
    return child!;
  }

  /// Gets the current build context of this boxy.
  BuildContext get buildContext => _getContext().render._element;

  /// The number of children that have not been given a [LayoutId], this
  /// guarantees there are child ids between 0 (inclusive) to indexedChildCount
  /// (exclusive).
  int get indexedChildCount => _getContext().indexedChildCount;

  /// The most recent constraints given to this boxy during layout.
  BoxConstraints get constraints {
    final context = _getContext();
    return context._dryConstraints ?? context.render.constraints;
  }

  /// The current canvas, should only be accessed from paint methods.
  Canvas get canvas {
    assert(() {
      if (_context == null || _context!.debugState != _BoxyDelegateState.Painting) {
        throw FlutterError(
          'The $this boxy delegate attempted to access the canvas outside of a paint method.'
        );
      }
      return true;
    }());
    return _context!.paintingContext!.canvas;
  }

  /// The offset of the current paint context.
  ///
  /// This offset applies to to [paint] and [paintForeground] by default, you
  /// should translate by this in [paintChildren] if you paint to [canvas].
  Offset get paintOffset {
    assert(() {
      if (_context == null || _context!.debugState != _BoxyDelegateState.Painting) {
        throw FlutterError(
          'The $this boxy delegate attempted to access the paint offset outside of a paint method.'
        );
      }
      return true;
    }());
    return _context!.offset!;
  }

  /// The current painting context, should only be accessed from paint methods.
  PaintingContext get paintingContext {
    assert(() {
      if (_context == null || _context!.debugState != _BoxyDelegateState.Painting) {
        throw FlutterError(
          'The $this boxy delegate attempted to access the paint context outside of a paint method.'
        );
      }
      return true;
    }());
    return _context!.paintingContext!;
  }

  /// The current layer context, useful for pushing [Layer]s to the scene during
  /// [paintChildren].
  ///
  /// Delegates that push layers should override [needsCompositing] to return
  /// true.
  BoxyLayerContext get layers => _context!.layers;
  
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
  void paintLayer(ContainerLayer layer, {
    VoidCallback? painter, Offset? offset, Rect? debugBounds
  }) {
    final boxyContext = _getContext();
    paintingContext.pushLayer(layer, (context, offset) {
      final lastContext = boxyContext.paintingContext;
      final lastOffset = boxyContext.offset;
      boxyContext.paintingContext = context;
      boxyContext.offset = lastOffset;
      if (painter != null) painter();
      boxyContext.paintingContext = lastContext;
      boxyContext.offset = lastOffset;
    }, offset ?? boxyContext.offset!, childPaintBounds: debugBounds);
  }

  /// The current hit test result, should only be accessed from [hitTest].
  BoxHitTestResult get hitTestResult {
    assert(() {
      if (_context == null || _context!.debugState != _BoxyDelegateState.HitTest) {
        throw FlutterError(
          'The $this boxy attempted to get the hit test result outside of the hitTest method.'
        );
      }
      return true;
    }());
    return _context!.hitTestResult!;
  }

  T _callWithContext<T>(_BoxyDelegateContext context, _BoxyDelegateState state, T Function() func) {
    // A particular delegate could be called reentrantly, e.g. if it used
    // by both a parent and a child. So, we must restore the context when
    // we return.

    final prevContext = _context;
    _context = context;
    context.debugState = state;

    try {
      return func();
    } finally {
      context.debugState = _BoxyDelegateState.None;
      _context = prevContext;
    }
  }

  /// Dynamically inflates a widget as a child of this boxy, should only be
  /// called in [layout].
  ///
  /// If [id] is not provided the resulting child has an id of [indexedChildCount]
  /// which gets incremented.
  ///
  /// After calling this method the child becomes available with [getChild], it
  /// is removed before the next call to [layout].
  ///
  /// A child's state will only be preserved if inflated with the same id as the
  /// previous layout.
  ///
  /// Unlike children passed to the widget, [Key]s cannot be used to move state
  /// from one child id to another. You may hit duplicate [GlobalKey] assertions
  /// from children inflated during the previous layout.
  BoxyChild inflate(Widget widget, {Object? id}) {
    final context = _context;
    assert(() {
      if (context?.debugState == _BoxyDelegateState.DryLayout) {
        final error = _CannotInflateError(this);
        render.debugCannotComputeDryLayout(error: error);
        throw error;
      } else if (context == null || context.inflater == null) {
        throw FlutterError(
          'The $this boxy attempted to inflate a widget outside of the layout method.\n'
          'You should only call `inflate` from its overriden methods.'
        );
      }
      return true;
    }());

    id ??= context?.indexedChildCount++;

    assert(() {
      if (hasChild(id!)) {
        throw FlutterError(
          'The $this boxy delegate attempted to inflate a widget with a duplicate id.\n'
          'There is already a child with the id "$id"'
        );
      }
      context?.debugChildrenNeedingLayout.add(id);
      return true;
    }());

    final child = BoxyChild._(
      context: context!,
      id: id!,
      widget: widget,
    );

    context.inflateQueue.add(child);
    context.children.add(child);
    context.childrenMap[id] = child;

    return child;
  }

  /// Whether or not this boxy is performing a dry layout.
  bool get isDryLayout => _getContext().debugState == _BoxyDelegateState.DryLayout;

  /// Override this method to lay out children and return the final size of the
  /// boxy.
  ///
  /// This method must call [BoxyChild.layout] exactly once for each child. It
  /// should also specify the final position of each child with
  /// [BoxyChild.position].
  ///
  /// Unlike [MultiChildLayoutDelegate] the resulting size can depend on both
  /// child layouts and incoming [constraints].
  ///
  /// The default behavior is to pass incoming constraints to children and size
  /// to the largest dimensions, or the smallest size if there are no children.
  ///
  /// During a dry layout this method is called like normal, but calling methods
  /// such as [BoxyChild.position] and [BoxyChild.layout] no longer not affect
  /// their actual orientation. Additionally, the [inflate] method will throw
  /// an exception if called during a dry layout.
  Size layout() {
    Size biggest = constraints.smallest;
    for (final child in children) {
      final size = child.layout(constraints);
      biggest = Size(
        max(biggest.width, size.width),
        max(biggest.height, size.height)
      );
    }
    return biggest;
  }

  /// Override this method to return true when the children need to be
  /// laid out.
  ///
  /// This should compare the fields of the current delegate and the given
  /// `oldDelegate` and return true if the fields are such that the layout would
  /// be different.
  bool shouldRelayout(covariant BoxyDelegate oldDelegate) => false;

  /// Override this method to return true when the children need to be
  /// repainted.
  ///
  /// This should compare the fields of the current delegate and the given
  /// `oldDelegate` and return true if the fields are such that the paint would
  /// be different.
  ///
  /// This is only called if [shouldRelayout] returns false so it doesn't need
  /// to check fields that have already been checked by your [shouldRelayout].
  bool shouldRepaint(covariant BoxyDelegate oldDelegate) => false;

  /// Override this method to return true if the [paint] method will push one or
  /// more layers to [paintingContext].
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
  /// You can get the size of the widget with `render.size`.
  void paintForeground() {}

  /// Override this method to change how children get painted.
  ///
  /// This method has access to [canvas] and [paintingContext] for painting.
  ///
  /// If you paint to [canvas] here you should translate by [paintOffset] before
  /// painting yourself and restore before painting children. This translation
  /// is required because a child might need its own [Layer] which is rendered
  /// in a separate context.
  ///
  /// You can get the size of the widget with `render.size`.
  void paintChildren() {
    for (final child in children) child.paint();
  }

  /// Override this method to paint below children.
  ///
  /// This method has access to [canvas] and [paintingContext] for painting.
  ///
  /// You can get the size of the widget with `render.size`.
  void paint() {}

  /// Adds the boxy to the hit test result, call from [hitTest] when the hit
  /// succeeds.
  void addHit() {
    hitTestResult.add(BoxHitTestEntry(render, _getContext().offset!));
  }

  /// Override this method to change how the boxy gets hit tested.
  ///
  /// Return true to indicate a successful hit, false to let the parent continue
  /// testing other children.
  ///
  /// Call [hitTestAdd] to register the boxy in the hit result.
  ///
  /// The default behavior is to hit test all children and add itself to the
  /// result if any succeeded.
  bool hitTest(Offset position) {
    for (final child in children.reversed) {
      if (child.hitTest()) {
        addHit();
        return true;
      }
    }

    return false;
  }

  /// Override to change the minimum width that this box could be without
  /// failing to correctly paint its contents within itself, without clipping.
  ///
  /// See also:
  ///
  ///  * [RenderBox.computeMinIntrinsicWidth], which has usage examples.
  double minIntrinsicWidth(double height) {
    assert(() {
      if (!RenderObject.debugCheckingIntrinsics) {
        throw FlutterError(
          'Something tried to get the minimum intrinsic width of the boxy delegate $this.\n'
          'You must override minIntrinsicWidth to use the intrinsic width.'
        );
      }
      return true;
    }());
    return 0.0;
  }

  /// Override to change the maximum width that this box could be without
  /// failing to correctly paint its contents within itself, without clipping.
  ///
  /// See also:
  ///
  ///  * [RenderBox.computeMinIntrinsicWidth], which has usage examples.
  double maxIntrinsicWidth(double height) {
    assert(() {
      if (!RenderObject.debugCheckingIntrinsics) {
        throw FlutterError(
          'Something tried to get the maximum intrinsic width of the boxy delegate $this.\n'
          'You must override maxIntrinsicWidth to use the intrinsic width.'
        );
      }
      return true;
    }());
    return 0.0;
  }

  /// Override to change the minimum height that this box could be without
  /// failing to correctly paint its contents within itself, without clipping.
  ///
  /// See also:
  ///
  ///  * [RenderBox.computeMinIntrinsicWidth], which has usage examples.
  double minIntrinsicHeight(double width) {
    assert(() {
      if (!RenderObject.debugCheckingIntrinsics) {
        throw FlutterError(
          'Something tried to get the minimum intrinsic height of the boxy delegate $this.\n'
          'You must override minIntrinsicHeight to use the intrinsic width.'
        );
      }
      return true;
    }());
    return 0.0;
  }

  /// Override to change the maximum height that this box could be without
  /// failing to correctly paint its contents within itself, without clipping.
  ///
  /// See also:
  ///
  ///  * [RenderBox.computeMinIntrinsicWidth], which has usage examples.
  double maxIntrinsicHeight(double width) {
    assert(() {
      if (!RenderObject.debugCheckingIntrinsics) {
        throw FlutterError(
          'Something tried to get the maximum intrinsic height of the boxy delegate $this.\n'
          'You must override maxIntrinsicHeight to use the intrinsic width.'
        );
      }
      return true;
    }());
    return 0.0;
  }
}