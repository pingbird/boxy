import 'package:boxy/boxy.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart' as rx;

import '../components/palette.dart';
import '../main.dart';

class ProductTitleController {
  var expanded = rx.BehaviorSubject<int>();
  void close() {
    expanded.close();
  }
}

class ProductTileSimplePage extends StatefulWidget {
  @override
  State createState() => ProductTileSimplePageState();
}

class ProductTileSimplePageState extends State<ProductTileSimplePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GalleryAppBar(
        ['Boxy Gallery', 'Simple Product Tile'],
        source:
            'https://github.com/PixelToast/boxy/blob/master/boxy/example/lib/pages/product_tile_simple.dart',
      ),
      backgroundColor: palette.primary,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Separator(),
          Expanded(
            child: Align(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ProductTile(
                      title: SeebTitle(),
                      info: SeebInfo(),
                      seller: SeebSeller(),
                    ),
                  ]),
            ),
          ),
          Separator(),
        ],
      ),
    );
  }
}

class SeebSeller extends StatefulWidget {
  @override
  State createState() => _SeebSellerState();
}

class _SeebSellerState extends State<SeebSeller> {
  bool expanded = false;
  @override
  Widget build(context) {
    return ClipOval(
      child: Material(
        color: palette.primary,
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
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(256),
                color: const Color(0xFFE2F0CB),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SeebTitle extends StatefulWidget {
  @override
  SeebTitleState createState() => SeebTitleState();
}

class SeebTitleState extends State<SeebTitle> {
  bool expanded = false;

  @override
  Widget build(context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(children: [
        const Positioned.fill(child: ColoredBox(color: Color(0xFFC7CEEA))),
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: expanded ? 450 : 350,
          height: expanded ? 350 : 200,
          curve: Curves.ease,
          child: Material(
            color: Colors.transparent,
            child: InkWell(onTap: () {
              setState(() {
                expanded = !expanded;
              });
            }),
          ),
        ),
      ]),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class SeebInfo extends StatefulWidget {
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
  ClipRRect build(context) {
    return ClipRRect(
      child: Material(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFFB5EAD7),
        child: InkWell(
          child: AnimatedContainer(
            alignment: Alignment.topCenter,
            height: (expanded + 1) * 56.0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.ease,
          ),
          onTap: () {
            setState(() {
              expanded = (expanded + 1) % 3;
              anim.animateTo(expanded.toDouble(), curve: Curves.ease);
            });
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    anim.dispose();
    super.dispose();
  }
}

class ProductTileStyle {
  final double sellerInset;
  final double gapHeight;

  const ProductTileStyle({
    this.sellerInset = 16.0,
    this.gapHeight = 8.0,
  });

  bool sameLayout(ProductTileStyle other) =>
      other.sellerInset == sellerInset && other.gapHeight == gapHeight;
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
        BoxyId(id: #title, child: title),
        BoxyId(id: #info, child: info),
        BoxyId(id: #seller, child: seller),
      ],
    );
  }
}

class ProductTileDelegate extends BoxyDelegate {
  final ProductTileStyle style;

  ProductTileDelegate({
    required this.style,
  });

  @override
  Size layout() {
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
      titleSize.width,
      titleSize.height + infoSize.height + style.gapHeight,
    );
  }

  @override
  bool shouldRelayout(ProductTileDelegate oldDelegate) =>
      !style.sameLayout(oldDelegate.style);
}
