//
//  UICommentList.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 12/9/12.
//
//

#import "UICommentList.h"

#import "Util.h"
#import "UICommentCell.h"

#import <QuartzCore/QuartzCore.h>

@implementation UICommentList

@synthesize startingFrame;
@synthesize startingScrollFrame;
@synthesize swipe;

@synthesize commentTag;
@synthesize busy, status;

#pragma mark - Pull-To-Refresh Delegate

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view;
{
    [self.delegate refreshComments];
}

#pragma mark - View Lifecycle Code

- (id)initWithFrame:(CGRect)frame withTag:(int)tag withViewHeight:(CGFloat)viewHeight
{
    self = [super initWithFrame:frame];

    if (self)
    {
        // Initialization code
        // same coloring as the user info bar.
        self.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.5];
        self.tag = tag;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;

        CGRect sFrm = CGRectMake(0,
                                 35,
                                 frame.size.width,
                                 viewHeight - 40); // - 30 for it to fall off entirely.
        
        /*
         * @note I would make this autoresize width, but! if you do that sometimes
         * the contentview doesn't re-orient properly such as with primary imageview
         *  scrollview.
         */
        UIScrollView *lscroll = [[UIScrollView alloc] initWithFrame:sFrm];
        lscroll.backgroundColor = [UIColor clearColor];
        lscroll.tag = COMMENT_SUBVIEW_SCROLLER;
        lscroll.contentSize = CGSizeMake(frame.size.width, 0); // for now.
//        lscroll.contentSize = CGSizeMake(frame.size.width, 0); // for now.
        lscroll.scrollEnabled = YES;
        lscroll.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        lscroll.userInteractionEnabled = YES;

        self.scroller = lscroll;
        
        [self addSubview:self.scroller];

        /*
         * not necessarily centered unless border is 30.  could place at 2.5, but
         * then it's off.
         */
        CGRect aFrm = CGRectMake(5, 5, 20, 20);
        
        // Are all my spinners grey, or white, which?
        self.busy = \
            [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];

        self.busy.hidesWhenStopped = YES;
        self.busy.frame = aFrm;
        self.busy.tag = COMMENT_SUBVIEW_ACTIVITY;
        
        [self addSubview:self.busy];
        
        CGSize buttonSz = CGSizeMake(55, 25);
        
        /* I should only build these buttons once. */
        UIButton *addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        addBtn.frame = CGRectMake(frame.size.width - ((buttonSz.width + 5) * 2),
                                  5,
                                  buttonSz.width,
                                  buttonSz.height);
        /* future buttons will likely not be this coloring. */
        addBtn.backgroundColor = [UIColor blackColor];
        [addBtn setTitle:@"Add" forState:UIControlStateNormal];
        addBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        addBtn.titleLabel.textColor = [UIColor whiteColor];
        addBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
        addBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [addBtn addTarget:self
                   action:@selector(addCommentTextFieldButton)
         forControlEvents:UIControlEventTouchUpInside];
        
        addBtn.layer.borderColor = [UIColor whiteColor].CGColor;
        addBtn.layer.borderWidth = 1;
        addBtn.layer.cornerRadius = 5;
        addBtn.clipsToBounds = YES;
        addBtn.layer.shadowOffset = CGSizeMake(0, 3);
        addBtn.layer.shadowRadius = 5.0;
        addBtn.layer.shadowColor = [UIColor whiteColor].CGColor;
        addBtn.layer.shadowOpacity = 0.8;
        
        [self addSubview:addBtn];
        
        /* I should only build these buttons once. */
        UIButton *dissBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        dissBtn.frame = CGRectMake(frame.size.width - (buttonSz.width + 5),
                                   5,
                                   buttonSz.width,
                                   buttonSz.height);
        /* future buttons will likely not be this coloring. */
        dissBtn.backgroundColor = [UIColor blackColor];
        [dissBtn setTitle:@"Hide" forState:UIControlStateNormal];
        dissBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        dissBtn.titleLabel.textColor = [UIColor whiteColor];
        dissBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
        dissBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [dissBtn addTarget:self
                    action:@selector(hideComments)
          forControlEvents:UIControlEventTouchUpInside];
        
        dissBtn.layer.borderColor = [UIColor whiteColor].CGColor;
        dissBtn.layer.borderWidth = 1;
        dissBtn.layer.cornerRadius = 5;
        dissBtn.clipsToBounds = YES;
        dissBtn.layer.shadowOffset = CGSizeMake(0, 3);
        dissBtn.layer.shadowRadius = 5.0;
        dissBtn.layer.shadowColor = [UIColor whiteColor].CGColor;
        dissBtn.layer.shadowOpacity = 0.8;
        
        [self addSubview:dissBtn];

        CGFloat xOfs = aFrm.origin.x + aFrm.size.width + 5;
        CGFloat remainingX = frame.size.width - (xOfs + addBtn.frame.origin.x);

        CGRect stFrm = CGRectMake(xOfs, 5, remainingX, 25);

        self.status = [[UILabel alloc] initWithFrame:stFrm];
        self.status.backgroundColor = [UIColor clearColor];
        self.status.font = [UIFont boldSystemFontOfSize:18];
        self.status.textColor = [UIColor whiteColor];
        self.status.tag = COMMENT_SUBVIEW_STATUS;
        self.status.adjustsFontSizeToFitWidth = YES;
        
        [self addSubview:self.status];
        
        self.pull = [[PullToRefreshView alloc] initWithScrollView:self.scroller];
        self.pull.delegate = self;
        [self.scroller addSubview:self.pull];
        
        NSLog(@"Scroller Frame:");
        [Util printRectangle:self.scroller.frame];
        NSLog(@"Pull Frame:");
        [Util printRectangle:self.pull.frame];

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

#pragma mark - Comment Cell Code

/**
 * @brief Build the cell for the comment display.
 */
+ (UIView *)buildCommentCell:(Comment *)comm
                       withY:(CGFloat)yPos
                  withHeight:(CGFloat)height
                   withWidth:(CGFloat)width
                    withUser:(User *)user
              withViewBounds:(CGRect)bounds
{
    /*
     * view is offset 10 from the left of its master view, with y-position.
     * the width is the little white box's width.  the height here is the
     * minimum height.
     *
     * the labels within are 5 offset from the left, and 5 short on the right.
     */
    CGRect currFrm = CGRectMake(10, yPos, width, height);
    
    NSString *auth = nil;
    
    if (user != nil)
    {
        auth = user.display_name;
    }
    else
    {
        auth = comm.author;
    }
    
    UICommentCell *curr = [[UICommentCell alloc] initWithFrame:currFrm
                                                   withComment:comm
                                                      withAuth:auth
                                                withViewBounds:bounds];

    CGFloat realCellHeight = (curr.createLbl.frame.origin.y + curr.createLbl.frame.size.height);
    
    /* to support variable height -- with a minimum */
    if (height < realCellHeight)
    {
        curr.frame = CGRectMake(curr.frame.origin.x,
                                curr.frame.origin.y,
                                width,
                                realCellHeight);
    }
    
    return curr;
}

- (void)addComment:(Comment *)comment withPost:(Post *)post withUser:(User *)user
{
    int count = [post.comments count];
    CGFloat yPos = COMMENT_ROW_VERTICAL_OFFSET;
    CGFloat microHeight = COMMENT_ROW_MINIMUM_HEIGHT;
    CGFloat microWidth = self.superview.frame.size.width - 20;
    
    NSLog(@"comments: %@", post.comments);
    
    if (count == 1)
    {
        self.status.text = [NSString stringWithFormat:@"%d Comment", count];
    }
    else
    {
        self.status.text = [NSString stringWithFormat:@"%d Comments", count];
    }
    
    NSLog(@"result.text set.");

    UIView *newGuy = [UICommentList buildCommentCell:comment
                                               withY:yPos
                                          withHeight:microHeight
                                           withWidth:microWidth
                                            withUser:user
                                      withViewBounds:self.superview.bounds];

    newGuy.tag = self.commentTag++;
    
    CGFloat newTop = yPos + newGuy.frame.size.height + COMMENT_ROW_VERTICAL_GAP;
    
    [UIView animateWithDuration:0.1
                     animations:^{
                         for (UIView *view in [self.scroller subviews])
                         {
                             if (view.tag >= COMMENT_STARTING_INDEX)
                             {
                                 view.frame = CGRectMake(view.frame.origin.x,
                                                         view.frame.origin.y + newTop, // likely only for first.
                                                         view.frame.size.width,
                                                         view.frame. size.height);
                             }
                         }
                     }
                     completion:^(BOOL finished){
                         [self.scroller addSubview:newGuy];
                     }
     ];
    
    self.scroller.contentSize = CGSizeMake(self.scroller.contentSize.width,
                                           self.scroller.contentSize.height + newTop);
}

- (void)loadComments:(NSArray *)data withUser:(User *)user
{
    [self.busy stopAnimating];
    
    /* Delete all the subviews from the scroller... you could hit refresh
     * when there is something there and this didn't account for it.
     */
    for (UIView *sv in [self.scroller subviews])
    {
        /* The scrollindicators are a UIScrollView subview. */
        if (sv.tag >= COMMENT_STARTING_INDEX)
        {
            [sv removeFromSuperview];
        }
    }
    
    self.scroller.contentSize = CGSizeMake(self.scroller.contentSize.width,
                                           self.superview.bounds.size.height);
    
    self.scroller.contentOffset = CGPointMake(0, 0);

    NSLog(@"before loadComments works");
    NSLog(@"commentlist scroller:");
    [Util printRectangle:self.scroller.frame];
    NSLog(@"commentlist contentsize: (w%f, h%f)",
          self.scroller.contentSize.width, self.scroller.contentSize.height);

    if (data == nil || [data count] == 0)
    {
        self.status.text = @"No Comments";
    }
    else
    {
        int count = [data count];
        CGFloat yPos = COMMENT_ROW_VERTICAL_OFFSET;
        CGFloat microHeight = COMMENT_ROW_MINIMUM_HEIGHT;
        CGFloat microWidth = self.superview.bounds.size.width - 20;
        
        self.commentTag = COMMENT_STARTING_INDEX;
        
        if (count == 1)
        {
            self.status.text = [NSString stringWithFormat:@"%d Comment", count];
        }
        else
        {
            self.status.text = [NSString stringWithFormat:@"%d Comments", count];
        }
        
        /* each is 60 height.
         * UILabel Comment (20)
         * UILabel Author  (20)
         * UILabel Created (20)
         */
        
        NSLog(@"Add Comment Cells of width: %f\n", microWidth);
        
        for (int i = 0; i < count; i++)
        {
            Comment *comm = data[i];
            
            UIView *curr = [UICommentList buildCommentCell:comm
                                                     withY:yPos
                                                withHeight:microHeight
                                                 withWidth:microWidth
                                                  withUser:user
                                            withViewBounds:self.superview.bounds];
            
            curr.tag = self.commentTag++;
            
            [self.scroller addSubview:curr];
            
            yPos += curr.frame.size.height + COMMENT_ROW_VERTICAL_GAP;
        }

        NSLog(@"final yPos: %f", yPos);
        NSLog(@"curr height: %f", self.scroller.contentSize.height);
        
        if (yPos > self.scroller.contentSize.height)
        {
            NSLog(@"setting contentSize");
            self.scroller.contentSize = CGSizeMake(self.scroller.contentSize.width, yPos);
        }
    }

    NSLog(@"after loadComments");
    NSLog(@"commentlist scroller:");
    [Util printRectangle:self.scroller.frame];
    NSLog(@"commentlist contentsize: (w%f, h%f)",
          self.scroller.contentSize.width, self.scroller.contentSize.height);

    [self.pull finishedLoading];
}

#pragma mark - Comment View Buttons

- (void)addCommentTextFieldButton
{
    [self.delegate addCommentTextFieldButton];

    return;
}

- (void)hideComments
{
    [self.delegate hideComments];

    return;
}

#pragma mark - Handling User Interaction

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.swipe = SwipeDirection_Unknown;

    [super touchesBegan:touches withEvent:event];

    self.backgroundColor = [UIColor colorWithRed:0.0 green:128.0/255 blue:255.0/255 alpha:0.5];

    return;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];

    CGPoint current;// = [[touches anyObject] locationInView:self];
    CGPoint previous;// = [[touches anyObject] previousLocationInView:self];

    current = [[touches anyObject] locationInView:self];
    previous = [[touches anyObject] previousLocationInView:self];

    CGFloat difference = current.y - previous.y;
    
    if (difference > 0)
    {
        NSLog(@"swiping down.");
        self.swipe = SwipeDirection_Down;
    }
    else if (difference < 0)
    {
        NSLog(@"swiping up.");

        self.swipe = SwipeDirection_Up;

        if (self.frame.size.height == self.superview.bounds.size.height)
        {
            return;
        }
    }
    
    /* later just build this into the UIView as a child. */
    UIScrollView *scroller = (UIScrollView *)[self viewWithTag:COMMENT_SUBVIEW_SCROLLER];

    self.frame = CGRectMake(self.frame.origin.x,
                            self.frame.origin.y + difference,
                            self.frame.size.width,
                            self.frame.size.height - difference);
    
    scroller.frame = CGRectMake(scroller.frame.origin.x,
                                scroller.frame.origin.y,
                                scroller.frame.size.width,
                                scroller.frame.size.height - difference);
    
    // if position is less than half of full height, let's just drop it.
    // XXX: without adjusting the scroll height runs into issues.
    // need to really figure out the stupid animation thing here.

    return;
}

/**
 * @brief If you let go and it's lower than the starting position it will drop
 * it the rest of the way.
 */
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];

    /* later just build this into the UIView as a child. */
    UIScrollView *scroller = (UIScrollView *)[self viewWithTag:COMMENT_SUBVIEW_SCROLLER];

    CGFloat difference = self.startingFrame.size.height - self.startingScrollFrame.size.height;

    if (self.swipe == SwipeDirection_Down)
    {
        /* you lowered it. */
        if (self.frame.size.height < (self.startingFrame.size.height - 20))
        {
            [UIView animateWithDuration:0.2
                             animations:^{
                                 self.frame = CGRectMake(self.frame.origin.x,
                                                         self.frame.origin.y + self.frame.size.height,
                                                         self.frame.size.width,
                                                         0); // so it shrinks.
                             }
                             completion:^(BOOL finished){
                                 [self removeFromSuperview];
                                 
                             }];
        }
        else if (self.frame.size.height < self.superview.bounds.size.height)
        {
            /* lower to half-way? */
            [UIView animateWithDuration:0.2
                             animations:^{
                                 self.frame = CGRectMake(self.frame.origin.x,
                                                         self.startingFrame.origin.y,
                                                         self.frame.size.width,
                                                         self.startingFrame.size.height); // so it shrinks.
                                 
                                 scroller.frame = CGRectMake(scroller.frame.origin.x,
                                                             scroller.frame.origin.y,
                                                             scroller.frame.size.width,
                                                             self.startingScrollFrame.size.height);
                             }
                             completion:^(BOOL finished){
                                 self.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.5];
                             }];
        }
    }
    else if (self.swipe == SwipeDirection_Up)
    {
        if (self.frame.size.height > self.startingFrame.size.height + 20)
        {
            [UIView animateWithDuration:0.2
                             animations:^{
                                 self.frame = CGRectMake(self.frame.origin.x,
                                                         0,
                                                         self.frame.size.width,
                                                         self.superview.bounds.size.height); // so it grows
                                 
                                 scroller.frame = CGRectMake(scroller.frame.origin.x,
                                                             scroller.frame.origin.y,
                                                             scroller.frame.size.width,
                                                             self.superview.bounds.size.height - difference);
                             
                             }
                             completion:^(BOOL finished){
                                 self.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.5];
                             }];
        }
        else
        {
            [UIView animateWithDuration:0.2
                             animations:^{
                                 self.frame = CGRectMake(self.frame.origin.x,
                                                         self.startingFrame.origin.y,
                                                         self.frame.size.width,
                                                         self.startingFrame.size.height); // so it grows

                                 scroller.frame = CGRectMake(scroller.frame.origin.x,
                                                             scroller.frame.origin.y,
                                                             scroller.frame.size.width,
                                                             self.startingScrollFrame.size.height);
                             
                             }
                             completion:^(BOOL finished){
                                 self.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.5];
                             }];
        }
    }
    else
    {
        self.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.5];
    }

    return;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    
    UIScrollView *scroller = (UIScrollView *)[self viewWithTag:COMMENT_SUBVIEW_SCROLLER];

    [UIView animateWithDuration:0.2
                     animations:^{
                         self.frame = CGRectMake(self.frame.origin.x,
                                                 self.startingFrame.origin.y,
                                                 self.frame.size.width,
                                                 self.startingFrame.size.height); // so it shrinks.
                         
                         scroller.frame = CGRectMake(scroller.frame.origin.x,
                                                     scroller.frame.origin.y,
                                                     scroller.frame.size.width,
                                                     self.startingScrollFrame.size.height);
                     }
                     completion:^(BOOL finished){
                         self.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.5];
                     }];
}

@end
