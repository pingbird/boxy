// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';

class StateCacheController {

}

class StateCache extends StatefulWidget {
  final Widget child;

  const StateCache({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  _StateCacheState createState() => _StateCacheState();

  static StateCacheController? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_InheritedStateCache>()?.controller;
  }
}

class _StateCacheState extends State<StateCache> {
  late final StateCacheController controller;

  @override
  void initState() {
    super.initState();
    controller = StateCacheController();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedStateCache(
      controller: controller,
      child: widget.child,
    );
  }
}

class _InheritedStateCache extends InheritedWidget {
  final StateCacheController controller;

  const _InheritedStateCache({
    Key? key,
    required this.controller,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(_InheritedStateCache oldWidget) {
    return controller != oldWidget.controller;
  }
}
