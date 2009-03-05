//
//  RMMarker.m
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

#import "RMMarker.h"
#import "RMMarkerStyle.h"
#import "RMMarkerStyles.h"
#import "RMMarkerManager.h"

#import "RMPixel.h"

NSString* const RMMarkerBlueKey = @"RMMarkerBlueKey";
NSString* const RMMarkerRedKey = @"RMMarkerRedKey";

static CGImageRef _markerRed = nil;
static CGImageRef _markerBlue = nil;

@implementation RMMarker

@synthesize location;
@synthesize data;
@synthesize manager;
@synthesize markerChangeDelegate;
@synthesize touchAcceptRegion;

+ (RMMarker*) markerWithNamedStyle: (NSString*) styleName
{
	return [[[RMMarker alloc] initWithNamedStyle: styleName] autorelease];
}

- (id) initWithCGImage: (CGImageRef) image
{
	return [self initWithCGImage: image anchorPoint: CGPointMake(0.5, 1.0)];
}

- (id) initWithCGImage: (CGImageRef) image anchorPoint: (CGPoint) _anchorPoint
{
	if (![super init])
		return nil;
	
    [self replaceImage:image anchorPoint:_anchorPoint];
    
    touchAcceptRegion = [self bounds];
	
	return self;
}

- (void) replaceImage:(CGImageRef)image anchorPoint:(CGPoint)_anchorPoint
{
	self.contents = (id)image;
	self.bounds = CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image));
	self.anchorPoint = _anchorPoint;
	
	self.masksToBounds = NO;
}

- (id) initWithUIImage: (UIImage*) image
{
	return [self initWithCGImage: [image CGImage]];
}

- (id) initWithKey: (NSString*) key
{
	return [self initWithCGImage:[RMMarker markerImage:key]];
}

- (id) initWithStyle: (RMMarkerStyle*) style
{
	return [self initWithCGImage: [style.markerIcon CGImage] anchorPoint: style.anchorPoint]; 
}

- (id) initWithNamedStyle: (NSString*) styleName
{
	RMMarkerStyle* style = [[RMMarkerStyles styles] styleNamed: styleName];
	
	if (style==nil) {
		NSLog(@"problem creating marker: style '%@' not found", styleName);
		return [self initWithCGImage: [RMMarker markerImage: RMMarkerRedKey]];
	}
	return [self initWithStyle: style];
}

- (UIView*)labelView
{
    return [[labelView retain] autorelease];
}

- (void) setMarkerManager:(RMMarkerManager*)aManager
{
    manager = aManager;
    
    // Changing the manager also changes where the label should be displayed
    if (labelView)
    {
        [labelView removeFromSuperview];
        [manager.contents.overlay addSubview:labelView];
    }
}

- (void) setLabelView: (UIView*)aView
{
	if (labelView == aView) {
		return;
	}

	if (labelView != nil)
	{
        [labelView removeFromSuperview];
        [labelView release];
	}
	
    labelView = [aView retain];
    
	if (labelView)
	{
        [manager.contents.overlay addSubview:labelView];
	}
}

- (BOOL) canAcceptTouchWithPoint:(CGPoint)point
{
    return CGRectContainsPoint(touchAcceptRegion, point);
}

- (void) setTextLabel: (NSString*)text
{
    CGRect bds = [self frame];
    CGPoint pos = bds.origin;
    pos.x += bds.size.width/2 - [text sizeWithFont:[UIFont systemFontOfSize:15]].width / 2;
    pos.y += 4;
	[self setTextLabel:text atPosition:pos];	
}

- (void) setTextLabel: (NSString*)text atPosition:(CGPoint)position
{
	CGSize textSize = [text sizeWithFont:[UIFont systemFontOfSize:15]];
	CGRect frame = CGRectMake(position.x,
							  position.y,
							  textSize.width+4,
							  textSize.height+4);
	
	UILabel *aLabel = [[UILabel alloc] initWithFrame:frame];
	[aLabel setNumberOfLines:0];
	[aLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
	[aLabel setBackgroundColor:[UIColor clearColor]];
	[aLabel setTextColor:[UIColor blackColor]];
	[aLabel setFont:[UIFont systemFontOfSize:15]];
	[aLabel setTextAlignment:UITextAlignmentCenter];
	[aLabel setText:text];
	
	[self setLabelView:aLabel];
	[aLabel release];
	
}

- (void) removeLabel
{
    self.labelView = nil;
}
		
- (void) toggleLabelAnimated:(BOOL)anim
{
	if (labelView == nil) {
		return;
	}
	
	if ([labelView isHidden] || labelView.alpha < 0.1) {
		[self showLabelAnimated:anim];
	} else {
		[self hideLabelAnimated:anim];
	}
}

- (void) showLabelAnimated:(BOOL)anim
{
    if (anim)
    {
        labelView.alpha = 0.0;
        [labelView setHidden:NO];
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.3];
        labelView.alpha = 1.0;
        [UIView commitAnimations];
    }
    else
    {
        [labelView setHidden:NO];
    }
}

- (void)hideLabelAnimationDidStop:(NSString*)animationID finished:(NSNumber*)finished context:(void*)context
{
    if (labelView.alpha < 0.1)
    {
        [labelView setHidden:YES];
        labelView.alpha = 1.0;
    }
}

- (void) hideLabelAnimated:(BOOL)anim
{
    if (anim)
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.3];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(hideLabelAnimationDidStop:finished:context:)];
        labelView.alpha = 0.0;
        [UIView commitAnimations];
    }
    else
    {
        [labelView setHidden:YES];
    }
}

- (void) dealloc 
{
	self.labelView = nil;
	self.data = nil;

     if (_markerBlue && ([(id)_markerBlue retainCount] == 1))
     {
         [(id)_markerBlue release];
         _markerBlue = nil;
     }
     if (_markerRed && ([(id)_markerRed retainCount] == 1))
     {
         [(id)_markerRed release];
         _markerRed = nil;
     }


	[super dealloc];
}

- (void)setFrame:(CGRect)aFrame
{
    if (labelView)
    {
        CGPoint oldPosition = self.position;
        CGPoint labelCenter = labelView.center;
        labelView.center = CGPointMake(labelCenter.x - oldPosition.x + aFrame.origin.x, labelCenter.y - oldPosition.y + aFrame.origin.y);
    }
    
    [super setFrame:aFrame];
}

- (void)setPosition:(CGPoint)aPosition
{
    if (labelView)
    {
        CGPoint oldPosition = self.position;
        CGPoint labelCenter = labelView.center;
        labelView.center = CGPointMake(labelCenter.x - oldPosition.x + aPosition.x, labelCenter.y - oldPosition.y + aPosition.y);
    }
    
    [super setPosition:aPosition];
}

- (void)zoomByFactor: (float) zoomFactor near:(CGPoint) center
{
	self.position = RMScaleCGPointAboutPoint(self.position, zoomFactor, center);
	
/*	CGRect currentRect = CGRectMake(self.position.x, self.position.y, self.bounds.size.width, self.bounds.size.height);
	CGRect newRect = RMScaleCGRectAboutPoint(currentRect, zoomFactor, center);
	self.position = newRect.origin;
	self.bounds = CGRectMake(0, 0, newRect.size.width, newRect.size.height);
*/
}

+ (CGImageRef) loadPNGFromBundle: (NSString *)filename
{
	NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"png"];
	CGDataProviderRef dataProvider = CGDataProviderCreateWithFilename([path UTF8String]);
	CGImageRef image = CGImageCreateWithPNGDataProvider(dataProvider, NULL, FALSE, kCGRenderingIntentDefault);
	[NSMakeCollectable(image) autorelease];
	CGDataProviderRelease(dataProvider);
	
	return image;
}

+ (CGImageRef) markerImage: (NSString *) key
{
	if (RMMarkerBlueKey == key
		|| [RMMarkerBlueKey isEqualToString:key])
	{
		if (_markerBlue == nil)
			_markerBlue = (CGImageRef)[(id)[self loadPNGFromBundle:@"marker-blue"] retain];
		
		return _markerBlue;
	}
	else if (RMMarkerRedKey == key
		|| [RMMarkerRedKey isEqualToString: key])
	{
		if (_markerRed == nil)
			_markerRed = (CGImageRef)[(id)[self loadPNGFromBundle:@"marker-red"] retain];
		
		return _markerRed;
	}
	
	return nil;
}

- (void) setFocused:(BOOL)aFocused
{
    BOOL wasFocused = [self focused];
    if (wasFocused != aFocused)
    {
        if (aFocused)
        {
            [manager focusMarker:self];
        }
        else if (wasFocused)
        {
            [manager focusMarker:nil];
        }
    }
}

- (BOOL) focused
{
    return (self.zPosition > 0.5);
}


@end
