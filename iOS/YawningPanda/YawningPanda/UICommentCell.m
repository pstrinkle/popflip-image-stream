//
//  UICommentCell.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 11/24/12.
//
//

#import "UICommentCell.h"
#import "Util.h"

#import <QuartzCore/QuartzCore.h>

@implementation UICommentCell

@synthesize comment, authlbl, createLbl;

- (id)initWithFrame:(CGRect)frame
        withComment:(Comment *)commval
           withAuth:(NSString *)auth
     withViewBounds:(CGRect)bounds
{
    self = [super initWithFrame:frame];

    if (self)
    {
        // Initialization code
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.5];
        self.layer.cornerRadius = 9.0;
        self.layer.masksToBounds = YES;
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = [UIColor whiteColor].CGColor;

        CGFloat width = frame.size.width;
        CGFloat labelWidth = width - 10;
        CGFloat labelHeight = 20;
        
        /*
         * This is not going to work for anything more than a dumb
         * one line.
         */
        self.comment = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, labelWidth, labelHeight)];
        self.comment.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.comment.backgroundColor = [UIColor clearColor];
        self.comment.textColor = [UIColor whiteColor];
        self.comment.font = [UIFont systemFontOfSize:16];
        self.comment.lineBreakMode = NSLineBreakByWordWrapping;
        self.comment.textAlignment = UITextAlignmentLeft;
        
        comment.text = commval.comment;
        
        // XXX: Upgrade the bio view in the user table view controller to use this.
        /* I use a slightly narrower width because otherwise an ending character can be slightly cut off. */
        CGFloat newHeight = [commval.comment sizeWithFont:comment.font
                                     constrainedToSize:CGSizeMake(comment.frame.size.width, bounds.size.height)
                                         lineBreakMode:comment.lineBreakMode].height;
        
        self.comment.frame = CGRectMake(comment.frame.origin.x,
                                        comment.frame.origin.y,
                                        comment.frame.size.width,
                                        newHeight);
        comment.numberOfLines = ceilf(newHeight / comment.font.lineHeight);
        
        //    NSLog(@"newHeight: %f", newHeight);
        //    NSLog(@"numlines: %d", comment.numberOfLines);
        
        CGFloat authY = comment.frame.origin.y + comment.frame.size.height;
        
        self.authlbl = [[UILabel alloc] initWithFrame:CGRectMake(5, authY, labelWidth, labelHeight)];
        authlbl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        authlbl.backgroundColor = [UIColor clearColor];
        authlbl.textColor = [UIColor whiteColor];
        authlbl.font = [UIFont systemFontOfSize:14];
        
        authlbl.text = auth;

        CGFloat createY = authlbl.frame.origin.y + authlbl.frame.size.height;
        
        self.createLbl = [[UILabel alloc] initWithFrame:CGRectMake(5, createY, labelWidth, labelHeight)];
        createLbl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        createLbl.backgroundColor = [UIColor clearColor];
        createLbl.textColor = [UIColor whiteColor];
        createLbl.font = [UIFont systemFontOfSize:12];
        
        NSString *ago = [Util timeSinceWhen:commval.createdStamp];
        if ([ago isEqualToString:@"now"])
        {
            createLbl.text = ago;
        }
        else
        {
            createLbl.text = [NSString stringWithFormat:@"%@ ago", ago];
        }
        
        [self addSubview:comment];
        [self addSubview:authlbl];
        [self addSubview:createLbl];
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
