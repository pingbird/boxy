/// This library contains the guts of [CustomBoxy], useful if you want to
/// integrate a custom render protocol.
///
/// In most cases digging this deep is not necessary, consider using the
/// [CustomBoxy] widget directly.
library render_boxy;

export 'src/boxy/box_child.dart' hide BoxyChild;
export 'src/boxy/box_delegate.dart' hide BoxBoxyDelegate, BoxyDelegate;
export 'src/boxy/custom_boxy_base.dart'
    hide BaseBoxyChild, BoxyDelegatePhase, BoxyId, BoxyLayerContext, LayerKey;
export 'src/boxy/sliver_child.dart' hide SliverBoxyChild;
export 'src/boxy/sliver_delegate.dart' hide SliverBoxyDelegate;
