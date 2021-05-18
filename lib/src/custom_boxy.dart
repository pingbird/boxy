import 'dart:math';

import 'package:boxy/src/custom_boxy_base.dart';
import 'package:boxy/src/inflating_element.dart';
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
class CustomBoxy extends LayoutInflatingWidget {
  /// Constructs a CustomBoxy with a delegate and optional set of children.
  const CustomBoxy({
    Key? key,
    required this.delegate,
    List<Widget> children = const <Widget>[],
  }) : super(
    key: key,
    children: children,
  );

  /// The delegate that controls the layout of the children.
  final BoxyDelegate delegate;

  @override
  _RenderBoxy createRenderObject(BuildContext context) {
    return _RenderBoxy(delegate: delegate);
  }

  @override
  void updateRenderObject(BuildContext context, _RenderBoxy renderObject) {
    renderObject.delegate = delegate;
  }
}

class _BoxyParentData extends BaseBoxyParentData<RenderBox> implements MultiChildLayoutParentData {}

class _RenderBoxy extends RenderBox with
  RenderBoxyMixin<RenderBox, _BoxyParentData, BoxyChild>,
  ContainerRenderObjectMixin<RenderBox, _BoxyParentData>,
  InflatingRenderObjectMixin<RenderBox, _BoxyParentData, BoxyChild> {
  BoxConstraints? _dryConstraints;
  BoxHitTestResult? hitTestResult;
  BoxyDelegate _delegate;

  _RenderBoxy({
    required BoxyDelegate delegate,
  }) : _delegate = delegate;

  @override
  BoxyDelegate get delegate => _delegate;

  @override
  set delegate(BoxyDelegate newDelegate) {
    final oldDelegate = delegate;
    _delegate = newDelegate;
    notifyChangedDelegate(oldDelegate);
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _BoxyParentData)
      child.parentData = _BoxyParentData();
  }

  @override
  void performInflatingLayout() {
    delegate.wrapContext(this, BoxyDelegatePhase.layout, () {
      var resultSize = constraints.smallest;
      resultSize = delegate.layout();
      size = constraints.constrain(resultSize);
    });
  }

  @override
  void debugThrowLayout(FlutterError error) {
    debugCannotComputeDryLayout(error: error);
    super.debugThrowLayout(error);
  }

  @override
  BoxyChild createChild({
    required Object id,
    Widget? widget,
    RenderObject? render,
  }) {
    return BoxyChild._(
      id: id,
      parent: this,
      widget: widget,
      render: render,
    );
  }

  @override
  Size computeDryLayout(BoxConstraints dryConstraints) {
    _dryConstraints = dryConstraints;
    Size? resultSize;
    try {
      delegate.wrapContext(this, BoxyDelegatePhase.dryLayout, () {
        resultSize = delegate.layout();
        assert(resultSize != null);
        resultSize = dryConstraints.constrain(resultSize!);
      });
    } on CannotInflateError {
      return Size.zero;
    } finally {
      _dryConstraints = null;
    }
    return resultSize!;
  }

  @override
  double computeMinIntrinsicWidth(double height) => delegate.wrapContext(
    this, BoxyDelegatePhase.intrinsics, () => delegate.minIntrinsicWidth(height)
  );

  @override
  double computeMaxIntrinsicWidth(double height) => delegate.wrapContext(
    this, BoxyDelegatePhase.intrinsics, () => delegate.maxIntrinsicWidth(height)
  );

  @override
  double computeMinIntrinsicHeight(double width) => delegate.wrapContext(
    this, BoxyDelegatePhase.intrinsics, () => delegate.minIntrinsicHeight(width)
  );

  @override
  double computeMaxIntrinsicHeight(double width) => delegate.wrapContext(
    this, BoxyDelegatePhase.intrinsics, () => delegate.maxIntrinsicHeight(width)
  );

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    hitTestResult = result;
    paintOffset = position;
    try {
      return delegate.wrapContext(
        this, BoxyDelegatePhase.hitTest, () {
          return delegate.hitTest(position);
        }
      );
    } finally {
      hitTestResult = null;
      paintOffset = null;
    }
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
class BoxyChild extends BaseBoxyChild {
  BoxyChild._({
    required Object id,
    required InflatingRenderObjectMixin parent,
    RenderObject? render,
    Widget? widget,
  }) : super(
    id: id,
    parent: parent,
    render: render,
    widget: widget,
  );

  Matrix4? _dryTransform;
  Size? _drySize;

  @override
  RenderBox get render => super.render as RenderBox;

  _BoxyParentData get _parentData => render.parentData as _BoxyParentData;

  _RenderBoxy get _parent {
    return render.parent as _RenderBoxy;
  }

  /// The offset to this child relative to the parent, set during
  /// [BoxyDelegate.layout].
  Offset get offset => Offset(transform[12], transform[13]);

  set offset(Offset newOffset) => position(offset);

  /// The translation applied to this child while painting.
  Matrix4 get transform => _dryTransform ?? _parentData.transform;

  /// Sets the paint [transform] of this child, should only be called during
  /// layout or paint.
  void setTransform(Matrix4 newTransform) {
    if (_parent.debugPhase == BoxyDelegatePhase.dryLayout) {
      _dryTransform = newTransform;
      return;
    }

    assert(() {
      if (
        _parent.debugPhase != BoxyDelegatePhase.layout
        && _parent.debugPhase != BoxyDelegatePhase.painting
      ) {
        throw FlutterError(
          'The $this boxy delegate tried to position a child outside of the layout or paint methods.\n'
        );
      }

      return true;
    }());

    _parentData.transform = newTransform;
  }

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
  void position(Offset newOffset) {
    setTransform(Matrix4.translationValues(newOffset.dx, newOffset.dy, 0));
  }

  /// Lays out the child with the specified constraints and returns its size.
  ///
  /// If [useSize] is true, this boxy will re-layout when the child changes
  /// size.
  ///
  /// This should only be called in [BoxyDelegate.layout].
  Size layout(BoxConstraints constraints, {bool useSize = true}) {
    if (_parent.debugPhase == BoxyDelegatePhase.dryLayout) {
      _drySize = render.getDryLayout(constraints);
      return _drySize!;
    }

    assert(() {
      if (_parent.debugPhase != BoxyDelegatePhase.layout) {
        throw FlutterError(
          'The $this boxy delegate tried to lay out a child outside of the layout method.\n'
        );
      }

      if (!_parent.debugChildrenNeedingLayout.remove(id)) {
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

  /// Lays out and positions the child so that it fits in [rect].
  ///
  /// If the [alignment] argument is provided the child is loosely constrained
  /// and aligned into [rect], otherwise it is tightly constrained.
  void layoutRect(Rect rect, {Alignment? alignment}) {
    if (alignment != null) {
      layout(BoxConstraints.loose(rect.size));
      position(alignment.inscribe(size, rect).topLeft);
    } else {
      layout(BoxConstraints.tight(rect.size));
      position(rect.topLeft);
    }
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
    if (isIgnored) return false;
    return _parent.hitTestResult!.addWithPaintTransform(
      transform: transform,
      position: position ?? _parent.paintOffset!,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        return render.hitTest(result, position: transformed);
      },
    );
  }
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
/// ```
class BoxyDelegate<LayoutData extends Object> extends BaseBoxyDelegate<LayoutData, BoxyChild> {
  /// Constructs a BoxyDelegate with optional [relayout] and [repaint]
  /// [Listenable]s.
  BoxyDelegate({
    Listenable? relayout,
    Listenable? repaint,
  }) : super(
    relayout: relayout,
    repaint: repaint,
  );

  /// The current hit test result, should only be accessed from [hitTest].
  HitTestResult get hitTestResult {
    assert(() {
      if (debugPhase != BoxyDelegatePhase.hitTest) {
        throw FlutterError(
            'The $this boxy attempted to get the hit test result outside of the hitTest method.'
        );
      }
      return true;
    }());
    return render.hitTestResult!;
  }

  @override
  _RenderBoxy get render => super.render as _RenderBoxy;

  /// A list of each [BoxyChild] handle, this should not be modified in any way.
  @override
  List<BoxyChild> get children => render.childHandles;

  /// The most recent constraints given to this boxy during layout.
  BoxConstraints get constraints {
    final render = this.render;
    return render._dryConstraints ?? render.constraints;
  }

  /// Whether or not this boxy is performing a dry layout.
  bool get isDryLayout => debugPhase == BoxyDelegatePhase.dryLayout;

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

  /// Adds the boxy to the hit test result, call from [hitTest] when the hit
  /// succeeds.
  void addHit() {
    hitTestResult.add(BoxHitTestEntry(render, render.paintOffset!));
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
}