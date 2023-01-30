import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'components/palette.dart';
import 'pages/blog_tile.dart';
import 'pages/boxy_row.dart';
import 'pages/line_numbers.dart';
import 'pages/product_tile.dart';
import 'pages/product_tile_simple.dart';
import 'pages/sliver_container.dart';
import 'pages/tree_view.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final darkTheme = ThemeData.dark();

    return MaterialApp(
      title: 'Boxy gallery',
      theme: darkTheme.copyWith(
        scaffoldBackgroundColor: palette.background,
        primaryColor: palette.primary,
        textTheme: darkTheme.textTheme.apply(
          bodyColor: palette.foreground,
          displayColor: palette.foreground,
        ),
        appBarTheme: darkTheme.appBarTheme.copyWith(
          backgroundColor: palette.primary,
        ),
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

  @override
  Material build(context) {
    return Material(
      color: palette.background,
      child: InkWell(
        child: Row(children: [
          Container(
            padding:
                const EdgeInsets.only(left: 20, top: 8, bottom: 8, right: 16),
            child: Icon(
              icon,
            ),
          ),
          Text(
            name,
            style: const TextStyle(fontSize: 16),
          ),
        ]),
        onTap: () {
          Navigator.pushNamed(context, route);
        },
      ),
    );
  }
}

class Separator extends StatelessWidget {
  @override
  Widget build(context) {
    return Container(
      height: 1,
      color: palette.divider,
    );
  }
}

class GalleryAppBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const GalleryAppBarButton(this.icon, this.onTap, {this.tooltip});

  @override
  Widget build(context) {
    Widget result = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 56),
      child: Padding(
        padding: const EdgeInsets.only(
          top: 8,
          bottom: 8,
          left: 8,
        ),
        child: Material(
          color: palette.primary,
          borderRadius: BorderRadius.circular(2),
          child: InkWell(
            onTap: onTap,
            child: Icon(
              icon,
              size: 16,
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      result = Tooltip(
        message: tooltip,
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

  @override
  AppBar build(context) => AppBar(
        leading: title.length == 1
            ? null
            : GalleryAppBarButton(Icons.arrow_back_ios, () {
                Navigator.pushReplacementNamed(context, '/');
              }),
        title: SizedBox(
            height: kToolbarHeight,
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              maxWidth: double.infinity,
              child: Row(children: [
                for (var i = 0; i < title.length; i++) ...[
                  if (i != 0)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_right,
                        color: palette.foreground.withOpacity(0.5),
                      ),
                    ),
                  Text(
                    title[i],
                  ),
                ]
              ]),
            )),
        elevation: 0,
        actions: [
          if (actions != null) ...actions!,
          if (source != null)
            GalleryAppBarButton(
              Icons.description,
              () {
                launchUrl(Uri.parse(source!));
              },
              tooltip: 'Source code',
            ),
          const Padding(padding: EdgeInsets.only(right: 8)),
        ],
      );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class MyHomePage extends StatelessWidget {
  @override
  Scaffold build(BuildContext context) {
    return Scaffold(
      appBar: const GalleryAppBar(['Boxy Gallery']),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
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
        ],
      ),
    );
  }
}
