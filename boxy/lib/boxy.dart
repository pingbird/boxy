/// This library contains [CustomBoxy], a widget that uses a delegate to control
/// the layout of multiple children.
library boxy;

export 'src/boxy/box_child.dart' show BoxyChild;
export 'src/boxy/box_delegate.dart' show BoxBoxyDelegate, BoxyDelegate;
export 'src/boxy/custom_boxy.dart';
export 'src/boxy/custom_boxy_base.dart'
    show BaseBoxyChild, BoxyDelegatePhase, BoxyId, BoxyLayerContext, LayerKey;
export 'src/boxy/sliver_child.dart' show SliverBoxyChild;
export 'src/boxy/sliver_delegate.dart' show SliverBoxyDelegate;
export 'src/sliver_offset.dart';
