import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'axis_utils.dart';

/// The strategy of determining the cross-axis size of a [BoxyFlex] when
/// intrinsics are required.
enum BoxyFlexIntrinsicsBehavior {
  /// Measure the intrinsic main axis of inflexible children with an infinite
  /// max cross axis size, using it as the max main axis size of the dominant
  /// child.
  measureMain,

  /// Measure the intrinsic cross axis of the dominant child with an infinite
  /// max main axis size.
  measureCross,
}

/// A widget that displays its children in a one-dimensional array.
///
/// This is identical to [Flex] but also accepts [BoxyFlexible] and [Dominant]
/// children. The default crossAxisAlignment is also
/// [CrossAxisAlignment.stretch] instead of [CrossAxisAlignment.center].
///
/// During layout this widget searches for a [Dominant] child, if found the
/// dominant child is layed out first and defines the maximum cross-axis of
/// every non-dominant child in the flex.
///
/// See also:
///
///  * [Flex]
///  * [BoxyRow]
///  * [BoxyColumn]
class BoxyFlex extends MultiChildRenderObjectWidget {
  /// Creates a boxy flex layout.
  ///
  /// The [direction] is required.
  ///
  /// The [direction], [mainAxisAlignment], [crossAxisAlignment], and
  /// [verticalDirection] arguments must not be null. If [crossAxisAlignment] is
  /// [CrossAxisAlignment.baseline], then [textBaseline] must not be null.
  ///
  /// The [textDirection] argument defaults to the ambient [Directionality], if
  /// any. If there is no ambient directionality, and a text direction is going
  /// to be necessary to decide which direction to lay the children in or to
  /// disambiguate `start` or `end` values for the main or cross axis
  /// directions, the [textDirection] must not be null.
  BoxyFlex({
    Key? key,
    required this.direction,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.textBaseline,
    BoxyFlexIntrinsicsBehavior? intrinsicsBehavior,
    List<Widget> children = const <Widget>[],
  })  : intrinsicsBehavior = intrinsicsBehavior ??
            (direction == Axis.vertical
                ? BoxyFlexIntrinsicsBehavior.measureCross
                : BoxyFlexIntrinsicsBehavior.measureMain),
        assert(crossAxisAlignment != CrossAxisAlignment.baseline ||
            textBaseline != null),
        super(key: key, children: children);

  /// The direction to use as the main axis.
  ///
  /// If you know the axis in advance, then consider using a [Row] (if it's
  /// horizontal) or [Column] (if it's vertical) instead of a [Flex], since that
  /// will be less verbose. (For [Row] and [Column] this property is fixed to
  /// the appropriate axis.)
  final Axis direction;

  /// How the children should be placed along the main axis.
  ///
  /// For example, [MainAxisAlignment.start], the default, places the children
  /// at the start (i.e., the left for a [Row] or the top for a [Column]) of the
  /// main axis.
  final MainAxisAlignment mainAxisAlignment;

  /// How much space should be occupied in the main axis.
  ///
  /// After allocating space to children, there might be some remaining free
  /// space. This value controls whether to maximize or minimize the amount of
  /// free space, subject to the incoming layout constraints.
  ///
  /// If some children have a non-zero flex factors (and none have a fit of
  /// [FlexFit.loose]), they will expand to consume all the available space and
  /// there will be no remaining free space to maximize or minimize, making this
  /// value irrelevant to the final layout.
  final MainAxisSize mainAxisSize;

  /// How the children should be placed along the cross axis.
  ///
  /// For example, [CrossAxisAlignment.center], the default, centers the
  /// children in the cross axis (e.g., horizontally for a [Column]).
  final CrossAxisAlignment crossAxisAlignment;

  /// Determines the order to lay children out horizontally and how to interpret
  /// `start` and `end` in the horizontal direction.
  ///
  /// Defaults to the ambient [Directionality].
  ///
  /// If the [direction] is [Axis.horizontal], this controls the order in which
  /// the children are positioned (left-to-right or right-to-left), and the
  /// meaning of the [mainAxisAlignment] property's [MainAxisAlignment.start] and
  /// [MainAxisAlignment.end] values.
  ///
  /// If the [direction] is [Axis.horizontal], and either the
  /// [mainAxisAlignment] is either [MainAxisAlignment.start] or
  /// [MainAxisAlignment.end], or there's more than one child, then the
  /// [textDirection] (or the ambient [Directionality]) must not be null.
  ///
  /// If the [direction] is [Axis.vertical], this controls the meaning of the
  /// [crossAxisAlignment] property's [CrossAxisAlignment.start] and
  /// [CrossAxisAlignment.end] values.
  ///
  /// If the [direction] is [Axis.vertical], and the [crossAxisAlignment] is
  /// either [CrossAxisAlignment.start] or [CrossAxisAlignment.end], then the
  /// [textDirection] (or the ambient [Directionality]) must not be null.
  final TextDirection? textDirection;

  /// Determines the order to lay children out vertically and how to interpret
  /// `start` and `end` in the vertical direction.
  ///
  /// Defaults to [VerticalDirection.down].
  ///
  /// If the [direction] is [Axis.vertical], this controls which order children
  /// are painted in (down or up), the meaning of the [mainAxisAlignment]
  /// property's [MainAxisAlignment.start] and [MainAxisAlignment.end] values.
  ///
  /// If the [direction] is [Axis.vertical], and either the [mainAxisAlignment]
  /// is either [MainAxisAlignment.start] or [MainAxisAlignment.end], or there's
  /// more than one child, then the [verticalDirection] must not be null.
  ///
  /// If the [direction] is [Axis.horizontal], this controls the meaning of the
  /// [crossAxisAlignment] property's [CrossAxisAlignment.start] and
  /// [CrossAxisAlignment.end] values.
  ///
  /// If the [direction] is [Axis.horizontal], and the [crossAxisAlignment] is
  /// either [CrossAxisAlignment.start] or [CrossAxisAlignment.end], then the
  /// [verticalDirection] must not be null.
  final VerticalDirection verticalDirection;

  /// The strategy of determining the cross-axis size of this flex when
  /// intrinsics are required.
  ///
  /// Intrinsics are required iff the following conditions are met:
  ///
  ///  * There is a dominant child
  ///  * At least one child is flexible
  ///  * At least one child is inflexible
  ///
  /// By default, [BoxyFlexIntrinsicsBehavior.measureMain] is used for
  /// horizontal layouts, and [BoxyFlexIntrinsicsBehavior.measureMain] is used
  /// for vertical layouts. These defaults should be sufficient for most
  /// width-in-height-out layouts such as Text.
  final BoxyFlexIntrinsicsBehavior intrinsicsBehavior;

  /// If aligning items according to their baseline, which baseline to use.
  final TextBaseline? textBaseline;

  /// The value to pass to [RenderBoxyFlex.textDirection].
  ///
  /// This value is derived from the [textDirection] property and the ambient
  /// [Directionality]. The value is null if there is no need to specify the
  /// text direction. In practice there's always a need to specify the direction
  /// except for vertical flexes (e.g. [Column]s) whose [crossAxisAlignment] is
  /// not dependent on the text direction (not `start` or `end`). In particular,
  /// a [Row] always needs a text direction because the text direction controls
  /// its layout order. (For [Column]s, the layout order is controlled by
  /// [verticalDirection], which is always specified as it does not depend on an
  /// inherited widget and defaults to [VerticalDirection.down].)
  ///
  /// This method exists so that subclasses of [Flex] that create their own
  /// render objects that are derived from [RenderBoxyFlex] can do so and still use
  /// the logic for providing a text direction only when it is necessary.
  @protected
  TextDirection? getEffectiveTextDirection(BuildContext context) {
    return textDirection ?? Directionality.of(context);
  }

  @override
  RenderBoxyFlex createRenderObject(BuildContext context) {
    return RenderBoxyFlex(
      direction: direction,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: getEffectiveTextDirection(context),
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
      intrinsicsBehavior: intrinsicsBehavior,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderBoxyFlex renderObject) {
    renderObject
      ..direction = direction
      ..mainAxisAlignment = mainAxisAlignment
      ..mainAxisSize = mainAxisSize
      ..crossAxisAlignment = crossAxisAlignment
      ..textDirection = getEffectiveTextDirection(context)
      ..verticalDirection = verticalDirection
      ..textBaseline = textBaseline
      ..intrinsicsBehavior = intrinsicsBehavior;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<Axis>('direction', direction));
    properties.add(EnumProperty<MainAxisAlignment>(
        'mainAxisAlignment', mainAxisAlignment));
    properties.add(EnumProperty<MainAxisSize>('mainAxisSize', mainAxisSize,
        defaultValue: MainAxisSize.max));
    properties.add(EnumProperty<CrossAxisAlignment>(
        'crossAxisAlignment', crossAxisAlignment));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
        defaultValue: null));
    properties.add(EnumProperty<VerticalDirection>(
        'verticalDirection', verticalDirection,
        defaultValue: VerticalDirection.down));
    properties.add(EnumProperty<TextBaseline>('textBaseline', textBaseline,
        defaultValue: null));
  }
}

/// A widget that displays its children in a horizontal array.
///
/// This is identical to [Row] but also accepts [BoxyFlexible] and [Dominant]
/// children. The default crossAxisAlignment is also
/// [CrossAxisAlignment.stretch] instead of [CrossAxisAlignment.center].
///
/// During layout this widget searches for a [Dominant] child, if found the
/// dominant child is layed out first and defines the maximum cross-axis of
/// every non-dominant child in the row.
///
/// Children can override their cross-axis alignment using [BoxyFlexible.align].
///
/// See also:
///
///  * [Row]
///  * [BoxyColumn]
///  * [BoxyFlex]
class BoxyRow extends BoxyFlex {
  /// Creates a horizontal array of children.
  ///
  /// The [direction], [mainAxisAlignment], [mainAxisSize],
  /// [crossAxisAlignment], and [verticalDirection] arguments must not be null.
  /// If [crossAxisAlignment] is [CrossAxisAlignment.baseline], then
  /// [textBaseline] must not be null.
  ///
  /// The [textDirection] argument defaults to the ambient [Directionality], if
  /// any. If there is no ambient directionality, and a text direction is going
  /// to be necessary to determine the layout order (which is always the case
  /// unless the row has no children or only one child) or to disambiguate
  /// `start` or `end` values for the [mainAxisAlignment], the [textDirection]
  /// must not be null.
  BoxyRow({
    Key? key,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.stretch,
    TextDirection? textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline? textBaseline,
    List<Widget> children = const <Widget>[],
    BoxyFlexIntrinsicsBehavior? intrinsicsBehavior,
  }) : super(
          children: children,
          key: key,
          direction: Axis.horizontal,
          mainAxisAlignment: mainAxisAlignment,
          mainAxisSize: mainAxisSize,
          crossAxisAlignment: crossAxisAlignment,
          textDirection: textDirection,
          verticalDirection: verticalDirection,
          textBaseline: textBaseline,
          intrinsicsBehavior: intrinsicsBehavior,
        );
}

/// A widget that displays its children in a vertical array.
///
/// This is identical to [Column] but also accepts [BoxyFlexible] and [Dominant]
/// children. The default crossAxisAlignment is also
/// [CrossAxisAlignment.stretch] instead of [CrossAxisAlignment.center].
///
/// During layout this widget searches for a [Dominant] child, if found the
/// dominant child is layed out first and defines the maximum cross-axis of
/// every non-dominant child in the flex.
///
/// Children can override their cross-axis alignment using [BoxyFlexible.align].
///
///  * [Column]
///  * [BoxyRow]
///  * [BoxyFlex]
class BoxyColumn extends BoxyFlex {
  /// Creates a vertical array of children.
  ///
  /// The [direction], [mainAxisAlignment], [mainAxisSize],
  /// [crossAxisAlignment], and [verticalDirection] arguments must not be null.
  /// If [crossAxisAlignment] is [CrossAxisAlignment.baseline], then
  /// [textBaseline] must not be null.
  ///
  /// The [textDirection] argument defaults to the ambient [Directionality], if
  /// any. If there is no ambient directionality, and a text direction is going
  /// to be necessary to disambiguate `start` or `end` values for the
  /// [crossAxisAlignment], the [textDirection] must not be null.
  BoxyColumn({
    Key? key,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.stretch,
    TextDirection? textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline? textBaseline,
    List<Widget> children = const <Widget>[],
    BoxyFlexIntrinsicsBehavior? intrinsicsBehavior,
  }) : super(
          children: children,
          key: key,
          direction: Axis.vertical,
          mainAxisAlignment: mainAxisAlignment,
          mainAxisSize: mainAxisSize,
          crossAxisAlignment: crossAxisAlignment,
          textDirection: textDirection,
          verticalDirection: verticalDirection,
          textBaseline: textBaseline,
          intrinsicsBehavior: intrinsicsBehavior,
        );
}

/// Parent data for use with [RenderBoxyFlex].
class BoxyFlexParentData extends FlexParentData {
  /// Whether this child should determine the maximum cross axis size of every
  /// other child.
  bool? dominant;

  /// The cross axis alignment of this child, overrides the default alignment
  /// specified by the [BoxyFlex].
  CrossAxisAlignment? crossAxisAlignment;

  // Cached child size used in _computeSizes
  Size? _tempSize;

  // Cached main axis intrinsic size used in _computeSizes
  double? _intrinsicMainSize;

  @override
  String toString() =>
      '${super.toString()}; flex=$flex; fit=$fit; dominant=$dominant';
}

/// A widget that controls how a child of a [BoxyRow], [BoxyColumn], or
/// [BoxyFlex] flexes.
///
/// This is the same as [Flexible] but adds [dominant] and [crossAxisAlignment].
///
/// See also:
///
///  * [Dominant], a convenient wrapper around this widget.
class BoxyFlexible extends ParentDataWidget<FlexParentData> {
  /// Creates a widget that controls how a child of a [Row], [Column], or [Flex]
  /// flexes.
  const BoxyFlexible({
    Key? key,
    this.flex = 1,
    this.fit = FlexFit.loose,
    this.dominant = false,
    this.crossAxisAlignment,
    required Widget child,
  }) : super(key: key, child: child);

  /// Same as the default constructor but has a [flex] factor of 0, and makes
  /// [crossAxisAlignment] a required argument.
  const BoxyFlexible.align({
    Key? key,
    this.flex = 0,
    this.fit = FlexFit.loose,
    this.dominant = false,
    required this.crossAxisAlignment,
    required Widget child,
  }) : super(key: key, child: child);

  /// The flex factor to use for this child
  ///
  /// If null or zero, the child is inflexible and determines its own size. If
  /// non-zero, the amount of space the child's can occupy in the main axis is
  /// determined by dividing the free space (after placing the inflexible
  /// children) according to the flex factors of the flexible children.
  final int flex;

  /// How a flexible child is inscribed into the available space.
  ///
  /// If [flex] is non-zero, the [fit] determines whether the child fills the
  /// space the parent makes available during layout. If the fit is
  /// [FlexFit.tight], the child is required to fill the available space. If the
  /// fit is [FlexFit.loose], the child can be at most as large as the available
  /// space (but is allowed to be smaller).
  final FlexFit fit;

  /// Whether this child should determine the maximum cross axis size of every
  /// other child.
  final bool dominant;

  /// The cross axis alignment of this child, overrides the default alignment
  /// specified by the [BoxyFlex].
  final CrossAxisAlignment? crossAxisAlignment;

  @override
  void applyParentData(RenderObject renderObject) {
    final FlexParentData currentParentData =
        renderObject.parentData as FlexParentData;
    final BoxyFlexParentData parentData;
    if (currentParentData is BoxyFlexParentData) {
      parentData = currentParentData;
    } else {
      parentData = BoxyFlexParentData()
        ..flex = currentParentData.flex
        ..fit = currentParentData.fit;
      renderObject.parentData = parentData;
    }

    bool needsLayout = false;

    if (parentData.flex != flex) {
      parentData.flex = flex;
      needsLayout = true;
    }

    if (parentData.fit != fit) {
      parentData.fit = fit;
      needsLayout = true;
    }

    if (parentData.dominant != dominant) {
      parentData.dominant = dominant;
      needsLayout = true;
    }

    if (parentData.crossAxisAlignment != crossAxisAlignment) {
      parentData.crossAxisAlignment = crossAxisAlignment;
      needsLayout = true;
    }

    if (needsLayout) {
      final AbstractNode? targetParent = renderObject.parent;
      if (targetParent is RenderObject) targetParent.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => Flex;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('flex', flex));
  }
}

/// A widget that causes its own cross axis size to determine the cross axis
/// size of every other child in a [BoxyRow], [BoxyColumn], or [BoxyFlex].
class Dominant extends BoxyFlexible {
  /// Creates a widget that expands a child of a [Row], [Column], or [Flex]
  /// so that the child fills the available space along the flex widget's
  /// main axis.
  ///
  /// This is equivalent to `BoxyFlexible(flex: 0, dominant: true, child: ...)`.
  const Dominant({
    Key? key,
    required Widget child,
  }) : super(
          key: key,
          flex: 0,
          dominant: true,
          child: child,
        );

  /// Same as the default constructor, but expands the child on the main axis
  /// similar to Flexible.
  ///
  /// This is equivalent to `BoxyFlexible(flex: 0, dominant: true, child: ...)`.
  const Dominant.flexible({
    Key? key,
    int flex = 1,
    required Widget child,
  }) : super(
          key: key,
          flex: flex,
          dominant: true,
          child: child,
        );

  /// Same as the default constructor, but expands the child on the main axis
  /// similar to Expanded.
  ///
  /// This is equivalent to
  /// `BoxyFlexible(flex: 1, dominant: true, fit: FlexFit.tight, child: ...)`.
  const Dominant.expanded({
    Key? key,
    int flex = 1,
    required Widget child,
  }) : super(
          key: key,
          flex: flex,
          fit: FlexFit.tight,
          dominant: true,
          child: child,
        );
}

bool? _startIsTopLeft(Axis direction, TextDirection? textDirection,
    VerticalDirection verticalDirection) {
  // If the relevant value of textDirection or verticalDirection is null, this returns null too.
  switch (direction) {
    case Axis.horizontal:
      switch (textDirection) {
        case TextDirection.ltr:
          return true;
        case TextDirection.rtl:
          return false;
        case null:
          return null;
      }
    case Axis.vertical:
      switch (verticalDirection) {
        case VerticalDirection.down:
          return true;
        case VerticalDirection.up:
          return false;
      }
  }
}

typedef _ChildSizingFunction = double Function(RenderBox child, double extent);

/// Displays its children in a one-dimensional array.
///
/// Identical to [RenderFlex] but uses [BoxyFlexParentData] for its parent data.
///
/// See also:
///
///  * [BoxyFlex], the widget equivalent.
///  * [BoxyRow] and [BoxyColumn], direction-specific variants of [BoxyFlex].
class RenderBoxyFlex extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, FlexParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, FlexParentData>,
        DebugOverflowIndicatorMixin {
  /// Creates a flex render object.
  ///
  /// By default, the flex layout is horizontal and children are aligned to the
  /// start of the main axis and the center of the cross axis.
  RenderBoxyFlex({
    List<RenderBox>? children,
    Axis direction = Axis.horizontal,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.stretch,
    TextDirection? textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline? textBaseline,
    BoxyFlexIntrinsicsBehavior? intrinsicsBehavior,
  })  : _direction = direction,
        _mainAxisAlignment = mainAxisAlignment,
        _mainAxisSize = mainAxisSize,
        _crossAxisAlignment = crossAxisAlignment,
        _textDirection = textDirection,
        _verticalDirection = verticalDirection,
        _textBaseline = textBaseline,
        _intrinsicsBehavior = intrinsicsBehavior ??
            (direction == Axis.vertical
                ? BoxyFlexIntrinsicsBehavior.measureCross
                : BoxyFlexIntrinsicsBehavior.measureMain) {
    addAll(children);
  }

  /// The direction to use as the main axis.
  Axis get direction => _direction;
  Axis _direction;
  set direction(Axis value) {
    if (_direction != value) {
      _direction = value;
      markNeedsLayout();
    }
  }

  /// How the children should be placed along the main axis.
  ///
  /// If the [direction] is [Axis.horizontal], and the [mainAxisAlignment] is
  /// either [MainAxisAlignment.start] or [MainAxisAlignment.end], then the
  /// [textDirection] must not be null.
  ///
  /// If the [direction] is [Axis.vertical], and the [mainAxisAlignment] is
  /// either [MainAxisAlignment.start] or [MainAxisAlignment.end], then the
  /// [verticalDirection] must not be null.
  MainAxisAlignment get mainAxisAlignment => _mainAxisAlignment;
  MainAxisAlignment _mainAxisAlignment;
  set mainAxisAlignment(MainAxisAlignment value) {
    if (_mainAxisAlignment != value) {
      _mainAxisAlignment = value;
      markNeedsLayout();
    }
  }

  /// How much space should be occupied in the main axis.
  ///
  /// After allocating space to children, there might be some remaining free
  /// space. This value controls whether to maximize or minimize the amount of
  /// free space, subject to the incoming layout constraints.
  ///
  /// If some children have a non-zero flex factors (and none have a fit of
  /// [FlexFit.loose]), they will expand to consume all the available space and
  /// there will be no remaining free space to maximize or minimize, making this
  /// value irrelevant to the final layout.
  MainAxisSize get mainAxisSize => _mainAxisSize;
  MainAxisSize _mainAxisSize;
  set mainAxisSize(MainAxisSize value) {
    if (_mainAxisSize != value) {
      _mainAxisSize = value;
      markNeedsLayout();
    }
  }

  /// How the children should be placed along the cross axis.
  ///
  /// If the [direction] is [Axis.horizontal], and the [crossAxisAlignment] is
  /// either [CrossAxisAlignment.start] or [CrossAxisAlignment.end], then the
  /// [verticalDirection] must not be null.
  ///
  /// If the [direction] is [Axis.vertical], and the [crossAxisAlignment] is
  /// either [CrossAxisAlignment.start] or [CrossAxisAlignment.end], then the
  /// [textDirection] must not be null.
  CrossAxisAlignment get crossAxisAlignment => _crossAxisAlignment;
  CrossAxisAlignment _crossAxisAlignment;
  set crossAxisAlignment(CrossAxisAlignment value) {
    if (_crossAxisAlignment != value) {
      _crossAxisAlignment = value;
      markNeedsLayout();
    }
  }

  /// Determines the order to lay children out horizontally and how to interpret
  /// `start` and `end` in the horizontal direction.
  ///
  /// If the [direction] is [Axis.horizontal], this controls the order in which
  /// children are positioned (left-to-right or right-to-left), and the meaning
  /// of the [mainAxisAlignment] property's [MainAxisAlignment.start] and
  /// [MainAxisAlignment.end] values.
  ///
  /// If the [direction] is [Axis.horizontal], and either the
  /// [mainAxisAlignment] is either [MainAxisAlignment.start] or
  /// [MainAxisAlignment.end], or there's more than one child, then the
  /// [textDirection] must not be null.
  ///
  /// If the [direction] is [Axis.vertical], this controls the meaning of the
  /// [crossAxisAlignment] property's [CrossAxisAlignment.start] and
  /// [CrossAxisAlignment.end] values.
  ///
  /// If the [direction] is [Axis.vertical], and the [crossAxisAlignment] is
  /// either [CrossAxisAlignment.start] or [CrossAxisAlignment.end], then the
  /// [textDirection] must not be null.
  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (_textDirection != value) {
      _textDirection = value;
      markNeedsLayout();
    }
  }

  /// Determines the order to lay children out vertically and how to interpret
  /// `start` and `end` in the vertical direction.
  ///
  /// If the [direction] is [Axis.vertical], this controls which order children
  /// are painted in (down or up), the meaning of the [mainAxisAlignment]
  /// property's [MainAxisAlignment.start] and [MainAxisAlignment.end] values.
  ///
  /// If the [direction] is [Axis.vertical], and either the [mainAxisAlignment]
  /// is either [MainAxisAlignment.start] or [MainAxisAlignment.end], or there's
  /// more than one child, then the [verticalDirection] must not be null.
  ///
  /// If the [direction] is [Axis.horizontal], this controls the meaning of the
  /// [crossAxisAlignment] property's [CrossAxisAlignment.start] and
  /// [CrossAxisAlignment.end] values.
  ///
  /// If the [direction] is [Axis.horizontal], and the [crossAxisAlignment] is
  /// either [CrossAxisAlignment.start] or [CrossAxisAlignment.end], then the
  /// [verticalDirection] must not be null.
  VerticalDirection get verticalDirection => _verticalDirection;
  VerticalDirection _verticalDirection;
  set verticalDirection(VerticalDirection value) {
    if (_verticalDirection != value) {
      _verticalDirection = value;
      markNeedsLayout();
    }
  }

  /// If aligning items according to their baseline, which baseline to use.
  ///
  /// Must not be null if [crossAxisAlignment] is [CrossAxisAlignment.baseline].
  TextBaseline? get textBaseline => _textBaseline;
  TextBaseline? _textBaseline;
  set textBaseline(TextBaseline? value) {
    assert(_crossAxisAlignment != CrossAxisAlignment.baseline || value != null);
    if (_textBaseline != value) {
      _textBaseline = value;
      markNeedsLayout();
    }
  }

  /// The strategy of determining the cross-axis size of this flex when
  /// intrinsics are required.
  BoxyFlexIntrinsicsBehavior get intrinsicsBehavior => _intrinsicsBehavior;
  BoxyFlexIntrinsicsBehavior _intrinsicsBehavior;
  set intrinsicsBehavior(BoxyFlexIntrinsicsBehavior value) {
    if (_intrinsicsBehavior != value) {
      _intrinsicsBehavior = value;
      markNeedsLayout();
    }
  }

  bool get _debugHasNecessaryDirections {
    if (firstChild != null && lastChild != firstChild) {
      // i.e. there's more than one child
      switch (direction) {
        case Axis.horizontal:
          assert(textDirection != null,
              'Horizontal $runtimeType with multiple children has a null textDirection, so the layout order is undefined.');
          break;
        case Axis.vertical:
          break;
      }
    }
    if (mainAxisAlignment == MainAxisAlignment.start ||
        mainAxisAlignment == MainAxisAlignment.end) {
      switch (direction) {
        case Axis.horizontal:
          assert(textDirection != null,
              'Horizontal $runtimeType with $mainAxisAlignment has a null textDirection, so the alignment cannot be resolved.');
          break;
        case Axis.vertical:
          break;
      }
    }
    if (crossAxisAlignment == CrossAxisAlignment.start ||
        crossAxisAlignment == CrossAxisAlignment.end) {
      switch (direction) {
        case Axis.horizontal:
          break;
        case Axis.vertical:
          assert(textDirection != null,
              'Vertical $runtimeType with $crossAxisAlignment has a null textDirection, so the alignment cannot be resolved.');
          break;
      }
    }
    return true;
  }

  // Set during layout if overflow occurred on the main axis.
  double _overflow = 0.0;
  // Check whether any meaningful overflow is present. Values below an epsilon
  // are treated as not overflowing.
  bool get _hasOverflow => _overflow > precisionErrorTolerance;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! FlexParentData) {
      child.parentData = BoxyFlexParentData();
    } else if (child.parentData is! BoxyFlexParentData) {
      final parentData = child.parentData as FlexParentData;
      child.parentData = BoxyFlexParentData()
        ..flex = parentData.flex
        ..fit = parentData.fit;
    }
  }

  bool get _canComputeIntrinsics =>
      crossAxisAlignment != CrossAxisAlignment.baseline;

  double _getIntrinsicSize({
    required Axis sizingDirection,
    required double
        extent, // the extent in the direction that isn't the sizing direction
    required _ChildSizingFunction
        childSize, // a method to find the size in the sizing direction
  }) {
    if (!_canComputeIntrinsics) {
      // Intrinsics cannot be calculated without a full layout for
      // baseline alignment. Throw an assertion and return 0.0 as documented
      // on [RenderBox.computeMinIntrinsicWidth].
      assert(RenderObject.debugCheckingIntrinsics,
          'Intrinsics are not available for CrossAxisAlignment.baseline.');
      return 0.0;
    }

    if (_direction == sizingDirection) {
      // INTRINSIC MAIN SIZE
      // Intrinsic main size is the smallest size the flex container can take
      // while maintaining the min/max-content contributions of its flex items.
      double totalFlex = 0.0;
      double inflexibleSpace = 0.0;
      double maxFlexFractionSoFar = 0.0;
      RenderBox? child = firstChild;
      while (child != null) {
        final int flex = _getFlex(child);
        totalFlex += flex;
        if (flex > 0) {
          final double flexFraction =
              childSize(child, extent) / _getFlex(child);
          maxFlexFractionSoFar = math.max(maxFlexFractionSoFar, flexFraction);
        } else {
          inflexibleSpace += childSize(child, extent);
        }
        final FlexParentData childParentData =
            child.parentData as FlexParentData;
        child = childParentData.nextSibling;
      }
      return maxFlexFractionSoFar * totalFlex + inflexibleSpace;
    } else {
      // INTRINSIC CROSS SIZE
      // Intrinsic cross size is the max of the intrinsic cross sizes of the
      // children, after the flexible children are fit into the available space,
      // with the children sized using their max intrinsic dimensions.

      // Return the dominant intrinsic size, if any.
      RenderBox? child = firstChild;
      RenderBox? dominantChild;
      while (child != null) {
        final flex = _getFlex(child);
        if (_getDominant(child)) {
          assert(() {
            if (dominantChild != null) {}
            return true;
          }());
          if (flex == 0) {
            final mainSize =
                child.getMaxIntrinsicAxis(_direction, double.infinity);
            return childSize(child, mainSize);
          }
          dominantChild = child;
        }
        final childParentData = child.parentData as FlexParentData;
        child = childParentData.nextSibling;
      }

      // Get inflexible space using the max intrinsic dimensions of fixed children in the main direction.
      final double availableMainSpace = extent;
      int totalFlex = 0;
      double inflexibleSpace = 0.0;
      double maxCrossSize = 0.0;
      child = firstChild;
      while (child != null) {
        final int flex = _getFlex(child);
        totalFlex += flex;
        if (flex == 0) {
          final mainSize =
              child.getMaxIntrinsicAxis(_direction, double.infinity);
          inflexibleSpace += mainSize;
          if (dominantChild == null) {
            maxCrossSize = math.max(maxCrossSize, childSize(child, mainSize));
          }
        }
        final FlexParentData childParentData =
            child.parentData as FlexParentData;
        child = childParentData.nextSibling;
      }

      // Determine the spacePerFlex by allocating the remaining available space.
      // When you're overconstrained spacePerFlex can be negative.
      final double spacePerFlex =
          math.max(0.0, (availableMainSpace - inflexibleSpace) / totalFlex);

      if (dominantChild != null) {
        return childSize(dominantChild, spacePerFlex * _getFlex(dominantChild));
      }

      // Size remaining (flexible) items, find the maximum cross size.
      child = firstChild;
      while (child != null) {
        final int flex = _getFlex(child);
        if (flex > 0)
          maxCrossSize =
              math.max(maxCrossSize, childSize(child, spacePerFlex * flex));
        final FlexParentData childParentData =
            child.parentData as FlexParentData;
        child = childParentData.nextSibling;
      }

      return maxCrossSize;
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _getIntrinsicSize(
      sizingDirection: Axis.horizontal,
      extent: height,
      childSize: (RenderBox child, double extent) =>
          child.getMinIntrinsicWidth(extent),
    );
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _getIntrinsicSize(
      sizingDirection: Axis.horizontal,
      extent: height,
      childSize: (RenderBox child, double extent) =>
          child.getMaxIntrinsicWidth(extent),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _getIntrinsicSize(
      sizingDirection: Axis.vertical,
      extent: width,
      childSize: (RenderBox child, double extent) =>
          child.getMinIntrinsicHeight(extent),
    );
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _getIntrinsicSize(
      sizingDirection: Axis.vertical,
      extent: width,
      childSize: (RenderBox child, double extent) =>
          child.getMaxIntrinsicHeight(extent),
    );
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    if (_direction == Axis.horizontal)
      return defaultComputeDistanceToHighestActualBaseline(baseline);
    return defaultComputeDistanceToFirstActualBaseline(baseline);
  }

  int _getFlex(RenderBox child) {
    final FlexParentData childParentData = child.parentData as FlexParentData;
    return childParentData.flex ?? 0;
  }

  FlexFit _getFit(RenderBox child) {
    final FlexParentData childParentData = child.parentData as FlexParentData;
    return childParentData.fit ?? FlexFit.tight;
  }

  bool _getDominant(RenderBox child) {
    if (child.parentData is! BoxyFlexParentData) return false;
    final childParentData = child.parentData as BoxyFlexParentData;
    return childParentData.dominant ?? false;
  }

  CrossAxisAlignment _getCrossAxisAlignment(RenderBox child) {
    final parentData = child.parentData;
    if (parentData is BoxyFlexParentData) {
      return parentData.crossAxisAlignment ?? crossAxisAlignment;
    }
    return crossAxisAlignment;
  }

  FlutterError? _debugCheckConstraints(
      {required BoxConstraints constraints,
      required bool reportParentConstraints}) {
    FlutterError? result;
    assert(() {
      final double maxMainSize = _direction == Axis.horizontal
          ? constraints.maxWidth
          : constraints.maxHeight;
      final bool canFlex = maxMainSize < double.infinity;
      RenderBox? child = firstChild;
      while (child != null) {
        final int flex = _getFlex(child);
        if (flex > 0) {
          final String identity =
              _direction == Axis.horizontal ? 'row' : 'column';
          final String axis =
              _direction == Axis.horizontal ? 'horizontal' : 'vertical';
          final String dimension =
              _direction == Axis.horizontal ? 'width' : 'height';
          DiagnosticsNode error, message;
          final List<DiagnosticsNode> addendum = <DiagnosticsNode>[];
          if (!canFlex &&
              (mainAxisSize == MainAxisSize.max ||
                  _getFit(child) == FlexFit.tight)) {
            error = ErrorSummary(
                'RenderBoxyFlex children have non-zero flex but incoming $dimension constraints are unbounded.');
            message = ErrorDescription(
                'When a $identity is in a parent that does not provide a finite $dimension constraint, for example '
                'if it is in a $axis scrollable, it will try to shrink-wrap its children along the $axis '
                'axis. Setting a flex on a child (e.g. using Expanded) indicates that the child is to '
                'expand to fill the remaining space in the $axis direction.');
            if (reportParentConstraints) {
              // Constraints of parents are unavailable in dry layout.
              RenderBox? node = this;
              switch (_direction) {
                case Axis.horizontal:
                  while (!node!.constraints.hasBoundedWidth &&
                      node.parent is RenderBox)
                    node = node.parent as RenderBox?;
                  if (!node.constraints.hasBoundedWidth) node = null;
                  break;
                case Axis.vertical:
                  while (!node!.constraints.hasBoundedHeight &&
                      node.parent is RenderBox)
                    node = node.parent as RenderBox?;
                  if (!node.constraints.hasBoundedHeight) node = null;
                  break;
              }
              if (node != null) {
                addendum.add(node.describeForError(
                    'The nearest ancestor providing an unbounded width constraint is'));
              }
            }
            addendum.add(ErrorHint('See also: https://flutter.dev/layout/'));
          } else {
            return true;
          }
          result = FlutterError.fromParts(<DiagnosticsNode>[
            error,
            message,
            ErrorDescription(
                'These two directives are mutually exclusive. If a parent is to shrink-wrap its child, the child '
                'cannot simultaneously expand to fit its parent.'),
            ErrorHint(
                'Consider setting mainAxisSize to MainAxisSize.min and using FlexFit.loose fits for the flexible '
                'children (using Flexible rather than Expanded). This will allow the flexible children '
                'to size themselves to less than the infinite remaining space they would otherwise be '
                'forced to take, and then will cause the RenderBoxyFlex to shrink-wrap the children '
                'rather than expanding to fit the maximum constraints provided by the parent.'),
            ErrorDescription(
                'If this message did not help you determine the problem, consider using debugDumpRenderTree():\n'
                '  https://flutter.dev/debugging/#rendering-layer\n'
                '  https://api.flutter.dev/flutter/rendering/debugDumpRenderTree.html'),
            describeForError('The affected RenderBoxyFlex is',
                style: DiagnosticsTreeStyle.errorProperty),
            DiagnosticsProperty<dynamic>(
                'The creator information is set to', debugCreator,
                style: DiagnosticsTreeStyle.errorProperty),
            ...addendum,
            ErrorDescription(
                "If none of the above helps enough to fix this problem, please don't hesitate to file a bug:\n"
                '  https://github.com/flutter/flutter/issues/new?template=2_bug.md'),
          ]);
          return true;
        }
        child = childAfter(child);
      }
      return true;
    }());
    return result;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    if (!_canComputeIntrinsics) {
      assert(debugCannotComputeDryLayout(
          reason:
              'Dry layout cannot be computed for CrossAxisAlignment.baseline, which requires a full layout.'));
      return Size.zero;
    }
    FlutterError? constraintsError;
    assert(() {
      constraintsError = _debugCheckConstraints(
        constraints: constraints,
        reportParentConstraints: false,
      );
      return true;
    }());
    if (constraintsError != null) {
      assert(debugCannotComputeDryLayout(error: constraintsError));
      return Size.zero;
    }

    final _LayoutSizes sizes = _computeSizes(
      layoutChild: (RenderBox child, BoxConstraints constraints) {
        final size = child.getDryLayout(constraints);
        final childParentData = child.parentData as BoxyFlexParentData;
        childParentData._tempSize = child.size;
        return size;
      },
      constraints: constraints,
    );

    switch (_direction) {
      case Axis.horizontal:
        return constraints.constrain(Size(sizes.mainSize, sizes.crossSize));
      case Axis.vertical:
        return constraints.constrain(Size(sizes.crossSize, sizes.mainSize));
    }
  }

  _LayoutSizes _computeSizes({
    required BoxConstraints constraints,
    required ChildLayouter layoutChild,
  }) {
    int totalFlex = 0;
    final double maxMainSize = _direction == Axis.horizontal
        ? constraints.maxWidth
        : constraints.maxHeight;
    final bool canFlex = maxMainSize < double.infinity;

    RenderBox? dominantChild;
    RenderBox? child = firstChild;
    bool hasInflexible = false;
    bool needsBaseline = false;
    RenderBox? lastFlexChild;

    while (child != null) {
      final int flex = _getFlex(child);

      hasInflexible |= flex == 0;
      if (_getDominant(child)) {
        assert(dominantChild == null);
        dominantChild = child;
      }

      if (_getCrossAxisAlignment(child) == CrossAxisAlignment.baseline) {
        needsBaseline = true;
      }

      if (flex > 0) {
        assert(() {
          final String identity =
              _direction == Axis.horizontal ? 'row' : 'column';
          final String axis =
              _direction == Axis.horizontal ? 'horizontal' : 'vertical';
          final String dimension =
              _direction == Axis.horizontal ? 'width' : 'height';
          DiagnosticsNode error, message;
          final List<DiagnosticsNode> addendum = <DiagnosticsNode>[];
          if (!canFlex &&
              (mainAxisSize == MainAxisSize.max ||
                  _getFit(child!) == FlexFit.tight)) {
            error = ErrorSummary(
                'RenderBoxyFlex children have non-zero flex but incoming $dimension constraints are unbounded.');
            message = ErrorDescription(
                'When a $identity is in a parent that does not provide a finite $dimension constraint, for example '
                'if it is in a $axis scrollable, it will try to shrink-wrap its children along the $axis '
                'axis. Setting a flex on a child (e.g. using Expanded) indicates that the child is to '
                'expand to fill the remaining space in the $axis direction.');
            RenderBox? node = this;
            switch (_direction) {
              case Axis.horizontal:
                while (!node!.constraints.hasBoundedWidth &&
                    node.parent is RenderBox) node = node.parent as RenderBox?;
                if (!node.constraints.hasBoundedWidth) node = null;
                break;
              case Axis.vertical:
                while (!node!.constraints.hasBoundedHeight &&
                    node.parent is RenderBox) node = node.parent as RenderBox?;
                if (!node.constraints.hasBoundedHeight) node = null;
                break;
            }
            if (node != null) {
              addendum.add(node.describeForError(
                  'The nearest ancestor providing an unbounded width constraint is'));
            }
            addendum.add(ErrorHint('See also: https://flutter.dev/layout/'));
          } else {
            return true;
          }
          throw FlutterError.fromParts(<DiagnosticsNode>[
            error,
            message,
            ErrorDescription(
                'These two directives are mutually exclusive. If a parent is to shrink-wrap its child, the child '
                'cannot simultaneously expand to fit its parent.'),
            ErrorHint(
                'Consider setting mainAxisSize to MainAxisSize.min and using FlexFit.loose fits for the flexible '
                'children (using Flexible rather than Expanded). This will allow the flexible children '
                'to size themselves to less than the infinite remaining space they would otherwise be '
                'forced to take, and then will cause the RenderBoxyFlex to shrink-wrap the children '
                'rather than expanding to fit the maximum constraints provided by the parent.'),
            ErrorDescription(
                'If this message did not help you determine the problem, consider using debugDumpRenderTree():\n'
                '  https://flutter.dev/debugging/#rendering-layer\n'
                '  https://api.flutter.dev/flutter/rendering/debugDumpRenderTree.html'),
            describeForError('The affected RenderBoxyFlex is',
                style: DiagnosticsTreeStyle.errorProperty),
            DiagnosticsProperty<dynamic>(
                'The creator information is set to', debugCreator,
                style: DiagnosticsTreeStyle.errorProperty),
            ...addendum,
            ErrorDescription(
                "If none of the above helps enough to fix this problem, please don't hesitate to file a bug:\n"
                '  https://github.com/flutter/flutter/issues/new?template=BUG.md'),
          ]);
        }());

        totalFlex += flex;
        lastFlexChild = child;
      }

      final childParentData = child.parentData as FlexParentData;
      child = childParentData.nextSibling;
    }

    double maxCrossSize = constraints.maxCrossAxis(_direction);
    double crossSize = constraints.minCrossAxis(_direction);
    double allocatedSize = 0.0;
    bool didLayoutDominant = false;
    bool useIntrinsicMain = false;

    if (dominantChild == null) {
      maxCrossSize = constraints.maxCrossAxis(_direction);
    } else {
      final flex = _getFlex(dominantChild);
      if (flex > 0) {
        if (hasInflexible) {
          switch (intrinsicsBehavior) {
            case BoxyFlexIntrinsicsBehavior.measureMain:
              useIntrinsicMain = true;
              break;
            case BoxyFlexIntrinsicsBehavior.measureCross:
              maxCrossSize = constraints.constrainCrossAxis(
                _direction,
                dominantChild.getMaxIntrinsicCrossAxis(
                  _direction,
                  maxCrossSize,
                ),
              );
              break;
          }
        } else {
          final freeSpace =
              math.max(0.0, (canFlex ? maxMainSize : 0.0) - allocatedSize);
          final mainSize = (freeSpace / totalFlex) * flex;
          final childConstraints = constraints.copyWithAxis(
            _direction,
            minMain: mainSize,
            maxMain: mainSize,
          );
          final size = layoutChild(dominantChild, childConstraints);
          maxCrossSize = crossSize = size.crossAxisSize(_direction);
          didLayoutDominant = true;
        }
      } else {
        final size = layoutChild(
            dominantChild, constraints.crossAxisConstraints(_direction));
        maxCrossSize = crossSize = size.crossAxisSize(_direction);
        allocatedSize += size.axisSize(_direction);
      }
    }

    if (useIntrinsicMain) {
      // Measure the intrinsic main-axis size and use that to determine the
      // constraints of the dominant child.
      child = firstChild;
      while (child != null) {
        final BoxyFlexParentData childParentData =
            child.parentData as BoxyFlexParentData;
        final int flex = _getFlex(child);
        if (flex == 0 && child != dominantChild) {
          final mainSize = child.getMaxIntrinsicAxis(_direction, maxCrossSize);
          childParentData._intrinsicMainSize = mainSize;
          allocatedSize += mainSize;
        }
        child = childParentData.nextSibling;
      }

      final freeSpace =
          math.max(0.0, (canFlex ? maxMainSize : 0.0) - allocatedSize);
      final mainSize = (freeSpace / totalFlex) * _getFlex(dominantChild!);
      final size = layoutChild(
          dominantChild,
          BoxConstraintsAxisUtil.create(
            _direction,
            minCross: 0,
            maxCross: maxCrossSize,
            minMain: _getFit(dominantChild) == FlexFit.tight ? mainSize : 0.0,
            maxMain: mainSize,
          ));
      maxCrossSize = crossSize = size.crossAxisSize(_direction);
    } else if (hasInflexible) {
      // Lay out inflexible children to calculate the allocatedSize, giving
      // flexible children their available main axis size.
      child = firstChild;
      while (child != null) {
        final FlexParentData childParentData =
            child.parentData as FlexParentData;
        final int flex = _getFlex(child);
        if (flex == 0 && child != dominantChild) {
          final childConstraints = BoxConstraintsAxisUtil.create(
            _direction,
            minCross:
                _getCrossAxisAlignment(child) == CrossAxisAlignment.stretch
                    ? maxCrossSize
                    : 0.0,
            maxCross: maxCrossSize,
          );
          final size = layoutChild(child, childConstraints);
          allocatedSize += size.axisSize(_direction);
          crossSize = math.max(crossSize, size.crossAxisSize(_direction));
        }
        child = childParentData.nextSibling;
      }
    }

    // Distribute free space to flexible children, and determine baseline.
    var allocatedFlexSpace = 0.0;
    final freeSpace =
        math.max(0.0, (canFlex ? maxMainSize : 0.0) - allocatedSize);
    if (totalFlex > 0 || needsBaseline) {
      final spacePerFlex =
          canFlex && totalFlex > 0 ? (freeSpace / totalFlex) : double.nan;
      child = firstChild;
      while (child != null) {
        final childParentData = child.parentData as BoxyFlexParentData;
        final flex = childParentData.flex ?? 0;
        if (flex > 0) {
          final maxChildExtent = canFlex
              ? (child == lastFlexChild
                  ? (freeSpace - allocatedFlexSpace)
                  : spacePerFlex * flex)
              : double.infinity;
          late final double minChildExtent;
          switch (childParentData.fit ?? FlexFit.tight) {
            case FlexFit.tight:
              assert(maxChildExtent < double.infinity);
              minChildExtent = maxChildExtent;
              break;
            case FlexFit.loose:
              minChildExtent = 0.0;
              break;
          }

          if (child != dominantChild || !didLayoutDominant) {
            BoxConstraints flexConstraints;

            if (child == dominantChild) {
              flexConstraints = BoxConstraintsAxisUtil.create(
                _direction,
                minCross: maxCrossSize,
                maxCross: maxCrossSize,
                minMain: minChildExtent,
                maxMain: maxChildExtent,
              );
            } else {
              flexConstraints = BoxConstraintsAxisUtil.create(
                _direction,
                minCross:
                    _getCrossAxisAlignment(child) == CrossAxisAlignment.stretch
                        ? maxCrossSize
                        : 0.0,
                maxCross: maxCrossSize,
                minMain: minChildExtent,
                maxMain: maxChildExtent,
              );
            }

            layoutChild(child, flexConstraints);
          }

          final double childSize =
              childParentData._tempSize!.axisSize(_direction);
          assert(() {
            if (!(childSize <= maxChildExtent)) {
              return false;
            }
            return true;
          }());
          allocatedSize += childSize;
          allocatedFlexSpace += maxChildExtent;
          crossSize = math.max(
              crossSize, childParentData._tempSize!.crossAxisSize(_direction));
        } else if (useIntrinsicMain) {
          // Lay out inflexible children late, since we used the last pass to
          // measure their intrinsic main axis size.
          final mainSize = childParentData._intrinsicMainSize!;
          layoutChild(
              child,
              BoxConstraintsAxisUtil.create(
                _direction,
                minCross:
                    _getCrossAxisAlignment(child) == CrossAxisAlignment.stretch
                        ? maxCrossSize
                        : 0.0,
                maxCross: maxCrossSize,
                minMain: mainSize,
                maxMain: mainSize,
              ));
        }
        child = childParentData.nextSibling;
      }
    }

    return _LayoutSizes(
      mainSize: canFlex && mainAxisSize == MainAxisSize.max
          ? maxMainSize
          : allocatedSize,
      crossSize: crossSize,
      allocatedSize: allocatedSize,
      needsBaseline: needsBaseline,
    );
  }

  @override
  void performLayout() {
    assert(_debugHasNecessaryDirections);
    final BoxConstraints constraints = this.constraints;

    final _sizes = _computeSizes(
      constraints: constraints,
      layoutChild: (child, constraints) {
        child.layout(constraints, parentUsesSize: true);
        final childParentData = child.parentData as BoxyFlexParentData;
        childParentData._tempSize = child.size;
        return child.size;
      },
    );

    var crossSize = _sizes.crossSize;
    var maxBaselineDistance = 0.0;
    if (_sizes.needsBaseline) {
      var child = firstChild;
      double maxSizeAboveBaseline = 0;
      double maxSizeBelowBaseline = 0;
      while (child != null) {
        assert(() {
          if (textBaseline == null)
            throw FlutterError(
                'To use FlexAlignItems.baseline, you must also specify which baseline to use using the "baseline" argument.');
          return true;
        }());
        final double? distance =
            child.getDistanceToBaseline(textBaseline!, onlyReal: true);
        if (distance != null) {
          maxBaselineDistance = math.max(maxBaselineDistance, distance);
          maxSizeAboveBaseline = math.max(
            distance,
            maxSizeAboveBaseline,
          );
          maxSizeBelowBaseline = math.max(
            child.size.height - distance,
            maxSizeBelowBaseline,
          );
          crossSize =
              math.max(maxSizeAboveBaseline + maxSizeBelowBaseline, crossSize);
        }
        final FlexParentData childParentData =
            child.parentData as FlexParentData;
        child = childParentData.nextSibling;
      }
    }

    // Align items along the main axis.
    final mainSize = _sizes.mainSize;
    size = SizeAxisUtil.create(_direction, crossSize, mainSize);
    final actualSize = size.axisSize(_direction);
    final actualSizeDelta = actualSize - _sizes.allocatedSize;
    _overflow = math.max(0.0, -actualSizeDelta);
    final remainingSpace = math.max(0.0, actualSizeDelta);
    late double leadingSpace;
    late double betweenSpace;

    // flipMainAxis is used to decide whether to lay out left-to-right/top-to-bottom (false), or
    // right-to-left/bottom-to-top (true). The _startIsTopLeft will return null if there's only
    // one child and the relevant direction is null, in which case we arbitrarily decide not to
    // flip, but that doesn't have any detectable effect.
    final bool flipMainAxis =
        !(_startIsTopLeft(direction, textDirection, verticalDirection) ?? true);
    switch (_mainAxisAlignment) {
      case MainAxisAlignment.start:
        leadingSpace = 0.0;
        betweenSpace = 0.0;
        break;
      case MainAxisAlignment.end:
        leadingSpace = remainingSpace;
        betweenSpace = 0.0;
        break;
      case MainAxisAlignment.center:
        leadingSpace = remainingSpace / 2.0;
        betweenSpace = 0.0;
        break;
      case MainAxisAlignment.spaceBetween:
        leadingSpace = 0.0;
        betweenSpace = childCount > 1 ? remainingSpace / (childCount - 1) : 0.0;
        break;
      case MainAxisAlignment.spaceAround:
        betweenSpace = childCount > 0 ? remainingSpace / childCount : 0.0;
        leadingSpace = betweenSpace / 2.0;
        break;
      case MainAxisAlignment.spaceEvenly:
        betweenSpace = childCount > 0 ? remainingSpace / (childCount + 1) : 0.0;
        leadingSpace = betweenSpace;
        break;
    }

    // Position elements
    double childMainPosition =
        flipMainAxis ? actualSize - leadingSpace : leadingSpace;
    var child = firstChild;
    while (child != null) {
      final FlexParentData childParentData = child.parentData as FlexParentData;
      final double childCrossPosition;
      final childCrossAxisAlignment = _getCrossAxisAlignment(child);
      switch (childCrossAxisAlignment) {
        case CrossAxisAlignment.start:
        case CrossAxisAlignment.end:
          childCrossPosition = _startIsTopLeft(
                      flipAxis(direction), textDirection!, verticalDirection) ==
                  (childCrossAxisAlignment == CrossAxisAlignment.start)
              ? 0.0
              : crossSize - child.size.crossAxisSize(_direction);
          break;
        case CrossAxisAlignment.center:
          childCrossPosition =
              crossSize / 2.0 - child.size.crossAxisSize(_direction) / 2.0;
          break;
        case CrossAxisAlignment.stretch:
          childCrossPosition = 0.0;
          break;
        case CrossAxisAlignment.baseline:
          if (_direction == Axis.horizontal) {
            assert(textBaseline != null);
            final double? distance =
                child.getDistanceToBaseline(textBaseline!, onlyReal: true);
            if (distance != null)
              childCrossPosition = maxBaselineDistance - distance;
            else
              childCrossPosition = 0.0;
          } else {
            childCrossPosition = 0.0;
          }
          break;
      }
      if (flipMainAxis) childMainPosition -= child.size.axisSize(_direction);

      childParentData.offset = OffsetAxisUtil.create(
        _direction,
        childCrossPosition,
        childMainPosition,
      );

      if (flipMainAxis) {
        childMainPosition -= betweenSpace;
      } else {
        childMainPosition += child.size.axisSize(_direction) + betweenSpace;
      }
      child = childParentData.nextSibling;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_hasOverflow) {
      defaultPaint(context, offset);
      return;
    }

    // There's no point in drawing the children if we're empty.
    if (size.isEmpty) return;

    // We have overflow. Clip it.
    context.pushClipRect(
        needsCompositing, offset, Offset.zero & size, defaultPaint);

    assert(() {
      // Only set this if it's null to save work. It gets reset to null if the
      // _direction changes.
      final List<DiagnosticsNode> debugOverflowHints = <DiagnosticsNode>[
        ErrorDescription(
            'The overflowing $runtimeType has an orientation of $_direction.'),
        ErrorDescription(
            'The edge of the $runtimeType that is overflowing has been marked '
            'in the rendering with a yellow and black striped pattern. This is '
            'usually caused by the contents being too big for the $runtimeType.'),
        ErrorHint(
            'Consider applying a flex factor (e.g. using an Expanded widget) to '
            'force the children of the $runtimeType to fit within the available '
            'space instead of being sized to their natural size.'),
        ErrorHint(
            'This is considered an error condition because it indicates that there '
            'is content that cannot be seen. If the content is legitimately bigger '
            'than the available space, consider clipping it with a ClipRect widget '
            'before putting it in the flex, or using a scrollable container rather '
            'than a Flex, like a ListView.'),
      ];

      // Simulate a child rect that overflows by the right amount. This child
      // rect is never used for drawing, just for determining the overflow
      // location and amount.
      late Rect overflowChildRect;
      switch (_direction) {
        case Axis.horizontal:
          overflowChildRect =
              Rect.fromLTWH(0.0, 0.0, size.width + _overflow, 0.0);
          break;
        case Axis.vertical:
          overflowChildRect =
              Rect.fromLTWH(0.0, 0.0, 0.0, size.height + _overflow);
          break;
      }
      paintOverflowIndicator(
          context, offset, Offset.zero & size, overflowChildRect,
          overflowHints: debugOverflowHints);
      return true;
    }());
  }

  @override
  Rect? describeApproximatePaintClip(RenderObject child) =>
      _hasOverflow ? Offset.zero & size : null;

  @override
  String toStringShort() {
    String header = super.toStringShort();
    if (_overflow is double && _hasOverflow) header += ' OVERFLOWING';
    return header;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<Axis>('direction', direction));
    properties.add(EnumProperty<MainAxisAlignment>(
        'mainAxisAlignment', mainAxisAlignment));
    properties.add(EnumProperty<MainAxisSize>('mainAxisSize', mainAxisSize));
    properties.add(EnumProperty<CrossAxisAlignment>(
        'crossAxisAlignment', crossAxisAlignment));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
        defaultValue: null));
    properties.add(EnumProperty<VerticalDirection>(
        'verticalDirection', verticalDirection,
        defaultValue: null));
    properties.add(EnumProperty<TextBaseline>('textBaseline', textBaseline,
        defaultValue: null));
  }
}

class _LayoutSizes {
  const _LayoutSizes({
    required this.mainSize,
    required this.crossSize,
    required this.allocatedSize,
    required this.needsBaseline,
  });

  final double mainSize;
  final double crossSize;
  final double allocatedSize;
  final bool needsBaseline;
}
