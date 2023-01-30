/// This library contains the internal logic of [CustomBoxy], useful if you want
/// to implement a custom [RenderObject] that inflates arbitrary widgets at
/// layout time.
///
/// [InflatingElement] works in a similar fashion to [LayoutBuilder], calling
/// [BuildOwner.buildScope] to create a build scope and
/// [RenderObject.invokeLayoutCallback] to allow tree mutations.
library inflating_element;

export 'src/boxy/inflating_element.dart';
