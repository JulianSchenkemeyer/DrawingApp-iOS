//
//  CachedLIView.m
//  DrawingApp
//
//  Created by Julian Schenkemeyer on 16/01/15.
//  Copyright (c) 2015 SchenkemeyerJulian. All rights reserved.
//

#import "CachedLIView.h"

#define BUFFCAP 100
#define FF 20
#define LOWER 0.01
#define UPPER 1.0

typedef struct
{
    CGPoint firstPoint;
    CGPoint secondPoint;
} LineSegment;

@implementation CachedLIView
{
    UIImage *incrementalImage;  // offscreen bitmap for storing a copy of our screen
    CGPoint pts[5];             // four points to create a Bezier segment + one point to smooth out the junction point
    uint ctr;                   // counter to keep track of point index

    CGPoint pointsBuffer[BUFFCAP];
    uint buffIndex;
    dispatch_queue_t drawingQueue;
    
    BOOL isFirstTouchPoint;
    LineSegment lastSegmentOfPrev;
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
    isFirstTouchPoint = YES;
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
            UIBezierPath *offsetPath = [UIBezierPath bezierPath];
            
            LineSegment ls[4];
            for (int i = 0; i < buffIndex; i += 4) {
                if (isFirstTouchPoint) {
                    ls[0] = (LineSegment){pointsBuffer[0], pointsBuffer[0]};
                    [offsetPath moveToPoint:ls[0].firstPoint];
                    isFirstTouchPoint = NO;
                } else {
                    ls[0] = lastSegmentOfPrev;
                }
                
                float frac1 = clamp(FF/len_sq(pointsBuffer[i], pointsBuffer[i+1]), LOWER, UPPER);
                float frac2 = clamp(FF/len_sq(pointsBuffer[i+1], pointsBuffer[i+2]), LOWER, UPPER);
                float frac3 = clamp(FF/len_sq(pointsBuffer[i+2], pointsBuffer[i+3]), LOWER, UPPER);
                ls[1] = [self lineSegmentPerpendicularTo:(LineSegment){pointsBuffer[i], pointsBuffer[i+1]} ofRelativeLength:frac1];
                ls[2] = [self lineSegmentPerpendicularTo:(LineSegment){pointsBuffer[i+1], pointsBuffer[i+2]} ofRelativeLength:frac2];
                ls[3] = [self lineSegmentPerpendicularTo:(LineSegment){pointsBuffer[i+2], pointsBuffer[i+3]} ofRelativeLength:frac3];
                
                // draw bezier curves
                [offsetPath moveToPoint:ls[0].firstPoint];
                [offsetPath addCurveToPoint:ls[3].firstPoint controlPoint1:ls[1].firstPoint controlPoint2:ls[2].firstPoint];
                [offsetPath addLineToPoint:ls[3].secondPoint];
                [offsetPath addCurveToPoint:ls[0].secondPoint controlPoint1:ls[2].secondPoint controlPoint2:ls[1].secondPoint];
                [offsetPath closePath];
                
                lastSegmentOfPrev = ls[3];
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
            [[UIColor blackColor] setFill];
            [offsetPath stroke];
            [offsetPath fill];
            
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



-(LineSegment) lineSegmentPerpendicularTo: (LineSegment)pp ofRelativeLength:(float)fraction
{
    CGFloat x0 = pp.firstPoint.x, y0 = pp.firstPoint.y, x1 = pp.secondPoint.x, y1 = pp.secondPoint.y;
    
    CGFloat dx, dy;
    dx = x1 - x0;
    dy = y1 - y0;
    
    CGFloat xa, ya, xb, yb;
    xa = x1 + fraction/2 * dy;
    ya = y1 - fraction/2 * dx;
    xb = x1 - fraction/2 * dy;
    yb = y1 + fraction/2 * dx;
    
    return (LineSegment){ (CGPoint){xa, ya}, (CGPoint){xb, yb} };
    
}

float len_sq(CGPoint p1, CGPoint p2)
{
    float dx = p2.x - p1.x;
    float dy = p2.y - p1.y;
    return dx * dx + dy * dy;
}

float clamp(float value, float lower, float higher)
{
    if (value < lower) return lower;
    if (value > higher) return higher;
    return value;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
