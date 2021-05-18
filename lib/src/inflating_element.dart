import 'dart:collection';
import 'dart:math';

import 'package:boxy/boxy.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

/// The base class for widgets that can inflate arbitrary widgets during layout.
///
/// Used by [CustomBoxy] to perform similar layout-time widget inflation as
/// [LayoutBuilder], but allows delegates to inflate multiple widgets at the
/// same time, in addition to rendering a list of children provided to the
/// LayoutInflatingWidget.
abstract class LayoutInflatingWidget extends RenderObjectWidget {
  /// Base constructor for a widget that can inflate arbitrary widgets during
  /// layout.
  const LayoutInflatingWidget({
    Key? key,
    this.children = const [],
  }) : super(key: key);

  /// The list of children this boxy is a parent of.
  final List<Widget> children;

  @override
  InflatingElement createElement() => InflatingElement(this);
}

/// Linked list entry to keep track of inflated [Element]s
class _InflationEntry extends LinkedListEntry<_InflationEntry> {
  _InflationEntry(this.id, this.element);

  final Object id;
  Element element;
}

/// Parent data type of [InflatingRenderObjectMixin], provides an id for
/// the child similar to [MultiChildLayoutParentData].
class InflatingParentData<
  ChildType extends RenderObject
> extends ParentData with ContainerParentDataMixin<ChildType> {
  /// An id that can be optionally set using a [ParentDataWidget].
  Object? id;
}

/// The base class for lazily-inflated handles used to keep track of children
/// in a [LayoutInflatingWidget].
///
/// This class is typically not used directly, instead consider obtaining a
/// [BoxyChild] through [BaseBoxyDelegate.getChild].
class InflatedChildHandle {
  /// The id of the child, will either be the id given by LayoutId, BoxyId, or
  /// an incrementing int in-order.
  final Object id;

  final InflatingRenderObjectMixin _parent;

  /// The [RenderObject] representing this child.
  ///
  /// This getter is useful to access properties and methods that the child
  /// handle does not provide.
  RenderObject get render {
    if (_render != null) return _render!;
    _parent.flushInflateQueue();
    assert(_render != null);
    return _render!;
  }
  RenderObject? _render;

  final Widget? _widget;

  /// Constructs a child handle.
  InflatedChildHandle({
    required this.id,
    required InflatingRenderObjectMixin parent,
    RenderObject? render,
    Widget? widget,
  }) :
    _parent = parent,
    _render = render,
    _widget = widget,
    assert((render != null) != (widget != null), 'Either render or widget should be provided');
}

/// Signature for a function that inflates widgets during layout.
typedef _InflationCallback<T extends RenderObject> = T Function(Object, Widget);

/// Mixin for [RenderObject]s that can inflate arbitrary widgets during layout.
///
/// Objects that mixin this class should also use [ContainerRenderObjectMixin]
/// and be configured by [LayoutInflatingWidget].
/// [LayoutInflatingWidget],
mixin InflatingRenderObjectMixin<
  ChildType extends RenderObject,
  ParentDataType extends InflatingParentData<ChildType>,
  ChildHandleType extends InflatedChildHandle
> on RenderObject
  implements ContainerRenderObjectMixin<ChildType, ParentDataType>
{
  InflatingElement? _context;
  _InflationCallback<ChildType>? _inflater;
  var _indexedChildCount = 0;

  /// The current element that manages this RenderObject.
  ///
  /// Only valid while mounted.
  InflatingElement get context => _context!;

  /// A list of child handles for the associated [context] to manage.
  final childHandles = <ChildHandleType>[];

  /// A map of ids to child handles for the associated [context] to manage.
  final childHandleMap = <Object, ChildHandleType>{};

  /// A set of child ids that need layout.
  final debugChildrenNeedingLayout = <Object>{};

  /// The number of children with an integer id in order.
  int get indexedChildCount => _indexedChildCount;

  /// Override to perform layout where [inflater] is valid.
  void performInflatingLayout();

  final _inflateQueue = <ChildHandleType>[];

  void _allowSubtreeMutation(void Function() callback) {
    // Take off the training wheels and tell flutter we mean business.
    invokeLayoutCallback((constraints) {
      callback();
    });
  }

  /// Flushes the inflate queue so that newly inflated child handles become
  /// valid.
  ///
  /// We use a queue instead of wrapping [performInflatingLayout] in a single
  /// [BuildOwner.buildScope] because it cannot be called reentrantly, not doing
  /// layout inside of a scope is important because a descendant [Viewport],
  /// [CustomBoxy], [LayoutBuilder], etc. will also call it when being layed out.
  ///
  /// Should only be called during layout inside [performInflatingLayout].
  void flushInflateQueue() {
    // For some ungodly reason, eliding this call to buildScope if _inflateQueue
    // is empty causes a duplicate GlobalKey exception, only after inflating a
    // child and then moving it to another place in the tree.
    //
    // This is a symptom of us not understanding how GlobalKeys work, and/or a
    // bug in the framework, but we do have exhaustive testing that ensures
    // nothing is broken *too* badly in this regard.
    _allowSubtreeMutation(() {
      context.owner!.buildScope(context, () {
        for (final child in _inflateQueue) {
          assert(child._widget != null);
          final childObject = _inflater!(child.id, child._widget!);
          child._render = childObject;
        }
        _inflateQueue.clear();
      });
    });
  }

  /// Dynamically inflates a widget as a child, should only be called during
  /// layout inside [performInflatingLayout].
  ChildHandleType inflate(Widget widget, {Object? id}) {
    id ??= _indexedChildCount++;

    assert(() {
      if (childHandleMap.containsKey(id)) {
        throw FlutterError(
          'This boxy attempted to inflate a widget with a duplicate id.\n'
          'There is already a child with the id "$id"'
        );
      }
      debugChildrenNeedingLayout.add(id!);
      return true;
    }());

    final child = createChild(id: id, widget: widget);

    _inflateQueue.add(child);
    childHandles.add(child);
    childHandleMap[id] = child;

    return child;
  }

  /// Override to prepare children before layout, setting defaults for example.
  void prepareChild(ChildHandleType child) {}

  /// Override to construct custom [InflatedChildHandle]s.
  ChildHandleType createChild({
    required Object id,
    Widget? widget,
    RenderObject? render,
  }) {
    return InflatedChildHandle(
      id: id,
      parent: this,
      widget: widget,
      render: render,
    ) as ChildHandleType;
  }

  @override
  void performLayout() {
    childHandleMap.clear();

    assert(() {
      debugChildrenNeedingLayout.clear();
      return true;
    }());

    int index = 0;
    int movingIndex = 0;
    RenderObject? child = firstChild;

    // Attempt to recycle existing child handles.
    final top = min<int>(context._children!.length, childHandles.length);
    while (index < top && child != null) {
      final parentData = child.parentData as ParentDataType;
      var id = parentData.id;

      final oldChild = childHandles[index];
      if (oldChild.id != (id ?? movingIndex) || oldChild.render != child) break;

      // Assign the child an incrementing index if it does not already have one.
      id ??= movingIndex++;

      assert(() {
        debugChildrenNeedingLayout.add(id!);
        return true;
      }());

      final handle = childHandles[index++];
      childHandleMap[id] = handle;
      prepareChild(handle);
      child = parentData.nextSibling;
    }

    // Discard child handles that might be old
    for (int i = index; i < childHandles.length; i++) {
      childHandleMap.remove(childHandles[i].id);
    }
    childHandles.length = index;

    // Create new child handles
    while (child != null && index < context._children!.length) {
      final parentData = child.parentData as ParentDataType;
      var id = parentData.id;

      // Assign the child an incrementing index if it does not already have one.
      id ??= movingIndex++;

      assert(() {
        if (childHandleMap.containsKey(id)) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary('The Boxy was given children with duplicate ids.'),
            child!.describeForError('The following id was given to multiple children "$id"'),
          ]);
        }
        return true;
      }());

      final handle = createChild(id: id, render: child);

      assert(childHandles.length == index);
      index++;
      childHandleMap[id] = handle;
      childHandles.add(handle);

      assert(() {
        debugChildrenNeedingLayout.add(id!);
        return true;
      }());

      child = parentData.nextSibling;
    }

    _indexedChildCount = movingIndex;

    context._wrapInflater<ChildType>((inflater) {
      _inflater = inflater;
      try {
        performInflatingLayout();
      } finally {
        flushInflateQueue();
        _inflater = null;
      }
    });
  }
}

/// An Element that uses a [LayoutInflatingWidget] as its configuration, this is
/// similar to [MultiChildRenderObjectElement] but allows multiple children to
/// be inflated during layout.
class InflatingElement extends RenderObjectElement {
  /// Constructs an InflatingElement using the specified widget.
  InflatingElement(LayoutInflatingWidget widget)
    : assert(!debugChildrenHaveDuplicateKeys(widget, widget.children)),
      super(widget);

  @override
  LayoutInflatingWidget get widget => super.widget as LayoutInflatingWidget;

  @override
  InflatingRenderObjectMixin get renderObject => super.renderObject as InflatingRenderObjectMixin;

  // Elements of children explicitly passed to the widget.
  List<Element>? _children;

  // Elements of widgets inflated at layout time, this is separate from
  // _children so we can leverage the performance of updateChildren without
  // touching ones inflated by the delegate.
  final LinkedList<_InflationEntry> _delegateChildren = LinkedList<_InflationEntry>();

  // Hash map of each entry in _delegateChildren
  final _delegateCache = HashMap<Object, _InflationEntry>();

  void _wrapInflater<T extends RenderObject>(void Function(_InflationCallback<T>) callback) {
    Set<Object> inflatedIds;

    inflatedIds = <Object>{};

    int index = 0;
    _InflationEntry? lastEntry;

    T inflateChild(Object id, Widget widget) {
      final slotIndex = index++;

      inflatedIds.add(id);

      var entry = _delegateCache[id];

      final children = _children!;

      void pushChild(Widget widget) {
        final newSlot = IndexedSlot(
          slotIndex, lastEntry == null ?
            (children.isEmpty ? null : children.last) : lastEntry!.element,
        );
        final newEntry = _InflationEntry(id, updateChild(null, widget, newSlot)!);
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
            moveRenderObjectChild(entry!.element.renderObject!, null, newSlot);
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

      return entry!.element.renderObject as T;
    }

    callback(inflateChild);

    // One or more cached children were not inflated, deactivate them.

    if (inflatedIds.length != _delegateCache.length) {
      renderObject._allowSubtreeMutation(() {
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
      });
    }
  }

  /// We keep a set of forgotten children so [updateChildren] can avoid
  /// O(n^2) work checking if a child is forgotten before deactivating it.
  final Set<Element> _forgottenChildren = HashSet<Element>();

  @override
  void insertRenderObjectChild(RenderObject child, IndexedSlot<Element?>? slot) {
    final renderObject = this.renderObject;
    assert(renderObject.debugValidateChild(child));
    renderObject.insert(child, after: slot?.value?.renderObject);
    assert(renderObject == this.renderObject);
  }

  @override
  void moveRenderObjectChild(
    RenderObject child,
    IndexedSlot<Element?>? oldSlot,
    IndexedSlot<Element?>? newSlot,
  ) {
    final renderObject = this.renderObject;
    assert(child.parent == renderObject);
    renderObject.move(child, after: newSlot?.value?.renderObject);
    assert(renderObject == this.renderObject);
  }

  @override
  void removeRenderObjectChild(RenderObject child, IndexedSlot<Element?>? slot) {
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
    _children = <Element>[];

    Element? previousChild;
    for (int i = 0; i < widget.children.length; i += 1) {
      final slot = IndexedSlot(i, previousChild);
      final newChild = inflateWidget(widget.children[i], slot);
      _children!.add(newChild);
      previousChild = newChild;
    }

    renderObject._context = this;
  }

  @override
  void unmount() {
    renderObject._context = null;
    _delegateChildren.clear();
    _delegateCache.clear();
    _children = null;
    super.unmount();
  }

  @override
  void update(LayoutInflatingWidget newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);

    final children = updateChildren(
      _children ?? const [],
      widget.children,
      forgottenChildren: _forgottenChildren,
    );
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