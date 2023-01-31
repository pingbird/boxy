import 'dart:math';

import 'package:boxy/slivers.dart';
import 'package:boxy/utils.dart';
import 'package:flutter/material.dart';

import '../components/palette.dart';
import '../main.dart';

class SliverContainerPage extends StatefulWidget {
  @override
  State createState() => SliverContainerPageState();
}

final rainbow = <MaterialColor>[
  Colors.red,
  Colors.pink,
  Colors.deepPurple,
  Colors.lightBlue,
  Colors.green,
  Colors.amber,
  Colors.orange,
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

class SliverContainerPageState extends State<SliverContainerPage> {
  var direction = AxisDirection.down;

  void setDir(AxisDirection dir) {
    direction = dir;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final buttonTheme = ElevatedButton.styleFrom(
      backgroundColor: palette.primary,
    );

    return Scaffold(
      appBar: const GalleryAppBar(
        ['Boxy Gallery', 'Sliver Container'],
        source:
            'https://github.com/PixelToast/boxy/blob/master/boxy/example/lib/pages/sliver_container.dart',
      ),
      body: Column(
        children: [
          Separator(),
          Expanded(
            child: Align(
              child: SizedBox(
                width: 400,
                height: 500,
                child: Column(
                  children: [
                    Flexible(child: SliverOverlayFrame(direction)),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 64,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            style: buttonTheme,
                            onPressed: () => setDir(AxisDirection.down),
                            child: const Icon(Icons.keyboard_arrow_down),
                          ),
                          ElevatedButton(
                            style: buttonTheme,
                            onPressed: () => setDir(AxisDirection.right),
                            child: const Icon(Icons.keyboard_arrow_right),
                          ),
                          ElevatedButton(
                            style: buttonTheme,
                            onPressed: () => setDir(AxisDirection.up),
                            child: const Icon(Icons.keyboard_arrow_up),
                          ),
                          ElevatedButton(
                            style: buttonTheme,
                            onPressed: () => setDir(AxisDirection.left),
                            child: const Icon(Icons.keyboard_arrow_left),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Separator(),
        ],
      ),
    );
  }
}

class SliverOverlayFrame extends StatelessWidget {
  final AxisDirection direction;

  const SliverOverlayFrame(this.direction);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: palette.foreground.withOpacity(0.1),
        ),
      ),
      child: CustomScrollView(
        scrollDirection: direction.axis,
        reverse: direction.isReverse,
        cacheExtent: 32,
        slivers: [
          SliverAppBar(
            expandedHeight: 150.0,
            title: const Text('App Bar'),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(color: Colors.red[400]),
            ),
          ),
          for (int s = 0; s < rainbow.length; s++)
            SliverCard(
              clipBehavior: Clip.antiAlias,
              color: Colors.white,
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Container(
                      width: direction.axis == Axis.horizontal
                          ? 16
                          : double.infinity,
                      height: direction.axis == Axis.horizontal
                          ? double.infinity
                          : 16,
                      color: rainbow[s][shades[0]],
                    ),
                    for (var i = 0; i <= s && i < shades.length; i++)
                      ColorTile(
                          color: rainbow[s][shades[i]]!, direction: direction),
                  ],
                ),
              ),
              margin: EdgeInsetsAxisUtil.direction(
                direction,
                mainBegin: s != 0 ? 0.0 : 16.0,
                mainEnd: 16.0,
                crossBegin: 16.0,
                crossEnd: 16.0,
              ),
            ),
        ],
      ),
    );
  }
}

class ColorTile extends StatefulWidget {
  final Color color;
  final AxisDirection direction;

  const ColorTile({required this.color, required this.direction});

  @override
  State<ColorTile> createState() => _ColorTileState();
}

class _ColorTileState extends State<ColorTile>
    with SingleTickerProviderStateMixin {
  late AnimationController anim;
  late double descWidth;

  @override
  void initState() {
    descWidth = Random().nextInt(100).toDouble();
    super.initState();
    anim = AnimationController(vsync: this)
      ..animateTo(1.0,
          duration: const Duration(seconds: 1), curve: Curves.ease);
  }

  @override
  void dispose() {
    anim.dispose();
    super.dispose();
  }

  @override
  Widget build(context) {
    return RotatedBox(
      quarterTurns: widget.direction.reversed.index,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: AnimatedBuilder(
          animation: anim,
          builder: (context, child) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Align(
                    child: Container(
                      width: 30 + 30 * anim.value,
                      height: 30 + 30 * anim.value,
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(anim.value),
                        borderRadius:
                            BorderRadius.circular(16 - 12 * anim.value),
                      ),
                    ),
                  ),
                ),
                const Padding(padding: EdgeInsets.only(right: 8)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(anim.value * 0.54),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      height: 15,
                      width: 90,
                      margin: const EdgeInsets.only(top: 8, bottom: 8),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(anim.value * 0.38),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      height: 15,
                      width: (descWidth * anim.value) + 50,
                      margin: const EdgeInsets.only(top: 8, bottom: 8),
                    ),
                  ],
                )
              ],
            );
          },
        ),
      ),
    );
  }
}
