![boxy, Layout made simple](https://i.tst.sh/zncIM.png)

## About

Boxy is designed to overcome the limitations of Flutter's built-in layout widgets, it provides utilities for flex,
custom multi-child layouts, dynamic widget inflation, slivers, and more!

## Flex layouts

A common design problem is when you need one or more children of a `Row` or `Column` to have the same cross-axis size
as another child in the list, with boxy this can be achieved trivially using `BoxyRow`, `BoxyColumn` and `Dominant`.

![Visualization of BoxyRow](https://i.tst.sh/WDmbR.png)

![Visualization of BoxyColumn](https://i.tst.sh/FdoiA.png)

See the documentation of [BoxyRow](https://pub.dev/documentation/boxy/latest/flex/BoxyRow-class.html) and
[BoxyColumn](https://pub.dev/documentation/boxy/latest/flex/BoxyColumn-class.html) for more information.

## Custom layouts

One of the pains of implementing custom layouts is learning the `RenderObject` model and how verbose it is, to make this
process easier we provide an extremely simple to use container `CustomBoxy` that delegates layout, paint, and hit
testing.

![Visualization of CustomBoxy. 1. Declare widget 2. Implement delegate](https://i.tst.sh/e0M7b.png)

The most powerful feature of `CustomBoxy` is the ability to inflate arbitrary widgets at layout time, this means widgets
can depend on the size of others, something previously impossible without hacky workarounds.

![Visualization of BoxyDelegate.inflate, lazy-loading children to match the width of a container](https://i.tst.sh/sYQHo.png)

See the documentation of [CustomBoxy](https://pub.dev/documentation/boxy/latest/boxy/CustomBoxy-class.html) and
[BoxyDelegate](https://pub.dev/documentation/boxy/latest/boxy/BoxyDelegate-class.html) for more information.

## Slivers

Ever want to give SliverList a box decoration? The [sliver](https://pub.dev/documentation/boxy/latest/sliver) library
provides [SliverContainer](https://pub.dev/documentation/boxy/latest/slivers/SliverContainer-class.html) which allows
you to use box widgets as the foreground or background of a sliver.

This library also provides [SliverCard](https://pub.dev/documentation/boxy/latest/slivers/SliverCard-class.html), a
[SliverContainer](https://pub.dev/documentation/boxy/latest/slivers/SliverContainer-class.html) that looks like a card.

![](https://i.tst.sh/iiyrk.png)

Also check out:
* [SliverPadding](https://api.flutter.dev/flutter/widgets/SliverPadding-class.html), an underrated built-in widget
* [sliver_tools](https://pub.dev/packages/sliver_tools), a cool package that does similar things

## Miscellaneous

The [utils](https://pub.dev/documentation/boxy/latest/utils/utils-library.html) library provides extensions with dozens
of axis-dependant methods on `BoxConstraints`, `Size`, `Offset`, and more. These extensions make writing directional
layouts significantly less cumbersome.

The [OverflowPadding](https://pub.dev/documentation/boxy/latest/padding/OverflowPadding-class.html) widget is similar to
`Padding` but allows the child to overflow when given negative insets.