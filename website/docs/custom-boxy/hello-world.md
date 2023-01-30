# Hello, World!

To start, create a [CustomBoxy](https://pub.dev/documentation/boxy/latest/boxy/CustomBoxy-class.html) widget and pass it a subclass of [BoxyDelegate](https://pub.dev/documentation/boxy/latest/boxy/BoxyDelegate-class.html):

![](image%20(1)%20(1)%20(1)%20(1)%20(1)%20(1).png)

```dart
class MyWidget extends StatelessWidget {
  const MyWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomBoxy(
      delegate: MyBoxyDelegate(),
      children: const [
        Text('Hello, World!'),
      ],
    );
  }
}

class MyBoxyDelegate extends BoxyDelegate {}
```

[CustomBoxy](https://pub.dev/documentation/boxy/latest/boxy/CustomBoxy-class.html) accepts a list of children, it's default behavior is similar to a [Stack](https://api.flutter.dev/flutter/widgets/Stack-class.html), passing through the constraints to each child and sizing itself to the biggest one.

There are many methods you can override in [BoxyDelegate](https://pub.dev/documentation/boxy/latest/boxy/BoxyDelegate-class.html), the most common being [layout](https://pub.dev/documentation/boxy/latest/boxy/BoxyDelegate/layout.html).

### Custom Layout



To customize layout, override the [layout](https://pub.dev/documentation/boxy/latest/boxy/BoxyDelegate/layout.html) method to return a size:

```dart
class MyBoxyDelegate extends BoxyDelegate { 
  @override
  // Choose the smallest size that our constraints allow, just like
  // an empty SizedBox().
  Size layout() => constraints.smallest;
}
```

[BoxyDelegate](https://pub.dev/documentation/boxy/latest/boxy/BoxyDelegate-class.html) includes several getters that are useful for layout, including:

* [constraints](https://pub.dev/documentation/boxy/latest/render\_boxy/BoxBoxyDelegateMixin/constraints.html), the [BoxConstraints](https://api.flutter.dev/flutter/rendering/BoxConstraints-class.html) provided by the parent
* [children](https://pub.dev/documentation/boxy/latest/render\_boxy/BaseBoxyDelegate/children.html), a list of [BoxyChild](https://pub.dev/documentation/boxy/latest/boxy/BoxyChild-class.html) instances which let you interact with things passed to [CustomBoxy](https://pub.dev/documentation/boxy/latest/boxy/CustomBoxy-class.html)
* [getChild](https://pub.dev/documentation/boxy/latest/render\_boxy/BaseBoxyDelegate/getChild.html), a method that can get a child by id using [BoxyId](https://pub.dev/documentation/boxy/latest/boxy/BoxyId-class.html)
* [hasChild](https://pub.dev/documentation/boxy/latest/render\_boxy/BaseBoxyDelegate/hasChild.html), a method that returns true if there is a child with a given id
* [layoutData](https://pub.dev/documentation/boxy/latest/render\_boxy/BaseBoxyDelegate/layoutData.html), a variable you can use to hold additional data created during layout
* [render](https://pub.dev/documentation/boxy/latest/render\_boxy/BoxBoxyDelegateMixin/render.html), a raw reference to the [RenderBoxy](https://pub.dev/documentation/boxy/latest/render\_boxy/RenderBoxy-class.html) of [CustomBoxy](https://pub.dev/documentation/boxy/latest/boxy/CustomBoxy-class.html)
* [buildContext](https://pub.dev/documentation/boxy/latest/render\_boxy/BaseBoxyDelegate/buildContext.html), the [BuildContext](https://api.flutter.dev/flutter/widgets/BuildContext-class.html) of the [CustomBoxy](https://pub.dev/documentation/boxy/latest/boxy/CustomBoxy-class.html).
