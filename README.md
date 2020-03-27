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

This is useful if you need layouts that no other widget can provide, for example one where one child is positioned above
the border of two others:

```
+-------------------------+
|       CustomBoxy        |
|  +-------------------+  |
|  |                   |  |
|  |        Top        |  |
|  |       +---------+ |  |
|  +-------| Middle  |-+  |
|  +-------|         |-+  |
|  |       +---------+ |  |
|  |      Bottom       |  |
|  |                   |  |
|  +-------------------+  |
|                         |
+-------------------------+
```

```dart
class MyLayout extends StatelessWidget {
  final Widget top;
  final Widget middle;
  final Widget bottom;
  
  // The margin between the middle widget and right edge
  final double inset;
  
  MyLayout({
    @required this.top,
    @required this.middle,
    @required this.bottom,
    @required this.inset,
  });

  build(context) => CustomBoxy(
    delegate: MyDelegate(inset: inset),
    children: [
      // Use LayoutId to give each child an id
      LayoutId(id: #top, child: top),
      LayoutId(id: #bottom, child: bottom),
      // The middle widget should be rendered above the others
      // so we put it at the bottom of the list
      LayoutId(id: #middle, child: middle),
    ],
  );
}

class MyDelegate extends BoxyDelegate {
  final double inset;

  MyDelegate({@required this.inset});
  
  @override
  layout() {
    // Get each child handle by a Symbol id
    var top = getChild(#top);
    var middle = getChild(#middle);
    var bottom = getChild(#bottom);
    
    // Children should have unbounded height
    var topConstraints = constraints.widthConstraints();
    
    // Lay out and position top widget
    var topSize = title.layout(topConstraints);
    top.position(Offset.zero);
    
    // Lay out and position middle widget using size of top widget
    var middleSize = middle.layout(BoxConstraints());
    middle.position(Offset(
      topSize.width - (middle.width + inset),
      topSize.height - middle.height / 2,
    ));
    
    // Lay out bottom widget
    var bottomSize = info.layout(topConstraints.tighten(
      // Bottom widget should be same width as top widget
      width: topSize.width,
    ));
    
    // Position bottom widget directly below top widget
    bottom.position(Offset(0, topSize.height));
    
    // Calculate total size
    return Size(
      topSize.width,
      topSize.height + bottomSize.height,
    );
  }
  
  // Check if any properties have changed
  @override
  shouldRelayout(MyDelegate old) => old.inset != inset;
}
```

See the [Product Tile](https://me.tst.sh/git/flutter-boxy/gallery/#product-tile) example for an implementation of this
layout, and the documentation of [CustomBoxy](https://pub.dev/documentation/boxy/latest/boxy/CustomBoxy-class.html) for
more information.

### Utilities

The [utils](https://pub.dev/documentation/boxy/latest/utils) library provides extensions with axis dependant
methods and constructors for `BoxConstraints`, `Offset`, `Size`, `RenderBox`, and `SizedBox`. These extensions make
writing axis agnostic layouts significantly easier. 