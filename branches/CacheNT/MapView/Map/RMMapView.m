//
//  RMMapView.m
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

#import "RMMapView.h"
#import "RMMapContents.h"
#import "RMMapViewDelegate.h"

#import "RMTileLoader.h"

#import "RMMercatorToScreenProjection.h"
#import "RMMarker.h"

#import "RMMarkerManager.h"

@interface RMMapView (PrivateMethods)
// methods for post-touch deceleration, ala UIScrollView
- (void)startDecelerationWithDelta:(CGSize)delta;
- (void)incrementDeceleration:(NSTimer *)timer;
- (void)stopDeceleration;
@end

@implementation RMMapView (Internal)
	BOOL delegateHasBeforeMapMove;
	BOOL delegateHasAfterMapMove;
	BOOL delegateHasBeforeMapZoomByFactor;
	BOOL delegateHasAfterMapZoomByFactor;
	BOOL delegateHasDoubleTapOnMap;
	BOOL delegateHasSingleTapOnMap;
	BOOL delegateHasTapOnMarker;
	BOOL delegateHasTapOnLabelForMarker;
	BOOL delegateHasAfterMapTouch;
	BOOL delegateHasDragMarkerPosition;
	NSTimer *decelerationTimer;
	CGSize decelerationDelta;
@end

@implementation RMMapView
@synthesize decelerationFactor;
@synthesize deceleration;

- (RMMarkerManager*)markerManager
{
  return contents.markerManager;
}

-(void) initValues:(CLLocationCoordinate2D)latlong
{
	if(round(latlong.latitude) != 0 && round(latlong.longitude) != 0)
	{
		contents = [[RMMapContents alloc] initForView:self WithLocation:latlong];
	}else
	{
		contents = [[RMMapContents alloc] initForView:self];
	}
	
	enableDragging = YES;
	enableZoom = YES;
	decelerationFactor = 0.88f;
	deceleration = NO;
	
	//	[self recalculateImageSet];
	
	if (enableZoom)
		[self setMultipleTouchEnabled:TRUE];
	
	self.backgroundColor = [UIColor grayColor];
	
//	[[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (id)initWithFrame:(CGRect)frame
{
	CLLocationCoordinate2D latlong;
	
	if (self = [super initWithFrame:frame]) {
		[self initValues:latlong];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame WithLocation:(CLLocationCoordinate2D)latlong
{
	if (self = [super initWithFrame:frame]) {
		[self initValues:latlong];
	}
	return self;
}

- (void)awakeFromNib
{
	CLLocationCoordinate2D latlong = {0, 0};
	[super awakeFromNib];
	[self initValues:latlong];
}

-(void) dealloc
{
	[contents release];
	[super dealloc];
}

-(void) drawRect: (CGRect) rect
{
	[contents drawRect:rect];
}

-(NSString*) description
{
	CGRect bounds = [self bounds];
	return [NSString stringWithFormat:@"MapView at %.0f,%.0f-%.0f,%.0f", bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height];
}

-(RMMapContents*) contents
{
	return [[contents retain] autorelease];
}

// Forward invocations to RMMapContents
- (void)forwardInvocation:(NSInvocation *)invocation
{
    SEL aSelector = [invocation selector];
	
    if ([contents respondsToSelector:aSelector])
        [invocation invokeWithTarget:contents];
    else
        [self doesNotRecognizeSelector:aSelector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	if ([super respondsToSelector:aSelector])
		return [super methodSignatureForSelector:aSelector];
	else
		return [contents methodSignatureForSelector:aSelector];
}

#pragma mark Delegate 

@dynamic delegate;

- (void) setDelegate: (id<RMMapViewDelegate>) _delegate
{
	if (delegate == _delegate) return;
	delegate = _delegate;
	
	delegateHasBeforeMapMove = [(NSObject*) delegate respondsToSelector: @selector(beforeMapMove:)];
	delegateHasAfterMapMove  = [(NSObject*) delegate respondsToSelector: @selector(afterMapMove:)];
	
	delegateHasBeforeMapZoomByFactor = [(NSObject*) delegate respondsToSelector: @selector(beforeMapZoom: byFactor: near:)];
	delegateHasAfterMapZoomByFactor  = [(NSObject*) delegate respondsToSelector: @selector(afterMapZoom: byFactor: near:)];

	delegateHasDoubleTapOnMap = [(NSObject*) delegate respondsToSelector: @selector(doubleTapOnMap:At:)];
	delegateHasSingleTapOnMap = [(NSObject*) delegate respondsToSelector: @selector(singleTapOnMap:At:)];
	
	delegateHasTapOnMarker = [(NSObject*) delegate respondsToSelector:@selector(tapOnMarker:onMap:)];
	delegateHasTapOnLabelForMarker = [(NSObject*) delegate respondsToSelector:@selector(tapOnLabelForMarker:onMap:)];
	
	delegateHasAfterMapTouch  = [(NSObject*) delegate respondsToSelector: @selector(afterMapTouch:)];
	
	delegateHasDragMarkerPosition = [(NSObject*) delegate respondsToSelector: @selector(dragMarkerPosition: onMap: position:)];
}

- (id<RMMapViewDelegate>) delegate
{
	return delegate;
}

#pragma mark Movement

-(void) moveToXYPoint: (RMXYPoint) aPoint
{
	if (delegateHasBeforeMapMove) [delegate beforeMapMove: self];
	[contents moveToXYPoint:aPoint];
	if (delegateHasAfterMapMove) [delegate afterMapMove: self];
}
-(void) moveToLatLong: (CLLocationCoordinate2D) point
{
	if (delegateHasBeforeMapMove) [delegate beforeMapMove: self];
	[contents moveToLatLong:point];
	if (delegateHasAfterMapMove) [delegate afterMapMove: self];
}

- (void)moveBy: (CGSize) delta
{
	if (delegateHasBeforeMapMove) [delegate beforeMapMove: self];
	[contents moveBy:delta];
	if (delegateHasAfterMapMove) [delegate afterMapMove: self];
}
- (void)zoomByFactor: (double) zoomFactor near:(CGPoint) center
{
	[self zoomByFactor:zoomFactor near:center animated:NO];
}
- (void)zoomByFactor: (double) zoomFactor near:(CGPoint) center animated:(BOOL)animated
{
	if (delegateHasBeforeMapZoomByFactor) [delegate beforeMapZoom: self byFactor: zoomFactor near: center];
	[contents zoomByFactor:zoomFactor near:center animated:animated withCallback:(animated && delegateHasAfterMapZoomByFactor)?self:nil];
	if (!animated)
		if (delegateHasAfterMapZoomByFactor) [delegate afterMapZoom: self byFactor: zoomFactor near: center];
}


#pragma mark RMMapContentsAnimationCallback methods

- (void)animationFinishedWithZoomFactor:(float)zoomFactor near:(CGPoint)p
{
	if (delegateHasAfterMapZoomByFactor)
		[delegate afterMapZoom: self byFactor: zoomFactor near: p];
}


#pragma mark Event handling

- (RMGestureDetails) getGestureDetails: (NSSet*) touches
{
	RMGestureDetails gesture;
	gesture.center.x = gesture.center.y = 0;
	gesture.averageDistanceFromCenter = 0;
	int activeTouches = 0;
	int interestingTouches = 0;
	
	for (UITouch *touch in touches)
	{
		activeTouches++;
		UITouchPhase phase = [touch phase];
		switch(phase){
			case UITouchPhaseBegan:
			case UITouchPhaseMoved:
			case UITouchPhaseStationary:
			break;
			case UITouchPhaseEnded:
			case UITouchPhaseCancelled:
			activeTouches--;
			/* FALLTHROUGH */
		default:
			continue;
			break;
		}
		//		NSLog(@"phase = %d", [touch phase]);
		
		interestingTouches++;
		
		CGPoint location = [touch locationInView: self];
		
		gesture.center.x += location.x;
		gesture.center.y += location.y;
	}

	switch (activeTouches){
		case 0:
		if (isMultiTouch) {
			isMultiTouch = NO;
			[contents multiTouchEnded];
		}
		if (isTouched) {
			isTouched = NO;
			[contents touchesEnded];
		}
		break;
		case 1:
		if (!isTouched) {
			isTouched = YES;
			[contents touchesBegan];
		}
		if (isMultiTouch) {
			isMultiTouch = NO;
			[contents multiTouchEnded];
		}
		break;
	default:
		if (!isTouched){
			isTouched = YES;
			[contents touchesBegan];
		}
		if (!isMultiTouch){
			isMultiTouch = YES;
			[contents multiTouchBegan];
		}
		break;
	}
//	NSLog(@"Active Touches = %d",activeTouches);
	
	if (interestingTouches == 0)
	{
		gesture.center = lastGesture.center;
		gesture.numTouches = 0;
		gesture.averageDistanceFromCenter = 0.0f;
		return gesture;
	}
	
	gesture.center.x /= interestingTouches;
	gesture.center.y /= interestingTouches;
	
	for (UITouch *touch in touches)
	{
		UITouchPhase phase = [touch phase];

		switch(phase){
			case UITouchPhaseBegan:
			case UITouchPhaseMoved:
			case UITouchPhaseStationary:
			break;
		default:
			continue;
			break;
		}
		CGPoint location = [touch locationInView: self];
		
		float dx = location.x - gesture.center.x;
		float dy = location.y - gesture.center.y;
		gesture.averageDistanceFromCenter += sqrtf((dx*dx) + (dy*dy));
	}
	
	gesture.averageDistanceFromCenter /= interestingTouches;
	
	gesture.numTouches = interestingTouches;
		
	return gesture;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	//NSLog(@"touchesBegan: %d withEvent: %d",count,[[event allTouches] count]);
			
	lastGesture = [self getGestureDetails:[event allTouches]];

	if(deceleration)
	{
		if (decelerationTimer != nil) {
			[self stopDeceleration];
		}
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self touchesEnded:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	//NSLog(@"touchesEnded: %d withEvent: %d",count,[[event allTouches] count]);	

	NSInteger lastTouches = lastGesture.numTouches;
	
	// Calculate the gesture.
	lastGesture = [self getGestureDetails:[event allTouches]];

	if (touch.tapCount >= 2)
	{
		if (delegateHasDoubleTapOnMap) {
			[delegate doubleTapOnMap: self At: lastGesture.center];
		} else {
			// Default behaviour matches built in maps.app
			float nextZoomFactor = [[self contents] getNextNativeZoomFactor];
			if (nextZoomFactor != 0)
				[self zoomByFactor:nextZoomFactor near:[touch locationInView:self] animated:YES];
		}
	} else if (lastTouches == 1 && touch.tapCount != 1) {
		// deceleration
		if (deceleration)
		{
			CGPoint prevLocation = [touch previousLocationInView:self];
			CGPoint currLocation = [touch locationInView:self];
			CGSize touchDelta = CGSizeMake(currLocation.x - prevLocation.x, currLocation.y - prevLocation.y);
			[self startDecelerationWithDelta:touchDelta];
		}
	}
	
	if (touch.tapCount == 1) 
	{
		CALayer* hit = [contents.overlay hitTest:[touch locationInView:self]];
//		NSLog(@"LAYER of type %@",[hit description]);
		
		if (hit != nil) {
			CALayer *superlayer = [hit superlayer];
			Class marker = [RMMarker class];
			// See if tap was on a marker or marker label and send delegate protocol method
			if ([hit isKindOfClass:marker]) {
				if (delegateHasTapOnMarker) {
					[delegate tapOnMarker:(RMMarker*)hit onMap:self];
				}
			} else if (superlayer != nil && [superlayer isKindOfClass:marker]) {
				if (delegateHasTapOnLabelForMarker) {
					[delegate tapOnLabelForMarker:(RMMarker*)superlayer onMap:self];
				}
			}
			else if (delegateHasSingleTapOnMap) {
				[delegate singleTapOnMap: self At: [touch locationInView:self]];
			}
		}
		
	}
	if (delegateHasAfterMapTouch) [delegate afterMapTouch: self];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [[touches allObjects] objectAtIndex:0];
	//NSLog(@"touchesMoved: %d withEvent: %d",[touches count],[[event allTouches] count]);	
	
	CALayer* hit = [contents.overlay hitTest:[touch locationInView:self]];
//	NSLog(@"LAYER of type %@",[hit description]);
	
	if (hit != nil) {
		if ([hit isKindOfClass: [RMMarker class]]) {
			if (delegateHasDragMarkerPosition) {
				[delegate dragMarkerPosition:(RMMarker*)hit onMap:self position:[[[event allTouches] anyObject]locationInView:self]];
				return;
			}
		}
	}
	
	RMGestureDetails newGesture = [self getGestureDetails:[event allTouches]];
	if (enableDragging && newGesture.numTouches == lastGesture.numTouches)
	{
		CGSize delta;
		delta.width = newGesture.center.x - lastGesture.center.x;
		delta.height = newGesture.center.y - lastGesture.center.y;
		
		if (enableZoom && newGesture.numTouches > 1)
		{
			NSAssert (lastGesture.averageDistanceFromCenter > 0.0f && newGesture.averageDistanceFromCenter > 0.0f,
					  @"Distance from center is zero despite >1 touches on the screen");
			
			double zoomFactor = newGesture.averageDistanceFromCenter / lastGesture.averageDistanceFromCenter;
			
			[self moveBy:delta];
			[self zoomByFactor: zoomFactor near: newGesture.center];
		}
		else
		{
			[self moveBy:delta];
		}
		
	}
	lastGesture = newGesture;
}

#pragma mark Deceleration

- (void)startDecelerationWithDelta:(CGSize)delta {
	if (ABS(delta.width) >= 1.0f && ABS(delta.height) >= 1.0f) {
		decelerationDelta = delta;
		decelerationTimer = [NSTimer scheduledTimerWithTimeInterval:0.01f 
															 target:self
														   selector:@selector(incrementDeceleration:) 
														   userInfo:nil 
															repeats:YES];
	}
}

- (void)incrementDeceleration:(NSTimer *)timer {
	if (ABS(decelerationDelta.width) < 0.01f && ABS(decelerationDelta.height) < 0.01f) {
		[self stopDeceleration];
		return;
	}

	// avoid calling delegate methods? design call here
	[contents moveBy:decelerationDelta];

	decelerationDelta.width *= [self decelerationFactor];
	decelerationDelta.height *= [self decelerationFactor];
}

- (void)stopDeceleration {
	if (decelerationTimer != nil) {
		[decelerationTimer invalidate];
		decelerationTimer = nil;
		decelerationDelta = CGSizeZero;

		// call delegate methods; design call (see above)
		[self moveBy:CGSizeZero];
	}
}

- (void)didReceiveMemoryWarning
{
	//NSLog(@"MEMORY WARNING IN RMMAPView");
  CLLocationCoordinate2D coord = contents.mapCenter;
  [contents release];
  [self initValues:coord];
}

- (void)setFrame:(CGRect)frame
{
  CGRect r = self.frame;
  [super setFrame:frame];
  // only change if the frame changes AND there is contents
  if (!CGRectEqualToRect(r, frame) && contents) {
    [contents setFrame:frame];
  }
}

@end
