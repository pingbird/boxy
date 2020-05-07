import 'dart:async';

import 'package:boxy/boxy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:boxy_gallery/main.dart';
import 'package:tuple/tuple.dart';
import 'package:rxdart/rxdart.dart' as rx;

class ProductTitleController {
  var expanded = rx.BehaviorSubject<int>();
  void close() {
    expanded.close();
  }
}

class ProductTileSimplePage extends StatefulWidget {
  createState() => ProductTileSimplePageState();
}

class ProductTileSimplePageState extends State<ProductTileSimplePage> {
  build(BuildContext context) => Scaffold(
    appBar: GalleryAppBar(
      ["Boxy Gallery", "Flex Dominant"],
      source: "https://github.com/PixelToast/flutter-boxy/blob/master/examples/gallery/lib/pages/tree_view.dart",
    ),
    backgroundColor: NiceColors.primary,
    body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Separator(),
      Expanded(child: Align(
        child: Column(children: [
          ProductTile(
            title: SeebTitle(),
            info: SeebInfo(),
            seller: SeebSeller(),
          ),
        ], mainAxisAlignment: MainAxisAlignment.center),
      )),
      Separator(),
    ]),
  );
}

class SeebSeller extends StatefulWidget {
  final String image;

  SeebSeller({@required this.image});

  createState() => _SeebSellerState();
}

class _SeebSellerState extends State<SeebSeller> {
  bool expanded = false;
  build(context) => ClipOval(child: Stack(children: [
    Positioned.fill(child: Container(
      color: NiceColors.background,
      child: ClipOval(child:
        Image.network(widget.image, fit: BoxFit.cover),
      ),
      padding: EdgeInsets.all(8),
    )),
    Material(child: InkWell(onTap: () {
      setState(() {
        expanded = !expanded;
      });
    }, child: AnimatedContainer(
      duration: Duration(milliseconds: 500),
      width: expanded ? 84 : 48,
      height: expanded ? 84 : 48,
      curve: Curves.ease,
      margin: EdgeInsets.all(8),
    )), color: Colors.transparent),
  ]));
}

class SeebTitle extends StatefulWidget {
  createState() => SeebTitleState();
}

class SeebTitleState extends State<SeebTitle> {
  StreamSubscription subscription;
  bool expanded = false;

  build(context) => ClipRRect(child: Stack(children: [
    Positioned.fill(child: Container(color: Colors.redAccent)),
    AnimatedContainer(
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: () {
          setState(() {
            expanded = !expanded;
          });
        }),
      ),
      duration: Duration(milliseconds: 500),
      width: expanded ? 450 : 350,
      height: expanded ? 350 : 200,
      curve: Curves.ease,
    ),
  ]), borderRadius: BorderRadius.circular(8));

  dispose() {
    super.dispose();
    subscription.cancel();
  }
}

class SeebInfo extends StatefulWidget {
  createState() => SeebInfoState();
}

class SeebInfoState extends State<SeebInfo> with TickerProviderStateMixin {
  AnimationController anim;
  int expanded = 0;

  initState() {
    super.initState();
    anim = AnimationController.unbounded(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    anim.addListener(() => setState(() {}));
  }

  build(context) => ClipRRect(child: Stack(children: [
    Positioned.fill(child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blueGrey.shade900,
            Colors.blueGrey.shade700,
          ],
        ),
      ),
    )),
    Material(
      color: Colors.transparent,
      child: InkWell(child: AnimatedContainer(
        alignment: Alignment.topCenter,
        child: Container(
          height: expanded * 25.0,
        ),
        duration: Duration(milliseconds: 250),
        curve: Curves.ease,
      ), onTap: () {
        setState(() {
          expanded = (expanded + 1) % 4;
          anim.animateTo(expanded.toDouble(), curve: Curves.ease);
        });
      }),
    ),
  ]), borderRadius: BorderRadius.circular(8));
}

class ProductTileStyle {
  final double sellerInset;
  final double gapHeight;

  const ProductTileStyle({
    this.sellerInset = 16.0,
    this.gapHeight = 8.0,
  });

  bool sameLayout(ProductTileStyle other) =>
    other.sellerInset == sellerInset &&
    other.gapHeight == gapHeight;
}

class ProductTile extends StatelessWidget {
  final Widget title;
  final Widget info;
  final Widget seller;
  final ProductTileStyle style;

  ProductTile({
    @required this.title,
    @required this.info,
    @required this.seller,
    this.style = const ProductTileStyle(),
  });

  build(context) => CustomBoxy(
    delegate: ProductTileDelegate(style: style),
    children: [
      LayoutId(id: #title, child: title),
      LayoutId(id: #info, child: info),
      LayoutId(id: #seller, child: seller),
    ],
  );
}

class ProductTileDelegate extends BoxyDelegate {
  final ProductTileStyle style;

  ProductTileDelegate({
    @required this.style,
  });

  @override
  layout() {
    var title = getChild(#title);
    var seller = getChild(#seller);
    var info = getChild(#info);

    var sellerSize = seller.layout(constraints.deflate(
      EdgeInsets.only(right: style.sellerInset),
    ));

    var titleSize = title.layout(constraints.copyWith(
      minHeight: sellerSize.height / 2 + style.gapHeight / 2,
    ));

    title.position(Offset.zero);
    seller.position(Offset(
      titleSize.width - (sellerSize.width + style.sellerInset),
      (titleSize.height - sellerSize.height / 2) + style.gapHeight / 2,
    ));

    var infoSize = info.layout(constraints.copyWith(
      minHeight: sellerSize.height / 2,
      minWidth: titleSize.width,
      maxWidth: titleSize.width,
    ));
    info.position(Offset(0, titleSize.height + style.gapHeight));

    return Size(
      titleSize.width, titleSize.height + infoSize.height + style.gapHeight,
    );
  }

  @override
  shouldRelayout(ProductTileDelegate old) =>
    !style.sameLayout(old.style);
}