import 'package:flutter/material.dart';

enum BoxType {
  flat,
  raised,
  outlined,
  sketch,
}

class Box extends StatefulWidget {
  const Box({Key? key}) : super(key: key);

  @override
  State<Box> createState() => _BoxState();
}

class _BoxState extends State<Box> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
