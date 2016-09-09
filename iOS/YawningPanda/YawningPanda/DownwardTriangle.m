//
//  DownwardTriangle.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 10/7/12.
//
//

#import "DownwardTriangle.h"

@implementation DownwardTriangle

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextBeginPath(ctx);

#if 0
    /* faces down. */
    CGContextMoveToPoint   (ctx, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextAddLineToPoint(ctx, CGRectGetMidX(rect), CGRectGetMaxY(rect));
    CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect), CGRectGetMinY(rect));
#endif
    
    /* faces left. */
    CGContextMoveToPoint   (ctx, CGRectGetMaxX(rect), CGRectGetMinY(rect));
    CGContextAddLineToPoint(ctx, CGRectGetMinX(rect), CGRectGetMidY(rect));
    CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    
    CGContextClosePath(ctx);
    
    /*
     CGFloat red,
     CGFloat green,
     CGFloat blue,
     CGFloat alpha
     */
    CGContextSetRGBFillColor(ctx, 39.0/255, 99.0/255, 24.0/255, 1);
    CGContextFillPath(ctx);
}

@end
