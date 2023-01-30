# Widget Inflation

The most powerful feature of Boxy is the ability to [inflate](https://pub.dev/documentation/boxy/latest/render\_boxy/BaseBoxyDelegate/inflate.html) arbitrary widgets at layout time.

In the below example we construct a [Text](https://api.flutter.dev/flutter/widgets/Text-class.html) widget based on the size of another child. This would be extremely difficult to accomplish without Boxy, even using a custom [Element](https://api.flutter.dev/flutter/widgets/Element-class.html) and [RenderObject](https://api.flutter.dev/flutter/rendering/RenderObject-class.html).

![](ftest_m3xCKjHuvM.png)

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
          width: 50,
          height: 50,
        ),
      ],
    );
  }
}

class MyBoxyDelegate extends BoxyDelegate {
  @override
  Size layout() {
    // Lay out the container first.
    final container = children.single;
    final containerSize = container.layout(constraints);

    // Inflate a Text widget based on the containers size.
    final text = inflate(
      Text('^ $containerSize'),
      id: #text,
    );
    final textSize = text.layout(constraints);

    // Position the text below the container.
    text.position(Offset(0, containerSize.height));

    return Size(
      max(containerSize.width, textSize.width),
      containerSize.height + textSize.height,
    );
  }
}
```
