//
//  CachedLIView.m
//  DrawingApp
//
//  Created by Julian Schenkemeyer on 16/01/15.
//  Copyright (c) 2015 SchenkemeyerJulian. All rights reserved.
//

#import "CachedLIView.h"

#define FUDGE_FACTOR 100

@implementation CachedLIView
{
    UIBezierPath *path;
    UIImage *incrementalImage;  // offscreen bitmap for storing a copy of our screen
    CGPoint pts[5];             // four points to create a Bezier segment + one point to smooth out the junction point
    uint ctr;                   // counter to keep track of point index
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setMultipleTouchEnabled:NO];          // We only want the user to be able to draw with one finger
        path = [UIBezierPath bezierPath];
        [path setLineWidth:2.0];                    // thickness
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [incrementalImage drawInRect:rect];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    ctr = 0;                                    // set counter to 0
    UITouch *touch = [touches anyObject];
    pts[0] = [touch locationInView:self];       // location
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];                                        // location
    ctr++;                                                                          // increment the counter
    pts[ctr] = p;                                                                   // set new point for Bezier curve
    
    if (ctr == 4) {                                                                 // if 5 point are available
        
        pts[3] = CGPointMake((pts[2].x + pts[4].x)/2.0, (pts[2].y + pts[4].y)/2.0); // find the middle between the second controlpoint and the first controlpoint of the next bezier curve
        
        [path moveToPoint:pts[0]];                                                  // set beginning of the Bezier curve
        [path addCurveToPoint:pts[3] controlPoint1:pts[1] controlPoint2:pts[2]];    // draw the Bezier curve from pts[0] to pts[3]
        
        // create an offscreen bitmap
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, 0.0);
        
        // if no offscreen bitmap is already available, create one
        if (!incrementalImage) {
            UIBezierPath *rectpath = [UIBezierPath bezierPathWithRect:self.bounds];
            [[UIColor whiteColor] setFill];
            [rectpath fill];
        }
        
        [incrementalImage drawAtPoint:CGPointZero];
        [[UIColor blackColor] setStroke];
        
        // change stroke width in relation to drawing speed
        float speed = 0.0;
        
        // calculate the drawing speed
        for (int i = 0; i < 3; i++) {
            float dx = pts[i+1].x - pts[i].x;
            float dy = pts[i+1].y - pts[i].y;
            speed += sqrtf(dx * dx + dy * dy);
        }
        
        float width = FUDGE_FACTOR / speed;
        
        [path setLineWidth:width];
        [path stroke];
        incrementalImage = UIGraphicsGetImageFromCurrentImageContext();
        
        [self setNeedsDisplay];                                                     // refresh
        
        // setup for the next curve
        [path removeAllPoints];
        pts[0] = pts[3];
        pts[1] = pts[4];
        ctr = 1;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self setNeedsDisplay];                     // refresh
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
