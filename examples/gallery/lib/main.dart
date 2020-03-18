import 'package:flutter/material.dart';
import 'package:gallery/pages/product_tile.dart';
import 'package:gallery/pages/tree_view.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

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
    home: MyHomePage(),
    routes: {
      "tree-view": (_) => TreeViewPage(),
      "product-tile": (_) => ProductTilePage(),
    },
  );
}

class DemoTile extends StatelessWidget {
  DemoTile({
    @required this.icon,
    @required this.name,
    @required this.route,
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
      padding: EdgeInsets.only(
        left: 20,
        top: 8,
        bottom: 8,
        right: 16
      ),
    ),
    Text(
      name,
      style: TextStyle(
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

class GalleryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<String> title;
  
  GalleryAppBar(this.title);
  
  build(context) => AppBar(
    leading: title.length == 1 ? null : Padding(child: Material(child: InkWell(
      child: Icon(
        Icons.arrow_back_ios,
        color: NiceColors.text,
        size: 16,
      ),
      onTap: () {
        Navigator.pop(context);
      },
    ),
      color: NiceColors.primary,
      borderRadius: BorderRadius.circular(2),
    ), padding: EdgeInsets.only(
      top: 8,
      bottom: 8,
      left: 8,
    )),
    title: Row(children: [
      for (var i = 0; i < title.length; i++) ...[
        if (i != 0) Padding(
          child: Icon(Icons.arrow_right, color: NiceColors.text.withOpacity(0.5)),
          padding: EdgeInsets.all(8),
        ),
        Text(
          title[i],
          style: TextStyle(
            color: NiceColors.text,
          ),
        ),
      ]
    ]),
    elevation: 0,
  );

  get preferredSize => Size.fromHeight(kToolbarHeight);
}

class MyHomePage extends StatelessWidget {
  build(BuildContext context) => Scaffold(
    appBar: GalleryAppBar(["Boxy gallery"]),
    body: Container(child: ListView(children: [
      Separator(),
      DemoTile(
        icon: MdiIcons.fileTree,
        name: "Tree view",
        route: "tree-view",
      ),
      DemoTile(
        icon: MdiIcons.viewDashboardOutline,
        name: "Product tile",
        route: "product-tile",
      ),
      Separator(),
    ], physics: BouncingScrollPhysics()), color: NiceColors.primary),
  );
}