import 'dart:math';

import 'package:boxy/boxy.dart';
import 'package:flutter/material.dart';
import 'package:boxy_gallery/main.dart';
import 'package:tuple/tuple.dart';

class TreeViewPage extends StatefulWidget {
  createState() => TreeViewPageState();
}

class TreeViewPageState extends State<TreeViewPage> {
  var style = TreeStyle();
  static const settingsWidth = 400.0;

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

  build(BuildContext context) => Scaffold(
    appBar: GalleryAppBar(
      ["Boxy Gallery", "Tree View"],
      source: "https://github.com/PixelToast/flutter-boxy/blob/master/examples/gallery/lib/pages/tree_view.dart",
    ),
    backgroundColor: NiceColors.primary,
    body: Column(children: [
      Separator(),
      Expanded(child: Container(child: ListView(children: [
        Center(child: Container(
          child: TreeView(
            style: style,
            root: TreeBranch(TreeTile(text: "RawObject"), [
              TreeLeaf(TreeTile(text: "RawClass")),
              TreeBranch(TreeTile(text: "RawError"), [
                TreeLeaf(TreeTile(text: "RawApiError")),
                TreeLeaf(TreeTile(text: "RawUnwindError")),
              ]),
              TreeBranch(TreeTile(text: "RawInstance"), [
                TreeBranch(TreeTile(text: "RawNumber"), [
                  TreeBranch(TreeTile(text: "RawInteger"), [
                    TreeLeaf(TreeTile(text: "RawSmi")),
                    TreeLeaf(TreeTile(text: "RawMint")),
                  ]),
                  TreeLeaf(TreeTile(text: "RawDouble")),
                ]),
                TreeBranch(TreeTile(text: "RawTypedDataBase"), [
                  TreeLeaf(TreeTile(text: "RawTypedData")),
                  TreeLeaf(TreeTile(text: "RawTypedDataView")),
                  TreeLeaf(TreeTile(text: "RawExternalTypedData")),
                ]),
              ]),
            ]),
          ),
          padding: EdgeInsets.symmetric(vertical: 64, horizontal: 8),
        )),
      ], physics: BouncingScrollPhysics()), color: NiceColors.background)),
      Separator(),
      buildSettings(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(padding: EdgeInsets.only(top: 8)),
        buildTitle("Line thickness"),
        Slider(
          label: "${style.lineThickness.round()}px",
          value: style.lineThickness,
          min: 1,
          max: 10,
          onChanged: (v) => setState(() {
            style = style.copyWith(lineWidth: v);
          }),
          divisions: 9,
        ),
        buildTitle("Line spacing"),
        Slider(
          label: "${style.lineSpacing.round()}px",
          value: style.lineSpacing,
          min: 1,
          max: 100,
          onChanged: (v) => setState(() {
            style = style.copyWith(lineSpacing: v);
          }),
          divisions: 100,
        ),
        buildTitle("Line border radius"),
        Slider(
          label: "${style.lineRadius.round()}px",
          value: style.lineRadius,
          min: 0,
          max: 25,
          onChanged: (v) => setState(() {
            style = style.copyWith(lineRadius: v);
          }),
          divisions: 26,
        ),
        buildTitle("Vertical spacing"),
        Slider(
          label: "${style.spacing.round()}px",
          value: style.spacing,
          min: 0,
          max: 100,
          onChanged: (v) => setState(() {
            style = style.copyWith(spacing: v);
          }),
          divisions: 101,
        ),
      ])),
      Separator(),
    ]),
  );
}

class TreeTile extends StatefulWidget {
  final String text;

  TreeTile({
    @required this.text,
  });

  createState() => TreeTileState();
}

class TreeTileState extends State<TreeTile> with SingleTickerProviderStateMixin {
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

  build(context) => ClipRRect(child: AnimatedContainer(
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() {
          state = (state + 1) % 3;
          anim.animateTo(state.toDouble(), curve: Curves.ease);
        }),
        child: Padding(child: Text(
          widget.text,
          style: TextStyle(
            fontSize: 16 * anim.value + 16,
            color: NiceColors.text,
          ),
        ), padding: EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 32,
        )),
      ),
    ),
    decoration: BoxDecoration(
      color: NiceColors.primary,
    ),
    duration: Duration(milliseconds: 250),
  ), borderRadius: BorderRadius.circular(8));
}

class TreeStyle {
  final double lineThickness;
  final Color lineColor;
  final double spacing;
  final double lineSpacing;
  final double lineRadius;

  const TreeStyle({
    this.lineThickness = 2,
    this.lineColor = Colors.grey,
    this.spacing = 16,
    this.lineSpacing = 16,
    this.lineRadius = 8,
  });

  TreeStyle copyWith({
    double lineWidth,
    Color lineColor,
    double spacing,
    double lineSpacing,
    double lineRadius,
  }) => TreeStyle(
    lineThickness: lineWidth ?? this.lineThickness,
    lineColor: lineColor ?? this.lineColor,
    spacing: spacing ?? this.spacing,
    lineSpacing: lineSpacing ?? this.lineSpacing,
    lineRadius: lineRadius ?? this.lineRadius,
  );

  bool sameLayout(TreeStyle other) =>
    other.lineSpacing == lineSpacing &&
    other.spacing == spacing;

  bool samePaint(TreeStyle other) =>
    other.lineThickness == lineThickness &&
    other.lineColor == lineColor &&
    other.lineRadius == lineRadius;
}

class TreeView extends StatelessWidget {
  final TreeNode root;
  final TreeStyle style;

  TreeView({
    @required this.root,
    this.style = const TreeStyle(),
  });

  build(context) {
    var children = <Widget>[];
    root.addTo(children);

    return CustomBoxy(
      children: children,
      delegate: TreeViewDelegate(
        root: root,
        style: style,
      ),
    );
  }
}

abstract class TreeNode {
  void addTo(List<Widget> widgets);
  bool sameLayout(TreeNode other);
}

class TreeBranch extends TreeNode {
  final Widget parent;
  final List<TreeNode> children;

  TreeBranch(this.parent, this.children) :
    assert(parent != null),
    assert(children != null),
    assert(children.isNotEmpty);

  addTo(widgets) {
    widgets.add(parent);
    for (var child in children) {
      child.addTo(widgets);
    }
  }
  
  sameLayout(other) {
    if (other is TreeBranch) {
      if (other.children.length != children.length) return false;
      for (var i = 0; i < children.length; i++) {
        if (!other.children[i].sameLayout(children[i])) return false;
      }
      return true;
    }
    return false;
  }
}

class TreeLeaf extends TreeNode {
  final Widget child;

  TreeLeaf(this.child);

  addTo(widgets) {
    widgets.add(child);
  }

  sameLayout(other) => true;
}

class TreeViewDelegate extends BoxyDelegate {
  final TreeNode root;
  final TreeStyle style;

  TreeViewDelegate({
    @required this.root,
    @required this.style,
  });

  @override
  shouldRelayout(TreeViewDelegate other) =>
    !other.root.sameLayout(root) ||
    !other.style.sameLayout(style);

  @override
  shouldRepaint(TreeViewDelegate other) =>
    !other.style.samePaint(style);

  @override
  layout() {
    int i = 0;
    // size, offset of parent, position
    Tuple3<Size, double, void Function(Offset)> layoutNode(
      TreeNode node, BoxConstraints constraints
    ) {
      if (node is TreeLeaf) {
        var child = children[i++];
        child.layout(constraints);
        return Tuple3(
          child.render.size,
          child.render.size.height / 2,
          child.position
        );
      } else if (node is TreeBranch) {
        var parent = children[i++];
        var pSize = parent.layout(constraints.loosen());
        var left = pSize.width + style.lineSpacing;
        if (node.children.length != 1) {
          left += style.lineSpacing;
        }
        var cConstraints = constraints.deflate(EdgeInsets.only(left: left));
        var branches = <void Function(Offset)>[];
        var cSize = Size.zero;

        double topY;
        double btmY;

        for (var i = 0; i < node.children.length; i++) {
          if (i != 0) cSize += Offset(0, style.spacing);
          var ch = layoutNode(node.children[i], cConstraints);

          var y = cSize.height + ch.item2;
          if (i == 0) topY = y;
          if (i == node.children.length - 1) btmY = y;

          var offset = Offset(left, cSize.height);
          branches.add((o) => ch.item3(o + offset));
          cSize = Size(
            max(cSize.width, ch.item1.width),
            cSize.height + ch.item1.height,
          );
        }

        var midY = (topY + btmY) / 2;

        double pOffset;
        double cOffset;

        var pHalfHeight = pSize.height / 2;

        if (pSize.height > cSize.height) {
          // Center branches to parent
          cOffset = pHalfHeight - midY;
          var pad = max(0.0, -cOffset);
          pOffset = pad;
          cOffset += pad;
        } else {
          // Center parent to branches
          pOffset = midY - pHalfHeight;
          var pad = max(0.0, -pOffset);
          cOffset = pad;
          pOffset += pad;
        }

        return Tuple3(
          Size(cSize.width + left, max(pOffset + pSize.height, cOffset + cSize.height)),
          pOffset + pSize.height / 2,
          (o) {
            parent.position(o + Offset(0, pOffset));
            var bo = o + Offset(0, cOffset);
            for (var b in branches) b(bo);
          },
        );
      } else { // Unreachable
        assert(false);
        return null;
      }
    }

    var ch = layoutNode(root, constraints);
    ch.item3(Offset.zero);
    return ch.item1;
  }

  @override
  void paint() {
    var linePaint = Paint()
      ..strokeWidth = style.lineThickness
      ..color = style.lineColor
      ..style = PaintingStyle.stroke;

    int childIndex = 0;

    void paintNode(TreeNode node) {
      if (node is TreeBranch) {
        var parent = children[childIndex++].rect.centerRight;
        canvas.drawLine(
          parent, parent + Offset(style.lineSpacing, 0), linePaint,
        );
        var x = parent.dx;

        double start;
        double end;
        for (int i = 0; i < node.children.length; i++) {
          var left = children[childIndex].rect.centerLeft;
          end = left.dy;
          start ??= end;
          if (i != 0 && i != node.children.length - 1) {
            canvas.drawLine(
              left - Offset(style.lineSpacing, 0), left, linePaint
            );
          }
          paintNode(node.children[i]);
        }

        if (start != end) {
          var diameter = style.lineRadius * 2;
          canvas.drawPath(
            Path()
              ..moveTo(x + style.lineSpacing * 2, start)
              ..addArc(Rect.fromLTWH(
                x + style.lineSpacing, start, diameter, diameter
              ), pi / -2, pi / -2)
              ..arcTo(Rect.fromLTWH(
                x + style.lineSpacing, end - diameter, diameter, diameter,
              ), pi, pi / -2, false)
              ..lineTo(x + style.lineSpacing * 2, end),
            linePaint,
          );
        }
      } else {
        childIndex++;
      }
    }

    paintNode(root);
  }
}