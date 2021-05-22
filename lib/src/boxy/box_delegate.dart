import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../axis_utils.dart';
import 'box_child.dart';
import 'custom_boxy_base.dart';
import 'inflating_element.dart';

/// The [RenderObject] of [CustomBoxy], delegates control of layout to a
/// [BoxyDelegate].
///
/// See also:
///   * [CustomBoxy]
///   * [BoxyDelegate]
class RenderBoxy<ChildHandleType extends BaseBoxyChild> extends RenderBox with
  RenderBoxyMixin<RenderObject, BoxyParentData, ChildHandleType>,
  ContainerRenderObjectMixin<RenderObject, BoxyParentData>,
  InflatingRenderObjectMixin<RenderObject, BoxyParentData, ChildHandleType> {
  BoxBoxyDelegateMixin<Object, ChildHandleType> _delegate;

  @override
  final InflatedChildHandleFactory childFactory;

  /// Creates a RenderBoxy with a delegate.
  RenderBoxy({
    required BoxBoxyDelegateMixin<Object, ChildHandleType> delegate,
    required this.childFactory,
  }) : _delegate = delegate;

  BoxConstraints? _dryConstraints;

  @override
  BoxHitTestResult? hitTestResult;

  @override
  void prepareChild(ChildHandleType child) {
    super.prepareChild(child);
    final parentData = child.render.parentData as BoxyParentData;
    parentData.drySize = null;
    parentData.dryTransform = null;
  }

  @override
  BoxBoxyDelegateMixin<Object, ChildHandleType> get delegate => _delegate;

  @override
  set delegate(BoxBoxyDelegateMixin<Object, ChildHandleType> newDelegate) {
    final oldDelegate = delegate;
    _delegate = newDelegate;
    notifyChangedDelegate(oldDelegate);
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxyParentData)
      child.parentData = BoxyParentData();
  }

  @override
  void performInflatingLayout() {
    wrapPhase(BoxyDelegatePhase.layout, () {
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
  bool get isDryLayout => _dryConstraints != null;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    _dryConstraints = constraints;
    Size? resultSize;
    try {
      wrapPhase(BoxyDelegatePhase.dryLayout, () {
        resultSize = delegate.layout();
        resultSize = constraints.constrain(resultSize!);
      });
    } on CannotInflateError {
      return Size.zero;
    } finally {
      _dryConstraints = null;
    }
    return resultSize!;
  }

  @override
  double computeMinIntrinsicWidth(double height) => wrapPhase(
    BoxyDelegatePhase.intrinsics, () => delegate.minIntrinsicWidth(height)
  );

  @override
  double computeMaxIntrinsicWidth(double height) => wrapPhase(
    BoxyDelegatePhase.intrinsics, () => delegate.maxIntrinsicWidth(height)
  );

  @override
  double computeMinIntrinsicHeight(double width) => wrapPhase(
    BoxyDelegatePhase.intrinsics, () => delegate.minIntrinsicHeight(width)
  );

  @override
  double computeMaxIntrinsicHeight(double width) => wrapPhase(
    BoxyDelegatePhase.intrinsics, () => delegate.maxIntrinsicHeight(width)
  );

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    hitTestResult = result;
    paintOffset = position;
    try {
      return wrapPhase(
        BoxyDelegatePhase.hitTest, () {
          return delegate.hitTest(position);
        }
      );
    } finally {
      hitTestResult = null;
      paintOffset = null;
    }
  }

  @override
  bool hitTestBoxChild({required RenderBox child, required Offset position, required Matrix4 transform}) {
    return hitTestResult!.addWithPaintTransform(
      transform: transform,
      position: position,
      hitTest: (result, position) {
        return child.hitTest(result, position: position);
      },
    );
  }

  @override
  bool hitTestSliverChild({required RenderSliver child, required Offset position, required Matrix4 transform}) {
    position = position.rotateWithAxis(child.constraints.axis);
    return hitTestResult!.addWithPaintTransform(
      transform: transform,
      position: position,
      hitTest: (result, position) {
        return child.hitTest(
          SliverHitTestResult.wrap(result),
          crossAxisPosition: position.dx,
          mainAxisPosition: position.dy,
        );
      },
    );
  }
}

/// Mixin for the logic shared by [BoxBoxyDelegate] and [BoxyDelegate].
///
/// This mixin should typically not be used directly, instead consider extending
/// one of the above classes.
mixin BoxBoxyDelegateMixin<
  LayoutData extends Object,
  ChildHandleType extends BaseBoxyChild
> on BaseBoxyDelegate<LayoutData, ChildHandleType> {
  /// The current hit test result, should only be accessed from [hitTest].
  HitTestResult get hitTestResult {
    assert(() {
      if (debugPhase != BoxyDelegatePhase.hitTest) {
        throw FlutterError(
          'The $this boxy delegate attempted to access hitTestResult outside of the hitTest method.'
        );
      }
      return true;
    }());
    return render.hitTestResult!;
  }

  @override
  RenderBoxy<ChildHandleType> get render => super.render as RenderBoxy<ChildHandleType>;

  /// The most recent constraints given to this boxy by its parent.
  ///
  /// During a dry layout, this returns the last constraints given to the boxy's
  /// [RenderBox.getDryLayout].
  BoxConstraints get constraints {
    final render = this.render;
    return render._dryConstraints ?? render.constraints;
  }

  /// Whether or not this boxy is performing a dry layout.
  bool get isDryLayout => render.isDryLayout;

  /// Override this method to lay out children and return the final size of the
  /// boxy.
  ///
  /// This method should call [BoxyChild.layout] for each child. It should also
  /// specify the position of each child with [BoxyChild.position].
  ///
  /// Unlike [MultiChildLayoutDelegate] the resulting size can depend on both
  /// child layouts and incoming [constraints].
  ///
  /// For [BoxyDelegate]s, the default behavior is to pass incoming constraints
  /// to children and size to the largest dimensions, otherwise it returns the
  /// smallest size.
  ///
  /// During a dry layout this method is called like normal, but methods like
  /// [BoxyChild.position] and [BoxyChild.layout] no longer not affect their
  /// actual orientation. Additionally, the [inflate] method will throw
  /// [CannotInflateError] if called during a dry layout.
  Size layout() => constraints.smallest;

  /// Adds the boxy to [hitTestResult], this should typically be called from
  /// [hitTest] when a hit succeeds.
  void addHit() {
    hitTestResult.add(BoxHitTestEntry(render, render.paintOffset!));
  }

  /// Override this method to change how the boxy gets hit tested.
  ///
  /// Return true to indicate a successful hit, false to let the parent continue
  /// testing other children.
  ///
  /// Call [hitTestAdd] to add the boxy to [hitTestResult].
  ///
  /// The default behavior is to hit test all children and call [hitTestAdd] if
  /// any succeeded.
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

/// A delegate that controls the layout and paint of child widgets, used by
/// [CustomBoxy].
///
/// This is identical to [BoxyDelegate], but supports both [BoxyChild] and
/// [SliverBoxyChild] children.
class BoxBoxyDelegate<LayoutData extends Object>
  extends BaseBoxyDelegate<LayoutData, BaseBoxyChild>
  with BoxBoxyDelegateMixin<LayoutData, BaseBoxyChild> {
  /// Constructs a BoxyDelegate with optional [relayout] and [repaint]
  /// [Listenable]s.
  BoxBoxyDelegate({
    Listenable? relayout,
    Listenable? repaint,
  }) : super(
    relayout: relayout,
    repaint: repaint,
  );
}

/// A delegate that controls the layout and paint of child widgets, used by
/// [CustomBoxy].
///
/// Delegates must ensure an identical delegate would produce the same layout.
/// If your delegate takes arguments also make sure [shouldRelayout] and/or
/// [shouldRepaint] return true when those fields change.
///
/// A single delegate can be used by multiple widgets at a time and should not
/// keep any state. If you need to pass information from [layout] to another
/// method, store it in [layoutData] or [BoxyChild.parentData].
///
/// Delegates may access their children by name with [getChild], alternatively
/// they can be accessed through the [children] list.
///
/// The default constructor accepts [Listenable]s that can trigger re-layout and
/// re-paint. It's much more efficient for the boxy to listen directly to
/// animations than rebuilding the [CustomBoxy] with a new delegate each frame.
///
/// ## Layout
///
/// Override [layout] to control the layout of children and return what size
/// the boxy should be.
///
/// This method should call [BoxyChild.layout] for each child. It should also
/// specify the position of each child with [BoxyChild.position].
///
/// If the delegate does not depend on the size of a particular child, pass
/// `useSize: false` to [BoxyChild.layout], this prevents a change in the
/// child's size from causing a re-layout.
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
///         EdgeInsets.only(top: firstSize.height),
///       ).tighten(
///         // Force width to be the same as the first child
///         width: firstSize.width,
///       )
///     );
///
///     // Position the second child below the first
///     secondChild.position(Offset(0, firstSize.height));
///
///     // Calculate the total size based both child sizes
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
/// [CustomPainter.paint] which gives you a [Canvas].
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
/// You can draw above children similarly by overriding [paintForeground].
///
/// Override [paintChildren] to change how children themselves are painted, for
/// example changing the order or adding [layers].
///
/// The default behavior is to paint children at the [BoxyChild.offset] given to
/// them during [layout].
///
/// The [canvas] available to [paintChildren] is not transformed implicitly like
/// [paint] and [paintForeground], implementers of this method should draw at
/// [paintOffset] and restore the canvas before painting a child. This is
/// required by the framework because a child might need to insert its own
/// compositing [Layer] between two other [PictureLayer]s.
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
/// clipping, etc. delegates will need to interact with the compositing tree.
/// Boxy wraps this functionality conveniently with [layers].
///
/// Before a delegate can push layers make sure to override [needsCompositing].
/// This getter can check the fields of the boxy to determine if compositing
/// will be necessary, return true if that is the case.
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
/// One of the most powerful features of the boxy library is to inflate
/// arbitrary widgets at layout time, this would otherwise be extraordinarily
/// difficult to implement in Flutter.
///
/// In [layout] delegates can inflate arbitrary widgets using the [inflate]
/// method, this enables complex layouts where the contents of widgets change
/// depending on the size and orientation of others, in addition to
/// [constraints].
///
/// After calling this method the child becomes available in [children] and
/// any following painting and hit testing, it is removed from the list before
/// the next [layout].
///
/// Unlike children explicitly passed to [CustomBoxy], [Key]s are not managed for
/// widgets inflated during layout, this means a widgets state is preserved if
/// inflated again with the same object id, rather than equal [Key]s.
///
/// The following example displays a text widget describing the size of another
/// child:
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
abstract class BoxyDelegate<LayoutData extends Object>
  extends BaseBoxyDelegate<LayoutData, BoxyChild>
  with BoxBoxyDelegateMixin<LayoutData, BoxyChild> {
  /// Constructs a BoxyDelegate with optional [relayout] and [repaint]
  /// [Listenable]s.
  BoxyDelegate({
    Listenable? relayout,
    Listenable? repaint,
  }) : super(
    relayout: relayout,
    repaint: repaint,
  );

  @override
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
}