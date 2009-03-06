//
//  RMRadiusLayer.m
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

#import "RMRadiusLayer.h"



@implementation RMRadiusLayer
@synthesize lineColor;
@synthesize fillColor;

- (void)setLineColor:(UIColor*)color
{
    UIColor *oldColor = lineColor;
    lineColor = [color retain];
    [oldColor release];
    [self setNeedsDisplay];
}

- (void)setFillColor:(UIColor*)color
{
    UIColor *oldColor = fillColor;
    fillColor = [color retain];
    [oldColor release];
    [self setNeedsDisplay];
}

- (id)init
{
    self = [super init];
    self.needsDisplayOnBoundsChange = YES;
    
    self.anchorPoint = CGPointMake(0.5,0.5);
    self.fillColor = [UIColor colorWithRed:0 green:0.3 blue:1.0 alpha:0.1];
    self.bounds = CGRectMake(0,0,120,120);
    
    return self;
}

- (void)drawInContext:(CGContextRef)theContext
{
    CGRect bounds = self.bounds;
    
    if (fillColor)
    {
        CGContextSetFillColorWithColor(theContext, fillColor.CGColor);
        CGContextFillEllipseInRect(theContext, bounds);
    }
    if (lineColor)
    {
        CGContextSetStrokeColorWithColor(theContext, lineColor.CGColor);
        CGContextStrokeEllipseInRect(theContext, bounds);
    }
}

- (void)dealloc
{
    [lineColor release];
    [fillColor release];
    [super dealloc];
}

@end
