//
//  RMMarkerManager.m
//
// Copyright (c) 2008, Route-Me Contributors
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#import "RMMarkerManager.h"
#import "RMMercatorToScreenProjection.h"
#import "RMProjection.h"
#import "RMLayerSet.h"
#import "RMOverlayView.h"

@implementation RMMarkerManager

@synthesize contents;
@synthesize focused;

- (id)initWithContents:(RMMapContents *)mapContents
{
	if (![super init])
		return nil;
	
	contents = mapContents;

	return self;
}

- (void)dealloc
{
	contents = nil;
	[super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark 
#pragma mark Adding / Removing / Displaying Markers

- (void) addMarker: (RMMarker*)marker
{
    marker.manager = self;
	[[contents overlay].markerLayer addSublayer:marker];
}

- (void) addMarker: (RMMarker*)marker AtLatLong:(CLLocationCoordinate2D)point
{
	[marker setLocation:[[contents projection]latLongToPoint:point]];
	[self addMarker: marker];
}

- (void) addDefaultMarkerAt: (CLLocationCoordinate2D)point
{
	RMMarker *marker = [[RMMarker alloc] initWithKey:RMMarkerRedKey];
	[self addMarker:marker AtLatLong:point];
	[marker release];
}

- (void) removeMarkers
{
    for (RMMarker *marker in [[contents overlay].markerLayer sublayers])
    {
        marker.manager = nil;
    }
	[[contents overlay].markerLayer setSublayers:[NSArray arrayWithObjects:nil]]; 
}

- (void) hideAllMarkers 
{
	[[contents overlay] setHidden:YES];
}

- (void) unhideAllMarkers
{
	[[contents overlay] setHidden:NO];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark 
#pragma mark Marker information

- (NSArray *)getMarkers
{
	return [[contents overlay].markerLayer sublayers];
}

- (void) removeMarker:(RMMarker *)marker
{
    marker.manager = nil;
	[[contents overlay].markerLayer removeSublayer:marker];
}

- (void) removeMarkers:(NSArray *)markers
{
    for (RMMarker *marker in markers)
    {
        marker.manager = nil;
    }
	[[contents overlay].markerLayer removeSublayers:markers];
}

- (CGPoint) getMarkerScreenCoordinate: (RMMarker *)marker
{
	return [[contents mercatorToScreenProjection] projectXYPoint:[marker location]];
}

- (CLLocationCoordinate2D) getMarkerCoordinate2D: (RMMarker *) marker
{
	return [contents pixelToLatLong:[self getMarkerScreenCoordinate:marker]];
}

- (NSArray *) getMarkersForScreenBounds
{
	NSMutableArray *markersInScreenBounds = [NSMutableArray array];
	CGRect rect = [[contents mercatorToScreenProjection] screenBounds];
	
	for (RMMarker *marker in [self getMarkers]) {
		if ([self isMarker:marker withinBounds:rect]) {
			[markersInScreenBounds addObject:marker];
		}
	}
	
	return markersInScreenBounds;
}


- (void)focusMarker:(RMMarker*)marker
{
    for (RMMarker *m in [self getMarkers])
    {
        if (m != marker)
        {
            if (m.zPosition != 0)
            {
                m.zPosition = 0;
                [m.markerChangeDelegate marker:m focused:NO];
            }
        }
    }
    marker.zPosition = 1;
    focused = marker;
    [marker.markerChangeDelegate marker:marker focused:YES];
}

- (BOOL) isMarkerWithinScreenBounds:(RMMarker*)marker
{
	return [self isMarker:marker withinBounds:[[contents mercatorToScreenProjection] screenBounds]];
}

- (BOOL) isMarker:(RMMarker*)marker withinBounds:(CGRect)rect
{
	if (![self managingMarker:marker]) {
		return NO;
	}
	
	CGPoint markerCoord = [self getMarkerScreenCoordinate:marker];
	
	if (   markerCoord.x > rect.origin.x
		&& markerCoord.x < rect.origin.x + rect.size.width
		&& markerCoord.y > rect.origin.y
		&& markerCoord.y < rect.origin.y + rect.size.height)
	{
		return YES;
	}
	return NO;
}

- (BOOL) managingMarker:(RMMarker*)marker
{
	if (marker != nil && [[self getMarkers] indexOfObject:marker] != NSNotFound) {
		return YES;
	}
	return NO;
}

- (void) moveMarker:(RMMarker *)marker AtLatLon:(RMLatLong)point
{
	[marker setLocation:[[contents projection]latLongToPoint:point]];
	[marker setPosition:[[contents mercatorToScreenProjection] projectXYPoint:[[contents projection] latLongToPoint:point]]];
    [marker.markerChangeDelegate markerChanged:marker];
}

- (void) moveMarker:(RMMarker *)marker AtXY:(CGPoint)point
{
	[marker setLocation:[[contents mercatorToScreenProjection] projectScreenPointToXY:point]];
	[marker setPosition:point];
    [marker.markerChangeDelegate markerChanged:marker];
}

@end
