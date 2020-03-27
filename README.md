# Boxy - Advanced multi-child layouts in Flutter.

This library provides several widgets and utilities that enable you to create advanced multi-child layouts without
in-depth knowledge of the framework and minimal boilerplate.

### Flex layouts

A common pattern is when you need one or more widgets in a `Row` or `Column` to have the same cross axis size
as another child in the list, you can achieve this layout using `BoxyFlex`/`BoxyRow`/`BoxyColumn` and
`BoxyFlexible`/`Dominant`:

```
+---------------------------+
|         BoxyColumn        |
|  * Loose constraints      |
|  +---------------------+  |
|  |       Child 1       |  |
|  | * Dominant          |  |
|  | * Dynamic size      |  |
|  +---------------------+  |
|  +---------------------+  |
|  |       Child 2       |  |
|  | * Dynamic height    |  |
|  | * Width of Child 1  |  |
|  +---------------------+  |
|                           |
+---------------------------+
```

```dart
BoxyColumn(children: [
 Dominant(child: Child1()),
 Child2(),
]);

// Alternatively,
BoxyFlex(
  direction: Axis.vertical,
  children: [
    BoxyFlexible(
      flex: 0,
      dominant: true,
      child: Child1(),
    ),
    Child2(),
  ],
);
```

### Complex custom layouts

For more complex layouts this library provides `CustomBoxy`, a multi-child layout widget that allows you to inflate,
constrain, lay out, and paint each child manually similar to a `CustomMultiChildLayout`.

You implement a `CustomBoxy` as follows:

```dart
class MyLayout extends StatelessWidget {
  build(context) => CustomBoxy(
    delegate: MyDelegate,
    children: [
      // Add children
    ],
  );
}

class MyDelegate extends BoxyDelegate {
  // Override layout, shouldRelayout, paint, shouldRepaint, hitTest, etc.
}
```

This is useful if you need layouts that no other widget can provide, for example one where one child is positioned above
the border of two others:

```
+-------------------------+
|       CustomBoxy        |
|  +-------------------+  |
|  |                   |  |
|  |      Child 1      |  |
|  |       +---------+ |  |
|  +-------| Child 3 |-+  |
|  +-------|         |-+  |
|  |       +---------+ |  |
|  |      Child 2      |  |
|  |                   |  |
|  +-------------------+  |
|                         |
+-------------------------+
```

See the [Product Tile](https://me.tst.sh/git/flutter-boxy/gallery/#product-tile) example for an implementation of this
layout, and the documentation of [CustomBoxy](https://pub.dev/documentation/boxy/latest/boxy/CustomBoxy-class.html) for
more information.

### Utilities

The [utils](https://pub.dev/documentation/boxy/latest/utils) library provides extensions with axis dependant
methods and constructors for `BoxConstraints`, `Offset`, `Size`, `RenderBox`, and `SizedBox`. These extensions make
writing axis agnostic layouts significantly easier. 