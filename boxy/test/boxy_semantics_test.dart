import 'package:boxy/boxy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common.dart';

/// A simple delegate that lays out children in a column.
class SimpleDelegate extends BoxyDelegate {
  @override
  Size layout() {
    double y = 0;
    double maxWidth = 0;
    for (final child in children) {
      final size = child.layout(constraints);
      child.position(Offset(0, y));
      y += size.height;
      if (size.width > maxWidth) {
        maxWidth = size.width;
      }
    }
    return Size(maxWidth, y);
  }
}

/// A delegate that reverses the children order for paint/hit-test.
class ReversedChildrenDelegate extends BoxyDelegate {
  @override
  Size layout() {
    double y = 0;
    double maxWidth = 0;
    for (final child in children) {
      final size = child.layout(constraints);
      child.position(Offset(0, y));
      y += size.height;
      if (size.width > maxWidth) {
        maxWidth = size.width;
      }
    }
    return Size(maxWidth, y);
  }

  @override
  List<BoxyChild> get children => super.children.reversed.toList();
}

/// A delegate that provides custom semantics order independent of children.
class CustomSemanticsDelegate extends BoxyDelegate {
  @override
  Size layout() {
    double y = 0;
    double maxWidth = 0;
    for (final child in children) {
      final size = child.layout(constraints);
      child.position(Offset(0, y));
      y += size.height;
      if (size.width > maxWidth) {
        maxWidth = size.width;
      }
    }
    return Size(maxWidth, y);
  }

  @override
  Iterable<BoxyChild> get childrenForSemantics sync* {
    // Return only the second child for semantics
    final allChildren = super.children;
    if (allChildren.length > 1) {
      yield allChildren[1];
    }
  }
}

/// Collects children visited by visitChildrenForSemantics.
List<RenderObject> getSemanticsChildren(RenderObject renderObject) {
  final children = <RenderObject>[];
  renderObject.visitChildrenForSemantics(children.add);
  return children;
}

void main() {
  testWidgets(
    'Default childrenForSemantics returns children in paint order',
    (tester) async {
      await tester.pumpWidget(
        TestFrame(
          child: CustomBoxy(
            key: const GlobalObjectKey(#boxy),
            delegate: SimpleDelegate(),
            children: const [
              BoxyId(
                id: #first,
                child: SizedBox(
                  key: GlobalObjectKey(#first),
                  width: 100,
                  height: 50,
                ),
              ),
              BoxyId(
                id: #second,
                child: SizedBox(
                  key: GlobalObjectKey(#second),
                  width: 100,
                  height: 50,
                ),
              ),
              BoxyId(
                id: #third,
                child: SizedBox(
                  key: GlobalObjectKey(#third),
                  width: 100,
                  height: 50,
                ),
              ),
            ],
          ),
        ),
      );

      final boxyRender = keyBox(#boxy);
      final semanticsChildren = getSemanticsChildren(boxyRender);

      expect(semanticsChildren.length, 3);
      expect(semanticsChildren[0], keyBox(#first));
      expect(semanticsChildren[1], keyBox(#second));
      expect(semanticsChildren[2], keyBox(#third));
    },
  );

  testWidgets(
    'Overriding children affects childrenForSemantics',
    (tester) async {
      await tester.pumpWidget(
        TestFrame(
          child: CustomBoxy(
            key: const GlobalObjectKey(#boxy),
            delegate: ReversedChildrenDelegate(),
            children: const [
              BoxyId(
                id: #first,
                child: SizedBox(
                  key: GlobalObjectKey(#first),
                  width: 100,
                  height: 50,
                ),
              ),
              BoxyId(
                id: #second,
                child: SizedBox(
                  key: GlobalObjectKey(#second),
                  width: 100,
                  height: 50,
                ),
              ),
              BoxyId(
                id: #third,
                child: SizedBox(
                  key: GlobalObjectKey(#third),
                  width: 100,
                  height: 50,
                ),
              ),
            ],
          ),
        ),
      );

      final boxyRender = keyBox(#boxy);
      final semanticsChildren = getSemanticsChildren(boxyRender);

      // Semantics should follow the reversed children order
      expect(semanticsChildren.length, 3);
      expect(semanticsChildren[0], keyBox(#third));
      expect(semanticsChildren[1], keyBox(#second));
      expect(semanticsChildren[2], keyBox(#first));
    },
  );

  testWidgets(
    'Overriding childrenForSemantics customizes semantics order',
    (tester) async {
      await tester.pumpWidget(
        TestFrame(
          child: CustomBoxy(
            key: const GlobalObjectKey(#boxy),
            delegate: CustomSemanticsDelegate(),
            children: const [
              BoxyId(
                id: #first,
                child: SizedBox(
                  key: GlobalObjectKey(#first),
                  width: 100,
                  height: 50,
                ),
              ),
              BoxyId(
                id: #second,
                child: SizedBox(
                  key: GlobalObjectKey(#second),
                  width: 100,
                  height: 50,
                ),
              ),
              BoxyId(
                id: #third,
                child: SizedBox(
                  key: GlobalObjectKey(#third),
                  width: 100,
                  height: 50,
                ),
              ),
            ],
          ),
        ),
      );

      final boxyRender = keyBox(#boxy);
      final semanticsChildren = getSemanticsChildren(boxyRender);

      // Only the second child should be in semantics
      expect(semanticsChildren.length, 1);
      expect(semanticsChildren[0], keyBox(#second));
    },
  );
}
