# Painting

By overriding [paint](https://pub.dev/documentation/boxy/latest/render\_boxy/BaseBoxyDelegate/paint.html) or [paintForeground](https://pub.dev/documentation/boxy/latest/render\_boxy/BaseBoxyDelegate/paintForeground.html) you can get functionality similar to [CustomPaint](https://api.flutter.dev/flutter/widgets/CustomPaint-class.html):

![](ftest_frMkXTvID9.png)

```dart
class MyBoxyDelegate extends BoxyDelegate {
  @override
  Size layout() => const Size(32, 32);

  @override
  void paint() {
    canvas.drawRect(
      Offset.zero & render.size,
      Paint()..color = Colors.blue,
    );
  }
}
```

The [paint](https://pub.dev/documentation/boxy/latest/render\_boxy/BaseBoxyDelegate/paint.html) and [paintForeground](https://pub.dev/documentation/boxy/latest/render\_boxy/BaseBoxyDelegate/paintForeground.html) methods are the same, but [paintForeground](https://pub.dev/documentation/boxy/latest/render\_boxy/BaseBoxyDelegate/paintForeground.html) is called after [paintChildren](https://api.flutter.dev/flutter/rendering/FlowDelegate/paintChildren.html).

### Painting children

We can customize the way children are painted by overriding [paintChildren](https://api.flutter.dev/flutter/rendering/FlowDelegate/paintChildren.html), this is useful if you want to change their paint order for example:

![Without paintChildren](ftest_fcR5Z2lEZD.png) ![With paintChildren](image%20(1)%20(1)%20(1)%20(1)%20(1).png)

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
        Container(
          color: Colors.red,
          width: 96,
          height: 48,
        ),
      ],
    );
  }
}

class MyBoxyDelegate extends BoxyDelegate {
  @override
  void paintChildren() {
    children[1].paint();
    children[0].paint();
  }
}
```

Note that the [canvas](https://pub.dev/documentation/boxy/latest/render\_boxy/BaseBoxyDelegate/canvas.html) is still available, so we can use [paintChildren](https://api.flutter.dev/flutter/rendering/FlowDelegate/paintChildren.html) to paint things between children:

![](image%20(3).png)

```dart
class MyBoxyDelegate extends BoxyDelegate {
  @override
  void paintChildren() {
    children[1].paint();
    canvas.save();
    canvas.drawCircle(
      // Unlike the paint method, the canvas of paintChildren is not transformed
      // into the local coordinate space, so we need to offset by paintOffset.
      paintOffset + const Offset(48, 24),
      16,
      Paint()..color = Colors.white,
    );
    canvas.restore();
    children[0].paint();
  }
}
```
