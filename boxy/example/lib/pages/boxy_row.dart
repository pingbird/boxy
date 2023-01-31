import 'package:boxy/flex.dart';
import 'package:flutter/material.dart';

import '../main.dart';

class BoxyRowPage extends StatefulWidget {
  @override
  State createState() => BoxyRowPageState();
}

final rainbow = <MaterialColor>[
  Colors.red,
  Colors.deepPurple,
  Colors.lightBlue,
  Colors.green,
  Colors.amber,
];

const shades = [400, 500, 600, 700, 800, 900];

Color lerpGradient(List<Color> colors, List<double> stops, double t) {
  for (var s = 0; s < stops.length - 1; s++) {
    final leftStop = stops[s], rightStop = stops[s + 1];
    final leftColor = colors[s], rightColor = colors[s + 1];
    if (t <= leftStop) {
      return leftColor;
    } else if (t < rightStop) {
      final sectionT = (t - leftStop) / (rightStop - leftStop);
      return Color.lerp(leftColor, rightColor, sectionT)!;
    }
  }
  return colors.last;
}

Color getRainbowColor(double delta) {
  return lerpGradient(
    rainbow,
    [
      for (int i = 0; i < rainbow.length; i++) i / (rainbow.length - 1),
    ],
    delta,
  );
}

class BoxyRowPageState extends State<BoxyRowPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GalleryAppBar(
        ['Boxy Gallery', 'BoxyRow'],
        source:
            'https://github.com/PixelToast/boxy/blob/master/boxy/example/lib/pages/boxy_row.dart',
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Separator(),
        Expanded(
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: LabelBox(
              label: 'BoxyRow',
              child: BoxyRow(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ChildCard(text: 'Child 1', color: Colors.red),
                  Dominant(
                    child: LabelBox(
                      label: 'Dominant',
                      child: LabelBox(
                        label: 'Column',
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            ChildCard(
                                text: 'Child 2', color: Colors.lightGreen),
                            ChildCard(text: 'Child 3', color: Colors.blue),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Separator(),
      ]),
    );
  }
}

class ChildCard extends StatefulWidget {
  final String text;
  final Color color;

  const ChildCard({
    required this.text,
    required this.color,
  });

  @override
  ChildCardState createState() => ChildCardState();
}

class ChildCardState extends State<ChildCard>
    with SingleTickerProviderStateMixin {
  int state = 0;

  late AnimationController anim;

  @override
  void initState() {
    super.initState();
    anim = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
        upperBound: 2);
    anim.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    super.dispose();
    anim.dispose();
  }

  @override
  Card build(context) {
    return Card(
      color: widget.color,
      child: InkWell(
        onTap: () => setState(() {
          state = (state + 1) % 2;
          anim.animateTo(state.toDouble(), curve: Curves.ease);
        }),
        child: SizedBox(
          width: 80 + anim.value * 45,
          height: 80 + anim.value * 45,
          child: Center(child: Text(widget.text)),
        ),
      ),
    );
  }
}

class LabelBox extends StatelessWidget {
  final String label;
  final Widget child;

  const LabelBox({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.all(7),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: Align(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(label),
            ),
          ),
        ),
      ],
    );
  }
}
