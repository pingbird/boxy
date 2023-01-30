# SliverCard

[SliverCard](https://pub.dev/documentation/boxy/latest/slivers/SliverCard-class.html) is a [Card](https://api.flutter.dev/flutter/material/Card-class.html) that you can wrap slivers in:

![](image%20(1)%20(1).png)

```dart
final colors = [
  Colors.purple.shade50,
  Colors.purple.shade100,
  Colors.purple.shade200,
  Colors.purple.shade300,
  Colors.purple.shade400,
  Colors.purple.shade500,
  Colors.purple.shade600,
  Colors.purple.shade700,
  Colors.purple.shade800,
  Colors.purple.shade900,
];

class MyWidget extends StatelessWidget {
  const MyWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        for (var color in colors)
          SliverPadding(
            padding: MediaQuery.of(context).padding,
            sliver: SliverCard(
              color: color,
              margin: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 2.0,
              ),
              sliver: SliverPadding(
                padding: const EdgeInsets.all(4.0),
                sliver: SliverToBoxAdapter(
                  child: Text('#${(color.value & 0xFFFFFF).toRadixString(16)}'),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
```
