import 'package:boxy/boxy.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

class ParentDataBoxy extends BoxyDelegate {
  ParentDataBoxy(this.onLayoutChild);

  final void Function(dynamic parentData) onLayoutChild;

  @override
  Size layout() {
    final child = children.single;
    onLayoutChild(child.parentData);
    child.layout(constraints.loosen());
    return constraints.biggest;
  }
}

void main() {
  testWidgets('BoxyId.data', (tester) async {
    final expectedParentData = ValueNotifier<int>(0);
    var didLayout = false;

    void onLayoutChild(dynamic parentData) {
      expect(didLayout, isFalse);
      didLayout = true;
      expect(parentData, expectedParentData.value);
    }

    await tester.pumpWidget(
      CustomBoxy(
        delegate: ParentDataBoxy(onLayoutChild),
        children: [
          AnimatedBuilder(
            animation: expectedParentData,
            builder: (context, child) {
              return BoxyId(
                id: 'testId',
                data: expectedParentData.value,
                child: SizedBox(width: expectedParentData.value.toDouble()),
              );
            },
          )
        ],
      ),
    );

    // First layout
    expect(didLayout, isTrue);
    didLayout = false;

    // Second layout with new value
    expectedParentData.value++;
    await tester.pumpAndSettle();
    expect(didLayout, isTrue);
  });
}
