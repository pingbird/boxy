import 'package:boxy/boxy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import 'common.dart';

class BoxToSliverAdapterBoxy extends BoxBoxyDelegate {
  @override
  Size layout() {
    final child = getChild<SliverBoxyChild>(0);
    final geometry = child.layout(
      SliverConstraints(
        axisDirection: AxisDirection.down,
        growthDirection: GrowthDirection.forward,
        userScrollDirection: ScrollDirection.idle,
        scrollOffset: 0,
        precedingScrollExtent: 0,
        overlap: 0,
        remainingPaintExtent: constraints.maxHeight,
        crossAxisExtent: constraints.maxWidth,
        crossAxisDirection: AxisDirection.right,
        viewportMainAxisExtent: constraints.maxHeight,
        remainingCacheExtent: constraints.maxHeight,
        cacheOrigin: 0,
      ),
    );

    return Size(
      constraints.maxWidth,
      geometry.layoutExtent,
    );
  }
}

class TestButton extends StatelessWidget {
  final void Function(Offset position, int index) setPosition;
  final int index;

  const TestButton({
    Key? key,
    required this.index,
    required this.setPosition,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      child: GestureDetector(
        onTapDown: (details) {
          setPosition(details.localPosition, index);
        },
      ),
    );
  }
}

void main() {
  testWidgets('Consistent subtitle', (tester) async {
    Offset? lastPosition;
    int? lastIndex;

    void setPosition(Offset position, int index) {
      lastPosition = position;
      lastIndex = index;
    }

    await tester.pumpWidget(TestFrame(
      child: SizedBox(
        width: 200,
        child: CustomBoxy.box(
          key: const GlobalObjectKey(#boxy),
          delegate: BoxToSliverAdapterBoxy(),
          children: [
            SliverList(
              delegate: SliverChildListDelegate([
                TestButton(
                  key: const GlobalObjectKey(0),
                  index: 0,
                  setPosition: setPosition,
                ),
                TestButton(
                  key: const GlobalObjectKey(1),
                  index: 1,
                  setPosition: setPosition,
                ),
                TestButton(
                  key: const GlobalObjectKey(2),
                  index: 2,
                  setPosition: setPosition,
                ),
              ]),
            ),
          ],
        ),
      ),
    ));

    final boxyRect = boxRect(keyBox(#boxy));
    expect(boxyRect, const Rect.fromLTWH(0, 0, 200, 150));

    for (var i = 0; i < 3; i++) {
      final button = keyBox(i);
      expect(boxRect(button), Rect.fromLTWH(0, i * 50.0, 200, 50));
      await tester.tapAt(Offset(100, i * 50.0 + 25.0));
      expect(lastIndex, i);
      expect(lastPosition, const Offset(100, 25));
      final transform = button.getTransformTo(null);
      final topLeft = transform.transform3(Vector3.zero());
      expect(topLeft, Vector3(0, i * 50.0, 0));
    }
  });
}
