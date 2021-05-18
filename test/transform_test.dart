import 'package:boxy/boxy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import 'common.dart';

class TransformBoxy extends BoxyDelegate {
  final Matrix4 transform;

  TransformBoxy({
    required this.transform,
  });

  @override
  Size layout() {
    final childConstraints = constraints.loosen();
    for (final child in children) {
      child.layout(childConstraints);
    }
    return constraints.biggest;
  }

  @override
  void paintChildren() {
    for (final child in children) {
      child.setTransform(transform);
      child.paint();
    }
  }

  @override
  bool shouldRepaint(TransformBoxy oldDelegate) =>
    oldDelegate.transform != transform;
}

void main() {
  testWidgets('Transform test', (tester) => tester.runAsync(() async {
    await tester.pumpWidget(
      CustomBoxy(
        key: const GlobalObjectKey(#boxy),
        delegate: TransformBoxy(
          transform: Matrix4.compose(
            Vector3(10, 10, 0),
            Quaternion.identity(),
            Vector3(2, 1, 1),
          ),
        ),
        children: const [
          DecoratedBox(
            decoration: BoxDecoration(color: Colors.blue),
            key: GlobalObjectKey(#container1),
            child: SizedBox(width: 10, height: 10),
          ),
        ],
      ),
    );

    final container1Rect = boxRect(keyBox(#container1));

    // Verify paint transform
    expect(container1Rect, const Rect.fromLTWH(10.0, 10.0, 20.0, 10.0));

    final renderBoxy = keyBox(#boxy);

    // Miss around top and bottom edges of box
    for (final x in [
      container1Rect.left - 0.5,
      container1Rect.center.dx,
      container1Rect.right + 0.5,
    ]) {
      var result = BoxHitTestResult();
      renderBoxy.hitTest(result, position: Offset(x, container1Rect.top - 0.5));
      expect(result.path, isEmpty);

      result = BoxHitTestResult();
      renderBoxy.hitTest(result, position: Offset(x, container1Rect.bottom + 0.5));
      expect(result.path, isEmpty);
    }

    // Miss on left and right of box
    var result = BoxHitTestResult();
    renderBoxy.hitTest(result, position: Offset(container1Rect.left - 0.5, container1Rect.center.dy));
    expect(result.path, isEmpty);

    result = BoxHitTestResult();
    renderBoxy.hitTest(result, position: Offset(container1Rect.right + 0.5, container1Rect.center.dy));
    expect(result.path, isEmpty);

    // Hit on center of box
    result = BoxHitTestResult();
    renderBoxy.hitTest(result, position: Offset(container1Rect.center.dx, container1Rect.center.dy));
    expect((result.path.first as BoxHitTestEntry).target, keyBox(#container1));
  }));
}