---
hide:
- navigation
---

#

![](banner.png)

Boxy is a Flutter package created to overcome the limitations of built-in layout widgets, it provides utilities for flex, custom multi-child layouts, dynamic widget inflation, slivers, and more!

This package is ready for production use, it has excellent documentation, test coverage, and passes strict analysis.

<p class="grid" markdown>
  <a href="https://pub.dev/documentation/boxy/latest/" class="card md-button md-button--primary">:fontawesome-solid-book: __API Docs__</a>
  <a href="https://github.com/PixelToast/flutter-boxy" class="card md-button md-button--primary">:fontawesome-brands-github: __GitHub__</a>
  <a href="https://pub.dev/packages/boxy" class="card md-button md-button--primary">:simple-dart: __Pub__</a>
  <a href="https://discord.com/invite/N7Yshp4" class="card md-button md-button--primary">:fontawesome-brands-discord: __Discord__</a>
</p>

### Getting Started

To install Boxy, add it to your dependencies in `pubspec.yaml`:

```yaml
dependencies:
  boxy: ^2.0.5+1
```

Alternatively, you can also use the pub command:

```
flutter pub add boxy
```

After installing the package and running `flutter pub get`, import one of the top-level libraries:

```dart
import 'package:boxy/boxy.dart';
import 'package:boxy/flex.dart';
import 'package:boxy/padding.dart';
import 'package:boxy/slivers.dart';
import 'package:boxy/utils.dart';
```

### Sections

<div class="boxy-content-card">
<a href="/primer/introduction-to-layout/">
Introduction to Layout
<div class="description">Learn how constraints and RenderObjects work</div>
</a></div>

<div class="boxy-content-card">
<a href="/custom-boxy/introduction-to-customboxy/">
Introduction to CustomBoxy
<div class="description">Create advanced multi-child layouts</div>
</a></div>

<div class="boxy-content-card">
<a href="/helpers/cross-axis-alignment/">
Helpers
<div class="description">Simple layout widgets to make your life easier</div>
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
<div class="description">Stacking children with dynamic sizes</div>
</a></div>

<div class="boxy-content-card" style="background-image: url('/custom-boxy/examples/simplified_tree_view.png')">
<a href="/custom-boxy/examples/tree-view/">
Tree View
<div class="description">Complex tree layout with arbitrary widgets as nodes</div>
</a></div>
