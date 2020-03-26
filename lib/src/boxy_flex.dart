import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:boxy/src/layout_utils.dart';

import 'dart:math' as math;

/// A widget that displays its children in a one-dimensional array.
///
/// This is identical to [Flex] but accepts [BoxyFlexible] and [Dominant]
/// children.
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
    Key key,
    @required this.direction,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.textBaseline,
    List<Widget> children = const <Widget>[],
  }) : assert(direction != null),
        assert(mainAxisAlignment != null),
        assert(mainAxisSize != null),
        assert(crossAxisAlignment != null),
        assert(verticalDirection != null),
        assert(crossAxisAlignment != CrossAxisAlignment.baseline || textBaseline != null),
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
  final TextDirection textDirection;

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

  /// If aligning items according to their baseline, which baseline to use.
  final TextBaseline textBaseline;

  bool get _needTextDirection {
    assert(direction != null);
    switch (direction) {
      case Axis.horizontal:
        return true; // because it affects the layout order.
      case Axis.vertical:
        assert(crossAxisAlignment != null);
        return crossAxisAlignment == CrossAxisAlignment.start
            || crossAxisAlignment == CrossAxisAlignment.end;
    }
    return null;
  }

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
  TextDirection getEffectiveTextDirection(BuildContext context) {
    return textDirection ?? (_needTextDirection ? Directionality.of(context) : null);
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
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderBoxyFlex renderObject) {
    renderObject
      ..direction = direction
      ..mainAxisAlignment = mainAxisAlignment
      ..mainAxisSize = mainAxisSize
      ..crossAxisAlignment = crossAxisAlignment
      ..textDirection = getEffectiveTextDirection(context)
      ..verticalDirection = verticalDirection
      ..textBaseline = textBaseline;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<Axis>('direction', direction));
    properties.add(EnumProperty<MainAxisAlignment>('mainAxisAlignment', mainAxisAlignment));
    properties.add(EnumProperty<MainAxisSize>('mainAxisSize', mainAxisSize, defaultValue: MainAxisSize.max));
    properties.add(EnumProperty<CrossAxisAlignment>('crossAxisAlignment', crossAxisAlignment));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
    properties.add(EnumProperty<VerticalDirection>('verticalDirection', verticalDirection, defaultValue: VerticalDirection.down));
    properties.add(EnumProperty<TextBaseline>('textBaseline', textBaseline, defaultValue: null));
  }
}

/// A widget that displays its children in a horizontal array.
///
/// This is identical to [Row] but accepts [BoxyFlexible] and [Dominant]
/// children.
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
    Key key,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.stretch,
    TextDirection textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline textBaseline,
    List<Widget> children = const <Widget>[],
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
  );
}

/// A widget that displays its children in a vertical array.
///
/// This is identical to [Row] but accepts [BoxyFlexible] and [Dominant]
/// children.
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
    Key key,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.stretch,
    TextDirection textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline textBaseline,
    List<Widget> children = const <Widget>[],
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
  );
}

/// Parent data for use with [RenderBoxyFlex].
class BoxyFlexParentData extends ContainerBoxParentData<RenderBox> {
  /// The flex factor to use for this child
  ///
  /// If null or zero, the child is inflexible and determines its own size. If
  /// non-zero, the amount of space the child's can occupy in the main axis is
  /// determined by dividing the free space (after placing the inflexible
  /// children) according to the flex factors of the flexible children.
  int flex;

  /// How a flexible child is inscribed into the available space.
  ///
  /// If [flex] is non-zero, the [fit] determines whether the child fills the
  /// space the parent makes available during layout. If the fit is
  /// [FlexFit.tight], the child is required to fill the available space. If the
  /// fit is [FlexFit.loose], the child can be at most as large as the available
  /// space (but is allowed to be smaller).
  FlexFit fit;

  /// Whether this child should determine the maximum cross axis size of every
  /// other child.
  bool dominant;

  @override
  String toString() => '${super.toString()}; flex=$flex; fit=$fit; dominant=$dominant';
}

/// A widget that controls how a child of a [BoxyRow], [BoxyColumn], or
/// [BoxyFlex] flexes.
///
/// This is the same as [Flexible] but has a [dominant] flag.
class BoxyFlexible extends ParentDataWidget<BoxyFlexParentData> {
  /// Creates a widget that controls how a child of a [Row], [Column], or [Flex]
  /// flexes.
  const BoxyFlexible({
    Key key,
    this.flex = 1,
    this.fit = FlexFit.loose,
    this.dominant = false,
    @required Widget child,
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

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is FlexParentData);
    final parentData = renderObject.parentData as FlexParentData;
    bool needsLayout = false;

    if (parentData.flex != flex) {
      parentData.flex = flex;
      needsLayout = true;
    }

    if (parentData.fit != fit) {
      parentData.fit = fit;
      needsLayout = true;
    }

    if (parentData is BoxyFlexParentData) {
      final parentData = renderObject.parentData as BoxyFlexParentData;
      if (parentData.dominant != dominant) {
        parentData.dominant = dominant;
        needsLayout = true;
      }
    }

    if (needsLayout) {
      final AbstractNode targetParent = renderObject.parent;
      if (targetParent is RenderObject)
        targetParent.markNeedsLayout();
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

/// A widget that causes its child to determine the maximum width of every other
/// child in a [BoxyRow], [BoxyColumn], or [BoxyFlex].
class Dominant extends BoxyFlexible {
  /// Creates a widget that expands a child of a [Row], [Column], or [Flex]
  /// so that the child fills the available space along the flex widget's
  /// main axis.
  const Dominant({
    Key key,
    @required Widget child,
  }) : super(
    key: key,
    flex: 0,
    dominant: true,
    child: child,
  );
}

bool _startIsTopLeft(Axis direction, TextDirection textDirection, VerticalDirection verticalDirection) {
  assert(direction != null);
  // If the relevant value of textDirection or verticalDirection is null, this returns null too.
  switch (direction) {
    case Axis.horizontal:
      switch (textDirection) {
        case TextDirection.ltr:
          return true;
        case TextDirection.rtl:
          return false;
      }
      break;
    case Axis.vertical:
      switch (verticalDirection) {
        case VerticalDirection.down:
          return true;
        case VerticalDirection.up:
          return false;
      }
      break;
  }
  return null;
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
class RenderBoxyFlex extends RenderBox with ContainerRenderObjectMixin<RenderBox, FlexParentData>,
    RenderBoxContainerDefaultsMixin<RenderBox, FlexParentData>,
    DebugOverflowIndicatorMixin {
  /// Creates a flex render object.
  ///
  /// By default, the flex layout is horizontal and children are aligned to the
  /// start of the main axis and the center of the cross axis.
  RenderBoxyFlex({
    List<RenderBox> children,
    Axis direction = Axis.horizontal,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    TextDirection textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline textBaseline,
  }) : assert(direction != null),
        assert(mainAxisAlignment != null),
        assert(mainAxisSize != null),
        assert(crossAxisAlignment != null),
        _direction = direction,
        _mainAxisAlignment = mainAxisAlignment,
        _mainAxisSize = mainAxisSize,
        _crossAxisAlignment = crossAxisAlignment,
        _textDirection = textDirection,
        _verticalDirection = verticalDirection,
        _textBaseline = textBaseline {
    addAll(children);
  }

  /// The direction to use as the main axis.
  Axis get direction => _direction;
  Axis _direction;
  set direction(Axis value) {
    assert(value != null);
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
    assert(value != null);
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
    assert(value != null);
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
    assert(value != null);
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
  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
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
  TextBaseline get textBaseline => _textBaseline;
  TextBaseline _textBaseline;
  set textBaseline(TextBaseline value) {
    assert(_crossAxisAlignment != CrossAxisAlignment.baseline || value != null);
    if (_textBaseline != value) {
      _textBaseline = value;
      markNeedsLayout();
    }
  }

  bool get _debugHasNecessaryDirections {
    assert(direction != null);
    assert(crossAxisAlignment != null);
    if (firstChild != null && lastChild != firstChild) {
      // i.e. there's more than one child
      switch (direction) {
        case Axis.horizontal:
          assert(textDirection != null, 'Horizontal $runtimeType with multiple children has a null textDirection, so the layout order is undefined.');
          break;
        case Axis.vertical:
          assert(verticalDirection != null, 'Vertical $runtimeType with multiple children has a null verticalDirection, so the layout order is undefined.');
          break;
      }
    }
    if (mainAxisAlignment == MainAxisAlignment.start ||
        mainAxisAlignment == MainAxisAlignment.end) {
      switch (direction) {
        case Axis.horizontal:
          assert(textDirection != null, 'Horizontal $runtimeType with $mainAxisAlignment has a null textDirection, so the alignment cannot be resolved.');
          break;
        case Axis.vertical:
          assert(verticalDirection != null, 'Vertical $runtimeType with $mainAxisAlignment has a null verticalDirection, so the alignment cannot be resolved.');
          break;
      }
    }
    if (crossAxisAlignment == CrossAxisAlignment.start ||
        crossAxisAlignment == CrossAxisAlignment.end) {
      switch (direction) {
        case Axis.horizontal:
          assert(verticalDirection != null, 'Horizontal $runtimeType with $crossAxisAlignment has a null verticalDirection, so the alignment cannot be resolved.');
          break;
        case Axis.vertical:
          assert(textDirection != null, 'Vertical $runtimeType with $crossAxisAlignment has a null textDirection, so the alignment cannot be resolved.');
          break;
      }
    }
    return true;
  }

  // Set during layout if overflow occurred on the main axis.
  double _overflow;
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

  double _getIntrinsicSize({
    Axis sizingDirection,
    double extent, // the extent in the direction that isn't the sizing direction
    _ChildSizingFunction childSize, // a method to find the size in the sizing direction
  }) {
    if (_direction == sizingDirection) {
      // INTRINSIC MAIN SIZE
      // Intrinsic main size is the smallest size the flex container can take
      // while maintaining the min/max-content contributions of its flex items.
      double totalFlex = 0.0;
      double inflexibleSpace = 0.0;
      double maxFlexFractionSoFar = 0.0;
      RenderBox child = firstChild;
      while (child != null) {
        final int flex = _getFlex(child);
        totalFlex += flex;
        if (flex > 0) {
          final double flexFraction = childSize(child, extent) / _getFlex(child);
          maxFlexFractionSoFar = math.max(maxFlexFractionSoFar, flexFraction);
        } else {
          inflexibleSpace += childSize(child, extent);
        }
        final BoxyFlexParentData childParentData = child.parentData as BoxyFlexParentData;
        child = childParentData.nextSibling;
      }
      return maxFlexFractionSoFar * totalFlex + inflexibleSpace;
    } else {
      // INTRINSIC CROSS SIZE
      // Intrinsic cross size is the max of the intrinsic cross sizes of the
      // children, after the flexible children are fit into the available space,
      // with the children sized using their max intrinsic dimensions.

      // Return the dominant intrinsic size, if any.
      RenderBox child = firstChild;
      RenderBox dominantChild;
      while (child != null) {
        var flex = _getFlex(child);
        if (_getDominant(child)) {
          assert(() {
            if (dominantChild != null) {
              
            }
            return true;
          }());
          if (flex == 0) {
            var mainSize = child.getMaxIntrinsicAxis(_direction, double.infinity);
            return childSize(child, mainSize);
          }
          dominantChild = child;
        }
        final childParentData = child.parentData as BoxyFlexParentData;
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
          double mainSize = child.getMaxIntrinsicAxis(_direction, double.infinity);
          inflexibleSpace += mainSize;
          if (dominantChild == null) {
            maxCrossSize = math.max(maxCrossSize, childSize(child, mainSize));
          }
        }
        final BoxyFlexParentData childParentData = child.parentData as BoxyFlexParentData;
        child = childParentData.nextSibling;
      }

      // Determine the spacePerFlex by allocating the remaining available space.
      // When you're overconstrained spacePerFlex can be negative.
      final double spacePerFlex = math.max(0.0,
        (availableMainSpace - inflexibleSpace) / totalFlex);

      if (dominantChild != null) {
        return childSize(child, spacePerFlex * _getFlex(dominantChild));
      }

      // Size remaining (flexible) items, find the maximum cross size.
      child = firstChild;
      while (child != null) {
        final int flex = _getFlex(child);
        if (flex > 0)
          maxCrossSize = math.max(maxCrossSize, childSize(child, spacePerFlex * flex));
        final BoxyFlexParentData childParentData = child.parentData as BoxyFlexParentData;
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
      childSize: (RenderBox child, double extent) => child.getMinIntrinsicWidth(extent),
    );
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _getIntrinsicSize(
      sizingDirection: Axis.horizontal,
      extent: height,
      childSize: (RenderBox child, double extent) => child.getMaxIntrinsicWidth(extent),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _getIntrinsicSize(
      sizingDirection: Axis.vertical,
      extent: width,
      childSize: (RenderBox child, double extent) => child.getMinIntrinsicHeight(extent),
    );
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _getIntrinsicSize(
      sizingDirection: Axis.vertical,
      extent: width,
      childSize: (RenderBox child, double extent) => child.getMaxIntrinsicHeight(extent),
    );
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
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

  double _getCrossSize(RenderBox child) {
    switch (_direction) {
      case Axis.horizontal:
        return child.size.height;
      case Axis.vertical:
        return child.size.width;
    }
    return null;
  }

  double _getMainSize(RenderBox child) {
    switch (_direction) {
      case Axis.horizontal:
        return child.size.width;
      case Axis.vertical:
        return child.size.height;
    }
    return null;
  }

  @override
  void performLayout() {
    assert(_debugHasNecessaryDirections);
    final BoxConstraints constraints = this.constraints;

    // Determine used flex factor, size inflexible items, calculate free space.
    int totalFlex = 0;
    int totalChildren = 0;
    assert(constraints != null);
    final double maxMainSize = _direction == Axis.horizontal ? constraints.maxWidth : constraints.maxHeight;
    final bool canFlex = maxMainSize < double.infinity;

    RenderBox dominantChild;
    RenderBox child = firstChild;
    bool hasInflexible = false;
    bool intrinsicDominant = false;

    while (child != null) {
      totalChildren++;
      hasInflexible |= _getFlex(child) == 0;
      if (_getDominant(child)) {

        dominantChild = child;
      }
      final childParentData = child.parentData as BoxyFlexParentData;
      child = childParentData.nextSibling;
    }

    double maxCrossSize;
    double crossSize = 0.0;

    if (dominantChild == null) {
      maxCrossSize = constraints.maxCrossAxis(_direction);
    } else {
      intrinsicDominant = _getFlex(dominantChild) != 0 && hasInflexible;
      if (intrinsicDominant) {
        maxCrossSize = constraints.constrainCrossAxis(_direction,
          dominantChild.getMaxIntrinsicCrossAxis(_direction, double.infinity),
        );
      } else {
        dominantChild.layout(constraints.crossAxisConstraints(_direction));
        maxCrossSize = dominantChild.size.crossAxisSize(_direction);
      }
    }

    BoxConstraints innerConstraints = BoxConstraintsAxisUtil.tightFor(
      _direction, cross: maxCrossSize
    );
    double allocatedSize = 0.0; // Sum of the sizes of the non-flexible children.
    RenderBox lastFlexChild;
    child = firstChild;
    while (child != null) {
      final BoxyFlexParentData childParentData = child.parentData as BoxyFlexParentData;
      final int flex = _getFlex(child);
      if (flex > 0) {
        assert(() {
          final String identity = _direction == Axis.horizontal ? 'row' : 'column';
          final String axis = _direction == Axis.horizontal ? 'horizontal' : 'vertical';
          final String dimension = _direction == Axis.horizontal ? 'width' : 'height';
          DiagnosticsNode error, message;
          final List<DiagnosticsNode> addendum = <DiagnosticsNode>[];
          if (!canFlex && (mainAxisSize == MainAxisSize.max || _getFit(child) == FlexFit.tight)) {
            error = ErrorSummary('RenderFlex children have non-zero flex but incoming $dimension constraints are unbounded.');
            message = ErrorDescription(
                'When a $identity is in a parent that does not provide a finite $dimension constraint, for example '
                    'if it is in a $axis scrollable, it will try to shrink-wrap its children along the $axis '
                    'axis. Setting a flex on a child (e.g. using Expanded) indicates that the child is to '
                    'expand to fill the remaining space in the $axis direction.'
            );
            RenderBox node = this;
            switch (_direction) {
              case Axis.horizontal:
                while (!node.constraints.hasBoundedWidth && node.parent is RenderBox)
                  node = node.parent as RenderBox;
                if (!node.constraints.hasBoundedWidth)
                  node = null;
                break;
              case Axis.vertical:
                while (!node.constraints.hasBoundedHeight && node.parent is RenderBox)
                  node = node.parent as RenderBox;
                if (!node.constraints.hasBoundedHeight)
                  node = null;
                break;
            }
            if (node != null) {
              addendum.add(node.describeForError('The nearest ancestor providing an unbounded width constraint is'));
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
                    'cannot simultaneously expand to fit its parent.'
            ),
            ErrorHint(
                'Consider setting mainAxisSize to MainAxisSize.min and using FlexFit.loose fits for the flexible '
                    'children (using Flexible rather than Expanded). This will allow the flexible children '
                    'to size themselves to less than the infinite remaining space they would otherwise be '
                    'forced to take, and then will cause the RenderFlex to shrink-wrap the children '
                    'rather than expanding to fit the maximum constraints provided by the parent.'
            ),
            ErrorDescription(
                'If this message did not help you determine the problem, consider using debugDumpRenderTree():\n'
                    '  https://flutter.dev/debugging/#rendering-layer\n'
                    '  http://api.flutter.dev/flutter/rendering/debugDumpRenderTree.html'
            ),
            describeForError('The affected RenderFlex is', style: DiagnosticsTreeStyle.errorProperty),
            DiagnosticsProperty<dynamic>('The creator information is set to', debugCreator, style: DiagnosticsTreeStyle.errorProperty),
            ...addendum,
            ErrorDescription(
                "If none of the above helps enough to fix this problem, please don't hesitate to file a bug:\n"
                    '  https://github.com/flutter/flutter/issues/new?template=BUG.md'
            ),
          ]);
        }());
        totalFlex += childParentData.flex;
        lastFlexChild = child;
      } else if (child != dominantChild) {
        child.layout(innerConstraints, parentUsesSize: true);
        allocatedSize += _getMainSize(child);
        crossSize = math.max(crossSize, _getCrossSize(child));
      }
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }

    // Distribute free space to flexible children, and determine baseline.
    final double freeSpace = math.max(0.0, (canFlex ? maxMainSize : 0.0) - allocatedSize);
    double allocatedFlexSpace = 0.0;
    double maxBaselineDistance = 0.0;
    if (totalFlex > 0 || crossAxisAlignment == CrossAxisAlignment.baseline) {
      final double spacePerFlex = canFlex && totalFlex > 0 ? (freeSpace / totalFlex) : double.nan;
      child = firstChild;
      double maxSizeAboveBaseline = 0;
      double maxSizeBelowBaseline = 0;
      while (child != null) {
        final int flex = _getFlex(child);
        if (flex > 0) {
          final double maxChildExtent = canFlex ? (child == lastFlexChild ? (freeSpace - allocatedFlexSpace) : spacePerFlex * flex) : double.infinity;
          double minChildExtent;
          switch (_getFit(child)) {
            case FlexFit.tight:
              assert(maxChildExtent < double.infinity);
              minChildExtent = maxChildExtent;
              break;
            case FlexFit.loose:
              minChildExtent = 0.0;
              break;
          }
          assert(minChildExtent != null);

          BoxConstraints flexConstraints =
            BoxConstraintsAxisUtil.create(_direction,
              minCross: maxCrossSize,
              maxCross: crossAxisAlignment == CrossAxisAlignment.stretch ?
                maxCrossSize : 0.0,
              minMain: minChildExtent,
              maxMain: maxChildExtent,
            );

          child.layout(flexConstraints, parentUsesSize: true);
          final double childSize = _getMainSize(child);
          assert(childSize <= maxChildExtent);
          allocatedSize += childSize;
          allocatedFlexSpace += maxChildExtent;
          crossSize = math.max(crossSize, _getCrossSize(child));
        }
        if (crossAxisAlignment == CrossAxisAlignment.baseline) {
          assert(() {
            if (textBaseline == null)
              throw FlutterError('To use FlexAlignItems.baseline, you must also specify which baseline to use using the "baseline" argument.');
            return true;
          }());
          final double distance = child.getDistanceToBaseline(textBaseline, onlyReal: true);
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
            crossSize = maxSizeAboveBaseline + maxSizeBelowBaseline;
          }
        }
        final BoxyFlexParentData childParentData = child.parentData as BoxyFlexParentData;
        child = childParentData.nextSibling;
      }
    }

    // Align items along the main axis.
    final double idealSize = canFlex && mainAxisSize == MainAxisSize.max ? maxMainSize : allocatedSize;
    double actualSize;
    double actualSizeDelta;
    switch (_direction) {
      case Axis.horizontal:
        size = constraints.constrain(Size(idealSize, crossSize));
        actualSize = size.width;
        crossSize = size.height;
        break;
      case Axis.vertical:
        size = constraints.constrain(Size(crossSize, idealSize));
        actualSize = size.height;
        crossSize = size.width;
        break;
    }
    actualSizeDelta = actualSize - allocatedSize;
    _overflow = math.max(0.0, -actualSizeDelta);
    final double remainingSpace = math.max(0.0, actualSizeDelta);
    double leadingSpace;
    double betweenSpace;
    // flipMainAxis is used to decide whether to lay out left-to-right/top-to-bottom (false), or
    // right-to-left/bottom-to-top (true). The _startIsTopLeft will return null if there's only
    // one child and the relevant direction is null, in which case we arbitrarily decide not to
    // flip, but that doesn't have any detectable effect.
    final bool flipMainAxis = !(_startIsTopLeft(direction, textDirection, verticalDirection) ?? true);
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
        betweenSpace = totalChildren > 1 ? remainingSpace / (totalChildren - 1) : 0.0;
        break;
      case MainAxisAlignment.spaceAround:
        betweenSpace = totalChildren > 0 ? remainingSpace / totalChildren : 0.0;
        leadingSpace = betweenSpace / 2.0;
        break;
      case MainAxisAlignment.spaceEvenly:
        betweenSpace = totalChildren > 0 ? remainingSpace / (totalChildren + 1) : 0.0;
        leadingSpace = betweenSpace;
        break;
    }

    // Position elements
    double childMainPosition = flipMainAxis ? actualSize - leadingSpace : leadingSpace;
    child = firstChild;
    while (child != null) {
      final BoxyFlexParentData childParentData = child.parentData as BoxyFlexParentData;
      double childCrossPosition;
      switch (_crossAxisAlignment) {
        case CrossAxisAlignment.start:
        case CrossAxisAlignment.end:
          childCrossPosition = _startIsTopLeft(flipAxis(direction), textDirection, verticalDirection)
              == (_crossAxisAlignment == CrossAxisAlignment.start)
              ? 0.0
              : crossSize - _getCrossSize(child);
          break;
        case CrossAxisAlignment.center:
          childCrossPosition = crossSize / 2.0 - _getCrossSize(child) / 2.0;
          break;
        case CrossAxisAlignment.stretch:
          childCrossPosition = 0.0;
          break;
        case CrossAxisAlignment.baseline:
          childCrossPosition = 0.0;
          if (_direction == Axis.horizontal) {
            assert(textBaseline != null);
            final double distance = child.getDistanceToBaseline(textBaseline, onlyReal: true);
            if (distance != null)
              childCrossPosition = maxBaselineDistance - distance;
          }
          break;
      }
      if (flipMainAxis)
        childMainPosition -= _getMainSize(child);
      switch (_direction) {
        case Axis.horizontal:
          childParentData.offset = Offset(childMainPosition, childCrossPosition);
          break;
        case Axis.vertical:
          childParentData.offset = Offset(childCrossPosition, childMainPosition);
          break;
      }
      if (flipMainAxis) {
        childMainPosition -= betweenSpace;
      } else {
        childMainPosition += _getMainSize(child) + betweenSpace;
      }
      child = childParentData.nextSibling;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, { Offset position }) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_hasOverflow) {
      defaultPaint(context, offset);
      return;
    }

    // There's no point in drawing the children if we're empty.
    if (size.isEmpty)
      return;

    // We have overflow. Clip it.
    context.pushClipRect(needsCompositing, offset, Offset.zero & size, defaultPaint);

    assert(() {
      // Only set this if it's null to save work. It gets reset to null if the
      // _direction changes.
      final List<DiagnosticsNode> debugOverflowHints = <DiagnosticsNode>[
        ErrorDescription(
            'The overflowing $runtimeType has an orientation of $_direction.'
        ),
        ErrorDescription(
            'The edge of the $runtimeType that is overflowing has been marked '
                'in the rendering with a yellow and black striped pattern. This is '
                'usually caused by the contents being too big for the $runtimeType.'
        ),
        ErrorHint(
            'Consider applying a flex factor (e.g. using an Expanded widget) to '
                'force the children of the $runtimeType to fit within the available '
                'space instead of being sized to their natural size.'
        ),
        ErrorHint(
            'This is considered an error condition because it indicates that there '
                'is content that cannot be seen. If the content is legitimately bigger '
                'than the available space, consider clipping it with a ClipRect widget '
                'before putting it in the flex, or using a scrollable container rather '
                'than a Flex, like a ListView.'
        ),
      ];

      // Simulate a child rect that overflows by the right amount. This child
      // rect is never used for drawing, just for determining the overflow
      // location and amount.
      Rect overflowChildRect;
      switch (_direction) {
        case Axis.horizontal:
          overflowChildRect = Rect.fromLTWH(0.0, 0.0, size.width + _overflow, 0.0);
          break;
        case Axis.vertical:
          overflowChildRect = Rect.fromLTWH(0.0, 0.0, 0.0, size.height + _overflow);
          break;
      }
      paintOverflowIndicator(context, offset, Offset.zero & size, overflowChildRect, overflowHints: debugOverflowHints);
      return true;
    }());
  }

  @override
  Rect describeApproximatePaintClip(RenderObject child) => _hasOverflow ? Offset.zero & size : null;

  @override
  String toStringShort() {
    String header = super.toStringShort();
    if (_overflow is double && _hasOverflow)
      header += ' OVERFLOWING';
    return header;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<Axis>('direction', direction));
    properties.add(EnumProperty<MainAxisAlignment>('mainAxisAlignment', mainAxisAlignment));
    properties.add(EnumProperty<MainAxisSize>('mainAxisSize', mainAxisSize));
    properties.add(EnumProperty<CrossAxisAlignment>('crossAxisAlignment', crossAxisAlignment));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
    properties.add(EnumProperty<VerticalDirection>('verticalDirection', verticalDirection, defaultValue: null));
    properties.add(EnumProperty<TextBaseline>('textBaseline', textBaseline, defaultValue: null));
  }
}