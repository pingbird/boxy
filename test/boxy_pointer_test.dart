import 'package:boxy/boxy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'boxy_sliver_test.dart';
import 'common.dart';

class PointerBoxy extends BoxyDelegate {
  PointerBoxy(this._onPointerEvent);

  final void Function(
    PointerEvent event,
    BoxHitTestEntry entry,
  ) _onPointerEvent;

  @override
  void onPointerEvent(PointerEvent event, BoxHitTestEntry entry) {
    return _onPointerEvent(event, entry);
  }
}

class BoxPointerBoxy extends BoxBoxyDelegate {
  BoxPointerBoxy(this._onPointerEvent);

  final void Function(
    PointerEvent event,
    BoxHitTestEntry entry,
  ) _onPointerEvent;

  @override
  void onPointerEvent(PointerEvent event, BoxHitTestEntry entry) {
    return _onPointerEvent(event, entry);
  }
}

class SliverPointerBoxy extends SliverBoxyDelegate {
  SliverPointerBoxy(this._onPointerEvent);

  final void Function(
    PointerEvent event,
    SliverHitTestEntry entry,
  ) _onPointerEvent;

  @override
  void onPointerEvent(PointerEvent event, SliverHitTestEntry entry) {
    return _onPointerEvent(event, entry);
  }
}

void main() {
  testWidgets('BoxyDelegate onPointerEvent', (tester) async {
    BoxHitTestEntry? gotEntry;
    await tester.pumpWidget(
      CustomBoxy(
        key: const GlobalObjectKey(#boxy),
        delegate: PointerBoxy((event, entry) => gotEntry = entry),
      ),
    );
    final box = keyBox(#boxy);
    final realEntry = BoxHitTestEntry(box, Offset.zero);
    box.handleEvent(const PointerDownEvent(), realEntry);
    expect(gotEntry, realEntry);
  });

  testWidgets('BoxBoxyDelegate onPointerEvent', (tester) async {
    BoxHitTestEntry? gotEntry;
    await tester.pumpWidget(
      CustomBoxy.box(
        key: const GlobalObjectKey(#boxy),
        delegate: BoxPointerBoxy((event, entry) => gotEntry = entry),
      ),
    );
    final box = keyBox(#boxy);
    final realEntry = BoxHitTestEntry(box, Offset.zero);
    box.handleEvent(const PointerDownEvent(), realEntry);
    expect(gotEntry, realEntry);
  });

  testWidgets('SliverBoxyDelegate onPointerEvent', (tester) async {
    SliverHitTestEntry? gotEntry;
    await tester.pumpWidget(
      CustomBoxy.box(
        delegate: BoxToSliverAdapterBoxy(),
        children: [
          CustomBoxy.sliver(
            key: const GlobalObjectKey(#boxy),
            delegate: SliverPointerBoxy((event, entry) => gotEntry = entry),
          ),
        ],
      ),
    );
    final sliver = keySliver(#boxy);
    final realEntry = SliverHitTestEntry(
      sliver,
      crossAxisPosition: 0,
      mainAxisPosition: 0,
    );
    sliver.handleEvent(const PointerDownEvent(), realEntry);
    expect(gotEntry, realEntry);
  });
}
