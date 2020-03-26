import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Element keyElement(Object value) {
  var results = find.byKey(GlobalObjectKey(value));
  expect(results, findsOneWidget);
  return results.evaluate().first;
}

RenderBox keyBox(Object value) =>
  keyElement(value).renderObject as RenderBox;

T keyWidget<T>(Object value) {
  var widget = keyElement(value).widget;
  expect(widget, isA<T>());
  return widget as T;
}

Rect boxRect(RenderBox box) => Rect.fromPoints(
  box.localToGlobal(Offset.zero),
  box.localToGlobal(Offset(
    box.size.width,
    box.size.height,
  )),
);

class TestFrame extends StatelessWidget {
  final Widget child;
  final BoxConstraints constraints;

  TestFrame({
    @required this.child,
    this.constraints = const BoxConstraints(),
  });

  build(BuildContext context) => Directionality(
    child: Stack(children: [
      Positioned(
        top: 0,
        left: 0,
        child: ConstrainedBox(child: child, constraints: constraints),
      ),
    ]),
    textDirection: TextDirection.ltr,
  );
}