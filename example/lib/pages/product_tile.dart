import 'dart:async';

import 'package:boxy/boxy.dart';
import 'package:boxy_gallery/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rxdart/rxdart.dart' as rx;
import 'package:tuple/tuple.dart';

class ProductTitleController {
  var expanded = rx.BehaviorSubject<int?>();
  void close() {
    expanded.close();
  }
}

class ProductTilePage extends StatefulWidget {
  createState() => ProductTilePageState();
}

class ProductTilePageState extends State<ProductTilePage> {
  static const settingsWidth = 400.0;

  var style = const ProductTileStyle();
  var titleCtrl = ProductTitleController();

  dispose() {
    super.dispose();
    titleCtrl.close();
  }

  build(BuildContext context) => Scaffold(
    appBar: const GalleryAppBar(
      ['Boxy Gallery', 'Product Tile'],
      source: 'https://github.com/PixelToast/flutter-boxy/blob/master/example/lib/pages/product_tile.dart',
    ),
    backgroundColor: NiceColors.primary,
    body: Column(children: [
      Separator(),
      Expanded(child: Container(child: ListView(children: [
        const Padding(padding: EdgeInsets.only(top: 64)),
        Center(child: Container(
          child: ProductTile(
            title: SeebTitle(
              name: 'Millet', image: 'https://i.imgur.com/Stw5x9N.jpg',
              controller: titleCtrl, index: 0,
            ),
            info: const SeebInfo(price: '\$0.30 / oz'),
            seller: const SeebSeller(image: 'https://i.imgur.com/ayx4yZa.png'),
            style: style,
          ),
        )),
        const Padding(padding: EdgeInsets.only(top: 12)),
        Center(child: Container(
          child: ProductTile(
            title: SeebTitle(
              name: 'Sunflower', image: 'https://i.imgur.com/xRDWdPx.jpg',
              controller: titleCtrl, index: 1,
            ),
            info: const SeebInfo(price: '\$0.10 / oz'),
            seller: const SeebSeller(image: 'https://i.imgur.com/fKtqsMi.jpg'),
            style: style,
          ),
        )),
        const Padding(padding: EdgeInsets.only(top: 12)),
        Center(child: Container(
          child: ProductTile(
            title: SeebTitle(
              name: 'Blend', image: 'https://i.imgur.com/PItalTE.jpg',
              controller: titleCtrl, index: 2,
            ),
            info: const SeebInfo(price: '\$0.17 / oz'),
            seller: const SeebSeller(image: 'https://i.imgur.com/fKtqsMi.jpg'),
            style: style,
          ),
        )),
        const Padding(padding: EdgeInsets.only(top: 64)),
      ], physics: const BouncingScrollPhysics()), color: NiceColors.background)),
      Separator(),
    ]),
  );
}

class SeebSeller extends StatefulWidget {
  final String image;

  const SeebSeller({required this.image});

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
      padding: const EdgeInsets.all(8),
    )),
    Material(child: InkWell(onTap: () {
      setState(() {
        expanded = !expanded;
      });
    }, child: AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: expanded ? 84 : 48,
      height: expanded ? 84 : 48,
      curve: Curves.ease,
      margin: const EdgeInsets.all(8),
    )), color: Colors.transparent),
  ]));
}

class SeebTitle extends StatefulWidget {
  final ProductTitleController controller;
  final int index;
  final String name;
  final String image;

  SeebTitle({
    required this.controller, required this.index,
    required this.name, required this.image
  }) :
    super(key: ValueKey(Tuple2(#seebTitle, index)));

  createState() => SeebTitleState();
}

class SeebTitleState extends State<SeebTitle> {
  late StreamSubscription subscription;
  late bool expanded;

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
      duration: const Duration(milliseconds: 500),
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
            style: const TextStyle(
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
          padding: const EdgeInsets.all(16),
        ), alignment: Alignment.bottomLeft), onTap: () {
          if (widget.controller.expanded.value == widget.index) {
            widget.controller.expanded.add(null);
          } else {
            widget.controller.expanded.add(widget.index);
          }
        }),
      ),
      duration: const Duration(milliseconds: 500),
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

  const SeebInfoTile({required this.text});

  build(context) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Row(
      children: [
        const Icon(Icons.check, size: 14),
        const Padding(padding: EdgeInsets.only(right: 8)),
        Text(text, style: const TextStyle(
          color: Colors.white,
        )),
      ],
    ),
  );
}

class SeebInfo extends StatefulWidget {
  final String price;

  const SeebInfo({
    required this.price,
  });

  createState() => SeebInfoState();
}

class SeebInfoState extends State<SeebInfo> with TickerProviderStateMixin {
  late AnimationController anim;
  int expanded = 0;

  initState() {
    super.initState();
    anim = AnimationController.unbounded(
      duration: const Duration(milliseconds: 1000),
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            if (expanded > 0) const SeebInfoTile(text: 'Premium quality'),
            if (expanded > 1) const SeebInfoTile(text: 'Birb favorite'),
            if (expanded > 2) const SeebInfoTile(text: 'All natural'),
          ]
        ),
        duration: const Duration(milliseconds: 250),
        curve: Curves.ease,
      ), padding: const EdgeInsets.all(16)), onTap: () {
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

  const ProductTile({
    required this.title,
    required this.info,
    required this.seller,
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
    required this.style,
  });

  @override
  layout() {
    final title = getChild(#title);
    final seller = getChild(#seller);
    final info = getChild(#info);

    final sellerSize = seller.layout(constraints.deflate(
      EdgeInsets.only(right: style.sellerInset),
    ));

    final titleSize = title.layout(constraints.copyWith(
      minHeight: sellerSize.height / 2 + style.gapHeight / 2,
    ));

    title.position(Offset.zero);
    seller.position(Offset(
      titleSize.width - (sellerSize.width + style.sellerInset),
      (titleSize.height - sellerSize.height / 2) + style.gapHeight / 2,
    ));

    final infoSize = info.layout(constraints.copyWith(
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