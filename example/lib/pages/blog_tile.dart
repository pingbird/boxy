import 'dart:math';

import 'package:boxy/boxy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:boxy_gallery/main.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:tuple/tuple.dart';

class BlogTilePage extends StatefulWidget {
  createState() => BlogTilePageState();
}

const loremIpsum = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco...";

class BlogTilePageState extends State<BlogTilePage> {
  build(BuildContext context) => Scaffold(
    appBar: GalleryAppBar(
      ["Boxy Gallery", "Blog Tile"],
      source: "https://github.com/PixelToast/flutter-boxy/blob/master/example/lib/pages/blog_tile.dart",
    ),
    backgroundColor: NiceColors.primary,
    body: Column(children: [
      Separator(),
      Expanded(child: Container(child: ListView(children: [
        Padding(padding: EdgeInsets.only(top: 64)),
        Center(child: ConstrainedBox(child: BlogTile(
          body: BlogDesc(
            author: "Cicero",
          ),
          icons: [
            Tuple2(MdiIcons.shareVariant, null),
            Tuple2(MdiIcons.starOutline, MdiIcons.star),
            Tuple2(MdiIcons.heartOutline, MdiIcons.heart),
            Tuple2(MdiIcons.chatOutline, null),
          ],
        ), constraints: BoxConstraints(maxWidth: 450))),
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

class BlogDesc extends StatefulWidget {
  final String author;

  BlogDesc({
    @required this.author,
  });

  createState() => _BlogDescState();
}

class _BlogDescState extends State<BlogDesc> with TickerProviderStateMixin {
  bool expandDesc = false;
  bool expandText = false;

  build(BuildContext context) => Stack(children: [
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
        duration: Duration(milliseconds: 1000),
        curve: Curves.ease,
        height: expandDesc ? 200 : 42,
        child: Align(child: Padding(child: Row(children: [
          Padding(child: Icon(
            MdiIcons.rssBox,
            color: NiceColors.text,
          ), padding: EdgeInsets.only(right: 8)),
          Text(
            widget.author,
            style: TextStyle(
              color: NiceColors.text,
              fontSize: 18,
            ),
          ),
          Container(
            height: 2,
            width: 4,
            color: NiceColors.text.withOpacity(0.3),
            margin: EdgeInsets.symmetric(horizontal: 8),
          ),
          Text(
            "1h",
            style: TextStyle(
              color: NiceColors.text,
              fontSize: 15,
            ),
          ),
          Expanded(child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                NiceColors.text.withOpacity(0.1),
                NiceColors.text.withOpacity(0.3),
                NiceColors.text.withOpacity(0.1),
              ]),
            ),
            margin: EdgeInsets.only(left: 12),
          )),
        ]), padding: EdgeInsets.only(
          right: 42,
          top: 8,
          bottom: 8,
          left: 8,
        )), alignment: Alignment.topCenter),
      ),

      AnimatedSize(
        child: Padding(child: Text(
          loremIpsum,
          style: TextStyle(color: NiceColors.text),
          maxLines: 3,
        ), padding: EdgeInsets.only(
          left: 8,
        )),
        vsync: this,
        duration: Duration(milliseconds: 500),
        curve: Curves.ease,
        alignment: Alignment.topCenter,
      ),
    ]),

    Positioned(child: ExpandButton(
      onPressed: () => setState(() {
        expandDesc = !expandDesc;
      }),
      expanded: expandDesc,
    ), top: 0, right: 0),
  ]);
}

const kButtonSize = 50.0;

class ShareButton extends StatefulWidget {
  final IconData icon;
  final IconData alt;

  ShareButton({
    @required this.icon,
    this.alt,
  });

  createState() => _ShareButtonState();
}

class _ShareButtonState extends State<ShareButton> with SingleTickerProviderStateMixin {
  bool showAlt = false;

  static final borderRadius = BorderRadius.circular(16);


  build(context) => SizedBox(child: Material(
    color: Colors.transparent,
    child: InkWell(child: Container(
      decoration: BoxDecoration(
        border: Border.all(
          width: 3,
          color: NiceColors.divider.withOpacity(0.5),
        ),
        borderRadius: borderRadius,
      ),
      child: Align(child: Icon((
        showAlt && widget.alt != null) ?
          widget.alt : widget.icon,
        color: Colors.blueGrey.shade200,
      )),
    ), onTap: () => setState(() {
      showAlt = !showAlt;
    }),
      hoverColor: Colors.blueGrey.withOpacity(0.1),
      focusColor: Colors.blueGrey.withOpacity(0.2),
      highlightColor: Colors.blueGrey.withOpacity(0.3),
      splashColor: Colors.blueGrey.shade200.withOpacity(0.3),
    ),
    clipBehavior: Clip.antiAlias,
    borderRadius: borderRadius,
  ),
    width: kButtonSize,
    height: kButtonSize,
  );
}

class ShareMoreButton extends StatelessWidget {
  static final borderRadius = BorderRadius.circular(16);

  build(context) => Material(
    color: Colors.transparent,
    child: InkWell(child: AnimatedContainer(
      decoration: BoxDecoration(
        border: Border.all(
          width: 3,
          color: NiceColors.divider.withOpacity(0.5),
        ),
        borderRadius: borderRadius,
      ),
      width: kButtonSize,
      height: 30,
      duration: Duration(milliseconds: 500),
      curve: Curves.ease,
      child: Align(child: Icon(
        Icons.more_horiz,
        color: Colors.blueGrey.shade200,
      )),
    ),
      onTap: () {},
      hoverColor: Colors.blueGrey.withOpacity(0.1),
      focusColor: Colors.blueGrey.withOpacity(0.2),
      highlightColor: Colors.blueGrey.withOpacity(0.3),
      splashColor: Colors.blueGrey.shade200.withOpacity(0.3),
    ),
    clipBehavior: Clip.antiAlias,
    borderRadius: borderRadius,
  );
}


class BlogTile extends StatelessWidget {
  final Widget body;
  final List<Tuple2<IconData, IconData>> icons;

  BlogTile({
    @required this.body,
    @required this.icons,
  });

  build(context) => CustomBoxy(
    delegate: BlogTileDelegate(
      numButtons: icons.length,
      buttonBuilder: (context, i) =>
        ShareButton(icon: icons[i].item1, alt: icons[i].item2),
    ),
    children: [
      LayoutId(id: #body, child: body),
      LayoutId(id: #moreButton, child: ShareMoreButton()),
    ],
  );
}

class BlogTileDelegate extends BoxyDelegate {
  int numButtons;
  IndexedWidgetBuilder buttonBuilder;

  BlogTileDelegate({
    @required this.numButtons,
    @required this.buttonBuilder,
  });

  @override
  layout() {
    var moreButton = getChild(#moreButton);
    var moreButtonSize = moreButton.layout(constraints.loosen());

    var body = getChild(#body);
    var bodySize = body.layout(constraints.deflate(EdgeInsets.only(
      left: moreButtonSize.width,
    )));
    body.position(Offset(moreButtonSize.width, 0));

    const margin = 8.0;
    var buttonConstraints = BoxConstraints.tightFor(width: moreButtonSize.width);
    var offset = 0.0;
    var limit = bodySize.height - moreButtonSize.height;
    var finished = false;
    for (int i = 0; i < numButtons; i++) {
      var child = inflate(buttonBuilder(buildContext, i));
      var size = child.layout(buttonConstraints);
      child.position(Offset(0, offset));
      var newOffset = offset + size.height + margin;
      var last = i == numButtons - 1;
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

  shouldRelayout(BlogTileDelegate old) => true;
}