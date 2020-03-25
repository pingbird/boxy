import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:boxy/boxy.dart';

import 'common.dart';

class StateTestChild extends StatefulWidget {
  StateTestChild({Key key}) : super(key: key);
  createState() => StateTestChildState();
}

class StateTestChildState extends State<StateTestChild> {
  bool isNew;
  bool checkDisposed;

  @override
  initState() {
    super.initState();
    isNew = true;
  }

  @override
  dispose() {
    super.dispose();
    expect(checkDisposed, isNull);
    checkDisposed = true;
  }

  build(context) => Container(width: 10, height: 10);
}

class StateTestDelegate extends BoxyDelegate {
  final int numChildren;
  final List<String> inflatedNames;

  StateTestDelegate({
    @required this.numChildren,
    @required this.inflatedNames,
  });

  @override
  layout() {
    var offset = 0.0;
    var maxWidth = 0.0;
    final childConstraints = constraints.copyWith(
      minHeight: 0.0, maxHeight: double.infinity,
    );

    expect(children, hasLength(numChildren));

    for (var id in inflatedNames) inflate(
      StateTestChild(key: GlobalObjectKey(id)), id: id,
    );

    expect(children, hasLength(numChildren + inflatedNames.length));

    for (var child in children) {
      final size = child.layout(childConstraints);
      child.position(Offset(0, offset));
      offset += size.height;
      maxWidth = max(maxWidth, size.width);
    }

    return Size(maxWidth, offset);
  }

  @override
  shouldRelayout(StateTestDelegate old) => true;
}

void main() {
  testWidgets('State preservation', (tester) => tester.runAsync(() async {
    var states = <String, StateTestChildState>{};

    Future<void> testMutate(Set<String> children, Set<String> inflated, Set<String> outside) async {
      await tester.pumpWidget(TestFrame(child: Column(children: [
        Boxy(
          key: GlobalObjectKey(#boxy),
          delegate: StateTestDelegate(
            numChildren: children.length,
            inflatedNames: inflated.toList(),
          ),
          children: [
            for (var nm in children) StateTestChild(key: GlobalObjectKey(nm)),
          ],
        ),
        for (var nm in outside) StateTestChild(key: GlobalObjectKey(nm)),
      ])));

      var allNames = children.union(inflated).union(outside);

      var boxyElement = keyElement(#boxy);

      var childElements = <Element>[];
      boxyElement.visitChildren(childElements.add);
      expect(childElements, hasLength(allNames.length - outside.length));

      var childRenderObjects = <RenderBox>[];
      boxyElement.renderObject.visitChildren(childRenderObjects.add);

      // Make sure Element tree is in the correct order

      for (var i = 0; i < children.length; i++) {
        expect(childElements[i].widget.key, equals(GlobalObjectKey(children.elementAt(i))));
      }

      for (var i = 0; i < inflated.length; i++) {
        expect(childElements[i + children.length].widget.key, equals(GlobalObjectKey(inflated.elementAt(i))));
      }

      // Make sure Element tree matches RenderObject tree

      expect(childRenderObjects, hasLength(childElements.length));
      for (var i = 0; i < childElements.length; i++) {
        expect(childElements[i].renderObject, equals(childRenderObjects[i]));
        Element parent;
        childElements[i].visitAncestorElements((element) {
          parent = element;
          return false;
        });
        expect(parent, equals(boxyElement));
      }

      for (var nm in allNames) {
        var element = keyElement(nm) as StatefulElement;
        expect(element.widget, isA<StateTestChild>());
        var state = element.state as StateTestChildState;

        if (!states.containsKey(nm)) {
          // Make sure new children have new states
          expect(state.isNew, isTrue);
          state.isNew = false;
          states[nm] = state;
        } else {
          // Make sure state has been preserved
          expect(states[nm], equals(state));
        }
      }

      // Make sure old children have been disposed
      for (var nm in states.keys.where((nm) => !allNames.contains(nm)).toList()) {
        var state = states[nm];
        expect(state.checkDisposed, isTrue);
        state.checkDisposed = false;
        states.remove(nm);
      }
    }

    // Test arbitrary ordering of explicit children / inflated children
    Future<void> mutateIter(int n) => testMutate({
      if (n & 1 != 0) "c0",
      if ((n >> 1) & 1 != 0) "c1",
      if ((n >> 2) & 1 != 0) "c2",
    }, {
      if ((n >> 3) & 1 != 0) "c3",
      if ((n >> 4) & 1 != 0) "c4",
      if ((n >> 5) & 1 != 0) "c5",
    }, {});

    for (int i = 0; i < 64; i++) {
      for (int j = 0; j < i; j++) {
        await mutateIter(i);
        await mutateIter(j);
      }
    }

    // Test moving children in and out of the boxy element with GlobalKeys
    Future<void> mutateIter2(int n) => testMutate({}, {
      if (n % 3 == 1) "c0",
      if ((n ~/ 3) % 3 == 1) "c1",
      if ((n ~/ 9) % 3 == 1) "c2",
    }, {
      if (n % 3 == 2) "c0",
      if ((n ~/ 3) % 3 == 2) "c1",
      if ((n ~/ 9) % 3 == 2) "c2",
    });

    for (int i = 0; i < 27; i++) {
      for (int j = 0; j < i; j++) {
        await mutateIter2(i);
        await mutateIter2(j);
      }
    }
  }));
}