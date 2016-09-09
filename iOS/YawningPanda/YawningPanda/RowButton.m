//
//  RowButton.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 11/21/12.
//
//

#import "RowButton.h"

@implementation RowButton

@synthesize value, pivot;

+ (id)buttonWithType:(UIButtonType)buttonType
{
    return [super buttonWithType:buttonType];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
