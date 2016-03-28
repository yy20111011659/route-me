### Things that break applications ###
If you have shipped an app using Route-Me, pay special attention to this section.

The -description method in tile sources, used in the tile caches for determining the tile source, has been renamed as of [r341](https://code.google.com/p/route-me/source/detail?r=341) to -uniqueTilecacheKey, because the 0.4 usage conflicts with the special meaning of -description in Objective-C. Along with that change, mods were made to various tile sources to reflect various sub-types in the tile sources. For instance, Microsoft Virtual Earth can return three different styles of images, but the -uniqueTilecacheKey did not reflect that, so it was possible to have a mixture of satellite and roadmap images in the same tile cache. If you have two app versions that straddle [r341](https://code.google.com/p/route-me/source/detail?r=341), you must clear your tile cache the first time the new version is run. You might also have leftover tiles in the cache in a directory that will never be cleared.

The hash function used for tile caches was changed in [r398](https://code.google.com/p/route-me/source/detail?r=398). Prior to this, there was the possibility of hash collision between two different tile numbers. If you have two app versions that straddle [r398](https://code.google.com/p/route-me/source/detail?r=398), you must clear your tile cache the first time the new version is run.



### API revisions ###

API changes that require modification of client programs will not happen before Route-Me 0.5 is released, but may happen at any time after that.

Method names containing LatLng, LatLong, LatLon, or Location, operating on CLLocationCoordinate2D types, will be standardized to LatitudeLongitude spelling.

The "scale" instance variable and method in various projection-related code actually means, as of version 0.4,  "meters per pixel". Cartographic scale is a pure, dimensionless number, the ratio of a unit on the map to a unit in the real world. For instance, USGS topographic quads are published at 1/24000 scale, often written 1:24000 and colloquially referred to by just the denominator, e.g. "a 24K map" or "the 50K Ordnance Survey maps". "scale" will be refactored to "metersPerPixel".

Route-me is single threaded, from the app developer standpoint (although threads are used internally for image loading). Properties will be checked to correspond to this design.

Excessive prepositions in method names will be removed, and method names will be cleaned up to match standard Objective-C usage and comply with KVC rules. Most methods that begin with the word "get", for instance, will be renamed.

Designated initializers will be indicated for classes that need them. Any method name beginning with -init that is not actually an initializer will be renamed. For instance, RMMapView's -initValues method will be renamed to -performInitializations. Any method names beginning with -set that are not Cocoa Bindings compatible setters will be renamed. Any methods whose names begin with -get but that do not return values by reference will be renamed (e.g. -getScreenCoordinateBounds).

Functionality that relies on retrieving an image with a particular name from the application's main bundle will be removed. It will be replaced by functionality to set that image directly from the client app. The default background image for tile loading, RMMarkerStyles, and RMMarkerBlueKey andd RMMarkerRedKey, will be removed. Cocoa Touch does not provide the hooks needed for the library to guarantee this functionality always works.

Info.plist dependencies will be eliminated, and replaced by methods for run-time configuration of parameters that currently appear there: background image name, tile cache, etc.

### Delegates ###
dragMarkerPosition:onMap:position: will be removed from the RMMapViewDelegate protocol. Use mapView:did/shouldDragMarker:withEvent: instead. Other delegate names in this and other delegate protocols will be renamed to follow the standard Cocoa willSwizzle/shouldSwizzle/didSwizzle convention.

The mere presence of a delegate method will not eliminate the default behavior, except for delegate methods beginning with -should. If the delegate responds to willSwizzle or didSwizzle, the "swizzle" behavior will still take place. If the delegate returns NO from shouldSwizzle, the "swizzle" behavior will not happen.

### RMMapView and RMMapContents ###
All WithLocation: parameters in the various -initWith methods on these two classes will be removed.

Improved initializers for these two classes are present for testing purposes in branches/[issue58](https://code.google.com/p/route-me/issues/detail?id=58) and will be merged into the trunk between 0.4 and 0.5 tags.