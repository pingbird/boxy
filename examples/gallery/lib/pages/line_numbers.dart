import 'dart:async';
import 'dart:math';

import 'package:boxy/boxy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:boxy_gallery/main.dart';
import 'package:tuple/tuple.dart';
import 'package:rxdart/rxdart.dart' as rx;

class LineNumberPage extends StatefulWidget {
  createState() => LineNumberPageState();
}

class LineNumberPageState extends State<LineNumberPage> {
  static const settingsWidth = 400.0;
  bool constrainWidth = false;
  double maxWidth = 400.0;
  double exponent = 1.0;
  var numberAlignment = Alignment.topRight;

  Widget buildSettings(Widget child) => LayoutBuilder(builder: (ctx, cns) =>
    cns.maxWidth < settingsWidth ? child : Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [ConstrainedBox(
        child: child,
        constraints: BoxConstraints.tightFor(width: settingsWidth),
      )],
    ),
  );

  Widget buildTitle(String name) => Padding(
    child: Text(
      name,
      style: TextStyle(
        color: NiceColors.text,
      ),
    ),
    padding: EdgeInsets.only(
      left: 24,
      top: 8,
    ),
  );

  build(BuildContext context) {
    Widget view = LineNumberView(
      lineCount: 15,
      buildLine: (context, i) => Padding(
        child: Text((String.fromCharCode(i + "a".codeUnitAt(0))) * (1 + i * 2)),
        padding: EdgeInsets.all(2),
      ),
      buildNumber: (context, i) => Padding(
        child: Text(
          "${exponent == 1 ? i + 1 : pow(exponent, i).round()}",
          style: TextStyle(
            color: NiceColors.text.withOpacity(0.7),
          ),
        ),
        padding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      ),
      numberBg: Container(
        color: NiceColors.primary,
      ),
      numberAlignment: numberAlignment,
    );

    var width = constrainWidth ? maxWidth : MediaQuery.of(context).size.width;
    view = AnimatedContainer(
      child: view,
      constraints: BoxConstraints(
        maxWidth: width,
        minWidth: constrainWidth ? width : 0,
      ),
      duration: Duration(milliseconds: 250),
      curve: Curves.ease,
    );

    return Scaffold(
      appBar: GalleryAppBar(
        ["Boxy Gallery", "Line Numbers"],
        source: "https://github.com/PixelToast/flutter-boxy/blob/master/examples/gallery/lib/pages/line_numbers.dart",
      ),
      backgroundColor: NiceColors.primary,
      body: Column(children: [
        Separator(),
        Expanded(child: Container(child: ListView(children: [
          Padding(padding: EdgeInsets.only(top: 64)),
          Center(child: DecoratedBox(
            child: ClipRect(child: view),
            decoration: BoxDecoration(
              border: Border.all(color: NiceColors.divider, width: 1),
            ),
          )),
          Padding(padding: EdgeInsets.only(top: 64)),
        ], physics: BouncingScrollPhysics()), color: NiceColors.background)),
        Separator(),
        buildSettings(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(padding: EdgeInsets.only(top: 8)),
          buildTitle("Constrain width"),
          Row(children: [
            Padding(padding: EdgeInsets.only(right: 4)),
            Switch(
              value: constrainWidth,
              onChanged: (b) => setState(() {
                constrainWidth = b;
              }),
            ),
            Expanded(child: Slider(
              label: "${maxWidth}px",
              value: maxWidth,
              min: 50,
              max: 600,
              onChanged: constrainWidth ? (v) => setState(() {
                maxWidth = v;
              }) : null,
            )),
          ]),
          Padding(padding: EdgeInsets.only(top: 8)),
          buildTitle("Align number"),
          Row(children: [
            Expanded(child: Slider(
              label: "x: ${numberAlignment.x.toStringAsFixed(1)}",
              value: numberAlignment.x,
              min: -1,
              max: 1,
              divisions: 10,
              onChanged: (v) => setState(() {
                numberAlignment = Alignment(v, numberAlignment.y);
              }),
            )),
            Expanded(child: Slider(
              label: "y: ${numberAlignment.y.toStringAsFixed(1)}",
              value: numberAlignment.y,
              min: -1,
              max: 1,
              divisions: 10,
              onChanged: (v) => setState(() {
                numberAlignment = Alignment(numberAlignment.x, v);
              }),
            )),
          ]),
          Padding(padding: EdgeInsets.only(top: 8)),
          buildTitle("Number exponent"),
          Slider(
            label: "${exponent.toStringAsFixed(1)}",
            value: exponent,
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (v) => setState(() {
              exponent = v;
            }),
          ),
        ])),
        Separator(),
      ]),
    );
  }
}

class LineNumberView extends StatelessWidget {
  final int lineCount;
  final IndexedWidgetBuilder buildNumber;
  final IndexedWidgetBuilder buildLine;
  final Widget lineBg;
  final Widget numberBg;
  final Alignment numberAlignment;
  final double lineAlignment;

  LineNumberView({
    @required this.lineCount,
    @required this.buildNumber,
    @required this.buildLine,
    this.lineBg,
    this.numberBg,
    this.numberAlignment = Alignment.topRight,
    this.lineAlignment = 0.0,
  });

  build(context) => Boxy(
    children: [
      if (numberBg != null) LayoutId(id: #numBg, child: numberBg),
      if (lineBg != null) LayoutId(id: #lineBg, child: lineBg),
      for (int i = 0; i < lineCount; i++) ...[
        LayoutId(id: Tuple2(#num, i), child: buildNumber(context, i)),
        buildLine(context, i),
      ],
    ],
    delegate: LineNumberDelegate(
      lineCount: lineCount,
      numberAlignment: numberAlignment,
      lineAlignment: lineAlignment,
    ),
  );
}

class LineNumberDelegate extends BoxyDelegate {
  final int lineCount;
  final Alignment numberAlignment;
  final double lineAlignment;

  LineNumberDelegate({
    @required this.lineCount,
    @required this.numberAlignment,
    @required this.lineAlignment,
  });

  @override
  layout() {
    var numWidth = 0.0;
    var numConstraints = constraints.loosen();

    for (int i = 0; i < lineCount; i++) {
      var size = getChild(Tuple2(#num, i)).layout(numConstraints);
      numWidth = max(numWidth, size.width);
    }

    var offset = 0.0;
    var lineWidth = 0.0;

    var lineConstraints = BoxConstraints(
      minWidth: max(0.0, constraints.minWidth - numWidth),
      maxWidth: max(0.0, constraints.maxWidth - numWidth),
      minHeight: 0.0,
      maxHeight: double.infinity,
    );

    for (int i = 0; i < lineCount; i++) {
      var lineChild = getChild(i);
      var numChild = getChild(Tuple2(#num, i));
      var numHeight = numChild.render.size.height;

      var size = lineChild.layout(lineConstraints.copyWith(
        minHeight: numHeight,
      ));

      var height = max(size.height, numHeight);
      var halfHeightDelta = (height - size.height) / 2.0;
      var lineOffset = offset + halfHeightDelta + lineAlignment * halfHeightDelta;

      lineChild.position(Offset(numWidth, lineOffset));
      numChild.position(numberAlignment.inscribe(
        numChild.render.size,
        Offset(0, offset) & Size(numWidth, height),
      ).topLeft);

      offset += height;
      lineWidth = max(lineWidth, size.width);
    }

    if (hasChild(#numBg)) {
      getChild(#numBg).layoutRect(Rect.fromLTWH(0, 0, numWidth, offset));
    }

    if (hasChild(#lineBg)) {
      getChild(#lineBg).layoutRect(Rect.fromLTWH(numWidth, 0, lineWidth, offset));
    }

    return Size(
      lineWidth + numWidth,
      offset,
    );
  }

  @override
  shouldRelayout(LineNumberDelegate old) =>
    old.lineCount != lineCount ||
    old.lineAlignment != lineAlignment ||
    old.numberAlignment != numberAlignment;
}