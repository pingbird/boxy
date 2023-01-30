import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Element keyElement(Object value) {
  final results = find.byKey(GlobalObjectKey(value));
  expect(results, findsOneWidget);
  return results.evaluate().first;
}

RenderBox keyBox(Object value) => keyElement(value).renderObject! as RenderBox;

RenderSliver keySliver(Object value) =>
    keyElement(value).renderObject! as RenderSliver;

T keyWidget<T>(Object value) {
  final widget = keyElement(value).widget;
  expect(widget, isA<T>());
  return widget as T;
}

Rect boxRect(RenderBox box) {
  return Rect.fromPoints(
    box.localToGlobal(Offset.zero),
    box.localToGlobal(Offset(
      box.size.width,
      box.size.height,
    )),
  );
}

class TestFrame extends StatelessWidget {
  final Widget child;
  final BoxConstraints constraints;

  const TestFrame({
    Key? key,
    required this.child,
    this.constraints = const BoxConstraints(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: Typography.material2014().black.bodyMedium!,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: 0,
          maxWidth: double.infinity,
          minHeight: 0,
          maxHeight: double.infinity,
          child: ConstrainedBox(constraints: constraints, child: child),
        ),
      ),
    );
  }
}
