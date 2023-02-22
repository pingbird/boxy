# Introduction to CustomBoxy

[:fontawesome-solid-book: CustomBoxy API Docs](https://pub.dev/documentation/boxy/latest/boxy/CustomBoxy-class.html){ .md-button .md-button--primary .block }

[CustomBoxy](https://pub.dev/documentation/boxy/latest/boxy/CustomBoxy-class.html) is a widget that uses a delegate to implement a custom [RenderObject](https://api.flutter.dev/flutter/rendering/RenderObject-class.html).

This is essentially a more powerful version of [CustomMultiChildLayout](https://api.flutter.dev/flutter/widgets/CustomMultiChildLayout-class.html) or [CustomPaint](https://api.flutter.dev/flutter/widgets/CustomPaint-class.html), it allows you to inflate, constrain, and lay out each child manually, it also allows its size to depend on the layout of its children.

This is overkill in most cases, so before diving in you may want to check if some combination of [Stack](https://api.flutter.dev/flutter/widgets/Stack-class.html), [LayoutBuilder](https://api.flutter.dev/flutter/widgets/LayoutBuilder-class.html), [CustomMultiChildLayout](https://api.flutter.dev/flutter/widgets/CustomMultiChildLayout-class.html), or [Flow](https://api.flutter.dev/flutter/widgets/Flow-class.html) is more suitable.

### Sections

<div class="boxy-content-card">
<a href="/custom-boxy/hello-world/">
Hello, World!
<div class="description">Creating a basic BoxyDelegate</div>
</a></div>

<div class="boxy-content-card">
<a href="/custom-boxy/boxy-child/">
BoxyChild
<div class="description">Laying out children</div>
</a></div>

<div class="boxy-content-card">
<a href="/custom-boxy/boxy-id/">
BoxyId
<div class="description">Identifying children by name</div>
</a></div>

<div class="boxy-content-card">
<a href="/custom-boxy/painting/">
Painting
<div class="description">Custom painting</div>
</a></div>

<div class="boxy-content-card">
<a href="/custom-boxy/layers/">
Layers
<div class="description">Extra compositing effects</div>
</a></div>

<div class="boxy-content-card">
<a href="/custom-boxy/widget-inflation/">
Widget Inflation
<div class="description">Building arbitrary widgets during layout</div>
</a></div>

### Examples

<div class="boxy-content-card" style="background-image: url('/custom-boxy/examples/image%20%281%29%20%281%29%20%281%29.png')">
<a href="/custom-boxy/examples/square-layout/">
Square Layout
<div class="description">Simple square layout created with CustomBoxy</div>
</a></div>

<div class="boxy-content-card" style="background-image: url('/custom-boxy/examples/ftest_2ETeGIqwH8.png')">
<a href="/custom-boxy/examples/evenly-sized-row/">
Evenly Sized Row
<div class="description">Row where each child has the same size</div>
</a></div>

<div class="boxy-content-card" style="background-image: url('/custom-boxy/examples/ftest_MyQB0wRzDZ.png')">
<a href="/custom-boxy/examples/product-tile/">
Product Tile
<div class="description">Stacking children with a dynamic sizes</div>
</a></div>

<div class="boxy-content-card" style="background-image: url('/custom-boxy/examples/simplified_tree_view.png')">
<a href="/custom-boxy/examples/tree-view/">
Tree View
<div class="description">Complex tree layout with arbitrary widgets as nodes</div>
</a></div>
