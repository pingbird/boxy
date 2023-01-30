import 'package:boxy/boxy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common.dart';

class SimpleInflationDelegate extends BoxyDelegate {
  @override
  Size layout() {
    final firstChild = children[0];

    final firstSize = firstChild.layout(constraints);
    firstChild.position(Offset.zero);

    final text = Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        '^ This guy is ${firstSize.width} x ${firstSize.height}',
        key: const GlobalObjectKey(#subtitle),
        textAlign: TextAlign.center,
      ),
    );

    // Inflate the text widget
    final secondChild = inflate(text, id: #subtitle);

    final secondSize = secondChild.layout(constraints
        .deflate(EdgeInsets.only(top: firstSize.height))
        .tighten(width: firstSize.width));

    secondChild.position(Offset(0, firstSize.height));

    return Size(
      firstSize.width,
      firstSize.height + secondSize.height,
    );
  }
}

void main() {
  testWidgets('Consistent subtitle', (tester) async {
    await tester.pumpWidget(
      TestFrame(
        child: CustomBoxy(
          key: const GlobalObjectKey(#boxy),
          delegate: SimpleInflationDelegate(),
          children: const [
            SizedBox(
              width: 100,
              height: 50,
            ),
          ],
        ),
      ),
    );

    final subtitle = keyWidget<Text>(#subtitle).data;

    expect(subtitle, equals('^ This guy is 100.0 x 50.0'));
  });
}
