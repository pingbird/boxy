import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:boxy/flex.dart';
import 'package:boxy/utils.dart';

import 'common.dart';

void main() {
  testWidgets('No flexible children', (tester) async {
    for (var direction in Axis.values) {
      await tester.pumpWidget(TestFrame(child: BoxyFlex(
        key: GlobalObjectKey(#flex),
        direction: direction,
        children: [
          AxisSizedBox(
            axis: direction,
            key: GlobalObjectKey(#first),
            main: 25,
          ),
          Dominant(child: AxisSizedBox(
            axis: direction,
            main: 50,
            cross: 100,
            key: GlobalObjectKey(#second),
          )),
          AxisSizedBox(
            axis: direction,
            key: GlobalObjectKey(#third),
            main: 75,
          ),
        ],
      )));

      var flex = boxRect(keyBox(#flex));
      var first = boxRect(keyBox(#first));
      var second = boxRect(keyBox(#second));
      var third = boxRect(keyBox(#third));

      expect(flex, equals(
        Offset.zero & SizeAxisUtil.create(direction, 100, 150),
      ));

      expect(first, equals(
        Offset.zero & SizeAxisUtil.create(direction, 100, 25),
      ));

      expect(second, equals(
        OffsetAxisUtil.create(direction, 0, 25) &
        SizeAxisUtil.create(direction, 100, 50),
      ));

      expect(third, equals(
        OffsetAxisUtil.create(direction, 0, 75) &
        SizeAxisUtil.create(direction, 100, 75),
      ));
    }
  });

  testWidgets('All flexible children', (tester) async {
    for (var direction in Axis.values) {
      await tester.pumpWidget(TestFrame(child: BoxyFlex(
        key: GlobalObjectKey(#flex),
        direction: direction,
        children: [
          BoxyFlexible(
            flex: 1,
            child: Container(
              key: GlobalObjectKey(#first),
            ),
          ),
          BoxyFlexible(
            dominant: true,
            flex: 2,
            child: AxisSizedBox(
              axis: direction,
              key: GlobalObjectKey(#second),
              cross: 150,
            ),
          ),
          BoxyFlexible(
            flex: 1,
            child: Container(
              key: GlobalObjectKey(#third),
            ),
          ),
        ],
      ), constraints: BoxConstraintsAxisUtil.create(
        direction,
        minMain: 400,
        maxMain: 400,
      )));

      var flex = boxRect(keyBox(#flex));
      var first = boxRect(keyBox(#first));
      var second = boxRect(keyBox(#second));
      var third = boxRect(keyBox(#third));

      expect(flex, equals(
        Offset.zero & SizeAxisUtil.create(direction, 150, 400),
      ));

      expect(first, equals(
        Offset.zero & SizeAxisUtil.create(direction, 150, 100),
      ));

      expect(second, equals(
        OffsetAxisUtil.create(direction, 0, 100) &
        SizeAxisUtil.create(direction, 150, 200),
      ));

      expect(third, equals(
        OffsetAxisUtil.create(direction, 0, 300) &
        SizeAxisUtil.create(direction, 150, 100),
      ));
    }
  });

  testWidgets('Mixed flexible children', (tester) async {
    for (var direction in Axis.values) {
      await tester.pumpWidget(TestFrame(child: BoxyFlex(
        key: GlobalObjectKey(#flex),
        direction: direction,
        children: [
          BoxyFlexible(
            flex: 0,
            child: AxisSizedBox(
              axis: direction,
              key: GlobalObjectKey(#first),
              main: 100,
            ),
          ),
          BoxyFlexible(
            dominant: true,
            flex: 2,
            fit: FlexFit.tight,
            child: AxisSizedBox(
              axis: direction,
              key: GlobalObjectKey(#second),
              cross: 150,
            ),
          ),
          BoxyFlexible(
            flex: 1,
            fit: FlexFit.tight,
            child: Container(
              key: GlobalObjectKey(#third),
            ),
          ),
        ],
      ), constraints: BoxConstraintsAxisUtil.create(
        direction,
        minMain: 400,
        maxMain: 400,
      )));

      var flex = boxRect(keyBox(#flex));
      var first = boxRect(keyBox(#first));
      var second = boxRect(keyBox(#second));
      var third = boxRect(keyBox(#third));

      expect(flex, equals(
        Offset.zero & SizeAxisUtil.create(direction, 150, 400),
      ));

      expect(first, equals(
        Offset.zero & SizeAxisUtil.create(direction, 150, 100),
      ));

      expect(second, equals(
        OffsetAxisUtil.create(direction, 0, 100) &
          SizeAxisUtil.create(direction, 150, 200),
      ));

      expect(third, equals(
        OffsetAxisUtil.create(direction, 0, 300) &
          SizeAxisUtil.create(direction, 150, 100),
      ));
    }
  });

  testWidgets('Centered cross axis', (tester) async {
    for (var direction in Axis.values) {
      await tester.pumpWidget(TestFrame(child: BoxyFlex(
        key: GlobalObjectKey(#flex),
        direction: direction,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          BoxyFlexible(
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
              key: GlobalObjectKey(#second),
              cross: 300,
              main: 100,
            ),
          ),
        ],
      )));

      var flexBox = keyBox(#flex);

      var flex = boxRect(flexBox);
      var first = boxRect(keyBox(#first));
      var second = boxRect(keyBox(#second));

      expect(flex, equals(
        Offset.zero & SizeAxisUtil.create(direction, 300, 200),
      ));

      expect(first, equals(
        OffsetAxisUtil.create(direction, 100, 0) & Size(100, 100),
      ));

      expect(second, equals(
        OffsetAxisUtil.create(direction, 0, 100) &
        SizeAxisUtil.create(direction, 300, 100),
      ));
    }
  });
}
