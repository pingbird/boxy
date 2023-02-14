# Interactive Example

![](image%20(2).png)

[:simple-dart: DartPad](https://dartpad.boxy.wiki/?id=0d12f9092860c0793e57eb3b9cad2926){ .md-button .md-button--primary .block }

It takes a child (Hello, World!) and ensures the height equals the width, the custom RenderObject also animates opacity to show how [Layer](https://api.flutter.dev/flutter/rendering/Layer-class.html)s work.

The actual layout algorithm itself is quite simple, the annoying part is just the amount of boilerplate:

1. Subclass [LeafRenderObjectWidget](https://api.flutter.dev/flutter/widgets/LeafRenderObjectWidget-class.html), [SingleChildRenderObjectWidget](https://api.flutter.dev/flutter/widgets/SingleChildRenderObjectWidget-class.html), or [MultiChildRenderObjectWidget](https://api.flutter.dev/flutter/widgets/MultiChildRenderObjectWidget-class.html)
2. Implement [createRenderObject](https://api.flutter.dev/flutter/widgets/RenderObjectWidget/createRenderObject.html) / [updateRenderObject](https://api.flutter.dev/flutter/widgets/RenderObjectWidget/updateRenderObject.html) to pass variables to your RenderObject
3. Subclass [RenderBox](https://api.flutter.dev/flutter/rendering/RenderBox-class.html)
4. Mix in [RenderObjectWithChildMixin](https://api.flutter.dev/flutter/rendering/RenderObjectWithChildMixin-mixin.html), [ContainerRenderObjectMixin](https://api.flutter.dev/flutter/rendering/ContainerRenderObjectMixin-mixin.html), or [SlottedContainerRenderObjectMixin](https://api.flutter.dev/flutter/widgets/SlottedContainerRenderObjectMixin-mixin.html)
5. Implement setters to check and call [markNeedsPaint](https://api.flutter.dev/flutter/rendering/RenderObject/markNeedsPaint.html) or [markNeedsLayout](https://api.flutter.dev/flutter/rendering/RenderObject/markNeedsLayout.html)
6. Implement [performLayout](https://api.flutter.dev/flutter/rendering/RenderBox/performLayout.html)
7. Implement [paint](https://api.flutter.dev/flutter/rendering/RenderObject/paint.html)

The original goal of Boxy was to boil this down into a simple, intuitive delegate class, sort of like a [CustomPainter](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html) on steroids.

```dart
/// A container that sizes itself as a square depending on the largest dimension
/// of the child, centering it.
class Square extends SingleChildRenderObjectWidget {
  final double opacity;

  const Square({
    Key? key,
    required Widget? child,
    this.opacity = 1.0,
  }) : super(
    key: key,
    child: child,
  );

  @override
  RenderObject createRenderObject(BuildContext context) =>
    RenderSquare(opacity: opacity);

  /// This function is called when a new widget instance
  /// is provided from a rebuild.
  @override
  void updateRenderObject(BuildContext context, RenderSquare renderObject) {
    renderObject.opacity = opacity;
  }
}

class RenderSquare extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {

  RenderSquare({
    double opacity = 1.0,
  }) : _opacity = opacity;

  double _opacity;
  double get opacity => _opacity;
  set opacity(double value) {
    // Do an early return if the value is the same, this prevents
    // any redundant repaints or relayouts.
    //
    // This kind of early return is actually one of the most
    // important optimizations in the whole framework.
    if (_opacity == value) return;

    // Set the real opacity value.
    _opacity = value;

    // Here we tell notify the framework of changes to our
    // configuration, in this case the update is purely visual
    // so we call `markNeedsPaint`.
    //
    // If this property affects layout we would call
    // `markNeedsLayout` instead, which does a relayout + repaint.
    markNeedsPaint();
  }

  @override
  void performLayout() {
    if (child == null) {
      // RenderObjects must have a size after layout, and that size
      // be within the constraints provided to it.
      //
      // Since there is no child, just use the smallest allowed.
      size = constraints.smallest;
    } else {
      // If a RenderObject has a child, it must be layed out at
      // least once.
      //
      // The constraints parameter tells the child what the upper
      // and lower bounds of its size can be, just like how we
      // handle incoming constraints to RenderSquare. The child's
      // size is forced to fit these constraints, even if it leads
      // to overpainting or other layout problems.
      //
      // A child's size can only be used by us if it has been
      // layed out AND parentUsesSize is true. In situations where
      // our layout does not depend on the size of the child, the
      // parentUsesSize argument can be false.
      child!.layout(constraints, parentUsesSize: true);

      // Now that the child has been layed out, we can grab its size.
      final childSize = child!.size;

      // Calculate the width of our square by taking the maximum of
      // the child's width and height.
      final width = max(childSize.width, childSize.height);

      // Size ourselves to the closest size that still fits within
      // the constraints given by our parent.
      size = constraints.constrain(Size.square(width));

      // Each RenderObject has a `parentData` field that is managed
      // by its parent, this is initialized when the child is mounted
      // with our `setupParentData` method. The default implementation
      // for `RenderBox.setupParentData` initializes the child's
      // parentData field with a BoxParentData.
      //
      // In this case, we use BoxParentData to give the child a
      // paint offset, this offset can then read by other methods
      // like `paint` and `applyPaintTransform`.
      final parentData = child!.parentData as BoxParentData;

      // Center the child vertically and horizontally into our size.
      parentData.offset = Offset(
        (size.width - childSize.width) / 2,
        (size.height - childSize.height) / 2,
      );
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      // Paint always happens after the layout phase is complete,
      // so we can safely access the parentData from before.
      final parentData = child!.parentData as BoxParentData;

      // Opacity layers use an 8 bit alpha, rather than a float.
      //
      // This function just clamps, scales, and rounds a 0 - 1
      // opacity value to what the layer expects.
      final alpha = Color.getAlphaFromOpacity(opacity);

      // RenderObjects do not just paint to a canvas like you would
      // expect from a low level graphics library, instead they build
      // a tree of `Layer`s.
      //
      // Because many widgets do need a canvas to paint on, the
      // `PaintingContext` interface provides a way for many objects
      // to opportunistically share the same CanvasLayer, which stops
      // recording when you push your own layer, e.g. OpacityLayer.
      //
      // The side effect of this opportunistic sharing is that the
      // canvas it gives you must be restored before painting a child,
      // and before you return from `paint`.
      //
      // These layers can contain external textures such as native
      // views, they are also used as a way to efficiently update
      // specific features without repainting e.g. simple offsets
      // with OffsetLayer.
      //
      // This means in order to apply many paint effects to a child,
      // we have to push a layer underneath it. In this case, we push
      // an OpacityLayer.
      context.pushOpacity(offset, alpha, (context, offset) {
        // We call PaintingContext.paintChild to paint the child,
        // you can paint a specific child either once or not at all
        // per frame.
        context.paintChild(child!, offset + parentData.offset);
      });
    }
  }

  /// Because our paint function pushes a layer during paint, we need
  /// to set this to true.
  ///
  /// Alternatively if the compositing is conditional, we could compute
  /// that condition here and call `markNeedsCompositingBitsUpdate`
  /// in set:opacity when it changes value.
  ///
  /// See the implementation of `RenderOpacity` if you are still curious.
  @override
  bool get alwaysNeedsCompositing => true;
}
```

Check out the introduction to [CustomBoxy](https://pub.dev/documentation/boxy/latest/boxy/CustomBoxy-class.html) next:

[:fontawesome-solid-book: Introduction to CustomBoxy](../custom-boxy/introduction-to-customboxy.md){ .md-button .md-button--primary .block }
