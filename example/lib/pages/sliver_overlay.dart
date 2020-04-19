import 'dart:math';
import 'dart:ui';

import 'package:boxy/slivers.dart';
import 'package:flutter/material.dart';
import 'package:boxy_gallery/main.dart';
import 'package:tuple/tuple.dart';

class SliverOverlayPage extends StatefulWidget {
  createState() => SliverOverlayPageState();
}

final rainbow = <Color>[
  Colors.red,
  Colors.pink,
  Colors.purple,
  Colors.deepPurple,
  Colors.indigo,
  Colors.blue,
  Colors.lightBlue,
  Colors.cyan,
  Colors.teal,
  Colors.green,
  Colors.lightGreen,
  Colors.lime,
  Colors.amber,
  Colors.orange,
];

class SliverOverlayPageState extends State<SliverOverlayPage> {
  build(BuildContext context) => Scaffold(
    appBar: GalleryAppBar(
      ["Boxy Gallery", "Sliver Overlay"],
      source: "https://github.com/PixelToast/flutter-boxy/blob/master/examples/gallery/lib/pages/sliver_overlay.dart",
    ),
    backgroundColor: NiceColors.primary,
    body: Column(children: [
      Separator(),
      Expanded(child: Align(child: Container(
        margin: EdgeInsets.all(256),
        decoration: BoxDecoration(
          border: Border.all(color: NiceColors.text.withOpacity(0.1), width: 1),
        ),
        child: CustomScrollView(
          cacheExtent: 0,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.all(32),
              sliver: SliverOverlay(
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Waveform(
                      color: rainbow[i],
                      x: i * 13.0,
                      y: i * 5.0,
                      z: i * 3.0,
                    ),
                    childCount: rainbow.length,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    color: NiceColors.background,
                  ),
                ),
              ),
            ),
          ],
        ),
      ))),
      Separator(),
    ]),
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

class _WaveformState extends State<Waveform> with TickerProviderStateMixin {
  AnimationController anim;
  AnimationController anim2;
  AnimationController anim3;

  initState() {
    super.initState();
    anim = AnimationController(vsync: this)
      ..animateTo(1.0, duration: Duration(seconds: 10), curve: Curves.ease);

    anim2 = AnimationController(vsync: this)
      ..animateTo(1.0, duration: Duration(seconds: 2), curve: Curves.ease);

    anim3 = AnimationController(vsync: this)
      ..animateTo(1.0, duration: Duration(seconds: 5), curve: Curves.ease);
  }

  build(BuildContext context) => AnimatedBuilder(
    animation: anim,
    builder: (context, child) => Opacity(child: CustomPaint(
      foregroundPainter: WaveformPainter(
        color: widget.color,
        x: widget.x * anim.value,
        y: widget.y,
        z: widget.z,
        a: anim3.value,
      ),
      child: SizedBox(
        height: 64,
      ),
    ), opacity: anim2.value),
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