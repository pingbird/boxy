import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'box_child.dart';
import 'box_delegate.dart';
import 'custom_boxy_base.dart';
import 'inflating_element.dart';
import 'sliver_child.dart';

/// A widget that uses a delegate to control the layout of multiple children.
///
/// This is essentially a more powerful version of [CustomMultiChildLayout],
/// it allows you to inflate, constrain, and lay out each child manually, it
/// also allows the size of the widget to depend on the layout of its children.
///
/// In most cases this is overkill, you may want to check if some combination
/// of [Stack], [LayoutBuilder], [CustomMultiChildLayout], and [Flow] is more
/// suitable.
///
/// Children can be given an id using [BoxyId], otherwise they are given an
/// incrementing int id in the provided order, for example:
///
/// ```dart
/// CustomBoxy(
///   delegate: MyBoxyDelegate(),
///   children: [
///     Container(color: Colors.red)), // Child 0
///     BoxyId(id: #green, child: Container(color: Colors.green)),
///     Container(color: Colors.green)), // Child 1
///   ],
/// );
/// ```
///
/// See also:
///
///  * [BoxyDelegate], the base class of a CustomBoxy delegate.
class CustomBoxy extends LayoutInflatingWidget {
  /// Constructs a CustomBoxy with a delegate and optional set of children.
  const CustomBoxy({
    Key? key,
    required this.delegate,
    List<Widget> children = const <Widget>[],
  }) : super(
    key: key,
    children: children,
  );

  /// The delegate that controls the layout of its children.
  final BoxyDelegate delegate;

  @override
  RenderBoxy createRenderObject(BuildContext context) {
    return RenderBoxy<BoxyChild>(
      delegate: delegate,
      childFactory: defaultChildFactory,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderBoxy renderObject) {
    renderObject.delegate = delegate;
  }

  /// The default child handle factory for [BaseBoxyChild] subclasses,
  /// constructs an appropriate child based on the the generic type argument.
  static T defaultChildFactory<T extends InflatedChildHandle>({
    required Object id,
    required InflatingRenderObjectMixin parent,
    RenderObject? render,
    Widget? widget,
  }) {
    R? expectType<R extends RenderObject>() {
      assert(() {
        if (render != null && render is! R) {
          throw FlutterError(
            'A ${parent.context.widget} widget was given a child of the wrong type: $render\n'
            'Expected child of the type $R\n'
          );
        }
        return true;
      }());
      return render as R?;
    }

    final BaseBoxyChild handle;
    if (render is RenderBox || T == BoxyChild) {
      handle = BoxyChild(
        id: id,
        parent: parent,
        widget: widget,
        render: expectType(),
      );
    } else if (render is RenderSliver || T == SliverBoxyChild) {
      handle = SliverBoxyChild(
        id: id,
        parent: parent,
        widget: widget,
        render: expectType(),
      );
    } else if (T == BaseBoxyChild) {
      handle = BaseBoxyChild(
        id: id,
        parent: parent,
        widget: widget,
        render: render,
      );
    } else {
      throw FlutterError(
        'A ${parent.context.widget} widget was given a child with an unknown type: $render\n'
        'No child factory is available for $T\n'
      );
    }

    return handle as T;
  }
}