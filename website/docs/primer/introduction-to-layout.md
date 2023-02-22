# Introduction to Layout

When Flutter was created, it set out to provide a render architecture that was simple, performant, and modular. Compare this to [HTML](https://developer.chrome.com/articles/layoutng/) or Android [View](https://developer.android.com/reference/android/view/View)s, which have many complex, slow, and implementation-specific rendering protocols.

Most of the layout widgets you use in Flutter are actually pretty simple and elegant under the hood, there is rarely any magic, so try not to be intimidated by it!

### Constraints go down, Sizes go up

You can think of layout in Flutter as a bunch of functions that take in BoxConstraints and return a Size:

```dart title="(simplification)"
Size layout(BoxConstraints constraints) {
  final childSize = child.layout(BoxConstraints()));
  child.position(Offset.zero);
  return childSize;
}
```

This is called the [RenderBox](https://api.flutter.dev/flutter/rendering/RenderBox-class.html) protocol, it's simplicity is what enables animations in Flutter to outperform native Android and iOS.

The downside of being simple is that developers have to put in a little extra effort to constrain widgets and avoid those pesky flex overflow, unbounded constraints, and infinite size errors.

The Flutter team made a great article on the design philosophy / performance implications of RenderObjects: [https://docs.flutter.dev/resources/inside-flutter](https://docs.flutter.dev/resources/inside-flutter)
