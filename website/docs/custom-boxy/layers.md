# Layers

Another way we can customize the way children are painted is with [layers](https://pub.dev/documentation/boxy/latest/render\_boxy/BaseBoxyDelegate/layers.html), this is a fancy wrapper around the low level compositing [Layers](https://api.flutter.dev/flutter/rendering/Layer-class.html) used for widgets like [Opacity](https://api.flutter.dev/flutter/widgets/Opacity-class.html) and [BackdropFilter](https://api.flutter.dev/flutter/widgets/BackdropFilter-class.html).

![](image%20(1)%20(1)%20(1)%20(1).png)

```dart
class MyWidget extends StatelessWidget {
  const MyWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomBoxy(
      delegate: MyBoxyDelegate(),
      children: [
        Container(
          color: Colors.blue,
          width: 48,
          height: 48,
        ),
      ],
    );
  }
}

class MyBoxyDelegate extends BoxyDelegate {
  @override
  void paintChildren() {
    // Make the square blurry
    layers.imageFilter(
      imageFilter: ImageFilter.blur(
        sigmaX: 2,
        sigmaY: 2,
        tileMode: TileMode.decal,
      ),
      paint: children.single.paint,
    );
  }
}
```
