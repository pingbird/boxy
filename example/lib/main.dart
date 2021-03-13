import 'package:flutter/material.dart';
import 'package:boxy_gallery/pages/blog_tile.dart';
import 'package:boxy_gallery/pages/boxy_row.dart';
import 'package:boxy_gallery/pages/line_numbers.dart';
import 'package:boxy_gallery/pages/product_tile_simple.dart';
import 'package:boxy_gallery/pages/sliver_container.dart';
import 'package:boxy_gallery/pages/product_tile.dart';
import 'package:boxy_gallery/pages/tree_view.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(MyApp());

class NiceColors {
  static const background = Color(0xff21252b);
  static const primary = Color(0xff282c34);
  static const divider = Color(0xff46494f);
  static const text = Color(0xffcbd3e3);
}

class MyApp extends StatelessWidget {
  build(BuildContext context) => MaterialApp(
    title: 'Boxy gallery',
    theme: ThemeData.dark().copyWith(
      scaffoldBackgroundColor: NiceColors.background,
      primaryColor: NiceColors.primary,
    ),
    routes: {
      '/': (_) => MyHomePage(),
      'tree-view': (_) => TreeViewPage(),
      'product-tile': (_) => ProductTilePage(),
      'product-tile-simple': (_) => ProductTileSimplePage(),
      'boxy-row': (_) => BoxyRowPage(),
      'line-numbers': (_) => LineNumberPage(),
      'blog-tile': (_) => BlogTilePage(),
      'sliver-container': (_) => SliverContainerPage(),
    },
  );
}

class DemoTile extends StatelessWidget {
  const DemoTile({
    required this.icon,
    required this.name,
    required this.route,
  });

  final String name;
  final IconData icon;
  final String route;

  build(context) => Material(child: InkWell(child: Row(children: [
    Container(
      child: Icon(
        icon,
        color: NiceColors.text,
      ),
      padding: const EdgeInsets.only(
        left: 20,
        top: 8,
        bottom: 8,
        right: 16
      ),
    ),
    Text(
      name,
      style: const TextStyle(
        color: NiceColors.text,
        fontSize: 16,
      ),
    ),
  ]), onTap: () {
    Navigator.pushNamed(context, route);
  }), color: NiceColors.background);
}

class Separator extends StatelessWidget {
  build(context) => Container(
    height: 1,
    color: NiceColors.divider,
  );
}

class GalleryAppBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const GalleryAppBarButton(this.icon, this.onTap, {this.tooltip});

  build(context) {
    Widget result = ConstrainedBox(child: Padding(child: Material(child: InkWell(
      child: Icon(
        icon,
        color: NiceColors.text,
        size: 16,
      ),
      onTap: onTap,
    ),
      color: NiceColors.primary,
      borderRadius: BorderRadius.circular(2),
    ), padding: const EdgeInsets.only(
      top: 8,
      bottom: 8,
      left: 8,
    )), constraints: const BoxConstraints(minWidth: 56));

    if (tooltip != null) {
      result = Tooltip(
        message: tooltip!,
        child: result,
      );
    }

    return result;
  }
}

class GalleryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<String> title;
  final String? source;
  final List<Widget>? actions;
  
  const GalleryAppBar(this.title, {this.source, this.actions});
  
  build(context) => AppBar(
    leading: title.length == 1 ? null : GalleryAppBarButton(
      Icons.arrow_back_ios, () {
        Navigator.pushReplacementNamed(context, '/');
      }
    ),
    title: SizedBox(height: kToolbarHeight, child: OverflowBox(
      child: Row(children: [
        for (var i = 0; i < title.length; i++) ...[
          if (i != 0) Padding(
            child: Icon(Icons.arrow_right, color: NiceColors.text.withOpacity(0.5)),
            padding: const EdgeInsets.all(8),
          ),
          Text(
            title[i],
            style: const TextStyle(
              color: NiceColors.text,
            ),
          ),
        ]
      ]),
      alignment: Alignment.centerLeft,
      maxWidth: double.infinity,
    )),
    elevation: 0,
    actions: [
      if (actions != null) ...actions!,
      if (source != null) GalleryAppBarButton(
        Icons.description, () {
          launch(source!);
        }, tooltip: 'Source code',
      ),
      const Padding(padding: EdgeInsets.only(right: 8)),
    ],
  );

  get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class MyHomePage extends StatelessWidget {
  build(BuildContext context) => Scaffold(
    appBar: const GalleryAppBar(['Boxy Gallery']),
    body: Container(child: ListView(children: [
      Separator(),
      const DemoTile(
        icon: MdiIcons.fileTree,
        name: 'Tree View',
        route: 'tree-view',
      ),
      const DemoTile(
        icon: MdiIcons.collage,
        name: 'BoxyRow',
        route: 'boxy-row',
      ),
      const DemoTile(
        icon: MdiIcons.dockBottom,
        name: 'Product Tile',
        route: 'product-tile',
      ),
      const DemoTile(
        icon: MdiIcons.dockBottom,
        name: 'Simple Product Tile',
        route: 'product-tile-simple',
      ),
      const DemoTile(
        icon: MdiIcons.formatListNumbered,
        name: 'Line Numbers',
        route: 'line-numbers',
      ),
      const DemoTile(
        icon: MdiIcons.viewSplitVertical,
        name: 'Blog Tile',
        route: 'blog-tile',
      ),
      const DemoTile(
        icon: MdiIcons.pageLayoutBody,
        name: 'Sliver Container',
        route: 'sliver-container',
      ),
      Separator(),
    ], physics: const BouncingScrollPhysics()), color: NiceColors.primary),
  );
}