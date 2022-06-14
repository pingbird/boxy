## [2.0.6+1]
* Added `BoxyDelegate.renderSize`

## [2.0.6]
* Added `BoxyLayerContext.imageFilter`

## [2.0.5+1]
* Fixed small bug in BoxyChild.paint

## [2.0.5]
* Implemented `BoxyChild.context`

## [2.0.4]
* Fixed an issue with `BoxyId.data` not being applied before first layout

## [2.0.3]
* Fixed an issue with accessing `CustomBoxy` children during intrinsic layout

## [2.0.2]
* Added the `BoxyFlexible.align` constructor

## [2.0.1]
* Added `BoxyFlexIntrinsicsBehavior`
* Fixed an issue with the intrinsic sizing of `BoxyFlex`

## [2.0.0]
* Added sliver support to `CustomBoxy`
* Added `BoxyId`, a replacement of `LayoutId`
* Added the `CustomBoxy.box` and `CustomBoxy.sliver` constructors
* Added the `BoxBoxyDelegate` and `SliverBoxyDelegate` boxy delegates
* Added `SliverBoxyChild` for managing sliver children
* Added the `SliverOffset` and `SliverSize` wrappers
* Added extensions for `SliverConstraints` and `RenderSliver`
* Separated the internal logic of `CustomBoxy` into the `inflating_element` and `render_boxy` libraries
* Bug fixes

## [1.3.0]

* Migrate to null safety
* Added `BoxyChild.parentData`
* Added `LayerKey` and `BoxyLayerContext`
* Added dry layouts
* Added the `Dominant.flexible` and `Dominant.expanded` constructors
* Bug fixes

## [1.2.0+1]

* Transition deprecated `RenderObjectElement` methods (flutter/#63269)

## [1.2.0]

* Bug fixes
* `BoxyChild.layout` no longer sets a default hasSize

## [1.1.1]

* Bug fixes

## [1.1.0]

* Added `SliverContainer` / `SliverCard`
* Added more axis/direction utilities
* Added OverflowPadding
* Bug fixes

## [1.0.1]

* Fixed Flutter SDK version constraints

## [1.0.0] - Initial release