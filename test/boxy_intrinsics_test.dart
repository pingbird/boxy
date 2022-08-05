import 'package:boxy/boxy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common.dart';

class IntrinsicSizedWrapperBoxy extends BoxyDelegate {
  @override
  Size layout() {
    final child = children.single;
    final size = child.layout(constraints);
    expect(
      child.render.getDistanceToBaseline(TextBaseline.alphabetic),
      11,
    );
    return size;
  }
}

class IntrinsicSizedBoxy extends BoxyDelegate {
  @override
  Size layout() => const Size(1, 2);

  @override
  double minIntrinsicWidth(double height) {
    expect(height, 3);
    return 4;
  }

  @override
  double minIntrinsicHeight(double width) {
    expect(width, 5);
    return 6;
  }

  @override
  double maxIntrinsicWidth(double height) {
    expect(height, 7);
    return 8;
  }

  @override
  double maxIntrinsicHeight(double width) {
    expect(width, 9);
    return 10;
  }

  @override
  double? distanceToBaseline(TextBaseline baseline) {
    return 11;
  }
}

void main() {
  testWidgets('Intrinsic sizes', (tester) async {
    await tester.pumpWidget(
      Center(
        child: CustomBoxy(
          delegate: IntrinsicSizedWrapperBoxy(),
          children: [
            CustomBoxy(
              key: const GlobalObjectKey(#boxy),
              delegate: IntrinsicSizedBoxy(),
            ),
          ],
        ),
      ),
    );
    final box = keyBox(#boxy);
    expect(box.size, const Size(1, 2));
    expect(box.getMinIntrinsicWidth(3), 4);
    expect(box.getMinIntrinsicHeight(5), 6);
    expect(box.getMaxIntrinsicWidth(7), 8);
    expect(box.getMaxIntrinsicHeight(9), 10);
  });
}
