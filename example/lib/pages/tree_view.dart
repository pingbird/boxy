import 'dart:math';

import 'package:boxy/boxy.dart';
import 'package:boxy_gallery/main.dart';
import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

class TreeViewPage extends StatefulWidget {
  createState() => TreeViewPageState();
}

class TreeViewPageState extends State<TreeViewPage> {
  var style = const TreeStyle();
  static const settingsWidth = 400.0;

  Widget buildSettings(Widget child) => LayoutBuilder(
        builder: (ctx, cns) => cns.maxWidth < settingsWidth
            ? child
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ConstrainedBox(
                    child: child,
                    constraints:
                        const BoxConstraints.tightFor(width: settingsWidth),
                  )
                ],
              ),
      );

  Widget buildTitle(String name) => Padding(
        child: Text(
          name,
          style: const TextStyle(
            color: NiceColors.text,
          ),
        ),
        padding: const EdgeInsets.only(
          left: 24,
          top: 8,
        ),
      );

  build(BuildContext context) => Scaffold(
        appBar: const GalleryAppBar(
          ['Boxy Gallery', 'Tree View'],
          source:
              'https://github.com/PixelToast/flutter-boxy/blob/master/example/lib/pages/tree_view.dart',
        ),
        backgroundColor: NiceColors.primary,
        body: Column(children: [
          Separator(),
          Expanded(
              child: Container(
                  child: ListView(children: [
                    Center(
                        child: Container(
                      child: TreeView(
                        style: style,
                        root: TreeBranch(const TreeTile(text: 'RawObject'), [
                          TreeLeaf(const TreeTile(text: 'RawClass')),
                          TreeBranch(const TreeTile(text: 'RawError'), [
                            TreeLeaf(const TreeTile(text: 'RawApiError')),
                            TreeLeaf(const TreeTile(text: 'RawUnwindError')),
                          ]),
                          TreeBranch(const TreeTile(text: 'RawInstance'), [
                            TreeBranch(const TreeTile(text: 'RawNumber'), [
                              TreeBranch(const TreeTile(text: 'RawInteger'), [
                                TreeLeaf(const TreeTile(text: 'RawSmi')),
                                TreeLeaf(const TreeTile(text: 'RawMint')),
                              ]),
                              TreeLeaf(const TreeTile(text: 'RawDouble')),
                            ]),
                            TreeBranch(
                                const TreeTile(text: 'RawTypedDataBase'), [
                              TreeLeaf(const TreeTile(text: 'RawTypedData')),
                              TreeLeaf(
                                  const TreeTile(text: 'RawTypedDataView')),
                              TreeLeaf(
                                  const TreeTile(text: 'RawExternalTypedData')),
                            ]),
                          ]),
                        ]),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 64, horizontal: 8),
                    )),
                  ], physics: const BouncingScrollPhysics()),
                  color: NiceColors.background)),
          Separator(),
          buildSettings(
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Padding(padding: EdgeInsets.only(top: 8)),
            buildTitle('Line thickness'),
            Slider(
              label: '${style.lineThickness.round()}px',
              value: style.lineThickness,
              min: 1,
              max: 10,
              onChanged: (v) => setState(() {
                style = style.copyWith(lineThickness: v);
              }),
              divisions: 9,
            ),
            buildTitle('Line spacing'),
            Slider(
              label: '${style.lineSpacing.round()}px',
              value: style.lineSpacing,
              min: 1,
              max: 100,
              onChanged: (v) => setState(() {
                style = style.copyWith(lineSpacing: v);
              }),
              divisions: 100,
            ),
            buildTitle('Line border radius'),
            Slider(
              label: '${style.lineRadius.round()}px',
              value: style.lineRadius,
              min: 0,
              max: 25,
              onChanged: (v) => setState(() {
                style = style.copyWith(lineRadius: v);
              }),
              divisions: 26,
            ),
            buildTitle('Vertical spacing'),
            Slider(
              label: '${style.spacing.round()}px',
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

  const TreeTile({
    required this.text,
  });

  createState() => TreeTileState();
}

class TreeTileState extends State<TreeTile>
    with SingleTickerProviderStateMixin {
  int state = 0;

  late AnimationController anim;

  initState() {
    super.initState();
    anim = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
        upperBound: 2);
    anim.addListener(() => setState(() {}));
  }

  dispose() {
    super.dispose();
    anim.dispose();
  }

  build(context) => ClipRRect(
      child: AnimatedContainer(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() {
              state = (state + 1) % 3;
              anim.animateTo(state.toDouble(), curve: Curves.ease);
            }),
            child: Padding(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: 16 * anim.value + 16,
                    color: NiceColors.text,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 32,
                )),
          ),
        ),
        decoration: const BoxDecoration(
          color: NiceColors.primary,
        ),
        duration: const Duration(milliseconds: 250),
      ),
      borderRadius: BorderRadius.circular(8));
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
    double? lineThickness,
    Color? lineColor,
    double? spacing,
    double? lineSpacing,
    double? lineRadius,
  }) =>
      TreeStyle(
        lineThickness: lineThickness ?? this.lineThickness,
        lineColor: lineColor ?? this.lineColor,
        spacing: spacing ?? this.spacing,
        lineSpacing: lineSpacing ?? this.lineSpacing,
        lineRadius: lineRadius ?? this.lineRadius,
      );

  bool sameLayout(TreeStyle other) =>
      other.lineSpacing == lineSpacing && other.spacing == spacing;

  bool samePaint(TreeStyle other) =>
      other.lineThickness == lineThickness &&
      other.lineColor == lineColor &&
      other.lineRadius == lineRadius;
}

class TreeView extends StatelessWidget {
  final TreeNode root;
  final TreeStyle style;

  const TreeView({
    required this.root,
    this.style = const TreeStyle(),
  });

  build(context) {
    final children = <Widget>[];
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

  TreeBranch(this.parent, this.children) : assert(children.isNotEmpty);

  addTo(widgets) {
    widgets.add(parent);
    for (final child in children) {
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
    required this.root,
    required this.style,
  });

  @override
  shouldRelayout(TreeViewDelegate other) =>
      !other.root.sameLayout(root) || !other.style.sameLayout(style);

  @override
  shouldRepaint(TreeViewDelegate other) => !other.style.samePaint(style);

  @override
  layout() {
    int i = 0;
    // size, offset of parent, position
    Tuple3<Size, double, void Function(Offset)>? layoutNode(
        TreeNode node, BoxConstraints constraints) {
      if (node is TreeLeaf) {
        final child = children[i++];
        child.layout(constraints);
        return Tuple3(
            child.render.size, child.render.size.height / 2, child.position);
      } else if (node is TreeBranch) {
        final parent = children[i++];
        final pSize = parent.layout(constraints.loosen());
        var left = pSize.width + style.lineSpacing;
        if (node.children.length != 1) {
          left += style.lineSpacing;
        }
        final cConstraints = constraints.deflate(EdgeInsets.only(left: left));
        final branches = <void Function(Offset)>[];
        var cSize = Size.zero;

        late double topY;
        late double btmY;

        for (var i = 0; i < node.children.length; i++) {
          if (i != 0) cSize += Offset(0, style.spacing);
          final ch = layoutNode(node.children[i], cConstraints)!;

          final y = cSize.height + ch.item2;
          if (i == 0) topY = y;
          if (i == node.children.length - 1) btmY = y;

          final offset = Offset(left, cSize.height);
          branches.add((o) => ch.item3(o + offset));
          cSize = Size(
            max(cSize.width, ch.item1.width),
            cSize.height + ch.item1.height,
          );
        }

        final midY = (topY + btmY) / 2;

        double pOffset;
        double cOffset;

        final pHalfHeight = pSize.height / 2;

        if (pSize.height > cSize.height) {
          // Center branches to parent
          cOffset = pHalfHeight - midY;
          final pad = max(0.0, -cOffset);
          pOffset = pad;
          cOffset += pad;
        } else {
          // Center parent to branches
          pOffset = midY - pHalfHeight;
          final pad = max(0.0, -pOffset);
          cOffset = pad;
          pOffset += pad;
        }

        return Tuple3(
          Size(cSize.width + left,
              max(pOffset + pSize.height, cOffset + cSize.height)),
          pOffset + pSize.height / 2,
          (o) {
            parent.position(o + Offset(0, pOffset));
            final bo = o + Offset(0, cOffset);
            for (final b in branches) b(bo);
          },
        );
      } else {
        // Unreachable
        assert(false);
        return null;
      }
    }

    final ch = layoutNode(root, constraints)!;
    ch.item3(Offset.zero);
    return constraints.constrain(ch.item1);
  }

  @override
  void paint() {
    final linePaint = Paint()
      ..strokeWidth = style.lineThickness
      ..color = style.lineColor
      ..style = PaintingStyle.stroke;

    int childIndex = 0;

    void paintNode(TreeNode node) {
      if (node is TreeBranch) {
        final parent = children[childIndex++].rect.centerRight;
        canvas.drawLine(
          parent,
          parent + Offset(style.lineSpacing, 0),
          linePaint,
        );
        final x = parent.dx;

        double? start;
        double? end;
        for (int i = 0; i < node.children.length; i++) {
          final left = children[childIndex].rect.centerLeft;
          end = left.dy;
          start ??= end;
          if (i != 0 && i != node.children.length - 1) {
            canvas.drawLine(
                left - Offset(style.lineSpacing, 0), left, linePaint);
          }
          paintNode(node.children[i]);
        }

        if (start != end) {
          final diameter = style.lineRadius * 2;
          canvas.drawPath(
            Path()
              ..moveTo(x + style.lineSpacing * 2, start!)
              ..arcTo(
                  Rect.fromLTWH(
                      x + style.lineSpacing, start, diameter, diameter),
                  pi / -2,
                  pi / -2,
                  false)
              ..arcTo(
                  Rect.fromLTWH(
                    x + style.lineSpacing,
                    end! - diameter,
                    diameter,
                    diameter,
                  ),
                  pi,
                  pi / -2,
                  false)
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
