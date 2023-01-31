import 'dart:async';

import 'package:boxy/boxy.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart' as rx;
import 'package:tuple/tuple.dart';

import '../components/palette.dart';
import '../main.dart';

class ProductTitleController {
  var expanded = rx.BehaviorSubject<int?>();
  void close() {
    expanded.close();
  }
}

class ProductTilePage extends StatefulWidget {
  @override
  State<ProductTilePage> createState() => ProductTilePageState();
}

class ProductTilePageState extends State<ProductTilePage> {
  static const settingsWidth = 400.0;

  var style = const ProductTileStyle();
  var titleCtrl = ProductTitleController();

  @override
  void dispose() {
    super.dispose();
    titleCtrl.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GalleryAppBar(
        ['Boxy Gallery', 'Product Tile'],
        source:
            'https://github.com/PixelToast/boxy/blob/master/boxy/example/lib/pages/product_tile.dart',
      ),
      backgroundColor: palette.primary,
      body: Column(
        children: [
          Separator(),
          Expanded(
            child: ColoredBox(
              color: palette.background,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  const Padding(padding: EdgeInsets.only(top: 64)),
                  Center(
                    child: ProductTile(
                      title: SeebTitle(
                        name: 'Millet',
                        image: 'https://i.imgur.com/Stw5x9N.jpg',
                        controller: titleCtrl,
                        index: 0,
                      ),
                      info: const SeebInfo(price: r'$0.30 / oz'),
                      seller: const SeebSeller(
                          image: 'https://i.imgur.com/ayx4yZa.png'),
                      style: style,
                    ),
                  ),
                  const Padding(padding: EdgeInsets.only(top: 12)),
                  Center(
                    child: ProductTile(
                      title: SeebTitle(
                        name: 'Sunflower',
                        image: 'https://i.imgur.com/xRDWdPx.jpg',
                        controller: titleCtrl,
                        index: 1,
                      ),
                      info: const SeebInfo(price: r'$0.10 / oz'),
                      seller: const SeebSeller(
                          image: 'https://i.imgur.com/fKtqsMi.jpg'),
                      style: style,
                    ),
                  ),
                  const Padding(padding: EdgeInsets.only(top: 12)),
                  Center(
                    child: ProductTile(
                      title: SeebTitle(
                        name: 'Blend',
                        image: 'https://i.imgur.com/PItalTE.jpg',
                        controller: titleCtrl,
                        index: 2,
                      ),
                      info: const SeebInfo(price: r'$0.17 / oz'),
                      seller: const SeebSeller(
                          image: 'https://i.imgur.com/fKtqsMi.jpg'),
                      style: style,
                    ),
                  ),
                  const Padding(padding: EdgeInsets.only(top: 64)),
                ],
              ),
            ),
          ),
          Separator(),
        ],
      ),
    );
  }
}

class SeebSeller extends StatefulWidget {
  final String image;

  const SeebSeller({required this.image});

  @override
  State<SeebSeller> createState() => _SeebSellerState();
}

class _SeebSellerState extends State<SeebSeller> {
  bool expanded = false;

  @override
  Widget build(context) {
    return ClipOval(
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: palette.background,
              padding: const EdgeInsets.all(8),
              child: ClipOval(
                child: Image.network(widget.image, fit: BoxFit.cover),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  expanded = !expanded;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: expanded ? 84 : 48,
                height: expanded ? 84 : 48,
                curve: Curves.ease,
                margin: const EdgeInsets.all(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SeebTitle extends StatefulWidget {
  final ProductTitleController controller;
  final int index;
  final String name;
  final String image;

  SeebTitle({
    required this.controller,
    required this.index,
    required this.name,
    required this.image,
  }) : super(key: ValueKey(Tuple2(#seebTitle, index)));

  @override
  SeebTitleState createState() => SeebTitleState();
}

class SeebTitleState extends State<SeebTitle> {
  late StreamSubscription subscription;
  late bool expanded;

  @override
  void initState() {
    super.initState();
    subscription = widget.controller.expanded.listen((value) {
      setState(() {
        expanded = value == widget.index;
      });
    });

    expanded = widget.controller.expanded.value == widget.index;
  }

  @override
  ClipRRect build(context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Positioned.fill(
              child: Container(
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
          Positioned.fill(
              child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.ease,
            padding: EdgeInsets.only(
              bottom: expanded ? 0 : 60,
            ),
            child: Image.network(
              widget.image,
              fit: BoxFit.cover,
            ),
          )),
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: expanded ? 450 : 350,
            height: expanded ? 350 : 200,
            curve: Curves.ease,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      widget.name,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 8.0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                onTap: () {
                  if (widget.controller.expanded.value == widget.index) {
                    widget.controller.expanded.add(null);
                  } else {
                    widget.controller.expanded.add(widget.index);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    subscription.cancel();
  }
}

class SeebInfoTile extends StatelessWidget {
  final String text;

  const SeebInfoTile({required this.text});

  @override
  Widget build(context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          const Icon(Icons.check, size: 14),
          const Padding(padding: EdgeInsets.only(right: 8)),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class SeebInfo extends StatefulWidget {
  final String price;

  const SeebInfo({
    required this.price,
  });

  @override
  SeebInfoState createState() => SeebInfoState();
}

class SeebInfoState extends State<SeebInfo> with TickerProviderStateMixin {
  late AnimationController anim;
  int expanded = 0;

  @override
  void initState() {
    super.initState();
    anim = AnimationController.unbounded(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    anim.addListener(() => setState(() {}));
  }

  @override
  Widget build(context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
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
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AnimatedSize(
                  alignment: Alignment.topCenter,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.ease,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.price,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      if (expanded > 0)
                        const SeebInfoTile(text: 'Premium quality'),
                      if (expanded > 1)
                        const SeebInfoTile(text: 'Birb favorite'),
                      if (expanded > 2) const SeebInfoTile(text: 'All natural'),
                    ],
                  ),
                ),
              ),
              onTap: () {
                setState(() {
                  expanded = (expanded + 1) % 4;
                  anim.animateTo(expanded.toDouble(), curve: Curves.ease);
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

@immutable
class ProductTileStyle {
  /// How far to the left the seller is inset
  final double sellerInset;

  /// The size of the gap between the title and description
  final double gapHeight;

  const ProductTileStyle({
    this.sellerInset = 16.0,
    this.gapHeight = 8.0,
  });

  @override
  bool operator ==(Object? other) =>
      identical(this, other) ||
      (other is ProductTileStyle &&
          other.sellerInset == sellerInset &&
          other.gapHeight == gapHeight);

  @override
  int get hashCode => Object.hash(sellerInset, gapHeight);
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

  @override
  Widget build(context) {
    return CustomBoxy(
      delegate: ProductTileDelegate(style: style),
      children: [
        // Children are in paint order, put the seller last so it can sit
        // above the others
        BoxyId(id: #title, child: title),
        BoxyId(id: #info, child: info),
        BoxyId(id: #seller, child: seller),
      ],
    );
  }
}

class ProductTileDelegate extends BoxyDelegate {
  final ProductTileStyle style;

  ProductTileDelegate({required this.style});

  @override
  Size layout() {
    // We can grab children by name using getChild
    final title = getChild(#title);
    final seller = getChild(#seller);
    final info = getChild(#info);

    // Lay out the seller first so it can provide a minimum height to the title
    // and info
    final sellerSize = seller.layout(constraints.deflate(
      EdgeInsets.only(right: style.sellerInset),
    ));

    // Lay out and position the title
    final titleSize = title.layout(constraints.copyWith(
      minHeight: sellerSize.height / 2 + style.gapHeight / 2,
    ));
    title.position(Offset.zero);

    // Position the seller at the bottom right of the title, offset to the left
    // by sellerInset
    seller.position(Offset(
      titleSize.width - (sellerSize.width + style.sellerInset),
      (titleSize.height - sellerSize.height / 2) + style.gapHeight / 2,
    ));

    // Lay out info to match the width of title and position it below the title
    final infoSize = info.layout(constraints.copyWith(
      minHeight: sellerSize.height / 2,
      minWidth: titleSize.width,
      maxWidth: titleSize.width,
    ));
    info.position(Offset(0, titleSize.height + style.gapHeight));

    return Size(
      titleSize.width,
      titleSize.height + infoSize.height + style.gapHeight,
    );
  }

  @override
  bool shouldRelayout(ProductTileDelegate oldDelegate) =>
      style != oldDelegate.style;
}
