import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:boxy/utils.dart';

class RenderSliverOverlay extends RenderSliver with RenderSliverHelpers {
  RenderSliverOverlay({
    this.foreground,
    this.sliver,
    this.background,
    double bufferExtent,
  }) : this.bufferExtent = bufferExtent ?? 0.0 {
    if (foreground != null) adoptChild(foreground);
    if (sliver != null) adoptChild(sliver);
    if (background != null) adoptChild(background);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    if (foreground != null) foreground.attach(owner);
  }

  @override
  void detach() {
    super.detach();
    if (foreground != null) foreground.detach();
    if (sliver != null) sliver.detach();
    if (background != null) background.detach();
  }

  @override
  void redepthChildren() {
    if (foreground != null) redepthChild(foreground);
    if (sliver != null) redepthChild(sliver);
    if (background != null) redepthChild(background);
  }

  @override
  void setupParentData(RenderObject child) {
    if (!identical(child, sliver)) {
      if (child.parentData is! BoxParentData)
        child.parentData = BoxParentData();
    }
  }

  void updateChild(RenderObject oldChild, RenderObject newChild) {
    if (oldChild != null) dropChild(oldChild);
    if (newChild != null) adoptChild(newChild);
  }

  double bufferExtent;
  RenderBox foreground;
  RenderSliver sliver;
  RenderBox background;

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    if (foreground != null) visitor(foreground);
    if (sliver != null) visitor(sliver);
    if (background != null) visitor(background);
  }

  @override
  void performLayout() {
    assert(sliver != null);
    sliver.layout(constraints, parentUsesSize: true);
    var geometry = this.geometry = sliver.geometry;

    var start = -min(constraints.scrollOffset, bufferExtent);
    var end = min(geometry.maxPaintExtent - constraints.scrollOffset, geometry.paintExtent + bufferExtent);

    if (constraints.scrollOffset > 0) {
      start = min(start, end - bufferExtent * 2);
    } else {
      end = max(end, start + bufferExtent * 2);
    }

    final boxConstraints = BoxConstraintsAxisUtil.tightFor(
      constraints.axis,
      main: end - start,
      cross: constraints.crossAxisExtent,
    );

    final offset = Offset(0, start);

    if (foreground != null) {
      (foreground.parentData as BoxParentData).offset = offset;
      foreground.layout(boxConstraints);
    }

    if (background != null) {
      (background.parentData as BoxParentData).offset = offset;
      background.layout(boxConstraints);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (background != null)
      context.paintChild(background, offset + (background.parentData as BoxParentData).offset);
    if (sliver != null)
      context.paintChild(sliver, offset);
    if (foreground != null)
      context.paintChild(foreground, offset + (foreground.parentData as BoxParentData).offset);
  }

  @override
  bool hitTestChildren(SliverHitTestResult result, {double mainAxisPosition, double crossAxisPosition}) {
    return (foreground != null && hitTestBoxChild(
      BoxHitTestResult.wrap(result),
      foreground,
      mainAxisPosition: mainAxisPosition,
      crossAxisPosition: crossAxisPosition,
    )) || (sliver != null && sliver.geometry.hitTestExtent > 0 && sliver.hitTest(
      result,
      mainAxisPosition: mainAxisPosition,
      crossAxisPosition: crossAxisPosition,
    )) || (background != null && hitTestBoxChild(
      BoxHitTestResult.wrap(result),
      background,
      mainAxisPosition: mainAxisPosition,
      crossAxisPosition: crossAxisPosition,
    ));
  }

  @override
  double childMainAxisPosition(RenderObject child) {
    if (identical(child, sliver)) {
      return 0.0;
    } else {
      return (child.parentData as BoxParentData).offset.dy;
    }
  }
}

class SliverOverlay extends RenderObjectWidget {
  const SliverOverlay({
    Key key,
    this.foreground,
    @required this.sliver,
    this.background,
    double bufferExtent,
  }) :
    this.bufferExtent = bufferExtent ?? 0.0,
    super(key: key);

  final Widget foreground;
  final Widget sliver;
  final Widget background;
  final double bufferExtent;

  createElement() => _SliverOverlayElement(this);

  RenderSliverOverlay createRenderObject(BuildContext context) {
    return RenderSliverOverlay(bufferExtent: bufferExtent);
  }

  updateRenderObject(BuildContext context, RenderSliverOverlay renderObject) {
    renderObject.bufferExtent = bufferExtent;
  }
}

enum _SliverOverlaySlot {
  foreground,
  sliver,
  background,
}

class _SliverOverlayElement extends RenderObjectElement {
  _SliverOverlayElement(SliverOverlay widget) : super(widget);

  Element foreground;
  Element sliver;
  Element background;

  SliverOverlay get widget => super.widget as SliverOverlay;
  RenderSliverOverlay get renderObject => super.renderObject as RenderSliverOverlay;

  visitChildren(ElementVisitor visitor) {
    if (foreground != null) visitor(foreground);
    if (sliver != null) visitor(sliver);
    if (background != null) visitor(background);
  }

  @override
  void forgetChild(Element child) {
    if (identical(foreground, child)) {
      foreground = null;
    } else if (identical(sliver, child)) {
      sliver = null;
    } else if (identical(background, child)) {
      background = null;
    }
    super.forgetChild(child);
  }

  void _updateChildren() {
    foreground = updateChild(foreground, widget.foreground, _SliverOverlaySlot.foreground);
    sliver = updateChild(sliver, widget.sliver, _SliverOverlaySlot.sliver);
    background = updateChild(background, widget.background, _SliverOverlaySlot.background);
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _updateChildren();
  }

  @override
  void update(SliverOverlay newWidget) {
    super.update(newWidget);
    _updateChildren();
  }

  void _updateRenderObject(RenderObject child, _SliverOverlaySlot slot) {
    switch (slot) {
      case _SliverOverlaySlot.foreground:
        renderObject.updateChild(renderObject.foreground, child);
        renderObject.foreground = child;
        break;
      case _SliverOverlaySlot.sliver:
        renderObject.updateChild(renderObject.sliver, child);
        renderObject.sliver = child;
        break;
      case _SliverOverlaySlot.background:
        renderObject.updateChild(renderObject.background, child);
        renderObject.background = child;
        break;
    }
  }

  @override
  void insertChildRenderObject(RenderObject child, dynamic slotValue) {
    _updateRenderObject(child, slotValue as _SliverOverlaySlot);
  }

  @override
  void removeChildRenderObject(RenderObject child) {
    _updateRenderObject(null, renderObject.parentData as _SliverOverlaySlot);
  }

  @override
  void moveChildRenderObject(RenderObject child, dynamic slotValue) {
    assert(false, 'Unreachable');
  }
}