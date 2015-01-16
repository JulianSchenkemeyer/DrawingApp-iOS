//
//  LinearInterpView.m
//  DrawingApp
//
//  Created by Julian Schenkemeyer on 16/01/15.
//  Copyright (c) 2015 SchenkemeyerJulian. All rights reserved.
//

#import "LinearInterpView.h"

@implementation LinearInterpView
{
    // UIKit class for drawing shapes out of straight lines and certain curves
    UIBezierPath *path;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self setMultipleTouchEnabled:NO];                  // We do not want to deal with multiple touches simultaneous
        [self setBackgroundColor:[UIColor whiteColor]];     // white background
        path = [UIBezierPath bezierPath];
        [path setLineWidth:2.0];                            // thickness
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [[UIColor blackColor] setStroke];   //stroke color
    [path stroke];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];    // read location of touch
    [path moveToPoint:p];                       // move the path to current location
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];
    [path addLineToPoint:p];                    // draw a line the next location
    [self setNeedsDisplay];                     // refresh the view
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesMoved:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
