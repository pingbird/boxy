import 'package:boxy/boxy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class ProxyBoxy extends BoxyDelegate {}

void main() {
  // Viewports call buildScope, which can fail if we call layout inside of our
  // own buildScope for inflation.
  testWidgets('CustomScrollView child smoketest', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CustomBoxy(
          delegate: ProxyBoxy(),
          children: [
            CustomScrollView(
              slivers: [
                SliverList(
                  delegate: SliverChildListDelegate([
                    for (int i = 0; i < 10; i++) Text('$i'),
                  ]),
                ),
              ],
            ),
            BoxyId(
              id: #namedList,
              child: CustomScrollView(
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate([
                      for (int i = 0; i < 10; i++) Text('$i'),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  });
}
