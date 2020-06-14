import 'package:boxy/slivers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common.dart';
import 'mock_canvas.dart';

class TestClipper extends CustomClipper<Path> {
  TestClipper(this.path);
  final Path path;

  var wasCalled = false;

  @override
  Path getClip(Size size) {
    wasCalled = true;
    return path;
  }

  @override
  bool shouldReclip(TestClipper oldClipper) {
    return oldClipper.path != path;
  }
}

class TestSliverChild extends StatelessWidget {
  const TestSliverChild({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => SliverList(
    delegate: SliverChildListDelegate([
      const Placeholder(fallbackWidth: 100, fallbackHeight: 100),
    ]),
  );
}

void main() {
  testWidgets('Reclips when clipper changes', (tester) async {
    final clipper1 = TestClipper(Path()
      ..moveTo(0, 0)
      ..lineTo(10, 0)
      ..lineTo(10, 10)
      ..close()
    );

    await tester.pumpWidget(TestFrame(
      child: CustomScrollView(
        slivers: [
          SliverContainer(
            key: const GlobalObjectKey(#container),
            sliver: const TestSliverChild(),
            clipper: clipper1,
            clipBehavior: Clip.antiAlias,
          ),
        ],
      ),
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
    ));

    expect(keySliver(#container).paint, paints
      ..save()
      ..clipPath(pathMatcher: isPathThat(includes: [
        const Offset(0, 0),
        const Offset(10, 0),
        const Offset(10, 10),
      ]))
      ..save()
      ..path() // Placeholder
      ..restore()
      ..restore(),
    );
    expect(clipper1.wasCalled, true);

    // Should not recalculate the clip unless clipper changes.

    clipper1.wasCalled = false;

    await tester.pumpWidget(TestFrame(
      child: CustomScrollView(
        slivers: [
          SliverContainer(
            key: const GlobalObjectKey(#container),
            sliver: const TestSliverChild(),
            clipper: clipper1,
            clipBehavior: Clip.antiAlias,
          ),
        ],
      ),
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
    ));

    expect(clipper1.wasCalled, false);

    // Should reclip if clipper changes.

    final clipper2 = TestClipper(Path()
      ..moveTo(5, 5)
      ..lineTo(15, 5)
      ..lineTo(15, 15)
      ..close()
    );

    await tester.pumpWidget(TestFrame(
      child: CustomScrollView(
        slivers: [
          SliverContainer(
            key: const GlobalObjectKey(#container),
            sliver: const TestSliverChild(),
            clipper: clipper2,
            clipBehavior: Clip.antiAlias,
          ),
        ],
      ),
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
    ));

    expect(keySliver(#container).paint, paints
      ..save()
      ..clipPath(pathMatcher: isPathThat(includes: [
        const Offset(5, 5),
        const Offset(15, 5),
        const Offset(15, 15),
      ]))
      ..save()
      ..path() // Placeholder
      ..restore()
      ..restore(),
    );
    expect(clipper2.wasCalled, true);
  });
}
