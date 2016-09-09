//
//  UICommentCell.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 11/24/12.
//
//

#import <UIKit/UIKit.h>

#import "Comment.h"

@interface UICommentCell : UIView

@property(strong) UILabel *comment;
@property(strong) UILabel *authlbl;
@property(strong) UILabel *createLbl;

- (id)initWithFrame:(CGRect)frame
        withComment:(Comment *)comment
           withAuth:(NSString *)auth
     withViewBounds:(CGRect)bounds;

@end
