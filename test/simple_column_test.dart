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
    var firstChild = getChild(#first);
    var secondChild = getChild(#second);

    // Lay out the first child with the incoming constraints
    var firstSize = firstChild.layout(constraints);
    firstChild.position(Offset.zero);

    // Lay out the second child
    var secondSize = secondChild.layout(
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
      key: GlobalObjectKey(#boxy),
      delegate: SimpleColumnDelegate(),
      children: [
        LayoutId(id: #first, child: Container(
          key: GlobalObjectKey(#first),
          width: 128,
          height: 64,
        )),
        LayoutId(id: #second, child: Container(
          key: GlobalObjectKey(#second),
          height: 32,
        )),
      ],
    )));

    var boxyRect = boxRect(keyBox(#boxy));
    var firstRect = boxRect(keyBox(#first));
    var secondRect = boxRect(keyBox(#second));

    expect(boxyRect, Rect.fromLTWH(0, 0, 128, 96));
    expect(firstRect, Rect.fromLTWH(0, 0, 128, 64));
    expect(secondRect, Rect.fromLTWH(0, 64, 128, 32));
  });

  testWidgets('Height constraints', (tester) async {
    await tester.pumpWidget(TestFrame(child: CustomBoxy(
      key: GlobalObjectKey(#boxy),
      delegate: SimpleColumnDelegate(),
      children: [
        LayoutId(id: #first, child: Container(
          key: GlobalObjectKey(#first),
          width: 128,
          height: 64,
        )),
        LayoutId(id: #second, child: Column(children: [
          Expanded(child: Container(
            key: GlobalObjectKey(#second),
          )),
        ])),
      ],
    ), constraints: BoxConstraints(maxHeight: 128)));

    var boxyRect = boxRect(keyBox(#boxy));
    var firstRect = boxRect(keyBox(#first));
    var secondRect = boxRect(keyBox(#second));

    expect(boxyRect, Rect.fromLTWH(0, 0, 128, 128));
    expect(firstRect, Rect.fromLTWH(0, 0, 128, 64));
    expect(secondRect, Rect.fromLTWH(0, 64, 128, 64));
  });
}
