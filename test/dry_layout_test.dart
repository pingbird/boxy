import 'package:boxy/boxy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common.dart';

class DryTestDelegate extends BoxyDelegate {
  @override
  Size layout() {
    return getChild(0).layout(constraints);
  }
}

void main() {
  testWidgets('CustomBoxy can compute dry layout', (tester) async {
    await tester.pumpWidget(
      Center(
        child: CustomBoxy(
          key: const GlobalObjectKey(#boxy),
          delegate: DryTestDelegate(),
          children: const [
            SizedBox(
              key: GlobalObjectKey(#child),
              width: 100,
              height: 100,
            ),
          ],
        ),
      ),
    );

    final renderBoxy = keyBox(#boxy);

    // Regular layout
    expect(renderBoxy.size, equals(const Size(100, 100)));

    // Compute dry layout with different constraints
    expect(
      renderBoxy.getDryLayout(const BoxConstraints.tightFor(width: 200)),
      equals(const Size(200, 100)),
    );

    // Actual size of boxy and child should remain the same
    expect(renderBoxy.size, equals(const Size(100, 100)));

    expect(
      keyBox(#child).size,
      equals(const Size(100, 100)),
    );

    // Relayout shouldn't cause issues
    await tester.pumpWidget(
      Center(
        child: CustomBoxy(
          key: const GlobalObjectKey(#boxy),
          delegate: DryTestDelegate(),
          children: const [
            SizedBox(
              key: GlobalObjectKey(#child),
              width: 100,
              height: 200,
            ),
          ],
        ),
      ),
    );

    expect(renderBoxy.size, equals(const Size(100, 200)));

    expect(
      keyBox(#child).size,
      equals(const Size(100, 200)),
    );
  });
}