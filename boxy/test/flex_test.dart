import 'package:boxy/flex.dart';
import 'package:boxy/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common.dart';

void main() {
  testWidgets('No flexible children', (tester) async {
    for (final direction in Axis.values) {
      await tester.pumpWidget(TestFrame(
          child: BoxyFlex(
        key: const GlobalObjectKey(#flex),
        direction: direction,
        children: [
          AxisSizedBox(
            axis: direction,
            key: const GlobalObjectKey(#first),
            main: 25,
          ),
          Dominant(
              child: AxisSizedBox(
            axis: direction,
            main: 50,
            cross: 100,
            key: const GlobalObjectKey(#second),
          )),
          AxisSizedBox(
            axis: direction,
            key: const GlobalObjectKey(#third),
            main: 75,
          ),
        ],
      )));

      final flex = boxRect(keyBox(#flex));
      final first = boxRect(keyBox(#first));
      final second = boxRect(keyBox(#second));
      final third = boxRect(keyBox(#third));

      expect(
          flex,
          equals(
            Offset.zero & SizeAxisUtil.create(direction, 100, 150),
          ));

      expect(
          first,
          equals(
            Offset.zero & SizeAxisUtil.create(direction, 100, 25),
          ));

      expect(
          second,
          equals(
            OffsetAxisUtil.create(direction, 0, 25) &
                SizeAxisUtil.create(direction, 100, 50),
          ));

      expect(
          third,
          equals(
            OffsetAxisUtil.create(direction, 0, 75) &
                SizeAxisUtil.create(direction, 100, 75),
          ));
    }
  });

  testWidgets('All flexible children', (tester) async {
    for (final direction in Axis.values) {
      await tester.pumpWidget(TestFrame(
        constraints: BoxConstraintsAxisUtil.create(
          direction,
          minMain: 400,
          maxMain: 400,
        ),
        child: BoxyFlex(
          key: const GlobalObjectKey(#flex),
          direction: direction,
          children: [
            const BoxyFlexible(
              child: SizedBox(
                key: GlobalObjectKey(#first),
                width: 50.0,
                height: 50.0,
              ),
            ),
            Dominant.expanded(
              flex: 2,
              child: AxisSizedBox(
                axis: direction,
                key: const GlobalObjectKey(#second),
                cross: 150,
              ),
            ),
            Expanded(
              child: Container(
                key: const GlobalObjectKey(#third),
              ),
            ),
          ],
        ),
      ));

      final flexBox = keyBox(#flex);
      final firstBox = keyBox(#first);
      final secondBox = keyBox(#second);
      final thirdBox = keyBox(#third);

      expect(
        firstBox.constraints,
        BoxConstraintsAxisUtil.create(
          direction,
          maxMain: 100.0,
          minCross: 150.0,
          maxCross: 150.0,
        ),
      );

      expect(
        secondBox.constraints,
        BoxConstraintsAxisUtil.tightFor(
          direction,
          main: 200.0,
        ),
      );

      expect(
        thirdBox.constraints,
        BoxConstraintsAxisUtil.tightFor(
          direction,
          main: 100.0,
          cross: 150.0,
        ),
      );

      expect(
        boxRect(flexBox),
        equals(
          Offset.zero & SizeAxisUtil.create(direction, 150, 400),
        ),
      );

      expect(
        boxRect(firstBox),
        equals(
          Offset.zero & SizeAxisUtil.create(direction, 150, 50),
        ),
      );

      expect(
        boxRect(secondBox),
        equals(
          OffsetAxisUtil.create(direction, 0, 50) &
              SizeAxisUtil.create(direction, 150, 200),
        ),
      );

      expect(
        boxRect(thirdBox),
        equals(
          OffsetAxisUtil.create(direction, 0, 250) &
              SizeAxisUtil.create(direction, 150, 100),
        ),
      );
    }
  });

  testWidgets('Mixed flexible children', (tester) async {
    for (final direction in Axis.values) {
      await tester.pumpWidget(TestFrame(
        constraints: BoxConstraintsAxisUtil.create(
          direction,
          minMain: 400,
          maxMain: 400,
        ),
        child: BoxyFlex(
          key: const GlobalObjectKey(#flex),
          direction: direction,
          children: [
            BoxyFlexible(
              flex: 0,
              child: AxisSizedBox(
                axis: direction,
                key: const GlobalObjectKey(#first),
                main: 100,
              ),
            ),
            BoxyFlexible(
              dominant: true,
              flex: 2,
              fit: FlexFit.tight,
              child: AxisSizedBox(
                axis: direction,
                key: const GlobalObjectKey(#second),
                cross: 150,
              ),
            ),
            BoxyFlexible(
              fit: FlexFit.tight,
              child: Container(
                key: const GlobalObjectKey(#third),
              ),
            ),
          ],
        ),
      ));

      final flex = boxRect(keyBox(#flex));
      final first = boxRect(keyBox(#first));
      final second = boxRect(keyBox(#second));
      final third = boxRect(keyBox(#third));

      expect(
        flex,
        equals(
          Offset.zero & SizeAxisUtil.create(direction, 150, 400),
        ),
      );

      expect(
        first,
        equals(
          Offset.zero & SizeAxisUtil.create(direction, 150, 100),
        ),
      );

      expect(
        second,
        equals(
          OffsetAxisUtil.create(direction, 0, 100) &
              SizeAxisUtil.create(direction, 150, 200),
        ),
      );

      expect(
        third,
        equals(
          OffsetAxisUtil.create(direction, 0, 300) &
              SizeAxisUtil.create(direction, 150, 100),
        ),
      );
    }
  });

  testWidgets('Centered cross axis', (tester) async {
    for (final direction in Axis.values) {
      await tester.pumpWidget(TestFrame(
        child: BoxyFlex(
          key: const GlobalObjectKey(#flex),
          direction: direction,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const BoxyFlexible(
              flex: 0,
              child: SizedBox(
                key: GlobalObjectKey(#first),
                width: 100,
                height: 100,
              ),
            ),
            BoxyFlexible(
              dominant: true,
              flex: 0,
              child: AxisSizedBox(
                axis: direction,
                key: const GlobalObjectKey(#second),
                cross: 300,
                main: 100,
              ),
            ),
          ],
        ),
      ));

      final flex = boxRect(keyBox(#flex));
      final first = boxRect(keyBox(#first));
      final second = boxRect(keyBox(#second));

      expect(
        flex,
        equals(
          Offset.zero & SizeAxisUtil.create(direction, 300, 200),
        ),
      );

      expect(
        first,
        equals(
          OffsetAxisUtil.create(direction, 100, 0) & const Size(100, 100),
        ),
      );

      expect(
        second,
        equals(
          OffsetAxisUtil.create(direction, 0, 100) &
              SizeAxisUtil.create(direction, 300, 100),
        ),
      );
    }
  });

  testWidgets('BoxyFlexIntrinsicsBehavior.measureMain (Horizontal)',
      (tester) async {
    await tester.pumpWidget(
      TestFrame(
        child: SizedBox(
          width: 100,
          child: BoxyRow(
            key: const GlobalObjectKey(#flex),
            children: const [
              SizedBox(
                key: GlobalObjectKey(#first),
                width: 50,
                height: 50,
              ),
              Dominant.expanded(
                key: GlobalObjectKey(#second),
                child:
                    Text('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'),
              ),
            ],
          ),
        ),
      ),
    );

    final flexBox = keyBox(#flex);
    final firstBox = keyBox(#first);
    final secondBox = keyBox(#second);

    final height = secondBox.getMaxIntrinsicHeight(50);

    expect(flexBox.size.height, equals(height));
    expect(firstBox.size, equals(Size(50, height)));
    expect(secondBox.size, equals(Size(50, height)));
  });

  testWidgets('BoxyFlexIntrinsicsBehavior.measureMain (Vertical)',
      (tester) async {
    await tester.pumpWidget(
      TestFrame(
        child: SizedBox(
          height: 100,
          child: BoxyColumn(
            key: const GlobalObjectKey(#flex),
            intrinsicsBehavior: BoxyFlexIntrinsicsBehavior.measureMain,
            children: const [
              SizedBox(
                key: GlobalObjectKey(#first),
                width: 50,
                height: 50,
              ),
              Dominant.expanded(
                key: GlobalObjectKey(#second),
                child: RotatedBox(
                  quarterTurns: 1,
                  child: Text(
                    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final flexBox = keyBox(#flex);
    final firstBox = keyBox(#first);
    final secondBox = keyBox(#second);

    final width = secondBox.getMaxIntrinsicWidth(50);

    expect(flexBox.size.width, equals(width));
    expect(firstBox.size, equals(Size(width, 50)));
    expect(secondBox.size, equals(Size(width, 50)));
  });

  testWidgets('BoxyFlexible.align', (tester) async {
    const blockSize = 100.0;
    const rowHeight = blockSize * 3;
    const alignmentOffsets = <CrossAxisAlignment, double>{
      CrossAxisAlignment.start: 0.0,
      CrossAxisAlignment.center: rowHeight / 2 - blockSize / 2,
      CrossAxisAlignment.end: rowHeight - blockSize,
      CrossAxisAlignment.stretch: 0.0,
    };

    for (final alignmentOffset in alignmentOffsets.entries) {
      await tester.pumpWidget(
        TestFrame(
          child: SizedBox(
            height: rowHeight,
            child: BoxyRow(
              key: const GlobalObjectKey(#flex),
              crossAxisAlignment: alignmentOffset.key,
              children: [
                for (final childAlignmentOffset in alignmentOffsets.entries)
                  BoxyFlexible.align(
                    crossAxisAlignment: childAlignmentOffset.key,
                    child: SizedBox(
                      key: GlobalObjectKey(childAlignmentOffset.key),
                      width: blockSize,
                      height: blockSize,
                    ),
                  ),
                const SizedBox(
                  key: GlobalObjectKey(#last),
                  width: blockSize,
                  height: blockSize,
                )
              ],
            ),
          ),
        ),
      );

      for (final childAlignmentOffset in alignmentOffsets.entries) {
        final alignBox = keyBox(childAlignmentOffset.key);
        final alignRect = boxRect(alignBox);
        expect(alignRect.top, childAlignmentOffset.value);
        if (childAlignmentOffset.key == CrossAxisAlignment.stretch) {
          expect(alignBox.size, const Size(blockSize, rowHeight));
        } else {
          expect(alignBox.size, const Size(blockSize, blockSize));
        }
      }

      final lastBox = keyBox(#last);
      final lastRect = boxRect(lastBox);
      expect(lastRect.top, alignmentOffset.value);
      if (alignmentOffset.key == CrossAxisAlignment.stretch) {
        expect(lastBox.size, const Size(blockSize, rowHeight));
      } else {
        expect(lastBox.size, const Size(blockSize, blockSize));
      }
    }
  });

  testWidgets('handles overflow properly', (tester) async {
    await tester.pumpWidget(
      TestFrame(
        constraints: BoxConstraints.loose(const Size(300, 300)),
        child: SizedBox(
          width: 200,
          child: BoxyRow(
            mainAxisSize: MainAxisSize.min,
            children: const [
              BoxyFlexible.align(
                crossAxisAlignment: CrossAxisAlignment.start,
                child: SizedBox(
                  width: 400,
                  height: 400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(
      tester.takeException().toString(),
      contains('A RenderBoxyFlex overflowed by 200 pixels on the right.'),
    );
  });
}
