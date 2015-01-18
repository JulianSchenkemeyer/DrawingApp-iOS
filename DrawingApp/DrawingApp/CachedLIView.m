//
//  CachedLIView.m
//  DrawingApp
//
//  Created by Julian Schenkemeyer on 16/01/15.
//  Copyright (c) 2015 SchenkemeyerJulian. All rights reserved.
//

#import "CachedLIView.h"

#define FUDGE_FACTOR 100
#define BUFFCAP 100

@implementation CachedLIView
{
    UIImage *incrementalImage;  // offscreen bitmap for storing a copy of our screen
    CGPoint pts[5];             // four points to create a Bezier segment + one point to smooth out the junction point
    uint ctr;                   // counter to keep track of point index

    CGPoint pointsBuffer[BUFFCAP];
    uint buffIndex;
    dispatch_queue_t drawingQueue;
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setMultipleTouchEnabled:NO];                          // We only want the user to be able to draw with one finger
        drawingQueue = dispatch_queue_create("drawingQueue", NULL); // create the drawingQueue
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
    buffIndex = 0;
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
        pointsBuffer[buffIndex] = pts[0];
        pointsBuffer[buffIndex + 1] = pts[1];
        pointsBuffer[buffIndex + 2] = pts[2];
        pointsBuffer[buffIndex + 3] = pts[3];
        
        buffIndex += 4;
        
        CGRect bounds = self.bounds;
        dispatch_async(drawingQueue, ^{
            if (buffIndex == 0) {
                return;
            }
            UIBezierPath *path = [UIBezierPath bezierPath];
            for (int i = 0; i < buffIndex; i += 4) {
                // draw bezier curve
                [path moveToPoint:pointsBuffer[i]];
                [path addCurveToPoint:pointsBuffer[i+3] controlPoint1:pointsBuffer[i+1] controlPoint2:pointsBuffer[i+2]];
            }
            
            // create an offscreen bitmap
            UIGraphicsBeginImageContextWithOptions(bounds.size, YES, 0.0);
            
            // if no offscreen bitmap is already available, create one
            if (!incrementalImage) {
                UIBezierPath *rectpath = [UIBezierPath bezierPathWithRect:bounds];
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
            UIGraphicsEndImageContext();
            
            dispatch_async(dispatch_get_main_queue(), ^{
                buffIndex = 0;
                [self setNeedsDisplay];
            });
        });
        
        // setup for the next curve
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
