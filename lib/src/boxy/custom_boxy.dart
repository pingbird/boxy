import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'box_child.dart';
import 'box_delegate.dart';
import 'custom_boxy_base.dart';
import 'inflating_element.dart';
import 'sliver_child.dart';
import 'sliver_delegate.dart';

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
/// Boxy supports both sliver and box render protocols for its own
/// [RenderObject], and arbitrary children. Which protocols you use is going to
/// affect the constructor and delegate to implement.
///
///  * Use the default constructor and [BoxyDelegate] to create a [RenderBox]
///  that only has [RenderBox] children.
///  * Use the [CustomBoxy.box] constructor and [BoxBoxyDelegate] to implement a
///    [RenderBox] with any child type.
///  * Use the [CustomBoxy.sliver] constructor and [SliverBoxyDelegate] to
///    implement a [RenderSliver] with any child type.
///
/// When implementing a [BoxBoxyDelegate] or [SliverBoxyDelegate], delegates
/// can access [BoxyChild] and [SliverBoxyChild] wrappers by passing type
/// arguments to [BaseBoxyDelegate.getChild], for example:
///
/// ```dart
/// final box = getChild<BoxyChild>(#box);
/// final sliver = getChild<SliverBoxyChild>(#sliver);
/// ```
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
///  * [BoxyDelegate], used with the default constructor.
///  * [BoxBoxyDelegate], used with [CustomBoxy.box].
///  * [SliverBoxyDelegate], used with [CustomBoxy.sliver].
abstract class CustomBoxy extends LayoutInflatingWidget {
  /// Factory function that constructs an appropriate [BaseBoxyChild]
  /// based on the the generic type argument.
  ///
  /// Useful if you have a custom [RenderObject] protocol and want to wrap its
  /// functionality.
  final InflatedChildHandleFactory childFactory;

  /// Constructs a CustomBoxy with [BoxyDelegate] that can manage [BoxyChild]
  /// children.
  const factory CustomBoxy({
    Key? key,
    required BoxyDelegate delegate,
    List<Widget> children,
  }) = _CustomBoxy;

  const CustomBoxy._({
    Key? key,
    List<Widget> children = const <Widget>[],
    required this.childFactory,
  }) : super(
    key: key,
    children: children,
  );

  /// Constructs a CustomBoxy with [BoxBoxyDelegate] that can manage both
  /// [BoxyChild] and [SliverBoxyChild] children.
  const factory CustomBoxy.box({
    Key? key,
    required BoxBoxyDelegate delegate,
    List<Widget> children,
    InflatedChildHandleFactory childFactory,
  }) = _BoxCustomBoxy;

  /// Constructs a CustomBoxy with [SliverBoxyDelegate] that can manage both
  /// [BoxyChild] and [SliverBoxyChild] children.
  const factory CustomBoxy.sliver({
    Key? key,
    required SliverBoxyDelegate delegate,
    List<Widget> children,
    InflatedChildHandleFactory childFactory,
  }) = _SliverCustomBoxy;

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

class _CustomBoxy extends CustomBoxy {
  /// The delegate that controls the layout of its children.
  final BoxyDelegate delegate;

  /// Constructs a CustomBoxy with a delegate and optional set of children.
  const _CustomBoxy({
    Key? key,
    required this.delegate,
    List<Widget> children = const <Widget>[],
    InflatedChildHandleFactory childFactory = CustomBoxy.defaultChildFactory,
  }) : super._(
    key: key,
    children: children,
    childFactory: childFactory,
  );

  @override
  RenderBoxy createRenderObject(BuildContext context) {
    return RenderBoxy<BoxyChild>(
      delegate: delegate,
      childFactory: childFactory,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderBoxy renderObject) {
    renderObject.delegate = delegate;
  }
}

class _BoxCustomBoxy extends CustomBoxy {
  final BoxBoxyDelegate delegate;

  const _BoxCustomBoxy({
    Key? key,
    required this.delegate,
    List<Widget> children = const <Widget>[],
    InflatedChildHandleFactory childFactory = CustomBoxy.defaultChildFactory,
  }) : super._(
    key: key,
    children: children,
    childFactory: childFactory,
  );

  @override
  RenderBoxy createRenderObject(BuildContext context) {
    return RenderBoxy<BaseBoxyChild>(
      delegate: delegate,
      childFactory: childFactory,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderBoxy renderObject) {
    renderObject.delegate = delegate;
  }
}

class _SliverCustomBoxy extends CustomBoxy {
  final SliverBoxyDelegate delegate;

  const _SliverCustomBoxy({
    Key? key,
    required this.delegate,
    List<Widget> children = const <Widget>[],
    InflatedChildHandleFactory childFactory = CustomBoxy.defaultChildFactory,
  }) : super._(
    key: key,
    children: children,
    childFactory: childFactory,
  );

  @override
  RenderSliverBoxy createRenderObject(BuildContext context) {
    return RenderSliverBoxy<BaseBoxyChild>(
      delegate: delegate,
      childFactory: childFactory,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderSliverBoxy renderObject) {
    renderObject.delegate = delegate;
  }
}