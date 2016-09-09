//
//  UpwardTriangle.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 10/7/12.
//
//

#import "UpwardTriangle.h"

@implementation UpwardTriangle

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
    CGContextMoveToPoint   (ctx, CGRectGetMinX(rect), CGRectGetMaxY(rect));
    CGContextAddLineToPoint(ctx, CGRectGetMidX(rect), CGRectGetMinY(rect));
    CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    CGContextClosePath(ctx);

    /*
     CGFloat red,
     CGFloat green,
     CGFloat blue,
     CGFloat alpha
     */
//    UIColor *tmp = [UIColor lightTextColor];
//    [tmp setFill];
//    CGContextSetAlpha(ctx, 1.0);
    CGContextSetRGBFillColor(ctx, 211.0/255, 211.0/255, 211.0/255, 1);
    CGContextFillPath(ctx);
}


@end
