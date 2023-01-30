# BoxConstraints

[BoxConstraints](https://api.flutter.dev/flutter/rendering/BoxConstraints-class.html) define a minimum and maximum length for each axis, by default it has a minimum width / height of 0, and maximum of infinity.

* An axis is said to be <mark style="background-color:purple;">**tight**</mark> if the minimum and maximum is the same, e.g. `BoxConstraints(minWidth: 10.0, maxWidth: 10.0)` has a tight width. The child will not be able to size itself on that axis.
* An axis is said to be <mark style="background-color:purple;">**loose**</mark> if the minimum is 0. The child will be able to choose its size on that axis assuming the maximum is not also 0.
* An axis is said to be <mark style="background-color:purple;">**unbounded**</mark> if the maximum is infinity. The child will have to determine its own size on that axis, which can cause issues if the child wants to fill its available space.
* An axis is said to be <mark style="background-color:purple;">**unconstrained**</mark> if the the minimum is 0 and the maximum is infinity. Unbounded constraints are usually also unconstrained, the child can choose any size it wants.

#### Tight constraints example

[SizedBox](https://api.flutter.dev/flutter/widgets/SizedBox-class.html) is an example of a way to provide tight constraints to a child:

```dart
SizedBox(
  width: 100,
  child: Text('My width is 100, no more, no less.'),
)
```

#### Loose constraints example

[Center](https://api.flutter.dev/flutter/widgets/Center-class.html) is a common way of loosening constraints:

```dart
SizedBox(
  width: 200,
  height: 200,
  child: Center(
    child: Text('I can be any size I want, as long as its < 200.'),
  ),
)
```

#### Unconstrained height example

The most common way widgets become unconstrained is inside a list, like a [ListView](https://api.flutter.dev/flutter/widgets/ListView-class.html) or [Column](https://api.flutter.dev/flutter/widgets/Column-class.html):

```dart
ListView(
  children: [
    Text('I have a constrained width, but an unconstrained height.'),
  ],
)
// or
Column(
  children: [
    Text('I also have an unconstrained height.'),
  ],
)
```

Problems can happen when a child wants to consume all of the space available, but its constraints don't let it:

```dart
ListView(
  children: [
    // Oops, the height constraint is loosened by ListView
    Column(
      children: [
        // This throws an error :(
        Expanded(child: Text('I want to be as tall as possible')),
      ],
    ),
  ],
)
```

#### Quirks and Features 🚗

One notable quirk is that children are forced to follow the constraints given by their parent, which can be unintuitive sometimes:

```dart
SizedBox(
  width: 100,
  child: SizedBox(
    width: 200,
    child: Text('Is my width 100 or 200?'),
  ),
)
```

Do you think the width of this text is 100 or 200 pixels wide? If you chose 100, you are correct.

The implementation of [RenderConstrainedBox](https://api.flutter.dev/flutter/rendering/RenderConstrainedBox-class.html) reveals why:

```dart
child!.layout(_additionalConstraints.enforce(constraints), parentUsesSize: true);
```

Before the tight constraints are passed down to the child, it enforces the constraints provided by the SizedBox's parent, otherwise the child would overflow.
