import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:boxy/boxy.dart';

import 'common.dart';

class SimpleInflationDelegate extends BoxyDelegate {
   @override
   Size layout() {
    var firstChild = children[0];

    var firstSize = firstChild.layout(constraints);
    firstChild.position(Offset.zero);

    var text = Padding(child: Text(
      "^ This guy is ${firstSize.width} x ${firstSize.height}",
      key: GlobalObjectKey(#subtitle),
      textAlign: TextAlign.center,
    ), padding: EdgeInsets.all(8));
  
    // Inflate the text widget
    var secondChild = inflate(text, id: #subtitle);

    var secondSize = secondChild.layout(
      constraints.deflate(
        EdgeInsets.only(top: firstSize.height)
      ).tighten(
        width: firstSize.width
      )
    );
  
    secondChild.position(Offset(0, firstSize.height));
  
    return Size(
      firstSize.width,
      firstSize.height + secondSize.height,
    );
  }
}

void main() {
  testWidgets('Consistent subtitle', (tester) async {
    await tester.pumpWidget(TestFrame(child: CustomBoxy(
      key: GlobalObjectKey(#boxy),
      delegate: SimpleInflationDelegate(),
      children: [
        Container(
          width: 100,
          height: 50,
        ),
      ],
    )));

    var subtitle = keyWidget<Text>(#subtitle).data;

    expect(subtitle, equals("^ This guy is 100.0 x 50.0"));
  });
}
