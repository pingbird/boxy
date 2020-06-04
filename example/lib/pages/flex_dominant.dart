import 'dart:math';
import 'dart:ui';

import 'package:boxy/flex.dart';
import 'package:boxy/slivers.dart';
import 'package:flutter/material.dart';
import 'package:boxy_gallery/main.dart';
import 'package:tuple/tuple.dart';
import 'package:boxy/utils.dart';

class FlexDominantPage extends StatefulWidget {
  createState() => FlexDominantPageState();
}

final rainbow = <MaterialColor>[
  Colors.red,
  Colors.deepPurple,
  Colors.lightBlue,
  Colors.green,
  Colors.amber,
];

const shades = [
  400, 500, 600, 700, 800, 900
];

Color lerpGradient(List<Color> colors, List<double> stops, double t) {
  for (var s = 0; s < stops.length - 1; s++) {
    final leftStop = stops[s], rightStop = stops[s + 1];
    final leftColor = colors[s], rightColor = colors[s + 1];
    if (t <= leftStop) {
      return leftColor;
    } else if (t < rightStop) {
      final sectionT = (t - leftStop) / (rightStop - leftStop);
      return Color.lerp(leftColor, rightColor, sectionT);
    }
  }
  return colors.last;
}

Color getRainbowColor(double delta) {
  return lerpGradient(rainbow, [
    for (int i = 0; i < rainbow.length; i++) i / (rainbow.length - 1),
  ], delta);
}

class FlexDominantPageState extends State<FlexDominantPage> {
  build(BuildContext context) => Scaffold(
    appBar: GalleryAppBar(
      ["Boxy Gallery", "Flex Dominant"],
      source: "https://github.com/PixelToast/flutter-boxy/blob/master/example/lib/pages/tree_view.dart",
    ),
    backgroundColor: NiceColors.primary,
    body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Separator(),
      Expanded(child: Align(
        child: BoxyFlex(
          direction: Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ChildCard(text: "Child 1", color: Colors.red),
            Dominant(child: Column(mainAxisSize: MainAxisSize.min, children: [
              ChildCard(text: "Child 2", color: Colors.lightGreen),
              ChildCard(text: "Child 3", color: Colors.blue),
            ])),
          ],
        ),
        widthFactor: 1,
        heightFactor: 1,
      )),
      Separator(),
    ]),
  );
}

class ChildCard extends StatefulWidget {
  final String text;
  final Color color;

  ChildCard({
    @required this.text,
    @required this.color,
  });

  createState() => ChildCardState();
}

class ChildCardState extends State<ChildCard> with SingleTickerProviderStateMixin {
  int state = 0;

  AnimationController anim;

  initState() {
    super.initState();
    anim = AnimationController(duration: Duration(milliseconds: 300), vsync: this, upperBound: 2);
    anim.addListener(() => setState(() {}));
  }

  dispose() {
    super.dispose();
    anim.dispose();
  }

  build(context) => Card(
    color: widget.color,
    child: InkWell(
      onTap: () => setState(() {
        state = (state + 1) % 3;
        anim.animateTo(state.toDouble(), curve: Curves.ease);
      }),
      child: Container(
        width: 100 + anim.value * 50,
        height: 100 + anim.value * 50,
        child: Center(child: Text(widget.text)),
      ),
    ),
  );
}