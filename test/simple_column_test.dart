// @dart=2.9

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:boxy/boxy.dart';

import 'common.dart';

/// Lays out two children like a column where the second widget is the same
/// width as the first
class SimpleColumnDelegate extends BoxyDelegate {
  @override
  Size layout() {
    // Get both children by a Symbol id.
    final firstChild = getChild(#first);
    final secondChild = getChild(#second);

    // Lay out the first child with the incoming constraints
    final firstSize = firstChild.layout(constraints);
    firstChild.position(Offset.zero);

    // Lay out the second child
    final secondSize = secondChild.layout(
      constraints.deflate(
        // Subtract height consumed by the first child from the constraints
        EdgeInsets.only(top: firstSize.height)
      ).tighten(
        // Force width to be the same as the first child
        width: firstSize.width
      )
    );

    // Position the second child below the first
    secondChild.position(Offset(0, firstSize.height));

    // Calculate the total size based on the size of each child
    return Size(
      firstSize.width,
      firstSize.height + secondSize.height,
    );
  }
}

void main() {
  testWidgets('Consistent dimensions', (tester) async {
    await tester.pumpWidget(TestFrame(child: CustomBoxy(
      key: const GlobalObjectKey(#boxy),
      delegate: SimpleColumnDelegate(),
      children: [
        LayoutId(id: #first, child: Container(
          key: const GlobalObjectKey(#first),
          width: 128,
          height: 64,
        )),
        LayoutId(id: #second, child: Container(
          key: const GlobalObjectKey(#second),
          height: 32,
        )),
      ],
    )));

    final boxyRect = boxRect(keyBox(#boxy));
    final firstRect = boxRect(keyBox(#first));
    final secondRect = boxRect(keyBox(#second));

    expect(boxyRect, const Rect.fromLTWH(0, 0, 128, 96));
    expect(firstRect, const Rect.fromLTWH(0, 0, 128, 64));
    expect(secondRect, const Rect.fromLTWH(0, 64, 128, 32));
  });

  testWidgets('Height constraints', (tester) async {
    await tester.pumpWidget(TestFrame(child: CustomBoxy(
      key: const GlobalObjectKey(#boxy),
      delegate: SimpleColumnDelegate(),
      children: [
        LayoutId(id: #first, child: Container(
          key: const GlobalObjectKey(#first),
          width: 128,
          height: 64,
        )),
        LayoutId(id: #second, child: Column(children: [
          Expanded(child: Container(
            key: const GlobalObjectKey(#second),
          )),
        ])),
      ],
    ), constraints: const BoxConstraints(maxHeight: 128)));

    final boxyRect = boxRect(keyBox(#boxy));
    final firstRect = boxRect(keyBox(#first));
    final secondRect = boxRect(keyBox(#second));

    expect(boxyRect, const Rect.fromLTWH(0, 0, 128, 128));
    expect(firstRect, const Rect.fromLTWH(0, 0, 128, 64));
    expect(secondRect, const Rect.fromLTWH(0, 64, 128, 64));
  });
}
