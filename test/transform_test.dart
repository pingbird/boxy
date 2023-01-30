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

class LayoutRectBoxy extends BoxyDelegate {
  LayoutRectBoxy(this.rect, [this.alignment]);

  final Rect rect;
  final Alignment? alignment;

  @override
  Size layout() {
    final rect = this.rect.intersect(Offset.zero & constraints.biggest);
    children.single.layoutRect(
      rect,
      alignment: alignment,
    );
    return rect.size;
  }
}

class LayoutFitBoxy extends BoxyDelegate {
  LayoutFitBoxy(this.rect, this.fit, this.alignment);

  final Rect rect;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Size layout() {
    final rect = this.rect.intersect(Offset.zero & constraints.biggest);
    children.single.layoutFit(
      rect,
      fit: fit,
      alignment: alignment,
    );
    return rect.size;
  }
}

void main() {
  testWidgets('Transform test', (tester) async {
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
      renderBoxy.hitTest(result,
          position: Offset(x, container1Rect.bottom + 0.5));
      expect(result.path, isEmpty);
    }

    // Miss on left and right of box
    var result = BoxHitTestResult();
    renderBoxy.hitTest(result,
        position: Offset(container1Rect.left - 0.5, container1Rect.center.dy));
    expect(result.path, isEmpty);

    result = BoxHitTestResult();
    renderBoxy.hitTest(result,
        position: Offset(container1Rect.right + 0.5, container1Rect.center.dy));
    expect(result.path, isEmpty);

    // Hit on center of box
    result = BoxHitTestResult();
    renderBoxy.hitTest(result,
        position: Offset(container1Rect.center.dx, container1Rect.center.dy));
    expect((result.path.first as BoxHitTestEntry).target, keyBox(#container1));
  });

  testWidgets('layoutRect', (tester) async {
    await tester.pumpWidget(
      CustomBoxy(
        delegate: LayoutRectBoxy(
          const Rect.fromLTRB(8, 8, 24, 24),
        ),
        children: const [
          SizedBox(
            key: GlobalObjectKey(#container),
            width: 8,
            height: 8,
          ),
        ],
      ),
    );

    final containerBox = keyBox(#container);
    final containerRect = boxRect(containerBox);

    expect(containerRect, const Rect.fromLTRB(8, 8, 24, 24));
    expect(
      containerBox.constraints,
      BoxConstraints.tight(const Size(16, 16)),
    );
  });

  testWidgets('layoutRect alignment', (tester) async {
    await tester.pumpWidget(
      CustomBoxy(
        delegate: LayoutRectBoxy(
          const Rect.fromLTRB(8, 8, 24, 24),
          Alignment.center,
        ),
        children: const [
          SizedBox(
            key: GlobalObjectKey(#container),
            width: 8,
            height: 8,
          ),
        ],
      ),
    );

    final containerBox = keyBox(#container);
    final containerRect = boxRect(containerBox);

    expect(containerRect, const Rect.fromLTRB(12, 12, 20, 20));
    expect(
      containerBox.constraints,
      BoxConstraints.loose(const Size(16, 16)),
    );
  });

  testWidgets('layoutFit', (tester) async {
    Future<void> testcase({
      required BoxFit fit,
      required Size parentSize,
      required Size childSize,
      required Alignment alignment,
    }) async {
      final params =
          'fit: $fit, parentSize: $parentSize, childSize: $childSize, '
          'alignment: $alignment';
      await tester.pumpWidget(
        Center(
          child: SizedBox.fromSize(
            size: parentSize,
            child: Stack(
              alignment: Alignment.topLeft,
              fit: StackFit.expand,
              children: [
                CustomBoxy(
                  delegate: LayoutFitBoxy(
                    (Offset.zero & parentSize).deflate(8),
                    fit,
                    alignment,
                  ),
                  children: [
                    SizedBox.fromSize(
                      key: const GlobalObjectKey(#container1),
                      size: childSize,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: FittedBox(
                    fit: fit,
                    alignment: alignment,
                    child: SizedBox.fromSize(
                      key: const GlobalObjectKey(#container2),
                      size: childSize,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final container1Box = keyBox(#container1);
      final container1Rect = boxRect(container1Box);

      final container2Box = keyBox(#container2);
      final container2Rect = boxRect(container2Box);

      expect(container1Rect, container2Rect, reason: params);
    }

    const testSizes = [
      Size(200, 100),
      Size(100, 100),
      Size(50, 75),
    ];

    const testAlignments = [
      Alignment.center,
      Alignment.topLeft,
    ];

    for (final alignment in testAlignments) {
      for (final fit in BoxFit.values) {
        for (final parentSize in testSizes) {
          for (final childSize in testSizes) {
            await testcase(
              fit: fit,
              parentSize: parentSize,
              childSize: childSize,
              alignment: alignment,
            );
          }
        }
      }
    }
  });
}
