# Boxy - Create advanced multi-child layouts in Flutter.

This library provides `Boxy`, a multi-child layout widget that allows you to inflate, constrain, and lay out each child
manually similar to a `CustomMultiChildLayout`.

The most common use case is when the size of one widget depends on the size of another, normally a layout
like this would require implementing your own `RenderBox` or figure out a workaround with `IntrinsicWidth`,
`InstrinsicHeight`, or `Positioned`.

