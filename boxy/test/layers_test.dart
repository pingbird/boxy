import 'package:boxy/boxy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

class OpacityBoxy extends BoxyDelegate {
  final ValueNotifier<double> opacity;

  OpacityBoxy({
    required this.opacity,
  }) : super(repaint: opacity);

  @override
  Size layout() {
    layoutData ??= LayerKey();
    return super.layout();
  }

  LayerKey get layerKey => layoutData! as LayerKey;

  @override
  void paintChildren() {
    layers.opacity(opacity: opacity.value, paint: super.paint, key: layerKey);
  }

  @override
  bool shouldRepaint(OpacityBoxy oldDelegate) => opacity != oldDelegate.opacity;
}

void main() {
  testWidgets('Opacity test', (tester) async {
    final opacity = ValueNotifier(1.0);

    await tester.pumpWidget(
      CustomBoxy(
        key: const GlobalObjectKey(#boxy),
        delegate: OpacityBoxy(opacity: opacity),
        children: const [
          DecoratedBox(
            decoration: BoxDecoration(color: Colors.blue),
            child: SizedBox(width: 10, height: 10),
          ),
        ],
      ),
    );

    OpacityLayer getLayer() {
      final rootLayer =
          // ignore: invalid_use_of_protected_member
          RendererBinding.instance.renderView.layer! as TransformLayer;
      final pictureLayer = rootLayer.firstChild! as PictureLayer;
      return pictureLayer.nextSibling! as OpacityLayer;
    }

    final originalLayer = getLayer();
    expect(originalLayer.alpha, 255);

    opacity.value = 0.5;
    await tester.pumpAndSettle();

    final newLayer = getLayer();
    expect(newLayer, originalLayer);
    expect(newLayer.alpha, 128);
  });
}
