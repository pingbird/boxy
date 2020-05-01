import 'dart:math';

import 'package:boxy/boxy.dart';
import 'package:boxy/padding.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:boxy_gallery/main.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:tuple/tuple.dart';

class FlexDominantPage extends StatefulWidget {
  createState() => FlexDominantPageState();
}

class FlexDominantPageState extends State<FlexDominantPage> {
  build(BuildContext context) => Scaffold(
    appBar: GalleryAppBar(
      ["Boxy Gallery", "Flex Dominant"],
      source: "https://github.com/PixelToast/flutter-boxy/blob/master/examples/gallery/lib/pages/flex_dominant.dart",
    ),
    backgroundColor: NiceColors.primary,
    body: Column(children: [
      Separator(),
      Expanded(child: Container(child: ListView(children: [
        Padding(padding: EdgeInsets.only(top: 64)),

        Padding(padding: EdgeInsets.only(top: 64)),
      ], physics: BouncingScrollPhysics()), color: NiceColors.background)),
      Separator(),
    ]),
  );
}

class ExpandButton extends StatefulWidget {
  final bool expanded;
  final VoidCallback onPressed;

  ExpandButton({
    @required this.expanded,
    @required this.onPressed,
  });

  createState() => _ExpandButtonState();
}

class _ExpandButtonState extends State<ExpandButton> with SingleTickerProviderStateMixin {
  AnimationController controller;

  @override
  initState() {
    super.initState();
    controller = AnimationController(vsync: this, value: widget.expanded ? 1 : 0);
    controller.addListener(() => setState(() {}));
  }

  @override
  didUpdateWidget(old) {
    super.didUpdateWidget(old);
    controller.animateTo(
      widget.expanded ? 1 : 0,
      duration: Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }

  @override
  dispose() {
    super.dispose();
    controller.dispose();
  }

  static const size = 42.0;

  build(context) => SizedBox(child: Material(
    borderRadius: BorderRadius.circular(size / 2),
    color: Colors.transparent,
    child: InkWell(child: Center(
      child: Transform.rotate(child: Icon(
        Icons.arrow_drop_down,
        size: 24,
        color: NiceColors.text,
      ), angle: pi * controller.value),
    ),
      onTap: widget.onPressed,
      hoverColor: Colors.blueGrey.withOpacity(0.1),
      focusColor: Colors.blueGrey.withOpacity(0.2),
      highlightColor: Colors.blueGrey.withOpacity(0.3),
      splashColor: Colors.blueGrey.shade200.withOpacity(0.3),
    ),
  ), width: size, height: size);
}