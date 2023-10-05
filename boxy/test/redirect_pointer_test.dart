import 'package:boxy/src/redirect_pointer.dart';
import 'package:boxy/src/scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common.dart';

void main() {
  testWidgets('RedirectPointer - Basic', (tester) async {
    final taps = <TapDownDetails>[];
    final key = GlobalKey();
    await tester.pumpWidget(TestFrame(
      constraints: BoxConstraints.tight(const Size(300, 300)),
      child: RedirectPointer(
        above: [key],
        child: Center(
          child: SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              children: [
                Positioned(
                  left: -100,
                  child: IgnorePointer(
                    child: Container(
                      key: key,
                      width: 50,
                      height: 50,
                      color: Colors.red,
                      child: GestureDetector(
                        onTapDown: taps.add,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
    await tester.tapAt(tester.getCenter(find.byKey(key)));
    expect(taps, hasLength(1));
    expect(taps.single.globalPosition, equals(const Offset(25, 125)));
    expect(taps.single.localPosition, equals(const Offset(25, 25)));
  });

  testWidgets('RedirectPointer - Scaled', (tester) async {
    final taps = <TapDownDetails>[];
    final key = GlobalKey();
    await tester.pumpWidget(TestFrame(
      constraints: BoxConstraints.tight(const Size(300, 300)),
      child: RedirectPointer(
        below: [key],
        child: Center(
          child: SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              children: [
                Positioned(
                  top: -100,
                  child: Scale(
                    scale: 2,
                    child: IgnorePointer(
                      child: Container(
                        key: key,
                        width: 50,
                        height: 50,
                        color: Colors.red,
                        child: GestureDetector(
                          onTapDown: taps.add,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
    await tester.tapAt(tester.getCenter(find.byKey(key)));
    expect(taps, hasLength(1));
    expect(taps.single.globalPosition, equals(const Offset(150, 50)));
    expect(taps.single.localPosition, equals(const Offset(25, 25)));
  });
}
