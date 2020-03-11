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
class Boxy extends RenderObjectWidget {
  Boxy({
    Key key,
    @required this.delegate,
    this.children = const <Widget>[],
  }) : assert(delegate != null),
    assert(children != null),
    assert(() {
      final int index = children.indexOf(null);
      if (index >= 0) {
        throw FlutterError(
          "$runtimeType's children must not contain any null values, "
          'but a null value was found at index $index'
        );
      }
      return true;
    }()),
    super(key: key);

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

/// An Element that uses a [Boxy] as its configuration, this is similar to
/// [MultiChildRenderObjectElement] but allows multiple children to be inflated
/// during layout.
class _RenderBoxyElement extends RenderObjectElement {
  _RenderBoxyElement(Boxy widget)
    : assert(!debugChildrenHaveDuplicateKeys(widget, widget.children)),
      super(widget);

  @override
  Boxy get widget => super.widget as Boxy;

  @override
  _RenderBoxy get renderObject => super.renderObject as _RenderBoxy;

  // Elements of children explicitly passed to the widget.
  List<Element> _children;

  // Elements of widgets inflated by the delegate, this is separate from
  // explicit children so we can leverage updateChildren without
  // touching widgets inflated by the delegate.
  LinkedList<_RenderBoxyElementEntry> _delegateChildren;

  // Hash map of each entry in _delegateChildren
  Map<Object, _RenderBoxyElementEntry> _delegateCache;

  void _removeEntriesWhere(bool Function(_RenderBoxyElementEntry) predicate) {
    var _unlinked = false;
    var entry = _delegateChildren.isEmpty ? null : _delegateChildren.first;

    while (entry != null) {
      var next = entry.next;
      if (predicate(entry)) {
        deactivateChild(entry.element);
        _delegateCache.remove(entry.id);
        entry.unlink();
        _unlinked = true;
      } else if (_unlinked) {
        // Previous entry was unlinked, update slot.
        updateSlotForChild(entry.element, entry.previous?.element ?? _children.last);
        _unlinked = false;
      }
      entry = next;
    }
  }

  void wrapInflaterCallback(void Function(_RenderBoxyInflater) callback) {
    assert(_delegateCache != null && _delegateChildren != null);

    var inflatedIds = <Object>{};

    RenderBox inflateChild(Object id, Widget widget) {
      inflatedIds.add(id);
      var entry = _delegateCache[id];

      owner.buildScope(this, () {
        IndexedSlot nextSlot() => _children.isEmpty ?
          IndexedSlot(null, _delegateChildren.last.element) : IndexedSlot(null, _children.last);

        try {
          if (entry != null) {
            var slot = IndexedSlot(null, entry.previous?.element ?? _children.last);
            entry.element = updateChild(entry.element, widget, slot);
          } else {
            var slot = nextSlot();
            entry = _RenderBoxyElementEntry(id, updateChild(null, widget, slot));
            _delegateCache[id] = entry;
          }
        } catch (e, stack) {
          var details = FlutterErrorDetails(
            context: ErrorDescription('building $widget'),
            exception: e,
            library: "boxy library",
            stack: stack,
            informationCollector: () sync* {
              yield DiagnosticsDebugCreator(DebugCreator(this));
            }
          );

          FlutterError.reportError(details);

          var errorWidget = ErrorWidget.builder(details);
          var slot = _children.isEmpty ?
            IndexedSlot(null, _delegateChildren.last.element) : IndexedSlot(null, _children.last);
          entry = _RenderBoxyElementEntry(id, updateChild(null, errorWidget, slot));
          _delegateCache[id] = entry;
        }
      });

      assert(entry.element.renderObject != null);

      return entry.element.renderObject as RenderBox;
    }

    callback(inflateChild);

    if (inflatedIds.length != _delegateCache.length) {
      // One or more cached children were not inflated, deactivate them.
      _removeEntriesWhere((e) => !inflatedIds.contains(e));
    }
  }

  // We keep a set of forgotten children to avoid O(n^2) work walking children
  // repeatedly to remove children.
  final Set<Element> _forgottenChildren = HashSet<Element>();

  @override
  void insertChildRenderObject(RenderObject child, IndexedSlot<Element> slot) {
    var renderObject = this.renderObject;
    assert(renderObject.debugValidateChild(child));
    renderObject.insert(child, after: slot?.value?.renderObject);
    assert(renderObject == this.renderObject);
  }

  @override
  void moveChildRenderObject(RenderObject child, IndexedSlot<Element> slot) {
    var renderObject = this.renderObject;
    assert(child.parent == renderObject);
    renderObject.move(child, after: slot?.value?.renderObject);
    assert(renderObject == this.renderObject);
  }

  @override
  void removeChildRenderObject(RenderObject child) {
    var renderObject = this.renderObject;
    assert(child.parent == renderObject);
    renderObject.remove(child);
    assert(renderObject == this.renderObject);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    for (final child in _children) {
      if (!_forgottenChildren.contains(child))
        visitor(child);
    }

    for (final element in _delegateChildren) {
      if (!_forgottenChildren.contains(element.element))
        visitor(element.element);
    }
  }

  @override
  void forgetChild(Element child) {
    assert(_children.contains(child) || _delegateChildren.contains(child));
    assert(!_forgottenChildren.contains(child));
    _forgottenChildren.add(child);
    super.forgetChild(child);
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _children = List<Element>(widget.children.length);

    Element previousChild;
    for (int i = 0; i < _children.length; i += 1) {
      var slot = IndexedSlot(i, previousChild);
      var newChild = inflateWidget(widget.children[i], slot);
      _children[i] = newChild;
      previousChild = newChild;
    }

    _delegateChildren = LinkedList();
    _delegateCache = HashMap();
    renderObject._element = this;
  }

  @override
  void update(Boxy newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);

    _children = updateChildren(_children, widget.children, forgottenChildren: _forgottenChildren);
    _removeEntriesWhere((e) => _forgottenChildren.contains(e.element));

    if (_delegateChildren.isNotEmpty) {
      var newSlot = _children.isEmpty ?
        IndexedSlot(null, null) : IndexedSlot(null, _children.last);
      updateSlotForChild(_delegateChildren.first.element, newSlot);
    }

    _forgottenChildren.clear();
  }

  @override
  void performRebuild() {
    // This gets called if markNeedsBuild() is called on us.
    // That might happen if, e.g., our delegate inflates Inherited widgets.
    renderObject.markNeedsLayout();
    super.performRebuild(); // Calls widget.updateRenderObject (a no-op in this case).
  }
}

class _RenderBoxy extends RenderBox with
  ContainerRenderObjectMixin<RenderBox, MultiChildLayoutParentData>,
  RenderBoxContainerDefaultsMixin<RenderBox, MultiChildLayoutParentData> {

  _RenderBoxy({@required BoxyDelegate delegate}) : assert(delegate != null),
    _delegate = delegate;

  BoxyDelegate get delegate => _delegate;
  var _delegateContext = _BoxyDelegateContext();

  _RenderBoxyElement _element;

  BoxyChild inflateChild(Object id, Widget widget) {
    var childObject = _delegateContext.inflater(id, widget);
    assert(childObject != null);

    var child = BoxyChild._(
      context: _delegateContext,
      id: id,
      render: childObject,
    );

    _delegateContext.children[id] = child;
    return child;
  }

  @override
  void performLayout() {
    _delegateContext.render = this;
    _delegateContext.children.clear();

    assert(() {
      _delegateContext.debugChildrenNeedingLayout = {};
      return true;
    }());

    int childIndex = 0;
    RenderBox child = firstChild;
    while (child != null) {
      final MultiChildLayoutParentData parentData = child.parentData;
      var id = parentData.id;

      // Assign the child an incrementing index if it does not already have one.
      if (id == null) {
        id = childIndex++;
      }

      assert(() {
        if (_delegateContext.children.containsKey(id)) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary('The $_delegate boxy delegate was given a child with a duplicate id.'),
            child.describeForError('The following child has the duplicate id $id'),
          ]);
        }
        return true;
      }());

      _delegateContext.children[id] = BoxyChild._(
        context: _delegateContext,
        id: id,
        render: child,
      );

      assert(() {
        _delegateContext.debugChildrenNeedingLayout.add(id);
        return true;
      }());

      child = parentData.nextSibling;
    }

    _delegateContext.indexedChildCount = childIndex;

    invokeLayoutCallback((_) {
      _element.wrapInflaterCallback((inflater) {
        _delegateContext.inflater = inflater;
        delegate._callWithContext(_delegateContext, _BoxyDelegateState.Layout, () {
          size = constraints.constrain(delegate.layout());
        });
        _delegateContext.inflater = null;
      });
    });

    assert(() {
      if (_delegateContext.debugChildrenNeedingLayout.isNotEmpty) {
        if (_delegateContext.debugChildrenNeedingLayout.length > 1) {
          throw new FlutterError(
            'The $_delegate boxy delegate forgot to lay out the following children:\n'
            '  ${_delegateContext.debugChildrenNeedingLayout.map(_debugDescribeChild).join("\n  ")}\n'
            'Each child must be laid out exactly once.'
          );
        } else {
          throw new FlutterError(
            'The $_delegate boxy delegate forgot to lay out the following child:\n'
            '  ${_debugDescribeChild(_delegateContext.debugChildrenNeedingLayout.single)}\n'
            'Each child must be laid out exactly once.'
          );
        }
      }
      return true;
    }());
  }

  String _debugDescribeChild(Object id) =>
    '$id: ${_delegateContext.children[id].render}';

  @override
  double computeMinIntrinsicWidth(double height) => _delegate._callWithContext(
    _delegateContext, _BoxyDelegateState.Layout, () => _delegate.minIntrinsicWidth(height)
  );

  @override
  double computeMaxIntrinsicWidth(double height) => _delegate._callWithContext(
    _delegateContext, _BoxyDelegateState.Layout, () => _delegate.maxIntrinsicWidth(height)
  );

  @override
  double computeMinIntrinsicHeight(double width) => _delegate._callWithContext(
    _delegateContext, _BoxyDelegateState.Layout, () => _delegate.minIntrinsicHeight(width)
  );

  @override
  double computeMaxIntrinsicHeight(double width) => _delegate._callWithContext(
    _delegateContext, _BoxyDelegateState.Layout, () => _delegate.maxIntrinsicHeight(width)
  );

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! MultiChildLayoutParentData)
      child.parentData = MultiChildLayoutParentData();
  }

  // The delegate that controls the layout of the children.
  BoxyDelegate _delegate;

  set delegate(BoxyDelegate newDelegate) {
    assert(newDelegate != null);
    if (_delegate == newDelegate)
      return;
    final BoxyDelegate oldDelegate = _delegate;
    if (newDelegate.runtimeType != oldDelegate.runtimeType || newDelegate.shouldRelayout(oldDelegate)) {
      markNeedsLayout();
    } else if (newDelegate.shouldRepaint(oldDelegate)) {
      markNeedsPaint();
    }
    _delegate = newDelegate;
    if (attached) {
      oldDelegate?._relayout?.removeListener(markNeedsLayout);
      oldDelegate?._repaint?.removeListener(markNeedsPaint);
      newDelegate?._relayout?.addListener(markNeedsLayout);
      newDelegate?._repaint?.addListener(markNeedsPaint);
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _delegate?._relayout?.addListener(markNeedsLayout);
    _delegate?._repaint?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _delegate?._relayout?.removeListener(markNeedsLayout);
    _delegate?._repaint?.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _delegateContext.paintingContext = context;
    _delegateContext.offset = offset;
    _delegate._callWithContext(
      _delegateContext, _BoxyDelegateState.Painting, () {
        var canvas = context.canvas;
        canvas.save();
        canvas.translate(offset.dx, offset.dy);
        _delegate.paint();
        canvas.restore();
        _delegate.paintChildren();
        canvas.save();
        canvas.translate(offset.dx, offset.dy);
        _delegate.paintForeground();
        canvas.restore();
      }
    );
    _delegateContext.paintingContext = null;
    _delegateContext.offset = null;
  }

  bool hitTest(BoxHitTestResult result, { @required Offset position }) {
    return defaultHitTestChildren(result, position: position);
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
}

enum _BoxyDelegateState {
  None,
  Layout,
  Painting,
  HitTest,
}

class _BoxyDelegateContext {
  _RenderBoxy render;
  Map<Object, BoxyChild> children = LinkedHashMap();
  int indexedChildCount = 0;
  PaintingContext paintingContext;
  BoxHitTestResult hitTestResult;
  Offset offset;
  Object layoutData;
  _RenderBoxyInflater inflater;

  Set<Object> debugChildrenNeedingLayout;
  _BoxyDelegateState debugState = _BoxyDelegateState.None;

  void setState(_BoxyDelegateState state) {
    assert(() {
      debugState = state;
      return true;
    }());
  }
}

/// A handle used by custom [BoxyDelegate]s to lay out, paint, and hit test
/// its children.
///
/// This class cannot be instantiated directly, instead access children by name
/// with [BoxyDelegate.children].
///
/// See also:
///
///  * [Boxy]
///  * [BoxyDelegate]
class BoxyChild {
  BoxyChild._({
    @required _BoxyDelegateContext context,
    @required this.id,
    @required this.render,
  }) :
    _context = context,
    assert(render != null);

  final _BoxyDelegateContext _context;

  /// The id of the child, will either be the id given by [LayoutId] or an
  /// incrementing int in the order provided to [Boxy].
  final Object id;

  /// The RenderBox for this child in case you need to access intrinsic
  /// dimensions, size, constraints, etc.
  final RenderBox render;

  MultiChildLayoutParentData get _parentData =>
    render.parentData as MultiChildLayoutParentData;

  /// The offset to this child relative to the parent, this can be set by
  /// calling [position] from [BoxyDelegate.layout].
  Offset get offset => _parentData.offset;

  /// The rect of this child relative to the parent, this is only valid after
  /// [layout] and [position] have been called.
  Rect get rect {
    var offset = _parentData.offset;
    var size = render.size;
    return Rect.fromLTWH(
      offset.dx, offset.dy,
      size.width, size.height,
    );
  }

  /// Sets the position of this child relative to the parent, this should only be
  /// called from [BoxyDelegate.layout].
  void position(Offset offset) {
    assert(() {
      if (_context.debugState != _BoxyDelegateState.Layout) {
        throw new FlutterError(
          'The $this boxy delegate tried to position a child outside of the layout method.\n'
        );
      }

      return true;
    }());

    _parentData.offset = offset;
  }

  /// Lays out the child given constraints and returns the size the child that
  /// fits in those constraints.
  ///
  /// By default [useSize] is true meaning if the child changes size the boxy is
  /// marked for needing layout, set this to false if you are not using it.
  ///
  /// This should only be called in [BoxyDelegate.layout].
  Size layout(BoxConstraints constraints, {bool useSize = true}) {
    assert(() {
      if (_context.debugState != _BoxyDelegateState.Layout) {
        throw new FlutterError(
          'The $this boxy delegate tried to lay out a child outside of the layout method.\n'
        );
      }

      if (!_context.debugChildrenNeedingLayout.remove(id)) {
        throw new FlutterError(
          'The $this boxy delegate tried to lay out the child with id "$id" more than once.\n'
          'Each child must be laid out exactly once.'
        );
      }

      try {
        assert(constraints.debugAssertIsValid(isAppliedConstraint: true));
      } on AssertionError catch (exception) {
        throw new FlutterError(
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

    return useSize ? render.size : null;
  }

  /// Paints the child in the current paint context, this should only be called
  /// in [BoxyDelegate.paintChildren].
  ///
  /// This the canvas must be restored before calling this because the child
  /// might need its own [Layer] which is rendered in a separate context.
  void paint({Offset offset}) {
    assert(() {
      if (_context.debugState != _BoxyDelegateState.Painting) {
        throw new FlutterError(
          'The $this boxy delegate tried to paint a child outside of the paint method.'
        );
      }

      return true;
    }());

    offset ??= _parentData.offset;
    _context.paintingContext.paintChild(render, _context.offset + offset);
  }

  bool hitTest(Offset position) {
    return _context.hitTestResult.addWithPaintOffset(
      offset: _context.offset,
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        return render.hitTest(result, position: transformed);
      },
    );
  }
}

/// A delegate that controls the layout of multiple children.
///
/// Used with [Boxy].
///
/// Delegates must ensure an identical delegate produces the same layout.
/// If your delegate takes arguments also make sure [shouldRelayout] and/or
/// [shouldRepaint] return true when fields change.
///
/// Keep in mind a single delegate can be used by multiple widgets at a time and
/// should not keep any state. If you need to pass information from [layout] to
/// another method, store it in [layoutData].
///
/// Delegates may access their children by id through [children], this map is a
/// [LinkedHashMap] of [BoxyChild] which can be iterated in the order the
/// children are provided to [Boxy].
///
/// The default constructor accepts [Listenable]s that can trigger a re-layout
/// and re-paint. For example during an animation it is more efficient to pass
/// the animation directly instead of having the parent rebuild [Boxy] with a
/// new delegate.
///
/// ### Layout
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
///     // Get both children by a Symbol id.
///     var firstChild = children[#first];
///     var secondChild = children[#second];
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
///       width: firstSize.width,
///       height: firstSize.height + secondSize.height,
///     );
///   }
/// ```
///
/// ### Painting
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
/// which is rendered in a separate context.
///
/// The following example draws a semi transparent rectangle between two
/// children:
///
/// ```dart
///   @override
///   void paintChildren() {
///     children[#first].paint();
///     canvas.drawRect(
///       paintOffset & render.size,
///       Paint()..color = Colors.blue.withOpacity(0.3),
///     );
///     children[#second].paint();
///   }
/// ```
///
/// ### Widget inflation
///
/// In [layout] you can inflate arbitrary widgets using the [inflate] method,
/// this enables complex layouts where the contents of widgets change depending
/// on the size and orientation of others in addition to the constraints.
///
/// After calling this method the child becomes available in [children] and
/// during further painting and hit testing, it is removed from the map before
/// the next call to [layout].
///
/// Unlike children explicitly passed to [Boxy], keys are not managed for
/// widgets inflated during layout meaning a widgets state can only be
/// preserved if inflated with the same object id in the previous layout.
///
/// The following example places a text widget containing the size of the
/// first child below it:
///
/// ```dart
///   @override
///   Size layout() {
///    var firstChild = children[#first];
///
///    var firstSize = firstChild.layout(constraints);
///    firstChild.position(Offset.zero);
///
///    var text = Padding(child: Text(
///      "^ This guy is ${firstSize.width} x ${firstSize.height}",
///      textAlign: TextAlign.center,
///    ), padding: EdgeInsets.all(8));
///
///    // Inflate the text widget
///    var secondChild = inflate(text, id: #second);
///
///    var secondSize = secondChild.layout(
///      constraints.deflate(
///        EdgeInsets.only(top: firstSize.height)
///      ).tighten(
///        width: firstSize.width
///      )
///    );
///
///    secondChild.position(Offset(0, firstSize.height));
///
///    return Size(
///      firstSize.width,
///      firstSize.height + secondSize.height,
///    );
///  }
///```
abstract class BoxyDelegate<T> {
  BoxyDelegate({
    Listenable relayout,
    Listenable repaint,
  }) : _relayout = relayout, _repaint = repaint;

  final Listenable _relayout;
  final Listenable _repaint;

  _BoxyDelegateContext _context;

  _BoxyDelegateContext _getContext() {
    assert(() {
      if (_context == null || _context.debugState == _BoxyDelegateState.None) {
        throw new FlutterError(
          'The $this boxy attempted to get the context outside of its normal lifecycle.\n'
          'You should only access the BoxyDelegate from its overriden methods.'
        );
      }
      return true;
    }());
    return _context;
  }

  /// A slot to hold additional data created during [layout] which can be used
  /// while painting and hit testing.
  T get layoutData => _getContext().layoutData as T;

  set layoutData(T data) {
    assert(() {
      if (_context == null || _context.debugState != _BoxyDelegateState.Layout) {
        throw new FlutterError(
          'The $this boxy attempted to set layout data outside of the layout method.\n'
        );
      }
      return true;
    }());
    _context.layoutData = data;
  }

  /// The RenderBox of the current context.
  _RenderBoxy get render => _getContext().render;

  /// A map from child ids to their [BoxyChild] handle.
  Map<Object, BoxyChild> get children => _getContext().children;

  /// The number of children that have not been given a [LayoutId], this
  /// guarantees there are child ids between 0 (inclusive) to indexedChildCount
  /// (exclusive).
  int get indexedChildCount => _getContext().indexedChildCount;

  /// The most recent constraints of the current layout.
  BoxConstraints get constraints => _getContext().render.constraints;

  /// The current canvas, should only be accessed from paint methods.
  Canvas get canvas {
    assert(() {
      if (_context == null || _context.debugState != _BoxyDelegateState.Painting) {
        throw new FlutterError(
          'The $this boxy attempted to access the canvas outside of a paint method.'
        );
      }
      return true;
    }());
    return _context.paintingContext.canvas;
  }

  /// The offset of the current paint context, should only be used if you paint
  /// to [canvas] in [paintChildren].
  Offset get paintOffset {
    assert(() {
      if (_context == null || _context.debugState != _BoxyDelegateState.Painting) {
        throw new FlutterError(
          'The $this boxy attempted to access the paint offset outside of a paint method.'
        );
      }
      return true;
    }());
    return _context.offset;
  }

  /// The current painting context, should only be accessed from paint methods.
  PaintingContext get paintingContext {
    assert(() {
      if (_context == null || _context.debugState != _BoxyDelegateState.Painting) {
        throw new FlutterError(
          'The $this boxy attempted to access the paint context outside of a paint method.'
        );
      }
      return true;
    }());
    return _context.paintingContext;
  }

  /// The current hit test result, should only be accessed from [hitTest].
  BoxHitTestResult get hitTestResult {
    assert(() {
      if (_context == null || _context.debugState != _BoxyDelegateState.HitTest) {
        throw new FlutterError(
          'The $this boxy attempted to get the hit test result outside of the hit hitTest method.'
        );
      }
      return true;
    }());
    return _context.hitTestResult;
  }

  T _callWithContext<T>(_BoxyDelegateContext context, _BoxyDelegateState state, T Function() func) {
    // A particular delegate could be called reentrantly, e.g. if it used
    // by both a parent and a child. So, we must restore the context when
    // we return.

    var prevContext = _context;
    _context = context;
    context.setState(state);

    try {
      return func();
    } finally {
      context.setState(_BoxyDelegateState.None);
      _context = prevContext;
    }
  }

  /// Dynamically inflates a widget as a child of this boxy, should only be
  /// called in [layout].
  ///
  /// If [id] is not provided the resulting child has an id of [indexedChildCount]
  /// which gets incremented.
  ///
  /// After calling this method the child becomes available in [children] and
  /// during further painting and hit testing, it is removed from the map before
  /// the next call to [layout].
  ///
  /// Unlike children explicitly passed to [Boxy], keys are not managed for
  /// widgets inflated during layout meaning a widgets state can only be
  /// preserved if inflated with the same object id in the previous layout.
  BoxyChild inflate(Widget child, {Object id}) {
    assert(() {
      if (_context == null || _context.inflater == null) {
        throw new FlutterError(
          'The $this boxy attempted to inflate a widget outside of the layout method.\n'
          'You should only call `inflate` from its overriden methods.'
        );
      }
      return true;
    }());

    if (id == null) {
      id = _context.indexedChildCount++;
    }

    assert(() {
      if (_context.children.containsKey(id)) {
        throw new FlutterError(
          'The $this boxy attempted to inflate a widget with a duplicate id.\n'
          'You should only call `inflate` from its overriden methods.'
        );
      }
      _context.debugChildrenNeedingLayout.add(id);
      return true;
    }());

    return render.inflateChild(id, child);
  }

  /// Override this method to lay out children and return the final size of the
  /// boxy.
  ///
  /// This method must call [BoxyChild.layout] for each child. It should also
  /// specify the final position of each child with [BoxyChild.position].
  ///
  /// Unlike [MultiChildLayoutDelegate] the output size can depend on both the
  /// child layout and incoming [constraints].
  ///
  /// The default behavior is to pass incoming constraints to children and size
  /// to the largest dimensions, or the smallest size if there are no children.
  Size layout() {
    Size biggest = constraints.smallest;
    for (final child in children.values) {
      var size = child.layout(constraints);
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
    for (final child in children.values) child.paint();
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
    hitTestResult.add(BoxHitTestEntry(render, _getContext().offset));
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
    for (final child in children.values) {
      if (child.hitTest(position)) {
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
  minIntrinsicWidth(double height) {
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
  maxIntrinsicWidth(double height) {
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
  minIntrinsicHeight(double width) {
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
  maxIntrinsicHeight(double width) {
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

CustomMultiChildLayout a;