import 'package:boxy/boxy.dart';
import 'package:boxy/utils.dart';
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

class SliverToBoxAdapterBoxy extends SliverBoxyDelegate {
  static const padding = 10.0;

  @override
  SliverGeometry layout() {
    final child = getChild<BoxyChild>(0);
    final size = child.layout(
      constraints.asBoxConstraints().deflate(const EdgeInsets.all(padding)),
    );
    child.position(const Offset(padding, padding));
    final childExtent = size.main + padding * 2;
    final paintedChildSize = constraints.paintOffset(0.0, childExtent);
    final cacheExtent = constraints.cacheOffset(0.0, childExtent);
    return SliverGeometry(
      scrollExtent: childExtent,
      paintExtent: paintedChildSize,
      cacheExtent: cacheExtent,
      maxPaintExtent: childExtent,
      hitTestExtent: paintedChildSize,
      hasVisualOverflow: childExtent > constraints.remainingPaintExtent || constraints.scrollOffset > 0.0,
    );
  }
}

class TestButton extends StatelessWidget {
  static const size = 100.0;

  final void Function(Offset position) setPosition;

  const TestButton({
    Key? key,
    required this.setPosition,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      child: GestureDetector(
        onTapDown: (details) {
          setPosition(details.localPosition);
        },
      ),
    );
  }
}

void main() {
  testWidgets('Sliver child of Box', (tester) async {
    Offset? lastPosition;
    int? lastIndex;

    Widget buildChild(int index) {
      return TestButton(
        key: GlobalObjectKey(index),
        setPosition: (position) {
          lastPosition = position;
          lastIndex = index;
        },
      );
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
                buildChild(0),
                buildChild(1),
                buildChild(2),
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

  testWidgets('Box child of Sliver', (tester) async {
    Offset? lastPosition;
    int? lastIndex;

    Widget buildChild(int index, [double padding = 0]) {
      return Padding(
        padding: EdgeInsets.all(padding),
        child: TestButton(
          key: GlobalObjectKey(index),
          setPosition: (position) {
            lastPosition = position;
            lastIndex = index;
          },
        ),
      );
    }

    final forwardKey = UniqueKey();
    const scrollSize = (SliverToBoxAdapterBoxy.padding * 2 + TestButton.size) * 4;

    for (final direction in AxisDirection.values) {
      Widget buildFrame(List<Widget> slivers) {
        return TestFrame(
          child: SizedBox(
            width: scrollSize,
            height: scrollSize,
            child: CustomScrollView(
              controller: ScrollController(initialScrollOffset: scrollSize / -2),
              center: forwardKey,
              scrollDirection: direction.axis,
              reverse: direction.isReverse,
              slivers: slivers,
            ),
          ),
        );
      }

      await tester.pumpWidget(buildFrame([
        SliverToBoxAdapter(child: buildChild(0, 10)),
        SliverToBoxAdapter(child: buildChild(1, 10)),
        SliverToBoxAdapter(child: buildChild(2, 10), key: forwardKey),
        SliverToBoxAdapter(child: buildChild(3, 10)),
      ]));

      final testRects = <Rect>[];
      final testHits = <Offset>[];
      final testIndices = <int>[];
      final testPositions = <Offset>[];

      Future<void> addHit(int index, Offset offset) async {
        testHits.add(offset);
        lastPosition = null;
        lastIndex = null;
        await tester.tapAt(offset);
        expect(
          lastIndex,
          index,
          reason: 'Expected hit at $offset to be child $index',
        );
        testIndices.add(lastIndex!);
        testPositions.add(lastPosition!);
      }

      // Test each corner of each child
      for (var i = 0; i < 4; i++) {
        final rect = boxRect(keyBox(i));
        final inner = rect.deflate(10.0);
        await addHit(i, inner.topLeft);
        await addHit(i, inner.topRight);
        await addHit(i, inner.bottomRight);
        await addHit(i, inner.bottomLeft);
        testRects.add(rect);
      }

      await tester.pumpWidget(buildFrame([
        // Reverse slivers
        CustomBoxy.sliver(
          delegate: SliverToBoxAdapterBoxy(),
          children: [buildChild(0)],
        ),
        CustomBoxy.sliver(
          delegate: SliverToBoxAdapterBoxy(),
          children: [buildChild(1)],
        ),
        // Forward slivers
        CustomBoxy.sliver(
          key: forwardKey,
          delegate: SliverToBoxAdapterBoxy(),
          children: [buildChild(2)],
        ),
        CustomBoxy.sliver(
          delegate: SliverToBoxAdapterBoxy(),
          children: [buildChild(3)],
        ),
      ]));

      for (var i = 0; i < 4; i++) {
        final rect = boxRect(keyBox(i));
        expect(testRects[i], rect);
      }

      for (var i = 0; i < testHits.length; i++) {
        lastPosition = null;
        lastIndex = null;
        await tester.tapAt(testHits[i]);
        expect(
          lastIndex,
          testIndices[i],
          reason: 'Expected hit at ${testHits[i]} ($lastPosition) to be child ${testIndices[i]}',
        );
        expect(
          lastPosition,
          testPositions[i],
          reason: 'Expected hit at ${testHits[i]} to be ${testPositions[i]} of child ${testIndices[i]}',
        );
      }
    }
  });
}
