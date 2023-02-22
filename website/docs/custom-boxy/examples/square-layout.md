# Square Layout

In the interactive example of [Introduction To Layout](/primer/interactive-example/) we showed a custom [RenderObject](https://api.flutter.dev/flutter/rendering/RenderObject-class.html) with a single child, let's see how [CustomBoxy](https://pub.dev/documentation/boxy/latest/boxy/CustomBoxy-class.html) can cut down all of the boilerplate.

The end goal of this example is to take an arbitrarily sized widget, and size itself so that it's width and height are equal. Ideally the child is also centered in the resulting square.

### Complete Example

To make the widget square, we will to create a [BoxyDelegate](https://pub.dev/documentation/boxy/latest/boxy/BoxyDelegate-class.html) that overrides [layout](https://pub.dev/documentation/boxy/latest/boxy/BoxyDelegate/layout.html):

![](image%20(1)%20(1)%20(1).png)

```dart
class Square extends StatelessWidget {
  const Square({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // Add a border so we can see the an outline showing the size
      decoration: BoxDecoration(border: Border.all(color: Colors.blue)),
      child: CustomBoxy(
        delegate: SquareBoxyDelegate(),
        children: const [
          Text('Hello, World!'),
        ],
      ),
    );
  }
}

class SquareBoxyDelegate extends BoxyDelegate {
  BoxyChild get child => children.single;

  @override
  Size layout() {
    // Lay out the child, pass through constraints.
    final childSize = child.layout(constraints);
    
    // Calculate the width of our square by getting the max of the child's
    // width and height.
    final width = max(childSize.width, childSize.height);
    
    // Position the child in the center
    child.position(Offset(
      (width - childSize.width) / 2,
      (width - childSize.height) / 2,
    ));
    
    // Return our size
    return Size.square(width);
    
    // An alternate way to center the child using inscribe:
    //
    // final rect = Offset.zero & Size.square(width);
    // child.position(Alignment.center.inscribe(childSize, rect).topLeft);
    // return rect.size;
  }
}
```

There was a little math involved to center the child, otherwise that was easy-peasy!
