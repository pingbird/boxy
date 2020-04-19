import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:boxy/utils.dart';

class RenderSliverOverlay extends RenderSliver with RenderSliverHelpers {
  RenderSliverOverlay({
    this.foreground,
    this.sliver,
    this.background,
  }) {
    if (foreground != null) adoptChild(foreground);
    if (sliver != null) adoptChild(sliver);
    if (background != null) adoptChild(background);
  }

  void updateChild(RenderObject oldChild, RenderObject newChild) {
    if (oldChild != null) dropChild(oldChild);
    if (newChild != null) adoptChild(newChild);
  }

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
    final geometry = this.geometry = sliver.geometry;
    final boxConstraints = BoxConstraintsAxisUtil.tightFor(
      constraints.axis,
      main: geometry.layoutExtent,
      cross: constraints.crossAxisExtent,
    );
    foreground?.layout(boxConstraints);
    background?.layout(boxConstraints);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (background != null)
      context.paintChild(background, offset);
    if (sliver != null)
      context.paintChild(sliver, offset);
    if (foreground != null)
      context.paintChild(foreground, offset);
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
    return 0.0;
  }
}

class SliverOverlay extends RenderObjectWidget {
  const SliverOverlay({
    Key key,
    this.foreground,
    @required this.sliver,
    this.background,
  }) : super(key: key);

  final Widget foreground;
  final Widget sliver;
  final Widget background;

  createElement() => _SliverOverlayElement(this);

  RenderSliverOverlay createRenderObject(BuildContext context) {
    return RenderSliverOverlay();
  }

  updateRenderObject(BuildContext context, RenderSliverOverlay renderObject) {
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