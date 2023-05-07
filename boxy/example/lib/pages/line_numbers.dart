import 'dart:math';

import 'package:boxy/boxy.dart';
import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import '../components/palette.dart';
import '../main.dart';

class LineNumberPage extends StatefulWidget {
  @override
  State createState() => LineNumberPageState();
}

class LineNumberPageState extends State<LineNumberPage> {
  static const settingsWidth = 400.0;
  bool constrainWidth = false;
  double maxWidth = 400.0;
  double exponent = 1.0;
  var numberAlignment = Alignment.topRight;

  Widget buildSettings(Widget child) {
    return LayoutBuilder(
      builder: (ctx, cns) => cns.maxWidth < settingsWidth
          ? child
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ConstrainedBox(
                  constraints:
                      const BoxConstraints.tightFor(width: settingsWidth),
                  child: child,
                )
              ],
            ),
    );
  }

  Widget buildTitle(String name) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 24,
        top: 8,
      ),
      child: Text(name),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget view = LineNumberView(
      lineCount: 15,
      buildLine: (context, i) => Padding(
        padding: const EdgeInsets.all(2),
        child: Text((String.fromCharCode(i + 'a'.codeUnitAt(0))) * (1 + i * 2)),
      ),
      buildNumber: (context, i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        child: Text(
          '${exponent == 1 ? i + 1 : pow(exponent, i).round()}',
          style: TextStyle(
            color: palette.foreground.withOpacity(0.7),
          ),
        ),
      ),
      numberBg: ColoredBox(color: palette.primary),
      numberAlignment: numberAlignment,
    );

    final width = constrainWidth ? maxWidth : MediaQuery.of(context).size.width;
    view = AnimatedContainer(
      constraints: BoxConstraints(
        maxWidth: width,
        minWidth: constrainWidth ? width : 0,
      ),
      duration: const Duration(milliseconds: 250),
      curve: Curves.ease,
      child: view,
    );

    return Scaffold(
      appBar: const GalleryAppBar(
        ['Boxy Gallery', 'Line Numbers'],
        source:
            'https://github.com/PixelToast/boxy/blob/master/boxy/example/lib/pages/line_numbers.dart',
      ),
      body: Column(children: [
        Separator(),
        Expanded(
          child: ColoredBox(
            color: palette.background,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                const Padding(padding: EdgeInsets.only(top: 64)),
                Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: palette.divider),
                    ),
                    child: ClipRect(child: view),
                  ),
                ),
                const Padding(padding: EdgeInsets.only(top: 64)),
              ],
            ),
          ),
        ),
        Separator(),
        buildSettings(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(padding: EdgeInsets.only(top: 8)),
              buildTitle('Constrain width'),
              Row(children: [
                const Padding(padding: EdgeInsets.only(right: 4)),
                Switch(
                  value: constrainWidth,
                  onChanged: (b) => setState(() {
                    constrainWidth = b;
                  }),
                ),
                Expanded(
                  child: Slider(
                    label: '${maxWidth}px',
                    value: maxWidth,
                    min: 50,
                    max: 600,
                    onChanged: constrainWidth
                        ? (v) => setState(() {
                              maxWidth = v;
                            })
                        : null,
                  ),
                ),
              ]),
              const Padding(padding: EdgeInsets.only(top: 8)),
              buildTitle('Align number'),
              Row(children: [
                Expanded(
                  child: Slider(
                    label: 'x: ${numberAlignment.x.toStringAsFixed(1)}',
                    value: numberAlignment.x,
                    min: -1,
                    divisions: 10,
                    onChanged: (v) => setState(() {
                      numberAlignment = Alignment(v, numberAlignment.y);
                    }),
                  ),
                ),
                Expanded(
                  child: Slider(
                    label: 'y: ${numberAlignment.y.toStringAsFixed(1)}',
                    value: numberAlignment.y,
                    min: -1,
                    divisions: 10,
                    onChanged: (v) => setState(() {
                      numberAlignment = Alignment(numberAlignment.x, v);
                    }),
                  ),
                ),
              ]),
              const Padding(padding: EdgeInsets.only(top: 8)),
              buildTitle('Number exponent'),
              Slider(
                label: exponent.toStringAsFixed(1),
                value: exponent,
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (v) => setState(() {
                  exponent = v;
                }),
              ),
            ],
          ),
        ),
        Separator(),
      ]),
    );
  }
}

class LineNumberView extends StatelessWidget {
  final int lineCount;
  final IndexedWidgetBuilder buildNumber;
  final IndexedWidgetBuilder buildLine;
  final Widget? lineBg;
  final Widget? numberBg;
  final Alignment numberAlignment;
  final double lineAlignment;

  const LineNumberView({
    required this.lineCount,
    required this.buildNumber,
    required this.buildLine,
    this.lineBg,
    this.numberBg,
    this.numberAlignment = Alignment.topRight,
    this.lineAlignment = 0.0,
  });

  @override
  Widget build(context) {
    return CustomBoxy(
      delegate: LineNumberDelegate(
        lineCount: lineCount,
        numberAlignment: numberAlignment,
        lineAlignment: lineAlignment,
      ),
      children: [
        if (numberBg != null) BoxyId(id: #numBg, child: numberBg!),
        if (lineBg != null) BoxyId(id: #lineBg, child: lineBg!),
        for (int i = 0; i < lineCount; i++) ...[
          BoxyId(id: Tuple2(#num, i), child: buildNumber(context, i)),
          buildLine(context, i),
        ],
      ],
    );
  }
}

class LineNumberDelegate extends BoxyDelegate {
  final int lineCount;
  final Alignment numberAlignment;
  final double lineAlignment;

  LineNumberDelegate({
    required this.lineCount,
    required this.numberAlignment,
    required this.lineAlignment,
  });

  @override
  Size layout() {
    var numWidth = 0.0;
    final numConstraints = constraints.loosen();

    for (int i = 0; i < lineCount; i++) {
      final size = getChild(Tuple2(#num, i)).layout(numConstraints);
      numWidth = max(numWidth, size.width);
    }

    var offset = 0.0;
    var lineWidth = 0.0;

    final lineConstraints = BoxConstraints(
      minWidth: max(0.0, constraints.minWidth - numWidth),
      maxWidth: max(0.0, constraints.maxWidth - numWidth),
    );

    for (int i = 0; i < lineCount; i++) {
      final lineChild = getChild(i);
      final numChild = getChild(Tuple2(#num, i));
      final numHeight = numChild.render.size.height;

      final size = lineChild.layout(lineConstraints.copyWith(
        minHeight: numHeight,
      ));

      final height = max(size.height, numHeight);
      final halfHeightDelta = (height - size.height) / 2.0;
      final lineOffset =
          offset + halfHeightDelta + lineAlignment * halfHeightDelta;

      lineChild.position(Offset(numWidth, lineOffset));
      numChild.position(numberAlignment
          .inscribe(
            numChild.render.size,
            Offset(0, offset) & Size(numWidth, height),
          )
          .topLeft);

      offset += height;
      lineWidth = max(lineWidth, size.width);
    }

    if (hasChild(#numBg)) {
      getChild(#numBg).layoutRect(Rect.fromLTWH(0, 0, numWidth, offset));
    }

    if (hasChild(#lineBg)) {
      getChild(#lineBg)
          .layoutRect(Rect.fromLTWH(numWidth, 0, lineWidth, offset));
    }

    return Size(
      lineWidth + numWidth,
      offset,
    );
  }

  @override
  bool shouldRelayout(LineNumberDelegate oldDelegate) =>
      oldDelegate.lineCount != lineCount ||
      oldDelegate.lineAlignment != lineAlignment ||
      oldDelegate.numberAlignment != numberAlignment;
}
