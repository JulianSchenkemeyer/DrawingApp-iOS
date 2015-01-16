//
//  CachedLIView.m
//  DrawingApp
//
//  Created by Julian Schenkemeyer on 16/01/15.
//  Copyright (c) 2015 SchenkemeyerJulian. All rights reserved.
//

#import "CachedLIView.h"

@implementation CachedLIView
{
    UIBezierPath *path;
    UIImage *incrementalImage; // offscreen bitmap for storing a copy of our screen
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self setMultipleTouchEnabled:NO];                  // We only want the user to be able to draw with one finger
        [self setBackgroundColor:[UIColor whiteColor]];     // background-color
        path = [UIBezierPath bezierPath];
        [path setLineWidth:2.0];                            // thickness
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [incrementalImage drawInRect:rect];
    [path stroke];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];    // location
    [path moveToPoint:p];                       // draw the beginning
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];    // location
    [path addLineToPoint:p];                       // draw a line between the current location and the starting point
    [self setNeedsDisplay];                     // refresh
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];    // location
    [path addLineToPoint:p];
    [self drawBitmap];                          // store the current screen as bitmap
    [self setNeedsDisplay];                     // refresh
    [path removeAllPoints];                     // reset the current screen
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}

- (void)drawBitmap
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, 0.0);
    [[UIColor blackColor] setStroke];
    if (!incrementalImage) {                                                        // if this is the first drawing, create the first
        // create white background
        UIBezierPath *rectpath = [UIBezierPath bezierPathWithRect:self.bounds];
        [[UIColor whiteColor] setFill];
        [rectpath fill];
    }
    // create bitmap from current screen
    [incrementalImage drawAtPoint:CGPointZero];
    [path stroke];
    incrementalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
