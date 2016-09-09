//
//  UITableCell.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 1/3/13.
//
//

#import "UITableCell.h"

#import <QuartzCore/QuartzCore.h>

@implementation UITableCell

@synthesize spin, heading, refresh;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
    {
        // Initialization code
        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CELL_WIDTH, LABEL_HEIGHT)];

        lbl.backgroundColor = [UIColor colorWithRed:0.0 green:128.0/255 blue:255.0/255 alpha:0.5];
        lbl.textColor = [UIColor whiteColor];
        lbl.textAlignment = NSTextAlignmentCenter;
        lbl.font = [UIFont boldSystemFontOfSize:12];
        
        ImageSpinner *img = [[ImageSpinner alloc] initWithFrame:CGRectMake(THUMBNAIL_MARGIN,
                                                                           lbl.frame.origin.y + lbl.frame.size.height + 10,
                                                                           THUMBNAIL_SIZE,
                                                                           THUMBNAIL_SIZE)];

        img.backgroundColor = [UIColor colorWithRed:0.0 green:128.0/255 blue:255.0/255 alpha:0.5];
        img.userInteractionEnabled = YES;
        
        img.clipsToBounds = YES; // unncessary. : P
        img.layer.cornerRadius = 9.0;
        img.layer.masksToBounds = YES;
        img.layer.borderColor = [UIColor clearColor].CGColor;
        img.layer.borderWidth = 1.0;
        
        self.heading = lbl;
        self.spin = img;
        
        UILabel *cnt = [[UILabel alloc] initWithFrame:CGRectMake(THUMBNAIL_MARGIN,
                                                                 img.frame.origin.y + (THUMBNAIL_SIZE - LABEL_HEIGHT),
                                                                 THUMBNAIL_SIZE - 10,
                                                                 LABEL_HEIGHT)];
        cnt.backgroundColor = [UIColor clearColor];
        cnt.font = [UIFont boldSystemFontOfSize:18];
        cnt.textAlignment = NSTextAlignmentRight;
        cnt.textColor = [UIColor whiteColor];
        cnt.text = @"";
        
        self.refresh = cnt;
        
        [self addSubview:lbl];
        [self addSubview:img];
        [self addSubview:cnt];
    }

    return self;
}

- (void)setImage:(UIImage *)image
{
    self.spin.image = image;
}

- (void)setText:(NSString *)text
{
    self.heading.text = text;
}

- (void)setFont:(UIFont *)font
{
    self.heading.font = font;
}

- (void)setNumberOfLines:(NSInteger)lines
{
    self.heading.numberOfLines = lines;
}

- (void)setRefreshCount:(NSInteger)count
{
    if (count == 0)
    {
        self.refresh.text = @"";
    }
    else
    {
        self.refresh.text = [NSString stringWithFormat:@"%d", count];
    }
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
