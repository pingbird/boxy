# Dominant

The [Dominant](https://pub.dev/documentation/boxy/latest/flex/Dominant-class.html) widget tells a [BoxyRow](https://pub.dev/documentation/boxy/latest/flex/BoxyRow-class.html) or [BoxyColumn](https://pub.dev/documentation/boxy/latest/flex/BoxyColumn-class.html) to constrain every other widget to match its cross-axis size:

![](image.png)

```dart
class MyWidget extends StatelessWidget {
  const MyWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BoxyRow(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Blue container should match the height of the pink one below
        Container(
          color: Colors.blue,
          width: 25,
        ),
        Dominant(
          child: Container(
            width: 50,
            height: 50,
            color: Colors.pink,
          ),
        ),
      ],
    );
  }
}
```

Due to the quirky nature of [ParentDataWidgets](https://api.flutter.dev/flutter/widgets/ParentDataWidget-class.html), you can't wrap a [Dominant](https://pub.dev/documentation/boxy/latest/flex/Dominant-class.html) widget inside an [Expanded](https://api.flutter.dev/flutter/widgets/Expanded-class.html) widget.

To make it expanded, use the alternate [Dominant.expanded](https://pub.dev/documentation/boxy/latest/flex/Dominant/Dominant.expanded.html) constructor:

![](ftest_nmZYWRSqsy%20(1).png)

```dart
class MyWidget extends StatelessWidget {
  const MyWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white38),
        borderRadius: BorderRadius.circular(2),
      ),
      padding: const EdgeInsets.all(4.0),
      child: BoxyRow(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: Colors.blue,
            child: const RotatedBox(
              quarterTurns: -1,
              child: Text('Chapter 1'),
            ),
            padding: const EdgeInsets.all(2.0),
          ),
          const SizedBox(width: 8.0),
          const Dominant.expanded(
            child: Text(
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed '
              'do eiusmod tempor incididunt ut labore et dolore magna '
              'aliqua. Ut enim ad minim veniam, quis nostrud exercitation '
              'ullamco laboris nisi ut aliquip ex ea commodo consequat.',
            ),
          ),
        ],
      ),
    );
  }
}
```
