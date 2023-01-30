# BoxyId

### Identifying children

In some cases you might want to identify children by name rather than index, [BoxyId](https://pub.dev/documentation/boxy/latest/boxy/BoxyId-class.html) is your friend:

![](ftest_XBEjnnpsdS.png)

```dart
class MyWidget extends StatelessWidget {
  const MyWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomBoxy(
      delegate: MyBoxyDelegate(),
      children: const [
        // BoxyId allows children to be accessed by name.
        BoxyId(
          // This `#hello` is called a Symbol, they are like strings but
          // slightly more performant for naming things.
          id: #hello,
          child: Text('Hello,'),
        ),
        BoxyId(
          id: #world,
          child: Text('World!'),
        ),
      ],
    );
  }
}

class MyBoxyDelegate extends BoxyDelegate {
  @override
  Size layout() {
    // Grab the children by name.
    final BoxyChild hello = getChild(#hello);
    final BoxyChild world = getChild(#world);

    // Lay them out and store their sizes.
    final Size helloSize = hello.layout(constraints);
    final Size worldSize = world.layout(constraints);

    // Position the "World!" text below the "Hello,".
    world.position(Offset(0, helloSize.height));

    // Return the size of our little column.
    return Size(
      max(helloSize.width, worldSize.height),
      helloSize.height + worldSize.height,
    );
  }
}
```

### Parent Data

You can pass data to the delegate using the [data](https://pub.dev/documentation/boxy/latest/boxy/BoxyId/data.html) parameter of [BoxyId](https://pub.dev/documentation/boxy/latest/boxy/BoxyId-class.html).

This is the same underlying mechanism that [Expanded](https://api.flutter.dev/flutter/widgets/Expanded-class.html) uses to tell the [Row](https://api.flutter.dev/flutter/widgets/Row-class.html) or [Column](https://api.flutter.dev/flutter/widgets/Column-class.html) how much space it should take up.

![](image%20(1).png)

```dart
class MyWidget extends StatelessWidget {
  const MyWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomBoxy(
      delegate: MyBoxyDelegate(),
      children: [
        const Text('👻 I am hiding '),
        BoxyId(
          child: Container(
            color: Colors.blue,
            width: 50,
            height: 50,
          ),
          // This gets passed to BoxyChild.parentData
          data: 0.5,
        ),
      ],
    );
  }
}

class MyBoxyDelegate extends BoxyDelegate {
  @override
  void paintChildren() {
    children[0].paint();
    layers.opacity(
      opacity: children[1].parentData,
      paint: children[1].paint,
    );
  }
}
```
