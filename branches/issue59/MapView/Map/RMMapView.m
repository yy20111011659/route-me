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

#import "RMOverlayView.h"
#import "RMMarkerManager.h"

@interface RMMapView (PrivateMethods)
// methods for post-touch deceleration, ala UIScrollView
- (void)startDecelerationWithDelta:(CGSize)delta;
- (void)incrementDeceleration:(NSTimer *)timer;
- (void)stopDeceleration;
@end

@implementation RMMapView
@synthesize decelerationFactor;
@synthesize deceleration;
@synthesize contents;

- (RMMarkerManager*)markerManager
{
  return self.contents.markerManager;
}

-(void) performInitialSetup
{
	LogMethod();

	enableDragging = YES;
	enableZoom = YES;
	decelerationFactor = 0.88f;
	deceleration = NO;
    
    // Number of pixels that the contact point can move before the touch is regarded as having moved
    markerDragPermittedDrift = 10.0;
	
	//	[self recalculateImageSet];
	
	if (enableZoom)
		[self setMultipleTouchEnabled:TRUE];
	
	self.backgroundColor = [UIColor grayColor];
	
//	[[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (id)initWithFrame:(CGRect)frame
{
	LogMethod();
	if (self = [super initWithFrame:frame]) {
		[self performInitialSetup];
	}
	return self;
}

/// deprecated any time after 0.5
- (id)initWithFrame:(CGRect)frame WithLocation:(CLLocationCoordinate2D)latlon
{
	LogMethod();
	if (self = [super initWithFrame:frame]) {
		[self performInitialSetup];
	}
	[self moveToLatLong:latlon];
	return self;
}

//=========================================================== 
//  contents 
//=========================================================== 
- (RMMapContents *)contents
{
    if (!_contentsIsSet) {
		self.contents = [[RMMapContents alloc] initForView:self];
		_contentsIsSet = YES;
	}
	return contents; 
}
- (void)setContents:(RMMapContents *)theContents
{
    if (contents != theContents) {
        [contents release];
        contents = [theContents retain];
		_contentsIsSet = YES;
		[self performInitialSetup];
    }
}

-(void) dealloc
{
	LogMethod();
	[self.contents release];
	contents = nil;
	[super dealloc];
}

-(void) drawRect: (CGRect) rect
{
	[self.contents drawRect:rect];
}

-(NSString*) description
{
	CGRect bounds = [self bounds];
	return [NSString stringWithFormat:@"MapView at %.0f,%.0f-%.0f,%.0f", bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height];
}

// Forward invocations to RMMapContents
- (void)forwardInvocation:(NSInvocation *)invocation
{
    SEL aSelector = [invocation selector];
	
    if ([self.contents respondsToSelector:aSelector])
        [invocation invokeWithTarget:self.contents];
    else
        [self doesNotRecognizeSelector:aSelector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	if ([super respondsToSelector:aSelector])
		return [super methodSignatureForSelector:aSelector];
	else
		return [self.contents methodSignatureForSelector:aSelector];
}

#pragma mark Delegate 

@dynamic delegate;

- (void) setDelegate: (id<RMMapViewDelegate>) _delegate
{
	if (delegate == _delegate) return;
	delegate = _delegate;
	
	_delegateHasBeforeMapMove = [(NSObject*) delegate respondsToSelector: @selector(beforeMapMove:)];
	_delegateHasAfterMapMove  = [(NSObject*) delegate respondsToSelector: @selector(afterMapMove:)];
	
	_delegateHasBeforeMapZoomByFactor = [(NSObject*) delegate respondsToSelector: @selector(beforeMapZoom: byFactor: near:)];
	_delegateHasAfterMapZoomByFactor  = [(NSObject*) delegate respondsToSelector: @selector(afterMapZoom: byFactor: near:)];

	_delegateHasDoubleTapOnMap = [(NSObject*) delegate respondsToSelector: @selector(doubleTapOnMap:At:)];
	_delegateHasSingleTapOnMap = [(NSObject*) delegate respondsToSelector: @selector(singleTapOnMap:At:)];
	
	_delegateHasTapOnMarker = [(NSObject*) delegate respondsToSelector:@selector(tapOnMarker:onMap:)];
    _delegateHasTapOnLabelForMarker = [(NSObject*) delegate respondsToSelector:@selector(tapOnLabelForMarker:onMap:withTouch:)];
    
    _delegateHasFocusChangedToMarker = [(NSObject*) delegate respondsToSelector:@selector(mapView:focusChangedToMarker:fromMarker:)];
	_delegateHasShouldDragMarker = [(NSObject*) delegate respondsToSelector:@selector(mapView:shouldDragMarker:)];
	_delegateHasDidDragMarker = [(NSObject*) delegate respondsToSelector:@selector(mapView:didDragMarker:)];
    
	_delegateHasAfterMapTouch  = [(NSObject*) delegate respondsToSelector: @selector(afterMapTouch:)];
   
   _delegateHasShouldDragMarker = [(NSObject*) delegate respondsToSelector: @selector(mapView: shouldDragMarker: withEvent:)];
   _delegateHasDidDragMarker = [(NSObject*) delegate respondsToSelector: @selector(mapView: didDragMarker: withEvent:)];
	
	_delegateHasDragMarkerPosition = [(NSObject*) delegate respondsToSelector: @selector(dragMarkerPosition: onMap: position:)];
}

- (id<RMMapViewDelegate>) delegate
{
	return delegate;
}

#pragma mark Movement

-(void) moveToXYPoint: (RMXYPoint) aPoint
{
	if (_delegateHasBeforeMapMove) [delegate beforeMapMove: self];
	[self.contents moveToXYPoint:aPoint];
	if (_delegateHasAfterMapMove) [delegate afterMapMove: self];
}
-(void) moveToLatLong: (CLLocationCoordinate2D) point
{
	if (_delegateHasBeforeMapMove) [delegate beforeMapMove: self];
	[self.contents moveToLatLong:point];
	if (_delegateHasAfterMapMove) [delegate afterMapMove: self];
}

- (void)moveBy: (CGSize) delta
{
	if (_delegateHasBeforeMapMove) [delegate beforeMapMove: self];
	[self.contents moveBy:delta];
	if (_delegateHasAfterMapMove) [delegate afterMapMove: self];
}
- (void)zoomByFactor: (float) zoomFactor near:(CGPoint) center
{
	[self zoomByFactor:zoomFactor near:center animated:NO];
}
- (void)zoomByFactor: (float) zoomFactor near:(CGPoint) center animated:(BOOL)animated
{
	if (_delegateHasBeforeMapZoomByFactor) [delegate beforeMapZoom: self byFactor: zoomFactor near: center];
	[self.contents zoomByFactor:zoomFactor near:center animated:animated withCallback:(animated && _delegateHasAfterMapZoomByFactor)?self:nil];
	if (!animated)
		if (_delegateHasAfterMapZoomByFactor) [delegate afterMapZoom: self byFactor: zoomFactor near: center];
}


#pragma mark RMMapContentsAnimationCallback methods

- (void)animationFinishedWithZoomFactor:(float)zoomFactor near:(CGPoint)p
{
	if (_delegateHasAfterMapZoomByFactor)
		[delegate afterMapZoom: self byFactor: zoomFactor near: p];
}


#pragma mark Event handling

- (RMGestureDetails) getGestureDetails: (NSSet*) touches
{
	RMGestureDetails gesture;
	gesture.center.x = gesture.center.y = 0;
	gesture.averageDistanceFromCenter = 0;
	
	int interestingTouches = 0;
	
	for (UITouch *touch in touches)
	{
		if ([touch phase] != UITouchPhaseBegan
			&& [touch phase] != UITouchPhaseMoved
			&& [touch phase] != UITouchPhaseStationary)
			continue;
		//		RMLog(@"phase = %d", [touch phase]);
		
		interestingTouches++;
		
		CGPoint location = [touch locationInView: self];
		
		gesture.center.x += location.x;
		gesture.center.y += location.y;
	}
	
	if (interestingTouches == 0)
	{
		gesture.center = lastGesture.center;
		gesture.numTouches = 0;
		gesture.averageDistanceFromCenter = 0.0f;
		return gesture;
	}
	
	//	RMLog(@"interestingTouches = %d", interestingTouches);
	
	gesture.center.x /= interestingTouches;
	gesture.center.y /= interestingTouches;
	
	for (UITouch *touch in touches)
	{
		if ([touch phase] != UITouchPhaseBegan
			&& [touch phase] != UITouchPhaseMoved
			&& [touch phase] != UITouchPhaseStationary)
			continue;
		
		CGPoint location = [touch locationInView: self];
		
		//		RMLog(@"For touch at %.0f, %.0f:", location.x, location.y);
		float dx = location.x - gesture.center.x;
		float dy = location.y - gesture.center.y;
		//		RMLog(@"delta = %.0f, %.0f  distance = %f", dx, dy, sqrtf((dx*dx) + (dy*dy)));
		gesture.averageDistanceFromCenter += sqrtf((dx*dx) + (dy*dy));
	}
	
	gesture.averageDistanceFromCenter /= interestingTouches;
	
	gesture.numTouches = interestingTouches;
	
	//	RMLog(@"center = %.0f,%.0f dist = %f", gesture.center.x, gesture.center.y, gesture.averageDistanceFromCenter);
	
	return gesture;
}

- (void)userPausedDragging
{
	[RMMapContents setPerformExpensiveOperations:YES];
}

- (void)unRegisterPausedDraggingDispatcher
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(userPausedDragging) object:nil];
}

- (void)registerPausedDraggingDispatcher
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(userPausedDragging) object:nil];
	[self performSelector:@selector(userPausedDragging) withObject:nil afterDelay:0.3];	
}

- (void)startedDraggingObject:(id)draggableObject
{
    draggable = draggableObject;
    if ([draggable isKindOfClass:[RMMarker class]])
    {
        // Only drag markers with a single touch
        if (lastGesture.numTouches != 1)
        {
            draggable = nil;
            return;
        }
        if (_delegateHasShouldDragMarker)
        {
            if (! [delegate mapView:self shouldDragMarker:(RMMarker*)draggable])
            {
                // Delegate requests we don't drag the marker
                draggable = nil;
                return;
            }
        }
        if (_delegateHasDragMarkerPosition) {
            [delegate dragMarkerPosition:(RMMarker*)draggable onMap:self position:lastGesture.center];
            return;
        }
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
	UITouch *touch = [[touches allObjects] objectAtIndex:0];
	//Check if the touch hit a RMMarker subclass and if so, forward the touch event on
	//so it can be handled there
	CALayer* furthestLayerDown = [[[self contents] overlay].markerLayer hitTest:[touch locationInView:self]];
    draggable = nil;
    if ([[furthestLayerDown superlayer] isKindOfClass:[RMMarker class]])
    {
        furthestLayerDown = [furthestLayerDown superlayer];
    }
    if ([furthestLayerDown isKindOfClass:[RMMarker class]])
    {
        RMMarkerManager *manager = self.markerManager;
        RMMarker *realTouchedMarker = [manager markerTouchableHitTest:[touch locationInView:contents.overlay]];
        RMMarker *oldFocus = manager.focused;
        
        if (realTouchedMarker)
        {
            if (realTouchedMarker != oldFocus)
            {
                [realTouchedMarker setFocused:YES];
                if (_delegateHasFocusChangedToMarker)
                {
                    [delegate mapView:self focusChangedToMarker:realTouchedMarker fromMarker:oldFocus];
                }
            }
            
            [self performSelector:@selector(startedDraggingObject:) withObject:realTouchedMarker afterDelay:0.5];
        }
            
        if ([[furthestLayerDown class]isSubclassOfClass: [RMMarker class]]) {
            if ([furthestLayerDown respondsToSelector:@selector(touchesBegan:withEvent:)]) {
                [furthestLayerDown performSelector:@selector(touchesBegan:withEvent:) withObject:touches withObject:event];
                return;
            }
        }
	}
        
	if (lastGesture.numTouches == 0)
	{
		[RMMapContents setPerformExpensiveOperations:NO];
	}
	
	//	RMLog(@"touchesBegan %d", [[event allTouches] count]);
	lastGesture = [self getGestureDetails:[event allTouches]];
    startGesture = lastGesture;
    
	if(deceleration)
	{
		if (_decelerationTimer != nil) {
			[self stopDeceleration];
		}
	}
	
	[self registerPausedDraggingDispatcher];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [[touches allObjects] objectAtIndex:0];
	
	//Check if the touch hit a RMMarker subclass and if so, forward the touch event on
	//so it can be handled there
	id furthestLayerDown = [[[self contents] overlay].markerLayer hitTest:[touch locationInView:self]];
    if ([[furthestLayerDown superlayer] isKindOfClass:[RMMarker class]])
    {
        furthestLayerDown = [furthestLayerDown superlayer];
    }
	if ([[furthestLayerDown class]isSubclassOfClass: [RMMarker class]]) {
		if ([furthestLayerDown respondsToSelector:@selector(touchesCancelled:withEvent:)]) {
			[furthestLayerDown performSelector:@selector(touchesCancelled:withEvent:) withObject:touches withObject:event];
			return;
		}
	}

	// I don't understand what the difference between this and touchesEnded is.
	[self touchesEnded:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
	UITouch *touch = [[touches allObjects] objectAtIndex:0];
    
	//Check if the touch hit a RMMarker subclass and if so, forward the touch event on
	//so it can be handled there
	id furthestLayerDown = [[[self contents] overlay].markerLayer hitTest:[touch locationInView:self]];
    if ([[furthestLayerDown superlayer] isKindOfClass:[RMMarker class]])
    {
        furthestLayerDown = [furthestLayerDown superlayer];
    }
	if ([[furthestLayerDown class]isSubclassOfClass: [RMMarker class]]) {
		if ([furthestLayerDown respondsToSelector:@selector(touchesEnded:withEvent:)]) {
			[furthestLayerDown performSelector:@selector(touchesEnded:withEvent:) withObject:touches withObject:event];
			return;
		}
	}
	NSInteger lastTouches = lastGesture.numTouches;
	
    
    if (draggable)
    {
        if (_delegateHasDidDragMarker)
        {
            [delegate mapView:self didDragMarker:(RMMarker*)draggable];
        }
        draggable = nil;
        return;
    }
    
	// Calculate the gesture.
	lastGesture = [self getGestureDetails:[event allTouches]];

	// If there are no more fingers on the screen, resume any slow operations.
	if (lastGesture.numTouches == 0)
	{
		[self unRegisterPausedDraggingDispatcher];
		// When factoring, beware these two instructions need to happen in this order.
		[RMMapContents setPerformExpensiveOperations:YES];
	}

	if (touch.tapCount >= 2)
	{
		if (_delegateHasDoubleTapOnMap) {
			[delegate doubleTapOnMap: self At: lastGesture.center];
		} else {
			// Default behaviour matches built in maps.app
			float nextZoomFactor = [self.contents getNextNativeZoomFactor];
			if (nextZoomFactor != 0)
				[self zoomByFactor:nextZoomFactor near:[touch locationInView:self] animated:YES];
		}
	} else if (lastTouches == 1 && touch.tapCount != 1) {
		// deceleration
		if(deceleration)
		{
			CGPoint prevLocation = [touch previousLocationInView:self];
			CGPoint currLocation = [touch locationInView:self];
			CGSize touchDelta = CGSizeMake(currLocation.x - prevLocation.x, currLocation.y - prevLocation.y);
			[self startDecelerationWithDelta:touchDelta];
		}
	}
	
		
	if (touch.tapCount == 1) 
	{
		CALayer* hit = (CALayer*)furthestLayerDown;
//		RMLog(@"LAYER of type %@",[hit description]);
		
		if (hit) {
			
			// See if tap was on a marker or marker label and send delegate protocol method
			if ([hit isKindOfClass: [RMMarker class]]) {
                if ([ (RMMarker*)hit canAcceptTouchWithPoint:[hit convertPoint:[touch locationInView:self] fromLayer:self.layer]])
                {
                    if (_delegateHasTapOnMarker) {
                        [delegate tapOnMarker:(RMMarker*)hit onMap:self];
                    }
                }
			}
            else
            {
                // Pursuant to comments on r227, have included an implementation for tapOnLabelForMarker.
                RMMarker *markerForTappedLabel = nil;
                if (_delegateHasTapOnLabelForMarker)
                {
                    CGPoint touchLoc = [touch locationInView:contents.overlay];
                    for (UIView *view in contents.overlay.subviews)
                    {
                        // Do a non-recursive hit-test
                        if ([view pointInside:touchLoc withEvent:event])
                        {
                            markerForTappedLabel = [contents.markerManager markerForLabelView:view];
                            
                            if (markerForTappedLabel)
                            {
                                [delegate tapOnLabelForMarker:markerForTappedLabel onMap:self];
                                break;
                            }
                        }
                    }
                }
                
                if ( (!markerForTappedLabel) && _delegateHasSingleTapOnMap) {
                    [delegate singleTapOnMap: self At: [touch locationInView:self]];
                }
			}
		}
        
        
		
	}

	if (_delegateHasAfterMapTouch) [delegate afterMapTouch: self];

//		[self.contents recalculateImageSet];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [[touches allObjects] objectAtIndex:0];
	
	//Check if the touch hit a RMMarker subclass and if so, forward the touch event on
	//so it can be handled there
	id furthestLayerDown = [[[self contents] overlay].markerLayer hitTest:[touch locationInView:self]];
    if ([[furthestLayerDown superlayer] isKindOfClass:[RMMarker class]])
    {
        furthestLayerDown = [furthestLayerDown superlayer];
    }
	if ([[furthestLayerDown class] isSubclassOfClass: [RMMarker class]]) {
		if ([furthestLayerDown respondsToSelector:@selector(touchesMoved:withEvent:)]) {
			[furthestLayerDown performSelector:@selector(touchesMoved:withEvent:) withObject:touches withObject:event];
			return;
		}
	}
	
	if (draggable) {
        if ([[event allTouches] count] != 1)
        {
            if (_delegateHasDidDragMarker)
            {
                [delegate mapView:self didDragMarker:(RMMarker*)draggable];
            }
            draggable = nil;
        }
        
		if ([draggable isKindOfClass: [RMMarker class]]) {
			if (_delegateHasDragMarkerPosition) {
				[delegate dragMarkerPosition:(RMMarker*)draggable onMap:self position:[touch locationInView:self]];
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
    
    // Cancel draggable being set, only if the gesture has moved from the start position by more than markerDragPermittedDrift
    CGSize deltaFromStart = CGSizeMake(newGesture.center.x - startGesture.center.x,
                                       newGesture.center.y - startGesture.center.y);
    CGFloat sqrDistFromStart = deltaFromStart.width *deltaFromStart.width + deltaFromStart.height*deltaFromStart.height;
    
    if ((newGesture.numTouches != 1) || (sqrDistFromStart > markerDragPermittedDrift*markerDragPermittedDrift))
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    }
	[self registerPausedDraggingDispatcher];
}

#pragma mark Deceleration

- (void)startDecelerationWithDelta:(CGSize)delta {
	if (ABS(delta.width) >= 1.0f && ABS(delta.height) >= 1.0f) {
		_decelerationDelta = delta;
		_decelerationTimer = [NSTimer scheduledTimerWithTimeInterval:0.01f 
															 target:self
														   selector:@selector(incrementDeceleration:) 
														   userInfo:nil 
															repeats:YES];
	}
}

- (void)incrementDeceleration:(NSTimer *)timer {
	if (ABS(_decelerationDelta.width) < 0.01f && ABS(_decelerationDelta.height) < 0.01f) {
		[self stopDeceleration];
		return;
	}

	// avoid calling delegate methods? design call here
	[self.contents moveBy:_decelerationDelta];

	_decelerationDelta.width *= [self decelerationFactor];
	_decelerationDelta.height *= [self decelerationFactor];
}

- (void)stopDeceleration {
	if (_decelerationTimer != nil) {
		[_decelerationTimer invalidate];
		_decelerationTimer = nil;
		_decelerationDelta = CGSizeZero;

		// call delegate methods; design call (see above)
		[self moveBy:CGSizeZero];
	}
}

// Must be called by higher didReceiveMemoryWarning
- (void)didReceiveMemoryWarning
{
        [contents didReceiveMemoryWarning];
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
