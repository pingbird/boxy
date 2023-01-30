# BoxyChild

To lay out child widgets we first grab a [BoxyChild](https://pub.dev/documentation/boxy/latest/boxy/BoxyChild-class.html) instance, call layout, and optionally position it.

```dart
@override
Size layout() {
  // Find our children, in this case we assume there is exactly one
  final BoxyChild child = children.single;

  // Call layout on the child to obtain their size, we just pass the
  // constraints given to the CustomBoxy by its parent
  final Size size = child.layout(constraints);

  // Optionally position the child
  child.position(Offset.zero);

  // Return a size
  return size;
}
```

[BoxyChild](https://pub.dev/documentation/boxy/latest/boxy/BoxyChild-class.html) is just a fancy wrapper around [RenderBox](https://api.flutter.dev/flutter/rendering/RenderBox-class.html), it has a bunch of methods and properties that are useful for layout:

* [layout](https://pub.dev/documentation/boxy/latest/boxy/BoxyChild/layout.html), a method that lays out the child given some constraints
* [layoutFit](https://pub.dev/documentation/boxy/latest/boxy/BoxyChild/layoutFit.html), a method that lays out and transforms the child according to a [Rect](https://api.dart.dev/stable/2.17.3/dart-ui/Rect-class.html) and [BoxFit](https://api.flutter.dev/flutter/painting/BoxFit.html), just like a [FittedBox](https://api.flutter.dev/flutter/widgets/FittedBox-class.html)
* [layoutRect](https://pub.dev/documentation/boxy/latest/boxy/BoxyChild/layoutRect.html), a method that lays out and positions the child so that it fits a [Rect](https://api.dart.dev/stable/2.17.3/dart-ui/Rect-class.html) with an optional alignment property that behaves like an [Align](https://api.flutter.dev/flutter/widgets/Align-class.html)
* [position](https://pub.dev/documentation/boxy/latest/boxy/BaseBoxyChild/position.html), a method that sets the offset of the child
* [setTransform](https://pub.dev/documentation/boxy/latest/boxy/BaseBoxyChild/setTransform.html), a more advanced version of position that takes a [Matrix4](https://pub.dev/documentation/vector\_math/2.1.2/vector\_math\_64/Matrix4-class.html) transform
* [size](https://pub.dev/documentation/boxy/latest/boxy/BoxyChild/size.html), the size of the child after it's laid out
* [context](https://pub.dev/documentation/boxy/latest/inflating\_element/InflatedChildHandle/context.html), the [Element](https://api.flutter.dev/flutter/widgets/Element-class.html) (aka [BuildContext](https://api.flutter.dev/flutter/widgets/BuildContext-class.html)) of the child
* [id](https://pub.dev/documentation/boxy/latest/inflating\_element/InflatedChildHandle/id.html), the id of the child which is provided by either [BoxyId](https://pub.dev/documentation/boxy/latest/boxy/BoxyId-class.html) or an incrementing integer
