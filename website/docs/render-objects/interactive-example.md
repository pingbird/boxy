# Interactive Example

![](image%20(2).png)

[:simple-dart: DartPad](https://dartpad.dartlang.org/?id=0d12f9092860c0793e57eb3b9cad2926){ .md-button .md-button--primary .block }

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

Check out the introduction to [CustomBoxy](https://pub.dev/documentation/boxy/latest/boxy/CustomBoxy-class.html) next:

[:fontawesome-solid-book: Introduction to CustomBoxy](../custom-boxy/introduction-to-customboxy.md){ .md-button .md-button--primary .block }
