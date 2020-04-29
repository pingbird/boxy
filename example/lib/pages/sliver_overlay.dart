import 'dart:math';
import 'dart:ui';

import 'package:boxy/slivers.dart';
import 'package:flutter/material.dart';
import 'package:boxy_gallery/main.dart';
import 'package:tuple/tuple.dart';
import 'package:boxy/utils.dart';

class SliverOverlayPage extends StatefulWidget {
  createState() => SliverOverlayPageState();
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

class SliverOverlayPageState extends State<SliverOverlayPage> {
  var direction = AxisDirection.down;

  void setDir(AxisDirection dir) {
    direction = dir;
    setState(() {});
  }

  build(BuildContext context) => Scaffold(
    appBar: GalleryAppBar(
      ["Boxy Gallery", "Sliver Overlay"],
      source: "https://github.com/PixelToast/flutter-boxy/blob/master/examples/gallery/lib/pages/sliver_overlay.dart",
    ),
    backgroundColor: NiceColors.primary,
    body: Column(children: [
      Separator(),
      Expanded(child: Align(child: Container(
        width: 400,
        height: 500,
        child: Column(children: [
          Flexible(child: SliverOverlayFrame(direction)),
          Padding(child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            RaisedButton(
              color: NiceColors.primary,
              onPressed: () => setDir(AxisDirection.down),
              child: Icon(Icons.keyboard_arrow_down),
            ),
            RaisedButton(
              color: NiceColors.primary,
              onPressed: () => setDir(AxisDirection.right),
              child: Icon(Icons.keyboard_arrow_right),
            ),
            RaisedButton(
              color: NiceColors.primary,
              onPressed: () => setDir(AxisDirection.up),
              child: Icon(Icons.keyboard_arrow_up),
            ),
            RaisedButton(
              color: NiceColors.primary,
              onPressed: () => setDir(AxisDirection.left),
              child: Icon(Icons.keyboard_arrow_left),
            ),
          ]), padding: EdgeInsets.only(
            top: 64,
          )),
        ]),
      ))),
      Separator(),
    ]),
  );
}

class SliverOverlayFrame extends StatelessWidget {
  final AxisDirection direction;

  SliverOverlayFrame(this.direction);

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      border: Border.all(color: NiceColors.text.withOpacity(0.1), width: 1),
    ),
    child: CustomScrollView(
      scrollDirection: direction.axis,
      reverse: direction.isReverse,
      cacheExtent: 32,
      slivers: [
        SliverAppBar(
          expandedHeight: 150.0,
          title: Text("App Bar"),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(color: Colors.blue),
          ),
        ),
        for (int s = 0; s < rainbow.length; s++) SliverOverlay(
          bufferExtent: 32,
          sliver: SliverOverlay(
            bufferExtent: 32 - 4.0,
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => i >= shades.length ? null : ColorContainer(
                  color: rainbow[s][shades[i]],
                  size: 5 + s * 25.0,
                ),
              ),
            ),
            clipper: ShapeBorderClipper(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              )
            ),
          ),
          //padding: EdgeInsets.all(16),
          background: Card(
            color: Colors.transparent,
          ),
          padding: EdgeInsets.all(4),
          margin: EdgeInsetsAxisUtil.direction(direction,
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

class ColorContainer extends StatefulWidget {
  final Color color;
  final double size;

  ColorContainer({this.color, this.size});

  createState() => _ColorContainerState();
}

class _ColorContainerState extends State<ColorContainer> with SingleTickerProviderStateMixin {
  AnimationController anim;

  initState() {
    super.initState();
    anim = AnimationController(vsync: this)
      ..animateTo(1.0, duration: Duration(seconds: 1), curve: Curves.easeOutSine);
  }

  dispose() {
    anim.dispose();
    super.dispose();
  }

  build(context) => AnimatedBuilder(
    animation: anim,
    builder: (context, child) => Container(
      color: widget.color.withOpacity(anim.value),
      width: widget.size,
      height: widget.size,
    ),
  );
}

class Waveform extends StatefulWidget {
  final Color color;
  final double x;
  final double y;
  final double z;

  Waveform({
    @required this.color,
    @required this.x,
    @required this.y,
    @required this.z,
  });

  _WaveformState createState() => _WaveformState();
}

class _WaveformState extends State<Waveform> with SingleTickerProviderStateMixin {
  AnimationController anim;

  initState() {
    super.initState();
    anim = AnimationController(vsync: this)
      ..animateTo(1.0, duration: Duration(seconds: 3), curve: Curves.easeOutSine);
  }

  @override
  dispose() {
    anim.dispose();
    super.dispose();
  }

  build(BuildContext context) => AnimatedBuilder(
    animation: anim,
    builder: (context, child) => Opacity(child: CustomPaint(
      foregroundPainter: WaveformPainter(
        color: widget.color,
        x: widget.x,
        y: widget.y,
        z: widget.z,
        a: anim.value,
      ),
      child: SizedBox(
        height: 64,
      ),
    ), opacity: anim.value),
  );
}


class WaveformPainter extends CustomPainter {
  final Color color;
  final double x;
  final double y;
  final double z;
  final double a;

  WaveformPainter({
    @required this.color,
    @required this.x,
    @required this.y,
    @required this.z,
    @required this.a,
  });

  paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(-size.width / 2, size.height / 2);
    var path = Path();
    for (int i = 0; i <= 500; i++) {
      var dt = (i / 500) + 0.5;
      (i == 0 ? path.moveTo : path.lineTo)(
        dt * size.width,
        (sin(dt * x) + sin(dt * y) * sin(dt * z)) * (size.height / 6) * a,
      );
    }
    canvas.drawPath(path, Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
    );
    canvas.restore();
  }

  shouldRepaint(WaveformPainter old) =>
    old.color != color || old.x != x || old.y != y || old.y != z || old.a != a;
}