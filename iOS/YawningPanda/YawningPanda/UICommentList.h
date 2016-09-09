//
//  UICommentList.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 12/9/12.
//
//

#import <UIKit/UIKit.h>

#import "Post.h"
#import "User.h"
#import "Comment.h"

#import "PullToRefreshView.h"

@protocol CommentDelegate
- (void)refreshComments;
/** @todo For now this is handled outside this. */
- (void)hideComments;
/** @todo For now this is handled outside this. */
- (void)addCommentTextFieldButton;
@end

@interface UICommentList : UIView <PullToRefreshViewDelegate>

enum CommentCellElements
{
    TAG_COMMENT_TEXT_ELEMENT = 0x20000,
    TAG_COMMENT_AUTHOR_ELEMENT,
    TAG_COMMENT_TIMESTAMP_ELEMENT,
};

enum SwipeDirection
{
    SwipeDirection_Unknown = 0,
    SwipeDirection_Up = 1,
    SwipeDirection_Down = 2,
};

enum
{
    COMMENT_SUBVIEW_SCROLLER = 0x0901,
    COMMENT_SUBVIEW_STATUS   = 0x0902,
    COMMENT_SUBVIEW_ACTIVITY = 0x0903
};

#define COMMENT_ROW_VERTICAL_OFFSET 5
#define COMMENT_ROW_VERTICAL_GAP 5
#define COMMENT_ROW_MINIMUM_HEIGHT 65
#define COMMENT_MAXIMUM_VIEW_HEIGHT 200
#define COMMENT_STARTING_INDEX 300

@property(assign) CGRect startingFrame;
@property(assign) CGRect startingScrollFrame;
@property(assign) enum SwipeDirection swipe;

@property(assign) int commentTag; /* This is the next tag value to use. */
@property(strong) UIActivityIndicatorView *busy;
@property(strong) UILabel *status;
@property(strong) UIScrollView *scroller;
@property(strong) PullToRefreshView *pull;

@property(nonatomic, unsafe_unretained) id<CommentDelegate> delegate;

/**
 * @brief Build the cell for the comment display.
 *
 * @param comm the Comment object
 * @param the yPos for the starting point of the frame.
 * @param the minimum height of the frame
 * @param the width of the frame
 * @param the User who wrote this comment
 * @param the super view's bounds.
 *
 * @return The comment Cell.  It's not a UICommentCell yet.
 */
+ (UIView *)buildCommentCell:(Comment *)comm
                       withY:(CGFloat)yPos
                  withHeight:(CGFloat)height
                   withWidth:(CGFloat)width
                    withUser:(User *)user
              withViewBounds:(CGRect)bounds;

- (id)initWithFrame:(CGRect)frame withTag:(int)tag withViewHeight:(CGFloat)viewHeight;
/**
 * @warning Only call this after you've added it to the parent view.
 */
- (void)loadComments:(NSArray *)data withUser:(User *)user;

- (void)addComment:(Comment *)comment withPost:(Post *)post withUser:(User *)user;


@end
