//
//  RMOverlayView.m
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

#import "RMOverlayView.h"


@implementation RMOverlayView
@synthesize markerLayer;

- (id)initWithContents:(RMMapContents *)contents andFrame:(CGRect)frame
{
    if (! [super initWithFrame:frame])
    {
        return nil;
    }
    
    markerLayer = [[RMLayerSet alloc] initForContents:contents];
    if (! markerLayer)
    {
        [self release];
        return nil;
    }
    markerLayer.frame = [self bounds];
    
    // Add the marker layer as a sublayer of our layer
    [[self layer] addSublayer:markerLayer];
    
    self.opaque = NO;
    self.clipsToBounds = YES;
    
    return self;
}

- (void)correctPositionOfAllSublayers
{
    [markerLayer correctPositionOfAllSublayers];
}


- (void)moveBy:(CGSize)delta
{
    [markerLayer moveBy:delta];
}

- (void)zoomByFactor:(float)zoomFactor near:(CGPoint)pivot
{
    [markerLayer zoomByFactor:zoomFactor near:pivot];
}


- (void)dealloc {
    [markerLayer removeFromSuperlayer];
    [markerLayer release];
    [super dealloc];
}


@end
