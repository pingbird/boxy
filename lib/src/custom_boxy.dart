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
  CustomBoxy({
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
  List<Element> _children;

  // Elements of widgets inflated at layout time, this is separate from
  // _children so we can leverage the performance of _updateChildren without
  // touching ones inflated by the delegate.
  LinkedList<_RenderBoxyElementEntry> _delegateChildren;

  // Hash map of each entry in _delegateChildren
  Map<Object, _RenderBoxyElementEntry> _delegateCache;

  void wrapInflaterCallback(void Function(_RenderBoxyInflater) callback) {
    assert(_delegateCache != null && _delegateChildren != null);

    Set<Object> inflatedIds;

    inflatedIds = <Object>{};

    int index = 0;
    _RenderBoxyElementEntry lastEntry;

    RenderBox inflateChild(Object id, Widget widget) {
      var slotIndex = index++;

      inflatedIds.add(id);

      var entry = _delegateCache[id];

      void pushChild(Widget widget) {
        var newSlot = _IndexedSlot(
          slotIndex, lastEntry == null ?
            (_children.isEmpty ? null : _children.last) : lastEntry.element,
        );
        entry = _RenderBoxyElementEntry(id, updateChild(null, widget, newSlot));
        _delegateCache[id] = entry;
        if (lastEntry == null) {
          _delegateChildren.addFirst(entry);
        } else {
          lastEntry.insertAfter(entry);
        }
      }

      try {
        if (entry != null) {
          bool movedTop = lastEntry == null && entry.previous != null;
          bool moved = movedTop || (lastEntry != null && entry.previous?.id != lastEntry.id);

          var newSlot = _IndexedSlot(slotIndex, moved ?
            (movedTop ?
              (_children.isEmpty ? null : _children.last) :
              lastEntry.element) :
            entry.previous?.element ??
              (_children.isEmpty ? null : _children.last));

          entry.element = updateChild(entry.element, widget, newSlot);

          // Move child if it was inflated in a different order
          if (moved) {
            entry.unlink();
            if (movedTop) {
              _delegateChildren.addFirst(entry);
            } else {
              lastEntry.insertAfter(entry);
            }
            moveChildRenderObject(entry.element.renderObject, newSlot);
          }
        } else {
          pushChild(widget);
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

        pushChild(ErrorWidget.builder(details));
      }

      lastEntry = entry;

      assert(entry.element.renderObject != null);

      return entry.element.renderObject as RenderBox;
    }

    owner.buildScope(this, () {
      callback(inflateChild);
    });

    // One or more cached children were not inflated, deactivate them.
    if (inflatedIds.length != _delegateCache.length) {
      assert(inflatedIds.length < _delegateCache.length);
      lastEntry = lastEntry == null ? _delegateChildren.first : lastEntry.next;
      while (lastEntry != null) {
        var next = lastEntry.next;
        assert(!inflatedIds.contains(lastEntry.id));
        deactivateChild(lastEntry.element);
        lastEntry.unlink();
        _delegateCache.remove(lastEntry.id);
        lastEntry = next;
      }
    }
  }

  // We keep a set of forgotten children to avoid O(n^2) work walking children
  // repeatedly to remove children.
  final Set<Element> _forgottenChildren = HashSet<Element>();

  @override
  void insertChildRenderObject(RenderObject child, _IndexedSlot<Element> slot) {
    var renderObject = this.renderObject;
    assert(renderObject.debugValidateChild(child));
    renderObject.insert(child, after: slot?.value?.renderObject);
    assert(renderObject == this.renderObject);
  }

  @override
  void moveChildRenderObject(RenderObject child, _IndexedSlot<Element> slot) {
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

    for (final child in _delegateChildren) {
      visitor(child.element);
    }
  }

  @override
  void forgetChild(Element child) {
    bool inflated = false;
    for (var entry in _delegateChildren) {
      if (entry.element == child) {
        entry.unlink();
        _delegateCache.remove(entry.id);
        inflated = true;
        break;
      }
    }
    if (!inflated) {
      assert(!_forgottenChildren.contains(child));
      assert(_children.contains(child));
      _forgottenChildren.add(child);
    }
    super.forgetChild(child);
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _children = List<Element>(widget.children.length);

    Element previousChild;
    for (int i = 0; i < _children.length; i += 1) {
      var slot = _IndexedSlot(i, previousChild);
      var newChild = inflateWidget(widget.children[i], slot);
      _children[i] = newChild;
      previousChild = newChild;
    }

    _delegateChildren = LinkedList();
    _delegateCache = HashMap();
    renderObject._element = this;
  }

  /// Copy of [RenderObjectElement.updateChildren].
  ///
  /// A breaking change was made in Flutter v1.15.19 which changed slots from
  /// Element to IndexedSlot<Element>, so to keep compatibility with old
  /// versions we backport the algorithm.
  List<Element> _updateChildren(
    List<Element> oldChildren,
    List<Widget> newWidgets, {
    Set<Element> forgottenChildren,
  }) {
    assert(oldChildren != null);
    assert(newWidgets != null);

    Element replaceWithNullIfForgotten(Element child) {
      return forgottenChildren != null && forgottenChildren.contains(child) ? null : child;
    }

    int newChildrenTop = 0;
    int oldChildrenTop = 0;
    int newChildrenBottom = newWidgets.length - 1;
    int oldChildrenBottom = oldChildren.length - 1;

    final List<Element> newChildren = oldChildren.length == newWidgets.length ?
    oldChildren : List<Element>(newWidgets.length);

    Element previousChild;

    // Update the top of the list.
    while ((oldChildrenTop <= oldChildrenBottom) && (newChildrenTop <= newChildrenBottom)) {
      final Element oldChild = replaceWithNullIfForgotten(oldChildren[oldChildrenTop]);
      final Widget newWidget = newWidgets[newChildrenTop];
      if (oldChild == null || !Widget.canUpdate(oldChild.widget, newWidget))
        break;
      final Element newChild = updateChild(oldChild, newWidget, _IndexedSlot<Element>(newChildrenTop, previousChild));
      newChildren[newChildrenTop] = newChild;
      previousChild = newChild;
      newChildrenTop += 1;
      oldChildrenTop += 1;
    }

    // Scan the bottom of the list.
    while ((oldChildrenTop <= oldChildrenBottom) && (newChildrenTop <= newChildrenBottom)) {
      final Element oldChild = replaceWithNullIfForgotten(oldChildren[oldChildrenBottom]);
      final Widget newWidget = newWidgets[newChildrenBottom];
      if (oldChild == null || !Widget.canUpdate(oldChild.widget, newWidget))
        break;
      oldChildrenBottom -= 1;
      newChildrenBottom -= 1;
    }

    // Scan the old children in the middle of the list.
    final bool haveOldChildren = oldChildrenTop <= oldChildrenBottom;
    Map<Key, Element> oldKeyedChildren;
    if (haveOldChildren) {
      oldKeyedChildren = <Key, Element>{};
      while (oldChildrenTop <= oldChildrenBottom) {
        final Element oldChild = replaceWithNullIfForgotten(oldChildren[oldChildrenTop]);
        if (oldChild != null) {
          if (oldChild.widget.key != null)
            oldKeyedChildren[oldChild.widget.key] = oldChild;
          else
            deactivateChild(oldChild);
        }
        oldChildrenTop += 1;
      }
    }

    // Update the middle of the list.
    while (newChildrenTop <= newChildrenBottom) {
      Element oldChild;
      final Widget newWidget = newWidgets[newChildrenTop];
      if (haveOldChildren) {
        final Key key = newWidget.key;
        if (key != null) {
          oldChild = oldKeyedChildren[key];
          if (oldChild != null) {
            if (Widget.canUpdate(oldChild.widget, newWidget)) {
              // we found a match!
              // remove it from oldKeyedChildren so we don't unsync it later
              oldKeyedChildren.remove(key);
            } else {
              // Not a match, let's pretend we didn't see it for now.
              oldChild = null;
            }
          }
        }
      }
      assert(oldChild == null || Widget.canUpdate(oldChild.widget, newWidget));
      final Element newChild = updateChild(oldChild, newWidget, _IndexedSlot<Element>(newChildrenTop, previousChild));
      newChildren[newChildrenTop] = newChild;
      previousChild = newChild;
      newChildrenTop += 1;
    }

    // We've scanned the whole list.
    assert(oldChildrenTop == oldChildrenBottom + 1);
    assert(newChildrenTop == newChildrenBottom + 1);
    assert(newWidgets.length - newChildrenTop == oldChildren.length - oldChildrenTop);
    newChildrenBottom = newWidgets.length - 1;
    oldChildrenBottom = oldChildren.length - 1;

    // Update the bottom of the list.
    while ((oldChildrenTop <= oldChildrenBottom) && (newChildrenTop <= newChildrenBottom)) {
      final Element oldChild = oldChildren[oldChildrenTop];
      assert(replaceWithNullIfForgotten(oldChild) != null);
      final Widget newWidget = newWidgets[newChildrenTop];
      assert(Widget.canUpdate(oldChild.widget, newWidget));
      final Element newChild = updateChild(oldChild, newWidget, _IndexedSlot<Element>(newChildrenTop, previousChild));
      newChildren[newChildrenTop] = newChild;
      previousChild = newChild;
      newChildrenTop += 1;
      oldChildrenTop += 1;
    }

    // Clean up any of the remaining middle nodes from the old list.
    if (haveOldChildren && oldKeyedChildren.isNotEmpty) {
      for (final Element oldChild in oldKeyedChildren.values) {
        if (forgottenChildren == null || !forgottenChildren.contains(oldChild))
          deactivateChild(oldChild);
      }
    }

    return newChildren;
  }

  @override
  void update(CustomBoxy newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);

    _children = _updateChildren(_children, widget.children, forgottenChildren: _forgottenChildren);
    _forgottenChildren.clear();

    if (_delegateChildren.isNotEmpty) {
      _IndexedSlot<Element> newSlot = _children.isEmpty ?
        _IndexedSlot(0, null) :
        _IndexedSlot(_children.length, _children.last);
      var childElement = _delegateChildren.first.element;
      if (childElement.slot != newSlot) {
        updateSlotForChild(childElement, newSlot);
      }
    }
  }

  @override
  void performRebuild() {
    // This gets called if markNeedsBuild() is called on us.
    // That might happen if, e.g., our delegate inflates Inherited widgets.
    renderObject.markNeedsLayout();
    super.performRebuild(); // Calls widget.updateRenderObject (a no-op in this case).
  }
}

/// Copy of [IndexedSlot] to maintain compatibility with Flutter versions older
/// than v1.15.19.
@immutable
class _IndexedSlot<T> {
  /// Creates an [_IndexedSlot] with the provided [index] and slot [value].
  const _IndexedSlot(this.index, this.value);

  /// Information to define where the child occupying this slot fits in its
  /// parent's child list.
  final T value;

  /// The index of this slot in the parent's child list.
  final int index;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    return other is _IndexedSlot
      && index == other.index
      && value == other.value;
  }

  @override
  int get hashCode => hashValues(index, value);
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

    _delegateContext.children.add(child);
    _delegateContext.childrenMap[id] = child;
    return child;
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
    RenderBox child = firstChild;

    // Attempt to recycle existing child handles
    var top = min(_element._children.length, _delegateContext.children.length);
    while (index < top && child != null) {
      final MultiChildLayoutParentData parentData = child.parentData;
      var id = parentData.id;

      var oldChild = _delegateContext.children[index];
      if (oldChild.id != (id ?? movingIndex) || oldChild.render != child) break;

      // Assign the child an incrementing index if it does not already have one.
      if (id == null) {
        id = movingIndex++;
      }

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
    while (child != null && index < _element._children.length) {
      final MultiChildLayoutParentData parentData = child.parentData;
      var id = parentData.id;

      // Assign the child an incrementing index if it does not already have one.
      if (id == null) {
        id = movingIndex++;
      }

      assert(() {
        if (_delegateContext.childrenMap.containsKey(id)) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary('The $_delegate boxy delegate was given a child with a duplicate id.'),
            child.describeForError('The following child has the duplicate id $id'),
          ]);
        }
        return true;
      }());

      var handle = BoxyChild._(
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

    invokeLayoutCallback((_) {
      _element.wrapInflaterCallback((inflater) {
        _delegateContext.inflater = inflater;
        delegate._callWithContext(_delegateContext, _BoxyDelegateState.Layout, () {
          size = delegate.layout();
          assert(size != null);
          size = constraints.constrain(size);
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
    '$id: ${_delegateContext.childrenMap[id].render}';

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
        context.canvas.save();
        context.canvas.translate(offset.dx, offset.dy);
        _delegate.paint();
        context.canvas.restore();
        _delegate.paintChildren();
        context.canvas.save();
        context.canvas.translate(offset.dx, offset.dy);
        _delegate.paintForeground();
        context.canvas.restore();
      }
    );
    _delegateContext.paintingContext = null;
    _delegateContext.offset = null;
  }

  bool hitTest(BoxHitTestResult result, {@required Offset position}) {
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
  List<BoxyChild> children = [];
  Map<Object, BoxyChild> childrenMap = HashMap();
  int indexedChildCount = 0;
  PaintingContext paintingContext;
  BoxHitTestResult hitTestResult;
  Offset offset;
  Object layoutData;
  _RenderBoxyInflater inflater;

  final Set<Object> debugChildrenNeedingLayout = {};
  _BoxyDelegateState debugState = _BoxyDelegateState.None;

  void setState(_BoxyDelegateState state) {
    assert(() {
      debugState = state;
      return true;
    }());
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
    @required _BoxyDelegateContext context,
    @required this.id,
    @required this.render,
  }) :
    _context = context,
    assert(render != null),
    assert(render.parentData != null);

  final _BoxyDelegateContext _context;
  bool _ignore = false;

  /// The id of the child, will either be the id given by [LayoutId] or an
  /// incrementing int in the order provided to [CustomBoxy].
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
  /// If [useSize] is true, the boxy will re-layout when the child changes size,
  /// this defaults to false if [constraints] are tight.
  ///
  /// This should only be called in [BoxyDelegate.layout].
  Size layout(BoxConstraints constraints, {bool useSize}) {
    useSize ??= !constraints.isTight;
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

  /// Tightly lays out and positions the child so that it fits in [rect].
  layoutRect(Rect rect) {
    layout(BoxConstraints.tight(rect.size));
    position(rect.topLeft);
  }

  /// Paints the child in the current paint context, this should only be called
  /// in [BoxyDelegate.paintChildren].
  ///
  /// This the canvas must be restored before calling this because the child
  /// might need its own [Layer] which is rendered in a separate context.
  void paint({Offset offset}) {
    if (_ignore) return;
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

  /// Hit tests this child, returns true if the hit was a success. This should
  /// only be called in [BoxyDelegate.hitTest].
  ///
  /// The [offset] argument specifies the relative position of this child,
  /// defaults to the offset given to it during layout.
  ///
  /// The [position] argument specifies the relative position of the hit test,
  /// defaults to the position given to [BoxyDelegate.hitTest].
  bool hitTest({Offset offset, Offset position}) {
    if (_ignore) return false;
    return _context.hitTestResult.addWithPaintOffset(
      offset: offset ?? this.offset,
      position: position ?? _context.offset,
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
    assert(value != null);
    _ignore = value;
  }

  @override
  toString() => "BoxyChild(id: $id)";
}

/// A delegate that controls the layout of multiple children.
///
/// Used with [CustomBoxy].
///
/// Delegates must ensure an identical delegate produces the same layout.
/// If your delegate takes arguments also make sure [shouldRelayout] and/or
/// [shouldRepaint] return true when fields change.
///
/// Keep in mind a single delegate can be used by multiple widgets at a time and
/// should not keep any state. If you need to pass information from [layout] to
/// another method, store it in [layoutData].
///
/// Delegates may access their children by id with [getChild], alternatively
/// they can be accessed through the [children] list.
///
/// The default constructor accepts [Listenable]s that can trigger a re-layout
/// and re-paint. For example during an animation it is more efficient to pass
/// the animation directly instead of having the parent rebuild [CustomBoxy] with a
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
///     getChild(#first).paint();
///     canvas.drawRect(
///       paintOffset & render.size,
///       Paint()..color = Colors.blue.withOpacity(0.3),
///     );
///     getChild(#second).paint();
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
/// ```
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
          'The $this boxy delegate attempted to get the context outside of its normal lifecycle.\n'
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
          'The $this boxy delegate attempted to set layout data outside of the layout method.\n'
        );
      }
      return true;
    }());
    _context.layoutData = data;
  }

  /// The RenderBox of the current context.
  _RenderBoxy get render => _getContext().render;

  /// A list of each [BoxyChild] handle, this should not be modified in any way.
  List<BoxyChild> get children => _getContext().children;

  /// Returns true if a child exists with the specified [id].
  bool hasChild(Object id) => _getContext().childrenMap.containsKey(id);

  /// Gets the child handle with the specified [id].
  BoxyChild getChild(Object id) {
    var child = _getContext().childrenMap[id];
    assert(() {
      if (child == null) {
        throw new FlutterError(
          'The $this boxy delegate attempted to get a nonexistent child.\n'
          'There is no child with the id "$id".'
        );
      }
      return true;
    }());
    return child;
  }

  /// Gets the current build context of the boxy.
  BuildContext get buildContext => _getContext().render._element;

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
          'The $this boxy delegate attempted to access the canvas outside of a paint method.'
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
          'The $this boxy delegate attempted to access the paint offset outside of a paint method.'
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
          'The $this boxy delegate attempted to access the paint context outside of a paint method.'
        );
      }
      return true;
    }());
    return _context.paintingContext;
  }

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
  void paintLayer(ContainerLayer layer, {
    VoidCallback painter, Offset offset, Rect debugBounds
  }) {
    assert(layer != null);

    paintingContext.pushLayer(layer, (context, offset) {
      var lastContext = _context.paintingContext;
      var lastOffset = _context.offset;
      _context.paintingContext = context;
      _context.offset = lastOffset;
      if (painter != null) painter();
      _context.paintingContext = lastContext;
      _context.offset = lastOffset;
    }, offset ?? _context.offset, childPaintBounds: debugBounds);
  }

  /// The current hit test result, should only be accessed from [hitTest].
  BoxHitTestResult get hitTestResult {
    assert(() {
      if (_context == null || _context.debugState != _BoxyDelegateState.HitTest) {
        throw new FlutterError(
          'The $this boxy attempted to get the hit test result outside of the hitTest method.'
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
  /// After calling this method the child becomes available with [getChild], it
  /// is removed before the next call to [layout].
  ///
  /// A child's state will only be preserved if inflated with the same id as the
  /// previous layout.
  ///
  /// Unlike children passed to the widget, [Key]s cannot be used to move state
  /// from one child id to another. You may hit duplicate [GlobalKey] assertions
  /// from children inflated during the previous layout.
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
      if (hasChild(id)) {
        throw new FlutterError(
          'The $this boxy delegate attempted to inflate a widget with a duplicate id.\n'
          'There is already a child with the id "$id"'
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
    for (final child in children) {
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