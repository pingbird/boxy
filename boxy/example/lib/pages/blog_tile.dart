import 'dart:math';

import 'package:boxy/boxy.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:tuple/tuple.dart';

import '../components/palette.dart';
import '../main.dart';

class BlogTilePage extends StatefulWidget {
  @override
  State createState() => BlogTilePageState();
}

const loremIpsum =
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco...';

class BlogTilePageState extends State<BlogTilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GalleryAppBar(
        ['Boxy Gallery', 'Blog Tile'],
        source:
            'https://github.com/PixelToast/boxy/blob/master/boxy/example/lib/pages/blog_tile.dart',
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
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: const BlogTile(
                      body: BlogDesc(
                        author: 'Cicero',
                      ),
                      icons: [
                        Tuple2(MdiIcons.shareVariant, null),
                        Tuple2(MdiIcons.starOutline, MdiIcons.star),
                        Tuple2(MdiIcons.heartOutline, MdiIcons.heart),
                        Tuple2(MdiIcons.chatOutline, null),
                      ],
                    ),
                  ),
                ),
                const Padding(padding: EdgeInsets.only(top: 64)),
              ],
            ),
          ),
        ),
        Separator(),
      ]),
    );
  }
}

class ExpandButton extends StatefulWidget {
  final bool expanded;
  final VoidCallback onPressed;

  const ExpandButton({
    required this.expanded,
    required this.onPressed,
  });

  @override
  State<ExpandButton> createState() => _ExpandButtonState();
}

class _ExpandButtonState extends State<ExpandButton>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller =
        AnimationController(vsync: this, value: widget.expanded ? 1 : 0);
    controller.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(ExpandButton old) {
    super.didUpdateWidget(old);
    controller.animateTo(
      widget.expanded ? 1 : 0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  static const size = 42.0;

  @override
  SizedBox build(context) => SizedBox(
      width: size,
      height: size,
      child: Material(
        borderRadius: BorderRadius.circular(size / 2),
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          hoverColor: Colors.blueGrey.withOpacity(0.1),
          focusColor: Colors.blueGrey.withOpacity(0.2),
          highlightColor: Colors.blueGrey.withOpacity(0.3),
          splashColor: Colors.blueGrey.shade200.withOpacity(0.3),
          child: Center(
            child: Transform.rotate(
                angle: pi * controller.value,
                child: const Icon(
                  Icons.arrow_drop_down,
                  size: 24,
                )),
          ),
        ),
      ));
}

class BlogDesc extends StatefulWidget {
  final String author;

  const BlogDesc({
    required this.author,
  });

  @override
  State<BlogDesc> createState() => _BlogDescState();
}

class _BlogDescState extends State<BlogDesc> with TickerProviderStateMixin {
  bool expandDesc = false;
  bool expandText = false;

  @override
  Stack build(BuildContext context) => Stack(children: [
        Column(children: [
          AnimatedContainer(
            margin: EdgeInsets.only(left: 8, bottom: expandDesc ? 4 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blueGrey.shade700.withOpacity(expandDesc ? 1 : 0),
                  Colors.blueGrey.shade800.withOpacity(expandDesc ? 1 : 0),
                ],
              ),
            ),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.ease,
            height: expandDesc ? 200 : 42,
            child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                    padding: const EdgeInsets.only(
                      right: 42,
                      top: 8,
                      bottom: 8,
                      left: 8,
                    ),
                    child: Row(children: [
                      const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(MdiIcons.rssBox)),
                      Text(
                        widget.author,
                        style: const TextStyle(fontSize: 18),
                      ),
                      Container(
                        height: 2,
                        width: 4,
                        color: palette.foreground.withOpacity(0.3),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      const Text(
                        '1h',
                        style: TextStyle(fontSize: 15),
                      ),
                      Expanded(
                          child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            palette.foreground.withOpacity(0.1),
                            palette.foreground.withOpacity(0.3),
                            palette.foreground.withOpacity(0.1),
                          ]),
                        ),
                        margin: const EdgeInsets.only(left: 12),
                      )),
                    ]))),
          ),
          const AnimatedSize(
            duration: Duration(milliseconds: 500),
            curve: Curves.ease,
            alignment: Alignment.topCenter,
            child: Padding(
                padding: EdgeInsets.only(
                  left: 8,
                ),
                child: Text(
                  loremIpsum,
                  maxLines: 3,
                )),
          ),
        ]),
        Positioned(
            top: 0,
            right: 0,
            child: ExpandButton(
              onPressed: () => setState(() {
                expandDesc = !expandDesc;
              }),
              expanded: expandDesc,
            )),
      ]);
}

const kButtonSize = 50.0;

class ShareButton extends StatefulWidget {
  final IconData icon;
  final IconData? alt;

  const ShareButton({
    required this.icon,
    this.alt,
  });

  @override
  State<ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends State<ShareButton>
    with SingleTickerProviderStateMixin {
  bool showAlt = false;

  static final borderRadius = BorderRadius.circular(16);

  @override
  SizedBox build(context) => SizedBox(
        width: kButtonSize,
        height: kButtonSize,
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          borderRadius: borderRadius,
          child: InkWell(
            onTap: () => setState(() {
              showAlt = !showAlt;
            }),
            hoverColor: Colors.blueGrey.withOpacity(0.1),
            focusColor: Colors.blueGrey.withOpacity(0.2),
            highlightColor: Colors.blueGrey.withOpacity(0.3),
            splashColor: Colors.blueGrey.shade200.withOpacity(0.3),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  width: 3,
                  color: palette.divider.withOpacity(0.5),
                ),
                borderRadius: borderRadius,
              ),
              child: Align(
                child: Icon(
                  (showAlt && widget.alt != null) ? widget.alt : widget.icon,
                  color: Colors.blueGrey.shade200,
                ),
              ),
            ),
          ),
        ),
      );
}

class ShareMoreButton extends StatelessWidget {
  static final borderRadius = BorderRadius.circular(16);

  @override
  Material build(context) => Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: () {},
          hoverColor: Colors.blueGrey.withOpacity(0.1),
          focusColor: Colors.blueGrey.withOpacity(0.2),
          highlightColor: Colors.blueGrey.withOpacity(0.3),
          splashColor: Colors.blueGrey.shade200.withOpacity(0.3),
          child: AnimatedContainer(
            decoration: BoxDecoration(
              border: Border.all(
                width: 3,
                color: palette.divider.withOpacity(0.5),
              ),
              borderRadius: borderRadius,
            ),
            width: kButtonSize,
            height: 30,
            duration: const Duration(milliseconds: 500),
            curve: Curves.ease,
            child: Align(
              child: Icon(
                Icons.more_horiz,
                color: Colors.blueGrey.shade200,
              ),
            ),
          ),
        ),
      );
}

class BlogTile extends StatelessWidget {
  final Widget body;
  final List<Tuple2<IconData, IconData?>> icons;

  const BlogTile({
    required this.body,
    required this.icons,
  });

  @override
  CustomBoxy build(context) => CustomBoxy(
        delegate: BlogTileDelegate(
          numButtons: icons.length,
          buttonBuilder: (context, i) =>
              ShareButton(icon: icons[i].item1, alt: icons[i].item2),
        ),
        children: [
          BoxyId(id: #body, child: body),
          BoxyId(id: #moreButton, child: ShareMoreButton()),
        ],
      );
}

class BlogTileDelegate extends BoxyDelegate {
  int numButtons;
  IndexedWidgetBuilder buttonBuilder;

  BlogTileDelegate({
    required this.numButtons,
    required this.buttonBuilder,
  });

  @override
  Size layout() {
    final moreButton = getChild(#moreButton);
    final moreButtonSize = moreButton.layout(constraints.loosen());

    final body = getChild(#body);
    final bodySize = body.layout(constraints.deflate(EdgeInsets.only(
      left: moreButtonSize.width,
    )));
    body.position(Offset(moreButtonSize.width, 0));

    const margin = 8.0;
    final buttonConstraints =
        BoxConstraints.tightFor(width: moreButtonSize.width);
    var offset = 0.0;
    final limit = bodySize.height - moreButtonSize.height;
    var finished = false;
    for (int i = 0; i < numButtons; i++) {
      final child = inflate(buttonBuilder(buildContext, i));
      final size = child.layout(buttonConstraints);
      child.position(Offset(0, offset));
      final newOffset = offset + size.height + margin;
      final last = i == numButtons - 1;
      if (newOffset > (last ? bodySize.height : limit)) {
        child.ignore();
        finished = true;
        break;
      } else {
        offset = newOffset;
      }
    }

    if (finished) {
      moreButton.position(Offset(0, offset));
    } else {
      moreButton.ignore();
    }

    return Size(
      bodySize.width + moreButtonSize.width,
      bodySize.height,
    );
  }

  @override
  bool shouldRelayout(BlogTileDelegate oldDelegate) => true;
}
