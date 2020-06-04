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

class ProductTilePage extends StatefulWidget {
  createState() => ProductTilePageState();
}

class ProductTilePageState extends State<ProductTilePage> {
  static const settingsWidth = 400.0;

  var style = ProductTileStyle();
  var titleCtrl = ProductTitleController();

  dispose() {
    super.dispose();
    titleCtrl.close();
  }

  build(BuildContext context) => Scaffold(
    appBar: GalleryAppBar(
      ["Boxy Gallery", "Product Tile"],
      source: "https://github.com/PixelToast/flutter-boxy/blob/master/example/lib/pages/product_tile.dart",
    ),
    backgroundColor: NiceColors.primary,
    body: Column(children: [
      Separator(),
      Expanded(child: Container(child: ListView(children: [
        Padding(padding: EdgeInsets.only(top: 64)),
        Center(child: Container(
          child: ProductTile(
            title: SeebTitle(
              name: "Millet", image: "https://i.imgur.com/Stw5x9N.jpg",
              controller: titleCtrl, index: 0,
            ),
            info: SeebInfo(price: "\$0.30 / oz"),
            seller: SeebSeller(image: "https://i.imgur.com/ayx4yZa.png"),
            style: style,
          ),
        )),
        Padding(padding: EdgeInsets.only(top: 12)),
        Center(child: Container(
          child: ProductTile(
            title: SeebTitle(
              name: "Sunflower", image: "https://i.imgur.com/xRDWdPx.jpg",
              controller: titleCtrl, index: 1,
            ),
            info: SeebInfo(price: "\$0.10 / oz"),
            seller: SeebSeller(image: "https://i.imgur.com/fKtqsMi.jpg"),
            style: style,
          ),
        )),
        Padding(padding: EdgeInsets.only(top: 12)),
        Center(child: Container(
          child: ProductTile(
            title: SeebTitle(
              name: "Blend", image: "https://i.imgur.com/PItalTE.jpg",
              controller: titleCtrl, index: 2,
            ),
            info: SeebInfo(price: "\$0.17 / oz"),
            seller: SeebSeller(image: "https://i.imgur.com/fKtqsMi.jpg"),
            style: style,
          ),
        )),
        Padding(padding: EdgeInsets.only(top: 64)),
      ], physics: BouncingScrollPhysics()), color: NiceColors.background)),
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
  final ProductTitleController controller;
  final int index;
  final String name;
  final String image;

  SeebTitle({
    @required this.controller, @required this.index,
    @required this.name, @required this.image
  }) :
    super(key: ValueKey(Tuple2(#seebTitle, index)));

  createState() => SeebTitleState();
}

class SeebTitleState extends State<SeebTitle> {
  StreamSubscription subscription;
  bool expanded;

  initState() {
    super.initState();
    subscription = widget.controller.expanded.listen((value) {
      setState(() {
        expanded = value == widget.index;
      });
    });

    expanded = widget.controller.expanded.value == widget.index;
  }

  build(context) => ClipRRect(child: Stack(children: [
    Positioned.fill(child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blueGrey.shade900,
            Colors.blueGrey.shade800,
          ],
        ),
      ),
    )),
    Positioned.fill(child: AnimatedContainer(
      child: Image.network(
        widget.image,
        fit: BoxFit.cover,
      ),
      duration: Duration(milliseconds: 500),
      curve: Curves.ease,
      padding: EdgeInsets.only(
        bottom: expanded ? 0 : 60,
      ),
    )),
    AnimatedContainer(
      child: Material(
        color: Colors.transparent,
        child: InkWell(child: Align(child: Padding(
          child: Text(
            widget.name,
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              shadows: [
                Shadow( // bottomLeft
                  offset: Offset.zero,
                  color: Colors.black26,
                  blurRadius: 8.0,
                ),
              ]
            ),
          ),
          padding: EdgeInsets.all(16),
        ), alignment: Alignment.bottomLeft), onTap: () {
          if (widget.controller.expanded.value == widget.index) {
            widget.controller.expanded.value = null;
          } else {
            widget.controller.expanded.value = widget.index;
          }
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

class SeebInfoTile extends StatelessWidget {
  final String text;

  SeebInfoTile({@required this.text});

  build(context) => Padding(
    padding: EdgeInsets.only(top: 16),
    child: Row(
      children: [
        Icon(Icons.check, size: 14),
        Padding(padding: EdgeInsets.only(right: 8)),
        Text(text, style: TextStyle(
          color: Colors.white,
        )),
      ],
    ),
  );
}

class SeebInfo extends StatefulWidget {
  final String price;

  SeebInfo({
    @required this.price,
  });

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
      child: InkWell(child: Padding(child: AnimatedSize(
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(
              widget.price,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            if (expanded > 0) SeebInfoTile(text: "Premium quality"),
            if (expanded > 1) SeebInfoTile(text: "Birb favorite"),
            if (expanded > 2) SeebInfoTile(text: "All natural"),
          ]
        ),
        duration: Duration(milliseconds: 250),
        curve: Curves.ease,
        vsync: this,
      ), padding: EdgeInsets.all(16)), onTap: () {
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