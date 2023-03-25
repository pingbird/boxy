import 'dart:collection';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

/// The base class for widgets that can inflate arbitrary widgets during layout.
///
/// Used by [CustomBoxy] to perform similar layout-time widget inflation as
/// [LayoutBuilder], but allows delegates to inflate multiple widgets at the
/// same time, in addition to rendering a list of children provided to the
/// LayoutInflatingWidget.
///
/// See also:
///
///  * [InflatingElement]
abstract class LayoutInflatingWidget extends RenderObjectWidget {
  /// Base constructor for a widget that can inflate arbitrary widgets during
  /// layout.
  const LayoutInflatingWidget({
    super.key,
    this.children = const [],
  });

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
///
/// See also:
///
///  * [InflatingElement]
class InflatingParentData<ChildType extends RenderObject> extends ParentData
    with ContainerParentDataMixin<ChildType> {
  /// An id that can be optionally set using a [ParentDataWidget].
  Object? id;
}

/// The base class for lazily-inflated handles used to keep track of children
/// in a [LayoutInflatingWidget].
///
/// This class is typically not used directly, instead consider obtaining a
/// [BoxyChild] through [BaseBoxyDelegate.getChild].
/// See also:
///
///  * [InflatingElement]
class InflatedChildHandle {
  /// The id of the child, will either be the id given by BoxyId, or an
  /// incrementing int.
  final Object id;

  final InflatingRenderObjectMixin _parent;

  RenderObject? _render;
  Element? _context;

  /// The [RenderObject] representing this child.
  ///
  /// This getter is useful to access properties and methods that the child
  /// handle does not provide.
  RenderObject get render {
    if (_render != null) {
      return _render!;
    }
    _parent.flushInflateQueue();
    assert(_render != null);
    return _render!;
  }

  /// The [Element] aka [BuildContext] representing this child.
  Element get context {
    if (_context != null) {
      return _context!;
    }
    _parent.flushInflateQueue();
    assert(_context != null);
    return _context!;
  }

  final Widget? _widget;

  /// Constructs a child handle.
  InflatedChildHandle({
    required this.id,
    required InflatingRenderObjectMixin parent,
    RenderObject? render,
    Widget? widget,
    Element? context,
  })  : _parent = parent,
        _render = render,
        _widget = widget,
        _context = context,
        assert((render != null) != (widget != null),
            'Either render or widget should be provided'),
        assert(render == null || context != null,
            "If render is not null, context can't be null");
}

/// Signature for a function that inflates widgets during layout.
typedef _InflationCallback = Element Function(Object, Widget);

/// Signature for constructors of [InflatedChildHandle] subclasses, used for
/// [InflatingRenderObjectMixin.childFactory].
typedef InflatedChildHandleFactory = T Function<T extends InflatedChildHandle>({
  required Object id,
  required InflatingRenderObjectMixin parent,
  RenderObject? render,
  Element? context,
  Widget? widget,
});

/// Mixin for [RenderObject]s that can inflate arbitrary widgets during layout.
///
/// Objects that mixin this class should also use [ContainerRenderObjectMixin]
/// and be configured by [LayoutInflatingWidget].
/// [LayoutInflatingWidget],
///
/// See also:
///
///  * [InflatingElement]
mixin InflatingRenderObjectMixin<
        ChildType extends RenderObject,
        ParentDataType extends InflatingParentData<ChildType>,
        ChildHandleType extends InflatedChildHandle> on RenderObject
    implements ContainerRenderObjectMixin<ChildType, ParentDataType> {
  InflatingElement? _context;
  _InflationCallback? _inflater;
  var _indexedChildCount = 0;
  var _needsBuildScope = false;
  var _didInflate = false;

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

  /// Override to perform layout where [flushInflateQueue] can be called to
  /// inflate child widgets.
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
  /// [CustomBoxy], [LayoutBuilder], etc. will also call it when being laid out.
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
    if (_inflateQueue.isEmpty && !_needsBuildScope) {
      return;
    }
    _needsBuildScope = false;
    _allowSubtreeMutation(() {
      context.owner!.buildScope(context, () {
        for (final child in _inflateQueue) {
          assert(child._widget != null);
          final element = _inflater!(child.id, child._widget!);
          child._render = element.renderObject;
          child._context = element;
        }
        _inflateQueue.clear();
      });
    });
  }

  /// Dynamically inflates a widget as a child, should only be called during
  /// layout inside [performInflatingLayout].
  T inflate<T extends InflatedChildHandle>(Widget widget, {Object? id}) {
    id ??= _indexedChildCount++;

    assert(() {
      if (childHandleMap.containsKey(id)) {
        throw FlutterError(
            'This boxy attempted to inflate a widget with a duplicate id.\n'
            'There is already a child with the id "$id"');
      }
      debugChildrenNeedingLayout.add(id!);
      return true;
    }());

    final child = childFactory<T>(id: id, parent: this, widget: widget);

    _inflateQueue.add(child as ChildHandleType);
    childHandles.add(child);
    childHandleMap[id] = child;
    _didInflate = true;

    return child;
  }

  /// Override to prepare children before layout, setting defaults for example.
  void prepareChild(ChildHandleType child) {}

  /// The default [childFactory], returns a base [InflatedChildHandle] for all
  /// types.
  T defaultChildFactory<T extends ChildHandleType>({
    required Object id,
    required InflatingRenderObjectMixin parent,
    RenderObject? render,
    Widget? widget,
  }) {
    return InflatedChildHandle(
      id: id,
      parent: this,
      widget: widget,
      render: render,
    ) as T;
  }

  /// Factory function that constructs an appropriate [InflatedChildHandle]
  /// based on the the generic type argument.
  InflatedChildHandleFactory get childFactory;

  void _addChildHandle(RenderObject child, Element context, Object id) {
    assert(() {
      if (childHandleMap.containsKey(id)) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('The Boxy was given children with duplicate ids.'),
          child.describeForError(
              'The following id was given to multiple children "$id"'),
        ]);
      }
      return true;
    }());

    final handle = childFactory<ChildHandleType>(
      id: id,
      parent: this,
      render: child,
      context: context,
    );

    childHandleMap[id] = handle;
    childHandles.add(handle);

    assert(() {
      debugChildrenNeedingLayout.add(id);
      return true;
    }());
  }

  /// Ensures [childHandles] and [childHandleMap] are ready to use outside of
  /// performLayout, useful for calculating intrinsic sizes.
  void updateChildHandles({bool doingLayout = false}) {
    if (doingLayout) {
      // We don't care about childHandleMap outside of performLayout
      childHandleMap.clear();
      assert(() {
        debugChildrenNeedingLayout.clear();
        return true;
      }());
    }

    int index = 0;
    int movingIndex = 0;
    RenderObject? child = firstChild;

    // Attempt to recycle existing child handles.
    final top = min<int>(context._children!.length, childHandles.length);
    while (index < top && child != null) {
      final parentData = child.parentData! as ParentDataType;
      var id = parentData.id;

      final oldChild = childHandles[index];
      if (oldChild.id != (id ?? movingIndex) || oldChild.render != child) {
        break;
      }

      // Assign the child an incrementing index if it does not already have one.
      id ??= movingIndex++;

      final handle = childHandles[index++];

      if (doingLayout) {
        assert(() {
          debugChildrenNeedingLayout.add(id!);
          return true;
        }());
        childHandleMap[id] = handle;
        prepareChild(handle);
      }

      child = parentData.nextSibling;
    }

    // Discard child handles that might be old
    for (int i = index; i < childHandles.length; i++) {
      childHandleMap.remove(childHandles[i].id);
    }
    childHandles.length = index;

    // Create new child handles
    while (child != null && index < context._children!.length) {
      final parentData = child.parentData! as ParentDataType;
      // Assign the child an incrementing index if it does not already have one.
      final childContext = context._children![index];
      assert(childContext.renderObject == child);
      _addChildHandle(child, childContext, parentData.id ?? movingIndex++);

      index++;
      child = parentData.nextSibling;
    }

    _indexedChildCount = movingIndex;
  }

  @override
  void performLayout() {
    updateChildHandles(doingLayout: true);
    context._wrapInflater((inflater) {
      _inflater = inflater;
      _didInflate = false;
      try {
        performInflatingLayout();
      } finally {
        flushInflateQueue();
        _needsBuildScope = _didInflate;
        _inflater = null;
      }
    });
  }
}

/// An Element that uses a [LayoutInflatingWidget] as its configuration, this is
/// similar to [MultiChildRenderObjectElement] but allows multiple children to
/// be inflated during layout.
///
/// These are the guts that make [BaseBoxyDelegate.inflate] possible.
///
/// See also:
///
///  * [InflatingRenderObjectMixin]
class InflatingElement extends RenderObjectElement {
  /// Constructs an InflatingElement using the specified widget.
  InflatingElement(LayoutInflatingWidget super.widget)
      : assert(!debugChildrenHaveDuplicateKeys(widget, widget.children));

  @override
  LayoutInflatingWidget get widget => super.widget as LayoutInflatingWidget;

  @override
  InflatingRenderObjectMixin get renderObject =>
      super.renderObject as InflatingRenderObjectMixin;

  // Elements of children explicitly passed to the widget.
  List<Element>? _children;

  // Elements of widgets inflated at layout time, this is separate from
  // _children so we can leverage the performance of updateChildren without
  // touching ones inflated by the delegate.
  final LinkedList<_InflationEntry> _delegateChildren =
      LinkedList<_InflationEntry>();

  // Hash map of each entry in _delegateChildren
  final _delegateCache = HashMap<Object, _InflationEntry>();

  void _wrapInflater(void Function(_InflationCallback) callback) {
    Set<Object> inflatedIds;

    inflatedIds = <Object>{};

    int index = 0;
    _InflationEntry? lastEntry;

    Element inflateChild(Object id, Widget widget) {
      final slotIndex = index++;

      inflatedIds.add(id);

      var entry = _delegateCache[id];

      final children = _children!;

      void pushChild(Widget widget) {
        final newSlot = IndexedSlot(
          slotIndex,
          lastEntry == null
              ? (children.isEmpty ? null : children.last)
              : lastEntry!.element,
        );
        final newEntry =
            _InflationEntry(id, updateChild(null, widget, newSlot)!);
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
          final moved = movedTop ||
              (lastEntry != null && entry!.previous?.id != lastEntry!.id);

          final newSlot = IndexedSlot(
              slotIndex,
              moved
                  ? (movedTop
                      ? (children.isEmpty ? null : children.last)
                      : lastEntry!.element)
                  : entry!.previous?.element ??
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
            });

        FlutterError.reportError(details);

        pushChild(ErrorWidget.builder(details));
      }

      lastEntry = entry;

      assert(entry!.element.renderObject != null);

      return entry!.element;
    }

    callback(inflateChild);

    // One or more cached children were not inflated, deactivate them.

    if (inflatedIds.length != _delegateCache.length) {
      renderObject._allowSubtreeMutation(() {
        assert(inflatedIds.length < _delegateCache.length);
        lastEntry =
            lastEntry == null ? _delegateChildren.first : lastEntry!.next;
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
  void insertRenderObjectChild(
      RenderObject child, IndexedSlot<Element?>? slot) {
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
  void removeRenderObjectChild(
      RenderObject child, IndexedSlot<Element?>? slot) {
    final renderObject = this.renderObject;
    assert(child.parent == renderObject);
    renderObject.remove(child);
    assert(renderObject == this.renderObject);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    for (final child in _children!) {
      if (!_forgottenChildren.contains(child)) {
        visitor(child);
      }
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
      final newSlot = children.isEmpty
          ? const IndexedSlot(0, null)
          : IndexedSlot(children.length, children.last);
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
    super
        .performRebuild(); // Calls widget.updateRenderObject (a no-op in this case).
  }
}
