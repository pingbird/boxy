![boxy, Layout made simple](https://i.tst.sh/zncIM.png)

# Background

Boxy is designed to overcome the limitations of Flutter's built-in layout widgets, it provides utilities for flex,
custom multi-child layouts, dynamic widget inflation, slivers, and more!

### Flex layouts

A common design problem is when you need one or more children of a `Row` or `Column` to have the same cross-axis size
as another child in the list, one way to achieve this layout is to use `BoxyRow`, `BoxyColumn` and `Dominant`.

![Visualization of BoxyRow](https://i.tst.sh/WDmbR.png)

![Visualization of BoxyColumn](https://i.tst.sh/FdoiA.png)

### Custom layouts

One of the pains of implementing custom layouts is learning the `RenderObject` model and how verbose it is, to solve
this issue we provide `CustomBoxy`, an extremely simple to use container that delegates layout, paint, and hit testing.

![Visualization of CustomBoxy. 1. Declare widget 2. Implement delegate](https://i.tst.sh/e0M7b.png)

The most powerful feature of `CustomBoxy` is the ability to inflate widgets at layout time, this means widgets can
depend on the size of others, something previously thought impossible without hacky workarounds.

![Visualization of BoxyDelegate.inflate, lazy-loading children to match the width of a container](https://i.tst.sh/sYQHo.png)

See the documentation of [CustomBoxy](https://pub.dev/documentation/boxy/latest/boxy/CustomBoxy-class.html) for
more information.

### Slivers

Ever want to give SliverList a box decoration? The [sliver](https://pub.dev/documentation/boxy/latest/sliver) library
provides `SliverContainer` which allows you to use a box widget as the foreground or background of a sliver:

![](https://i.tst.sh/iiyrk.png)

### Miscellaneous

The [utils](https://pub.dev/documentation/boxy/latest/utils/utils-library.html) library provides extensions with dozens of axis-dependant
method for `BoxConstraints`, `Size`, `Offset`, and more. These extensions make writing directional layouts significantly less cumbersome.

The [OverflowPadding](https://pub.dev/documentation/boxy/latest/padding/OverflowPadding-class.html) widget is similar to
Padding but allows the child to overflow when given negative insets.