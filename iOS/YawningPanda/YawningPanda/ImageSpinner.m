//
//  ImageSpinner.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/23/12.
//
//

#import "ImageSpinner.h"

@implementation ImageSpinner

@synthesize activity;
@synthesize key;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        /* it's a 20x20 point icon. */
        self.activity = \
            [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        self.activity.frame = CGRectMake((frame.size.width / 2) - 10,
                                          (frame.size.height / 2) - 10,
                                          20, 20);
        self.activity.hidesWhenStopped = YES;
        [self.activity startAnimating];
        
        [self addSubview:self.activity];
    }

    return self;
}

- (void)setImage:(UIImage *)image
{
    [super setImage:image];
    
    if (image != nil)
    {
        [self.activity stopAnimating];
    }
    else
    {
        [self.activity startAnimating];
    }
    
    return;
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
