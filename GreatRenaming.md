# The Great Renaming #

A major goal for Route-Me after version 0.5 is to bring consistency and Objective-C style compliance to the namespace. This document lists the changes that have been made so far.

# pending changes #
Quazie: All magic numbers will become constants.  Depending on the constant new .h files will be created (likely for strings).

Hal: normalizing latLng/latLong etc names.

(code has been altered but not committed)
# completed changes #
## RMMarker, RMMarkerStyle, RMMarkerStyles ##
[r504](https://code.google.com/p/route-me/source/detail?r=504), [r505](https://code.google.com/p/route-me/source/detail?r=505), [r506](https://code.google.com/p/route-me/source/detail?r=506) 24 April 2009

Removed: RMMarkerStyle, RMMarkerStyles, -addDefaultMarkerAt:, RMMarkerBlueKey, RMMarkerRedKey, initWithCGImage, initWithCGImage:anchorPoint, initWithKey, initWithStyle, initWithNamedStyle, -hide/-unhide (on RMMarker), markerImage:, loadPNGFromBundle:, replaceImage:anchorPoint:, replaceKey:, dragMarkerPosition:onMap:position.

Added: +defaultFont (on RMMarker), -replaceUIImage:anchorPoint:.

|setTextLabel:|changeLabelUsingText:|
|:------------|:--------------------|
|setTextLabel:toPosition:|changeLabelUsingText:position:|
|setTextLabel:withFont:withTextColor:withBackgroundColor|changeLabelUsingText:font:foregroundColor:backgroundColor:|
|setTextLabel:toPosition:toPosition:withFont:withTextColor:withBackgroundColor|changeLabelUsingText:position:font:foregroundColor:backgroundColor:|



## scale ##
[r500](https://code.google.com/p/route-me/source/detail?r=500) 22 April 2009

Renamed scale to metersPerPixel, trueScaleDenominator to scaleDenominator.

[r497](https://code.google.com/p/route-me/source/detail?r=497) 22 April 2009

## RMOpenStreetMapsSource ##
Renamed to RMOpenStreetMapSource.

## RMLatLongBounds ##
Renamed to RMSphericalTrapezium. The use of "bounds" throughout Cocoa implies specifying one corner plus a rectangular size, a convention that this `struct` does not follow.

Changed corners to northeast, southwest, so that right-hand rule is respected, and comparisons of two points' relative latitude and longitude can be made in the same order.

## get... style accessors ##

|getMarkers|markers|
|:---------|:------|
|getMarkerScreenCoordinate:|screenCoordinatesForMarker:|
|getMarkerCoordinate2D:|latitudeLongitudeForMarker|
|getNextNativeZoomFactor|nextNativeZoomFactor|
|getCoordinateBounds:|latitudeLongitudeBoundingBoxFor:|
|getScreenCoordinateBounds:|latitudeLongitudeBoundingBoxForScreen|
|getMarkersForScreenBounds|markersWithinScreenBounds|
|getGestureDetails:|gestureDetails: |

## RMXYPoint ##

[r491](https://code.google.com/p/route-me/source/detail?r=491) 22 April 2009

The RMXYPoint struct has been renamed to RMProjectedPoint. Its members x, y are now easting, northing. Most associated structs, functions, and ivars have been renamed appropriately.

If you see x/y references, those are screen coordinates.

|RMXYPoint| RMProjectedPoint|
|:--------|:----------------|
|RMXYSize |RMProjectedSize  |
|RMXYRect | RMProjectedRect |
| RMScaleXYPointAboutPoint|RMScaleProjectedPointAboutPoint()|
| RMScaleXYRectAboutPoint|RMScaleProjectedRectAboutPoint ()|
| RMTranslateXYPointBy|RMTranslateProjectedPointBy ()|
|RMTranslateXYRectBy | RMTranslateProjectedRectBy()|
| RMXYMakePoint ()|  RMMakeProjectedPoint () |
| RMXYMakeRect ()| RMMakeProjectedRect () |
|RMMapView -moveToXYPoint: |-moveToProjectedPoint:|
|RMFractalTileProjection.bounds | planetBounds    |
|RMLayerSet -moveToXYPoint:|-moveToProjectedPoint|
|RMMapContents.XYBounds| projectedBounds |
|RMMapContents -moveToXYPoint:| -moveToProjectedPoint:|
|RMMapContentsFacade -moveToXYPoint:| -moveToProjectedPoint:|
|RMMapLayer.location|projectedLocation|
|RMMarker.location|projectedLocation|
|RMMercatorToScreenProjection.XYBounds|projectedBounds  |
|RMMercatorToScreenProjection.XYCenter|projectedCenter  |
|RMMercatorToScreenProjection.bounds|planetBounds     |
|RMProjection.bounds|planetBounds     |