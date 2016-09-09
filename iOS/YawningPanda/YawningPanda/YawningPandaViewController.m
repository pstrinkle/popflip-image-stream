//
//  YawningPandaViewController.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 7/18/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "YawningPandaViewController.h"

#import "APIHandler.h"
#import "EventLogEntry.h"
#import "Post.h"
#import "Comment.h"
#import "PostInfoBundle.h"
#import "WatchList.h"
#import "Util.h"
#import "PivotDetails.h"

#import "PostSetMapViewController.h"

#import "LoginTVC.h"
#import "NewPostTableViewController.h"
#import "PostInfoTVC.h"
#import "PivotHistoryTVC.h"
#import "UserTableViewController.h"


/* Custom UIKit views. */
#import "ImageSpinner.h"
#import "DownwardTriangle.h"
#import "UpwardTriangle.h"
#import "RowButton.h"
#import "UICommentList.h"
#import "UICommentCell.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <QuartzCore/QuartzCore.h>

#define TILE_DIMENSION 90
#define DEGREES_TO_RANDIANS(x) ((x) * M_PI / 180.0)
#define USERINFOVIEW_HEIGHT 50 /* self.userInfoBar.frame.size.height */
#define THEME_GREEN [UIColor colorWithRed:39.0/255 green:99.0/255 blue:24.0/255 alpha:1.0]

@implementation YawningPandaViewController

@synthesize tagLbl, sinceLbl;
@synthesize postInfoBtn;
@synthesize display;
@synthesize mainScroll;

@synthesize currentPost, specifiedUser, userPrefs;
@synthesize favoritePost;
@synthesize userCache;
@synthesize queryCache;
@synthesize markAction;

@synthesize refreshQuery;
@synthesize queryOnGoing;
@synthesize cacheIndex;
@synthesize watchingUser;

@synthesize eventLog;
@synthesize downloadCache;

@synthesize queryTextField, hiddenField;

@synthesize outstandingCreates;
@synthesize lastUsedTags;
@synthesize defaultImage;

@synthesize outstandingItemsLbl;

@synthesize tilesVisible;
@synthesize imageViewTiles;
@synthesize downloadTileLbl;
@synthesize downloadTileCount;

@synthesize apiManager;
@synthesize postStorage;
@synthesize defaults;

@synthesize upperToolBar; //, pivotToolBar;
@synthesize createPostToolbarBtn, replyPostToolbarBtn, queryToolbarBtn;
@synthesize refreshToolbarBtn, titleToolbarBtn;

@synthesize lowerToolBar;
@synthesize meToolbarBtn, starToolbarBtn;
@synthesize commentToolbarBtn;
@synthesize actionToolbarBtn;

@synthesize userInfoBar;
@synthesize userInfoGrown;
@synthesize hideUserTimer;

@synthesize createCommentSpinner, commentOutstanding;
@synthesize commentHiddenField, commentTextField;
@synthesize createCommentHandler;
@synthesize commentAccessory;
@synthesize createCommentPostBtn;

@synthesize currNetStatus, reachNetStatus, downloadLargeImages;

@synthesize queryResults;

#if 0
/* for iOS 6. */
- (bool)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    NSLog(@"supportedInterfaceOrientations called.");
    return UIInterfaceOrientationMaskPortrait;
}
#endif

/******************************************************************************
 * State Preservation and Restoration Code
 ******************************************************************************/

#pragma mark - State Preservation and Restoration Code

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    NSLog(@"%@:encodeRestorableStateWithCoder:%@", self, coder);

    [coder encodeObject:self.currentPost forKey:@"currentPost"];
    [coder encodeObject:self.specifiedUser forKey:@"specifiedUser"];
    [coder encodeObject:self.lastUsedTags forKey:@"lastUsedTags"];

    [coder encodeObject:self.queryCache forKey:@"queryCache"];
    [coder encodeObject:self.userCache forKey:@"userCache"];
    [coder encodeObject:self.eventLog forKey:@"eventLog"];
    [coder encodeObject:self.postStorage forKey:@"postStorage"];
    [coder encodeInt:self.cacheIndex forKey:@"cacheIndex"];
    [coder encodeObject:self.userPrefs forKey:@"userPrefs"];
    [coder encodeObject:self.queryResults forKey:@"queryResults"];
    
    [coder encodeFloat:self.mainScroll.zoomScale forKey:@"mainScroll.zoomScale"];

    CGFloat ofsX = self.mainScroll.contentOffset.x + (self.view.bounds.size.width / 2) - 1;
    CGFloat ofsY = self.mainScroll.contentOffset.y + (self.view.bounds.size.height / 2) - 1;

    [coder encodeFloat:ofsX forKey:@"mainScroll.viewcenter.x"];
    [coder encodeFloat:ofsY forKey:@"mainScroll.viewcenter.y"];
    [coder encodeFloat:self.mainScroll.contentOffset.x forKey:@"mainScroll.contentOffset.x"];
    [coder encodeFloat:self.mainScroll.contentOffset.y forKey:@"mainScroll.contentOffset.y"];
    
    [coder encodeBool:self.allHidden forKey:@"allHidden"];
    NSLog(@"allHidden on encode: %d", self.allHidden);

    NSLog(@"modal view controller at encode time: %@", self.modalViewController);
    NSLog(@"navigation view controller: %@", self.navigationController.viewControllers);

    // consider saving the zoomscale and center for the mainScroll and zoom
    // after you load the view.

    /* viewdidload needs to save/restore whatever query they were in the middle of. */

    [super encodeRestorableStateWithCoder:coder];

    return;
}

/*
 * This is called after viewDidLoad
 */
- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    NSLog(@"%@:decodeRestorableStateWithCoder:%@", self, coder);

    /*
     * We need to let the view re-build stuff, which is fine, but then it needs
     * to be set with certain stuff.  I am fairly certain it's OK to drop the
     * keyboard, etc.
     */
    if ([coder containsValueForKey:@"currentPost"])
    {
        self.currentPost = [coder decodeObjectForKey:@"currentPost"];
    }
    if ([coder containsValueForKey:@"specifiedUser"])
    {
        self.specifiedUser = [coder decodeObjectForKey:@"specifiedUser"];
    }
    if ([coder containsValueForKey:@"lastUsedTags"])
    {
        self.lastUsedTags = [coder decodeObjectForKey:@"lastUsedTags"];
    }
    if ([coder containsValueForKey:@"cacheIndex"])
    {
        self.cacheIndex = [coder decodeIntForKey:@"cacheIndex"];
        NSLog(@"cacheIndex:%d", self.cacheIndex);
    }
    if ([coder containsValueForKey:@"queryCache"])
    {
        id x = [coder decodeObjectForKey:@"queryCache"];
        if (x != nil)
        {
            self.queryCache = x;
        }
    }
    if ([coder containsValueForKey:@"userCache"])
    {
        id x = [coder decodeObjectForKey:@"userCache"];
        if (x != nil)
        {
            self.userCache = x;
        }
    }
    if ([coder containsValueForKey:@"eventLog"])
    {
        id x = [coder decodeObjectForKey:@"eventLog"];
        if (x != nil)
        {
            self.eventLog = x;
        }

        NSLog(@"Can decode eventLog");
        NSLog(@"eventLog: %@", self.eventLog);
    }
    if ([coder containsValueForKey:@"postStorage"])
    {
        id x = [coder decodeObjectForKey:@"postStorage"];
        if (x != nil)
        {
            self.postStorage = x;
        }
    }
    if ([coder containsValueForKey:@"userPrefs"])
    {
        id x = [coder decodeObjectForKey:@"userPrefs"];
        if (x != nil)
        {
            self.userPrefs = x;
        }
    }
    if ([coder containsValueForKey:@"queryResults"])
    {
        id x = [coder decodeObjectForKey:@"queryResults"];
        if (x != nil)
        {
            self.queryResults = x;
        }
    }
    
    CGFloat zoom = 1.0;
    CGPoint center = CGPointMake(0, 0);
    CGPoint contentOffset = CGPointMake(0, 0);

    /* Update the view structure. */
    if ([self.postStorage.postId count] > 0)
    {
        [self updateView:[self.postStorage postAtIndex:self.cacheIndex]];
    }

    if ([coder containsValueForKey:@"allHidden"])
    {
        self.allHidden = [coder decodeBoolForKey:@"allHidden"];
        
        NSLog(@"allHidden on decode: %d", self.allHidden);
        
        // if hidden, hide things.
        if (self.allHidden)
        {
            [self hideDisplayItems];
        }
        else
        {
            [self showDisplayItems];
        }
    }
    if ([coder containsValueForKey:@"mainScroll.zoomScale"])
    {
        zoom = [coder decodeFloatForKey:@"mainScroll.zoomScale"];
    }    
    if ([coder containsValueForKey:@"mainScroll.contentOffset.x"] && [coder containsValueForKey:@"mainScroll.contentOffset.y"])
    {
        CGFloat x = [coder decodeFloatForKey:@"mainScroll.contentOffset.x"];
        CGFloat y = [coder decodeFloatForKey:@"mainScroll.contentOffset.y"];
        
        contentOffset = CGPointMake(x, y);
    }
    if ([coder containsValueForKey:@"mainScroll.viewcenter.x"] && [coder containsValueForKey:@"mainScroll.viewcenter.y"])
    {
        CGFloat x = [coder decodeFloatForKey:@"mainScroll.viewcenter.x"];
        CGFloat y = [coder decodeFloatForKey:@"mainScroll.viewcenter.y"];

        center = CGPointMake(x, y);
    }

    /* Zoomed in? */
    if (zoom != 1.0 && (contentOffset.x != 0 || contentOffset.y != 0))
    {
        CGRect zoomed = [self zoomRectForScrollView:self.mainScroll
                                          withScale:zoom
                                         withCenter:center];
        [self.mainScroll zoomToRect:zoomed animated:YES];
        [self.mainScroll setContentOffset:contentOffset animated:YES]; // this may not be necessary.
    }

    [super decodeRestorableStateWithCoder:coder];

    return;
}

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    NSLog(@"yp: viewControllerWithRestorationIdentifierPath:%@ :%@", identifierComponents, coder);

    YawningPandaViewController *myViewController = [[YawningPandaViewController alloc] initWithNibName:@"YawningPandaViewController" bundle:nil];
    
    NSLog(@"allocated yp: %@", myViewController);
    return myViewController;
}

/******************************************************************************
 * TextView Delegate Code
 ******************************************************************************/

#pragma mark - TextView Delegate Code

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if (textView == self.commentTextField)
    {
        NSLog(@"began editing comment textfield: %@", textView.superview);
    }
    
    return YES;

}

- (void)textViewDidChange:(UITextView *)textView
{
    if (textView == self.commentTextField)
    {
        NSLog(@"comment textfield edited.");
        
//        CGFloat startLines = ceilf(textView.frame.size.height / textView.font.lineHeight);
        
        CGFloat newHeight =
        [textView.text sizeWithFont:textView.font
                   constrainedToSize:CGSizeMake(textView.frame.size.width, self.view.bounds.size.height)
                       lineBreakMode:NSLineBreakByWordWrapping].height;

        CGFloat numLines = ceilf(newHeight / textView.font.lineHeight);
        
        NSLog(@"textView: newHeight: %f", newHeight);
        NSLog(@"textView: numlines: %f", numLines);
        
        if (numLines < 4 && numLines > 0)
        {
            CGRect mFrm = self.commentAccessory.frame;
            CGRect cFrm = self.commentTextField.frame;
        
            // need to have old height to find how much we should grow it.
            self.commentAccessory.frame = CGRectMake(mFrm.origin.x,
                                                     mFrm.origin.y,
                                                     mFrm.size.width,
                                                     mFrm.size.height + (newHeight - cFrm.size.height));
            self.commentTextField.frame = CGRectMake(cFrm.origin.x,
                                                     cFrm.origin.y,
                                                     cFrm.size.width,
                                                     newHeight);
        }
    }
}

/******************************************************************************
 * Utility Code
 ******************************************************************************/

#pragma mark - Utility Code

/**
 * @brief This is called by apihandler:didCompleteQuery and also by setCache,
 * which is called from the home view.
 */
- (void)handleQueryResults:(NSMutableArray *)data
{
    /*
     * If this was the first query and has results, or a later query without,
     * we want this button enabled.
     */
    if ([data count] > 0 || [self.postStorage.postId count] > 0)
    {
        self.refreshToolbarBtn.enabled = YES;
    }
    
    if (self.refreshQuery == YES)
    {
        self.refreshQuery = NO;
        
        NSLog(@"Refresh Query Returned.");

        NSMutableArray *newIds = [[NSMutableArray alloc] init];

        for (int i = 0; i < [data count]; i++)
        {
            Post *loopPost = data[i]; /* may need to retain this */

            (self.postStorage.posts)[loopPost.postid] = loopPost;
            [newIds addObject:loopPost.postid];
        }
        
        [self.postStorage.postId replaceObjectsInRange:NSMakeRange(0,0)
                                  withObjectsFromArray:newIds];

        self.cacheIndex = 0;
        [self.postStorage prune];
    }
    else
    {
        NSLog(@"setting new cache.");
        [self.postStorage setCache:data];
        [self.display setImage:nil];
    }
    
    /*
     * XXX: This won't be necessarily good to do if they hit refresh, albeit it
     * was already done on the pivot thing.
     */
    self.cacheIndex = 0;
    
    Post *post = [self.postStorage postAtIndex:self.cacheIndex];
    
    /* did the query return this entry as the first one */
    if ([post.postid isEqualToString:self.currentPost])
    {
        if ([self.postStorage.postId count] > 1)
        {
            self.cacheIndex += 1;
            post = [self.postStorage postAtIndex:self.cacheIndex];
        }
    }
    
    /* turn the spinner back on if we have to queue the current image. */
    post = [self.postStorage postAtIndex:self.cacheIndex];
    
    [self updateView:post];
    
    /* looping through the entire thing is a bit of a waste */
    int cacheCount = [self.postStorage.postId count];
    
    for (int i = 0; i < cacheCount; i++)
    {
        Post *loopPost = [self.postStorage postAtIndex:i];
        User *valueForKey = (self.userCache)[loopPost.author];
        
        if (valueForKey != nil)
        {
            loopPost.screen_name = valueForKey.screen_name;
            loopPost.display_name = valueForKey.display_name;
        }
    }
    
    /* We know for a fact we haven't started caching the images or users. */
    cacheCount = [self.postStorage.postId count];
    
    for (int i = 0; i < MIN(10, cacheCount); i++)
    {
        Post *preCachePost = [self.postStorage postAtIndex:i];
        
        if (preCachePost.image == nil && preCachePost.cachingImage == NO)
        {
            preCachePost.cachingImage = YES;
            [self.apiManager viewPost:preCachePost.postid
                              asLarge:self.downloadLargeImages];
        }
        
        if (![self.downloadCache containsObject:preCachePost.author])
        {
            if (preCachePost.screen_name == nil && preCachePost.cachingUser == NO)
            {
                preCachePost.cachingUser = YES;
                
                [self.apiManager getAuthor:preCachePost.author
                                    asUser:self.specifiedUser];
                
                [self.downloadCache addObject:preCachePost.author];
            }
        }
    }
}

/**
 * @brief Add an event to the event log.
 *
 * @param type
 * @param info details
 */
- (void)createEvent:(enum EventType)type
           withInfo:(NSString *)info
           withData:(NSDictionary *)data
{
    EventLogEntry *eventEntry = [[EventLogEntry alloc] init];
    eventEntry.note = info;
    eventEntry.eventType = type;
    eventEntry.details = data;

    [self.eventLog insertObject:eventEntry atIndex:0];

    return;
}

/**
 * @brief Build the accessory view for the hidden text field that contains the
 * search field, etc.
 */
- (UIView *)buildQueryFieldAccessory
{
    UIToolbar *accessView = [[UIToolbar alloc] init];
    [accessView setBarStyle:UIBarStyleBlackTranslucent];
    [accessView sizeToFit];
    accessView.autoresizingMask = \
        accessView.autoresizingMask | UIViewAutoresizingFlexibleHeight;

    UIBarButtonItem *flexible = \
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                      target:nil
                                                      action:nil];

    UIBarButtonItem *cancel = \
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                      target:self
                                                      action:@selector(cancelQueryBtnHandler)];

    // CGFloat x, CGFloat y, CGFloat width, CGFloat height)
    CGRect queryFrm = CGRectMake(0, 0,
                                 accessView.frame.size.width - 100,
                                 accessView.frame.size.height - 10);

    /* each time this is called it releases the previous version, so maybe I should just build this once. */
    self.queryTextField = [[UITextField alloc] initWithFrame:queryFrm];
    self.queryTextField.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.queryTextField.returnKeyType = UIReturnKeySearch;
    self.queryTextField.opaque = NO;
    self.queryTextField.delegate = self;
    self.queryTextField.borderStyle = UITextBorderStyleLine;
    self.queryTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.queryTextField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.queryTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    // UIEdgeInsetsMake(-8,-8,-8,-8);
    self.queryTextField.placeholder = @"query user";
    self.queryTextField.textColor = [UIColor lightTextColor];
//    self.queryTextField.clearButtonMode = UITextFieldViewModeWhileEditing;

    UIBarButtonItem *textFieldItem = \
        [[UIBarButtonItem alloc] initWithCustomView:queryTextField];

    [accessView setItems:@[textFieldItem, flexible, cancel]
                animated:YES];

    return accessView;
}

/**
 * @brief Build the accessory view for the hidden comment text field.
 */
- (UIView *)buildCommentFieldAccessory
{
    /* update the height below */
    UIView *fullView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 0)];
    self.commentAccessory = fullView;
    fullView.backgroundColor = [UIColor grayColor];
    
    UIToolbar *accessView = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
//    [accessView setBarStyle:UIBarStyleBlackTranslucent];
    accessView.barStyle = UIBarStyleDefault;
//    [accessView sizeToFit];
    accessView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    UIBarButtonItem *flexible = \
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                  target:nil
                                                  action:nil];
    
    UIBarButtonItem *title = \
        [[UIBarButtonItem alloc] initWithTitle:@"Enter Comment"
                                         style:UIBarButtonItemStylePlain
                                        target:nil
                                        action:nil];
    title.enabled = NO;
    
    UIBarButtonItem *cancel = \
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                      target:self
                                                      action:@selector(cancelCommentCreate)];

    UIBarButtonItem *post = \
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                      target:self
                                                      action:@selector(createCommentBtnHandler:)];
    [post setTitle:@"Post"];
    self.createCommentPostBtn = post;
    
    UIActivityIndicatorView *busy = \
        [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    busy.hidesWhenStopped = YES;
    self.createCommentSpinner = busy;
    
    UIBarButtonItem *busyItem = [[UIBarButtonItem alloc] initWithCustomView:busy];

    // CGFloat x, CGFloat y, CGFloat width, CGFloat height)
    CGRect queryFrm = CGRectMake(5,
                                 accessView.frame.size.height + 5,
                                 fullView.frame.size.width - 10,
                                 25);

    self.commentTextField = [[UITextView alloc] initWithFrame:queryFrm];
    self.commentTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.commentTextField.returnKeyType = UIReturnKeyDefault;
    self.commentTextField.opaque = NO;
    self.commentTextField.delegate = self;
    self.commentTextField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    self.commentTextField.textColor = [UIColor darkTextColor];
    self.commentTextField.backgroundColor = [UIColor whiteColor];
    self.commentTextField.font = [UIFont systemFontOfSize:14];
    self.commentTextField.contentMode = UIViewContentModeTopLeft;
    self.commentTextField.scrollEnabled = YES;

    self.commentTextField.layer.cornerRadius = 5;
    self.commentTextField.clipsToBounds = YES;

    [accessView setItems:@[cancel, flexible, title, flexible, busyItem, post]];
    [fullView addSubview:accessView];
    [fullView addSubview:self.commentTextField];

    /*
     * [accessView]
     * commentTextField
     */
    [fullView setFrame:CGRectMake(0, 0,
                                  self.view.bounds.size.width,
                                  accessView.frame.size.height + self.commentTextField.frame.size.height + 10)];

    return fullView;
}

#pragma mark - User Info Bar

/**
 * @brief Build the User Info Bar programmatically.  Could do in the Interface
 * Builder.
 *
 * @warn If you change the tagLbl's position, update this.
 */
- (void)buildUserInfoBar
{
    CGRect tagsFrm = self.tagLbl.frame;
    float yPos = tagsFrm.origin.y + tagsFrm.size.height;
    float width = self.view.bounds.size.width;

    float vwidth = width - 10;  // view width is 10 points narrower
    float vheight = USERINFOVIEW_HEIGHT; // view height

    float avatarsq = 40; // avatar is a square
    float lwidth = vwidth - (50 + 35); // labels go from the avatar full width

    CGRect tmpFrm = CGRectMake(5, yPos, vwidth, vheight);

    CGRect avatFrm = CGRectMake(5, 5, avatarsq, avatarsq);
    CGRect dispFrm = CGRectMake(50, 5, lwidth, 20);
    CGRect realFrm = CGRectMake(50, 30, lwidth, 20);
    CGRect triFrm = CGRectMake(50 + lwidth, 10, 20, 35);

    UIView *tmp = [[UIView alloc] initWithFrame:tmpFrm];
    tmp.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.5];
    tmp.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    tmp.layer.cornerRadius = 9.0;
    tmp.layer.masksToBounds = YES;
    /* Add shadow. */
    tmp.layer.shadowOffset = CGSizeMake(0, 3);
    tmp.layer.shadowRadius = 5.0;
    tmp.layer.shadowColor = [UIColor blackColor].CGColor;
    tmp.layer.shadowOpacity = 0.8;

    ImageSpinner *avatar = [[ImageSpinner alloc] initWithFrame:avatFrm];
    avatar.tag = 900;
    avatar.contentMode = UIViewContentModeScaleToFill;
    avatar.clipsToBounds = YES;
    avatar.backgroundColor = [UIColor clearColor];
    avatar.layer.cornerRadius = 9.0;
    avatar.layer.masksToBounds = YES;

    UILabel *displayName = [[UILabel alloc] initWithFrame:dispFrm];
    displayName.tag = 901;
    displayName.font = [UIFont boldSystemFontOfSize:18];
    displayName.backgroundColor = [UIColor clearColor];
    displayName.textColor = [UIColor lightTextColor];
    displayName.clipsToBounds = YES;
    displayName.adjustsFontSizeToFitWidth = YES;

    /* XXX: This looks too close to the bottom of the view because it's actually
     *  making it to the bottom of the view.  It starts 5 below the one above it
     *  which starts 5 below the top.  So, it's weird that it bumps right up 
     * against the bottom of the view.
     */
    UILabel *realName = [[UILabel alloc] initWithFrame:realFrm];
    realName.tag = 902;
    realName.font = [UIFont systemFontOfSize:18];
    realName.backgroundColor = [UIColor clearColor];
    realName.textColor = [UIColor lightTextColor];
    realName.clipsToBounds = YES;
    realName.adjustsFontSizeToFitWidth = YES;

    DownwardTriangle *tri = [[DownwardTriangle alloc] initWithFrame:triFrm];
    tri.backgroundColor = [UIColor clearColor];
    tri.tag = 903;
    tri.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin; // with this set it will always stay to the right.


    CGSize buttonSz = CGSizeMake(100, 25);
    
    /* I should only build these buttons once. */
    UIButton *userBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    userBtn.frame = CGRectMake(5, 55, buttonSz.width, buttonSz.height);
    userBtn.backgroundColor = THEME_GREEN;
    [userBtn setTitle:@"View User" forState:UIControlStateNormal];
    userBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    userBtn.titleLabel.textColor = [UIColor whiteColor];
    userBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
    userBtn.tag = 904;
    [userBtn addTarget:self
                action:@selector(userInfoBtnHandler)
      forControlEvents:UIControlEventTouchUpInside];

    userBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    userBtn.layer.borderWidth = 1;
    userBtn.layer.cornerRadius = 5;
    userBtn.clipsToBounds = YES;
    userBtn.layer.shadowOffset = CGSizeMake(0, 3);
    userBtn.layer.shadowRadius = 5.0;
    userBtn.layer.shadowColor = [UIColor whiteColor].CGColor;
    userBtn.layer.shadowOpacity = 0.8;

#if 0 /* more round. */
    userBtn.layer.cornerRadius = 9.0;
    userBtn.layer.masksToBounds = YES;
    /* Add shadow. */
    userBtn.layer.shadowOffset = CGSizeMake(0, 3);
    userBtn.layer.shadowRadius = 5.0;
    userBtn.layer.shadowColor = [UIColor blackColor].CGColor;
    userBtn.layer.shadowOpacity = 0.8;
#endif
    
    UIButton *postBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    postBtn.frame = CGRectMake(5 + buttonSz.width + 5, 55, buttonSz.width, buttonSz.height);
    postBtn.backgroundColor = THEME_GREEN;
    [postBtn setTitle:@"View Post" forState:UIControlStateNormal];
    postBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    postBtn.titleLabel.textColor = [UIColor whiteColor];
    postBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
    postBtn.tag = 905;
    [postBtn addTarget:self
                action:@selector(postInfoBtnHandler)
      forControlEvents:UIControlEventTouchUpInside];
    
    postBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    postBtn.layer.borderWidth = 1;
    postBtn.layer.cornerRadius = 5;
    postBtn.clipsToBounds = YES;
    postBtn.layer.shadowOffset = CGSizeMake(0, 3);
    postBtn.layer.shadowRadius = 5.0;
    postBtn.layer.shadowColor = [UIColor whiteColor].CGColor;
    postBtn.layer.shadowOpacity = 0.8;

    [tmp addSubview:userBtn];
    [tmp addSubview:postBtn];
    [tmp addSubview:tri];
    [tmp addSubview:avatar];
    [tmp addSubview:displayName];
    [tmp addSubview:realName];

    self.userInfoBar = tmp;
    self.userInfoBar.alpha = 0.0;

    UITapGestureRecognizer *tap = \
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(userInfoHandler:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;

    [tmp addGestureRecognizer:tap];

    [self.view addSubview:tmp];
    
    self.userInfoGrown = NO;

    return;
}

/**
 * @brief Call this to temporarily set the user info bar with minimal info.
 */
- (void)setUserInfoBarWithID:(NSString *)author
{
    NSLog(@"setting userinfobar: %@", author);
    
    ImageSpinner *avatar = (ImageSpinner *)[self.userInfoBar viewWithTag:900];
    UILabel *displayName = (UILabel *)[self.userInfoBar viewWithTag:901];
    UILabel *realName = (UILabel *)[self.userInfoBar viewWithTag:902];
    
    avatar.image = nil;
    displayName.text = author;
    realName.text = nil;
}

/**
 * @brief Call this to set the information before displaying it.
 */
- (void)setUserInfoBarUser:(User *)user
{
    NSLog(@"setting userinfobar: %@, name: %@, image: %@",
          user, user.display_name, user.image);

    ImageSpinner *avatar = (ImageSpinner *)[self.userInfoBar viewWithTag:900];
    UILabel *displayName = (UILabel *)[self.userInfoBar viewWithTag:901];
    UILabel *realName = (UILabel *)[self.userInfoBar viewWithTag:902];

    if (user != nil)
    {
        if (user.image == nil)
        {
            avatar.image = nil;
        }
        else
        {
            CGSize shrink = CGSizeMake(40, 40);

            UIGraphicsBeginImageContext(shrink);
            [user.image drawInRect:CGRectMake(0, 0, shrink.width, shrink.height)];
            UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();

            avatar.image = newImage;
        }

        displayName.text = user.display_name;
        realName.text = user.realish_name;
    }
    else
    {
        avatar.image = nil;
        displayName.text = @"";
        realName.text = @"";
    }

    return;
}

/**
 * @brief Display the User Info Bar.
 */
- (void)displayUserInfoBar
{
    if (self.userInfoBar.alpha == 1)
    {
        return;
    }

    self.userInfoBar.alpha = 0.0;

    [UIView animateWithDuration:0.3
                     animations:^{
                         self.userInfoBar.alpha = 1.0;
                     }];

    return;
}

/**
 * @brief This is a sub-function effectively because we sometimes want to 
 * shrink the view instead of just fading out.
 *
 * This shrinks very quickly!
 */
- (void)shrinkUserInfoBar
{
    CGRect userFrm = self.userInfoBar.frame;
    UIView *triangle = [self.userInfoBar viewWithTag:903];

    [UIView animateWithDuration:0.0
                     animations:^{
                         triangle.transform = CGAffineTransformMakeRotation(DEGREES_TO_RANDIANS(0));
                         self.userInfoBar.frame = CGRectMake(userFrm.origin.x,
                                                             userFrm.origin.y,
                                                             userFrm.size.width,
                                                             USERINFOVIEW_HEIGHT);
                     }
                     completion:^(BOOL finished){
                         self.userInfoGrown = NO;
                     }];

    return;
}

/**
 * @brief Hide the User Info Bar.  This will be called if the user does a 
 * single-tap transition or the timer goes off (currently there is no timer.)
 *
 * Because the information will be wrong at first.
 */
- (void)hideUserInfoBar
{
    if (self.userInfoBar.alpha == 0)
    {
        return;
    }

    self.userInfoBar.alpha = 1.0;
    CGRect userFrm = self.userInfoBar.frame;
    UIView *triangle = [self.userInfoBar viewWithTag:903];
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         triangle.transform = CGAffineTransformMakeRotation(DEGREES_TO_RANDIANS(0));
                         self.userInfoBar.alpha = 0.0;
                         self.userInfoBar.frame = CGRectMake(userFrm.origin.x,
                                                             userFrm.origin.y,
                                                             userFrm.size.width,
                                                             USERINFOVIEW_HEIGHT);
                     }
                     completion:^(BOOL finished){
                         self.userInfoGrown = NO;
                     }];

    return;
}

/**
 * @brief This function is called to update the outstanding posts indicator.
 */
- (void)updateOutStandingPosts
{
    if (self.outstandingCreates == 0) // fade it out.
    {
        self.outstandingItemsLbl.alpha = 0.5;
        
        [UIView animateWithDuration:0.5
                         animations:^{
                             self.outstandingItemsLbl.alpha = 0.0;
                         }];
    }
    else
    {
        self.outstandingItemsLbl.text = \
            [NSString stringWithFormat:@"CREATING: %d",
             self.outstandingCreates];

        if (self.outstandingCreates == 1) // fade it in.
        {
            self.outstandingItemsLbl.alpha = 0.00;
            
            [UIView animateWithDuration:0.5
                             animations:^{
                                 self.outstandingItemsLbl.alpha = 0.5;
                             }];
        }
    }

    return;
}

/**
 * @brief Set the view to the beginning view, no post, no query, no data.
 */
- (void)resetView
{
    self.titleToolbarBtn.title = @"0/0";
    self.tagLbl.text = @"";
    self.sinceLbl.text = @"";
    self.currentPost = nil;

    self.refreshToolbarBtn.enabled = NO;
    self.replyPostToolbarBtn.enabled = NO;
    self.starToolbarBtn.enabled = NO;
    self.actionToolbarBtn.enabled = NO;
    self.postInfoBtn.enabled = NO;

    self.watchingUser = NO;
    self.display.image = nil;
    [self.mainScroll setZoomScale:1.0];
    [self hideUserInfoBar];
    [self hideComments];

    self.allHidden = NO;

    return;
}

/**
 * @brief This method updates the YawningPandaViewController to detail the
 * current post information on the GUI.
 *
 * @param post the Post instance to use.
 */
- (void)updateView:(Post *)post
{
    if (post == nil)
    {
        return;
    }

    [self shrinkUserInfoBar];
    [self.mainScroll setZoomScale:1.0 animated:YES];

    UIImage *img = [post image];

    self.display.clipsToBounds = YES;
    self.display.image = img;
    [self.display setNeedsDisplay];

    if (img == nil) // need to download image
    {
        if (post.cachingImage == NO)
        {
            post.cachingImage = YES;
            [self.apiManager viewPost:post.postid
                              asLarge:self.downloadLargeImages];
        }
    }

    NSString *ago = [Util timeSinceWhen:post.createdStamp];
    if ([ago isEqualToString:@"now"])
    {
        self.sinceLbl.text = ago;
    }
    else
    {
        self.sinceLbl.text = [NSString stringWithFormat:@"%@ ago", ago];
    }

    self.titleToolbarBtn.title = [NSString stringWithFormat:@"%d/%d",
                                  self.cacheIndex + 1,
                                  [self.postStorage.postId count]];

    if (post.num_comments == 0)
    {
        self.commentToolbarBtn.title = @"+";
    }
    else
    {
        self.commentToolbarBtn.title = [NSString stringWithFormat:@"%d",
                                        post.num_comments];
    }

    /* The following buttons are really only valid once a query has returned. */
    self.refreshToolbarBtn.enabled = YES;
    self.replyPostToolbarBtn.enabled = YES;
    self.actionToolbarBtn.enabled = YES;
    self.starToolbarBtn.enabled = YES;
    self.postInfoBtn.enabled = YES;

    /* Are we watching this user? */
    WatchList *mywatches = (self.userPrefs)[@"watching"];

    self.watchingUser = NO;
    if ([mywatches.userids containsObject:post.author])
    {
        self.watchingUser = YES;
    }

    self.currentPost = post.postid; // to enable query shift detection.
    self.tagLbl.text = [post.tags componentsJoinedByString:@", "];

    User *user = (self.userCache)[post.author];
    if (user == nil)
    {
        [self setUserInfoBarWithID:post.author];
    }
    else
    {
        [self setUserInfoBarUser:user];
    }

    [self displayUserInfoBar];

    [self.hideUserTimer invalidate];
    self.hideUserTimer = \
        [NSTimer scheduledTimerWithTimeInterval:2.0
                                         target:self
                                       selector:@selector(hideUserInfoBar)
                                       userInfo:nil
                                        repeats:NO];

    return;
}

/**
 * @brief Debug the sliding window.
 */
- (void)determineWindow
{
    NSMutableArray *indexes = [[NSMutableArray alloc] init];
    
    int cacheCount = [self.postStorage.postId count];
    
    for (int i = 0; i < cacheCount; i++)
    {
        Post *post = [self.postStorage postAtIndex:i];

        if (post.image != nil || post.cachingImage)
        {
            [indexes addObject:@(i)];
        }
    }

    NSLog(@"current: %d, window: %@",
          self.cacheIndex,
          [indexes componentsJoinedByString:@", "]);

    return;
}

/**
 * @brief Do a quick pass and free all images.
 */
- (void)flushCache
{
    [self.postStorage flushImages];

    return;
}

/**
 * @brief This queues items later in the array (not necessarily time, just 
 * index).  It also goes back in index and frees the images.
 *
 * @param currentIndex it knows where you store the posts.... and technically 
 * which post you're on -- but you have to tell it the index.
 */
- (void)queueForward:(int)currentIndex
{
    /* last index minus current index is the number of entries left. */
    int remains = [Util lastIndex:self.postStorage.postId] - currentIndex;
    int toQueue = MIN(5, remains);
    int startingIndex = currentIndex + 1;

    NSLog(@"queueForward (%d)", currentIndex);
    
    if (remains == 0)
    {
        NSLog(@"non remain to queue.");
        return;
    }

    /* Queue the future. really could just move +5 with forIndx++ */
    for (int i = startingIndex; i < (startingIndex + toQueue); i++)
    {
        Post *nextPost = [self.postStorage postAtIndex:i];

        // need to download image
        if (nextPost.image == nil && nextPost.cachingImage == NO)
        {
            NSLog(@"caching index: %d", i);

            nextPost.cachingImage = YES;
            [self.apiManager viewPost:nextPost.postid
                              asLarge:self.downloadLargeImages];
        }

        if (nextPost.screen_name == nil && nextPost.cachingUser == NO)
        {
            /* 
             * The else case cannot happen; didCompleteQuery goes through the 
             * user list.
             */
            if (![self.downloadCache containsObject:nextPost.author])
            {
                nextPost.cachingUser = YES;

                [self.apiManager getAuthor:nextPost.author
                                    asUser:self.specifiedUser];

                [self.downloadCache addObject:nextPost.author];
            }
        }
    }

    /* Clear the trailing images. */
    int backWindowStarts = currentIndex - 5;
    if (backWindowStarts >= 0)
    {
        NSLog(@"backWindowStarts: %d", backWindowStarts);

        /* This shouldn't ever have to go to the very end once it's run once. */
        for (int i = backWindowStarts; i > -1; i--)
        {
            Post *prevPost = [self.postStorage postAtIndex:i];

            if (prevPost.image == nil && prevPost.cachingImage == NO)
            {
                break;
            }

            prevPost.image = nil;
            prevPost.cachingImage = NO;
            NSLog(@"de-caching index: %d", i);
        }
    }

    return;
}

/**
 * @brief This queues items at earlier array positions and frees the future 
 * posts.  The goal of this and queueForward is to maintain a sliding window.
 * I would probably do well to manage this within a data structure than on the
 * "raw" array thing --- but that is something I can easily do later.
 *
 * @param currentIndex it knows where you store the posts, etc.
 */
- (void)queueBackward:(int)currentIndex
{
    /* download the previous five images. */
    int cached = 0;
    
    NSLog(@"queueBackward (%d)", currentIndex);
    
    for (int i = currentIndex; i > -1; i--)
    {
        Post *prevPost = [self.postStorage postAtIndex:i];
        
        if (prevPost.image == nil && prevPost.cachingImage == NO)
        {
            NSLog(@"caching index: %d", i);
            
            prevPost.cachingImage = YES;
            [self.apiManager viewPost:prevPost.postid
                              asLarge:self.downloadLargeImages];
        }
        
        cached += 1;
        
        if (cached >= 5) /* only go back five */
        {
            break;
        }
    }
    
    /* free the later images */
    int lastI = [Util lastIndex:self.postStorage.postId];
    
    if (currentIndex + 5 < lastI)
    {
        int cacheCount = [self.postStorage.postId count];
        
        for (int i = currentIndex + 5; i < cacheCount; i++)
        {
            Post *nextPost = [self.postStorage postAtIndex:i];
            
            /* 
             * If you go very far forward this still won't have to get to the
             * end.
             */
            if (nextPost.image == nil && nextPost.cachingImage == NO)
            {
                break;
            }
            
            nextPost.image = nil;
            nextPost.cachingImage = NO;
            NSLog(@"de-caching index: %d", i);
        }
    }
    
    return;
}

/**
 * @brief Handler for viewing the previous post.
 *
 * @todo add lookback cachers (maybe free very old things).
 */
- (void)prevHandler
{
    if (self.cacheIndex == 0)
    {
        return;
    }

    if ([self.postStorage.postId count] == 0)
    {
        return;
    }

    Post *post = [self.postStorage postAtIndex:self.cacheIndex];
    
    /* You cannot slide until the current image loads. */
    if (post.image == nil)
    {
        return;
    }

    self.cacheIndex -= 1;

    post = [self.postStorage postAtIndex:self.cacheIndex];
    
    [self hideComments];
    [self updateView:post];

    if (self.cacheIndex > 0)
    {
        [self queueBackward:self.cacheIndex];
    }

    [self determineWindow];

    return;
}

/**
 * @brief Handler for viewing the next post.
 *
 * @todo add lookahead cachers.
 */
- (void)nextHandler
{
    if ([self.postStorage.postId count] == 0)
    {
        return;
    }

    if (self.cacheIndex == [Util lastIndex:self.postStorage.postId])
    {
        return;
    }

    Post *post = [self.postStorage postAtIndex:self.cacheIndex];

    /* You cannot slide until the current image loads. */
    if (post.image == nil)
    {
        return;
    }

    self.cacheIndex += 1;

    post = [self.postStorage postAtIndex:self.cacheIndex];

    [self hideComments];
    [self updateView:post];

    /* 
     * Move the sliding window, cache the next several items and free trailing
     * ones.
     */
    if (self.cacheIndex + 1 < [Util lastIndex:self.postStorage.postId])
    {
        [self queueForward:self.cacheIndex];
    }

    [self determineWindow];

    return;
}

//Called by Reachability whenever status changes.
- (void)reachabilityChanged:(NSNotification *)note
{
	Reachability *curReach = [note object];
	NSParameterAssert([curReach isKindOfClass:[Reachability class]]);

    self.currNetStatus = [curReach currentReachabilityStatus];

    NSLog(@"reachabilitychanged...: %@", curReach);
    
    if (self.currNetStatus == ReachableViaWiFi)
    {
        self.downloadLargeImages = YES;
    }
    else
    {
        self.downloadLargeImages = NO;
    }
}

/******************************************************************************
 * Scroll View Code
 ******************************************************************************/

#pragma mark - Scroll View Code

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.display;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
    [self.display setNeedsDisplay];
}

/******************************************************************************
 * Normal View Loading Code
 ******************************************************************************/

#pragma mark - Normal View Loading Code

/**
 * @brief This is called if we run out of memory.
 */
- (void)didReceiveMemoryWarning
{
    // Release any cached data, images, etc that aren't in use.

    [self createEvent:EVENT_TYPE_MEMORY_WARNING
             withInfo:[NSString stringWithFormat:@"memory warning: %@", [NSDate date]]
             withData:nil];
    
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if (interfaceOrientation == UIInterfaceOrientationPortrait)
    {
        return YES;
    }
    
    if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft)
    {
        return YES;
    }
    
    if (interfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
        return YES;
    }
    
    return NO;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    NSLog(@"primary view rotated.");

    if (fromInterfaceOrientation == UIInterfaceOrientationPortrait)
    {
        NSLog(@"fromInterfaceOrientation: portrait");
    }

    return;
}

/**
 * @brief Called while it's rotating, and the bounds are set to their final
 * positions.
 */
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                         duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];

    NSLog(@"willAnimateRotationToInterfaceOrientation");

    /* I have to do this, because when it shrinks it doesn't lower itself
     * enough; so often you can see the post underneath.
     * 
     * So when the computer does this rotation automatically they end up placing it 1 pixel above the bottom,
     * which is wrong.  If I do -1 here, like you should because the axis are 0 based, it has the same problem.
     */
    self.lowerToolBar.frame = CGRectMake(self.lowerToolBar.frame.origin.x,
                                         self.view.bounds.size.height - self.lowerToolBar.frame.size.height,
                                         self.lowerToolBar.frame.size.width,
                                         self.lowerToolBar.frame.size.height);

    /* The height for the userinfobar and the tileview. */
    CGRect upFrm = self.upperToolBar.frame;
    CGFloat height = upFrm.size.height + self.tagLbl.frame.size.height;
    
    UIView *jump = [self.view viewWithTag:TAG_JUMPOUT_SCROLLER];
    if (jump != nil)
    {
        jump.frame = CGRectMake(0,
                                self.view.bounds.size.height - jump.frame.size.height - 1, // should be -1 here because it's 0 based...
                                jump.frame.size.width,
                                jump.frame.size.height);
    }

    /*
     * I can't seem to get the autoresizing masks to correctly grow/shrink it;
     * because we want it to be possibly taller on portrait after it's been 
     * shorter on landscape.
     */
    UIView *pivotG = [self.view viewWithTag:TAG_PIVOT_BACKVIEW];
    if (pivotG != nil)
    {
        UIView *pivotView = [pivotG viewWithTag:TAG_PIVOT_FRAMEVIEW];
        UIScrollView *scroller = (UIScrollView *)[pivotView viewWithTag:TAG_PIVOT_SCROLLER];
        UIView *title = [pivotView viewWithTag:901];

        CGFloat newHeight;
        CGFloat navBarHeight = title.frame.origin.y + title.frame.size.height + 5;
        
        CGSize frameSz = CGSizeMake(self.view.bounds.size.width - 20,
                                    self.view.bounds.size.height - 20);
        CGSize tableSz = CGSizeMake(frameSz.width - 10,
                                    frameSz.height - (navBarHeight + 5));

        CGSize newFrameSize = CGSizeZero;
        CGFloat newMiddle = 0;
        CGFloat contentSize = scroller.contentSize.height + navBarHeight + 5;
        
        /* If the box we provide is too larger, shrink it and adjust. */
        if (pivotView.frame.size.height > tableSz.height)
        {
            newHeight = self.view.bounds.size.height - 20;
        }
        else if (contentSize < tableSz.height)
        {
            /* the +5 at the bottom of the height accounts for the frame border. */
            newFrameSize = CGSizeMake(frameSz.width, contentSize);
            newMiddle = ((self.view.bounds.size.height - newFrameSize.height) / 2) - 1;
        }

        if (newFrameSize.width == 0)
        {
            pivotView.frame = CGRectMake(10, 10, frameSz.width, frameSz.height);
        }
        else
        {
            pivotView.frame = CGRectMake(10,
                                         newMiddle,
                                         frameSz.width,
                                         newFrameSize.height);
        }

        title.frame = CGRectMake(title.frame.origin.x,
                                 title.frame.origin.y,
                                 pivotView.frame.size.width - (title.frame.origin.x + 5), // remaining width, ensure 5 pixel border to the right.
                                 title.frame.size.height);

        scroller.frame = CGRectMake(scroller.frame.origin.x,
                                    scroller.frame.origin.y,
                                    pivotView.frame.size.width - 10,
                                    pivotView.frame.size.height - (navBarHeight + 5));

        /* I could probably have used the autoresize for these guys. */
        for (UIView *view in [scroller subviews])
        {
            if (view.tag >= 900)
            {
                view.frame = CGRectMake(view.frame.origin.x,
                                        view.frame.origin.y,
                                        scroller.frame.size.width,
                                        view.frame.size.height);
            }
        }
    }
    
    /* equality comparisons with floating point aren't great. */
    if (self.mainScroll.zoomScale == 1.0)
    {
        self.mainScroll.contentSize = CGSizeMake(self.view.bounds.size.width,
                                                 self.view.bounds.size.height);
    }
    
    /* 
     * Should verify that the origin is always 0 based; the issue with the 
     * height could relate to the weird height change on horizontal.
     */
    if (self.userInfoGrown)
    {
        UIView *userBtn = [self.userInfoBar viewWithTag:904];
        float newHeight = userBtn.frame.origin.y + userBtn.frame.size.height + 5;

        self.userInfoBar.frame = CGRectMake(self.userInfoBar.frame.origin.x,
                                            height - 1,
                                            self.userInfoBar.frame.size.width,
                                            newHeight);
    }
    else
    {
        self.userInfoBar.frame = CGRectMake(self.userInfoBar.frame.origin.x,
                                            height - 1,
                                            self.userInfoBar.frame.size.width,
                                            self.userInfoBar.frame.size.height);
    }
    
    NSLog(@"tag frame: ");
    [Util printRectangle:self.tagLbl.frame];
    NSLog(@"userInfoBar frame: ");
    [Util printRectangle:self.userInfoBar.frame];

    if (self.tilesVisible)
    {
        UIView *view = [self.view viewWithTag:TAG_THUMBNAIL_SCROLLVIEW];
        UpwardTriangle *triview = (UpwardTriangle *)[self.view viewWithTag:TAG_THUMBNAIL_TRIANGLE];

        view.frame = CGRectMake(view.frame.origin.x,
                                height,
                                view.frame.size.width,
                                view.frame.size.height);

        CGRect newTri = CGRectMake(((self.view.bounds.size.width / 2) - 1) - 20,
                                   upFrm.size.height,
                                   40,
                                   view.frame.origin.y - upFrm.size.height);
        triview.frame = newTri;
    }
    
    UICommentList *commView = (UICommentList *)[self.view viewWithTag:TAG_COMMENT_MAINVIEW];
    
    if (commView != nil)
    {
        CGFloat yPos = COMMENT_ROW_VERTICAL_OFFSET;

        /* 
         * Each view should either be a custom UIView or a UICommentCell; or the
         *  scrollindicators.
         *
         * This code determines the minimum size of the comment text label.
         */
        for (UICommentCell *view in [commView.scroller subviews])
        {
            if (view.tag >= COMMENT_STARTING_INDEX)
            {
                UILabel *commLbl = view.comment;
                UILabel *authLbl = view.authlbl;
                UILabel *timestampLbl = view.createLbl;

                CGFloat newHeight = [commLbl.text sizeWithFont:commLbl.font
                                             constrainedToSize:CGSizeMake(commLbl.frame.size.width, self.view.bounds.size.height)
                                                 lineBreakMode:commLbl.lineBreakMode].height;
                int numberOfLines = ceilf(newHeight / commLbl.font.lineHeight);

                commLbl.numberOfLines = numberOfLines;
                commLbl.frame = CGRectMake(commLbl.frame.origin.x,
                                           commLbl.frame.origin.y,
                                           commLbl.frame.size.width,
                                           newHeight);
                authLbl.frame = CGRectMake(authLbl.frame.origin.x,
                                           commLbl.frame.origin.y + commLbl.frame.size.height,
                                           authLbl.frame.size.width,
                                           authLbl.frame.size.height);
                timestampLbl.frame = CGRectMake(timestampLbl.frame.origin.x,
                                                authLbl.frame.origin.y + authLbl.frame.size.height,
                                                timestampLbl.frame.size.width,
                                                timestampLbl.frame.size.height);
                
                CGFloat commentCellHeight = timestampLbl.frame.origin.y + timestampLbl.frame.size.height;
                
                if (COMMENT_ROW_MINIMUM_HEIGHT < commentCellHeight)
                {
                    view.frame = CGRectMake(view.frame.origin.x,
                                            yPos,
                                            view.frame.size.width,
                                            commentCellHeight);
                }
                else
                {
                    view.frame = CGRectMake(view.frame.origin.x,
                                            yPos,
                                            view.frame.size.width,
                                            COMMENT_ROW_MINIMUM_HEIGHT);
                }
                
                yPos += view.frame.size.height + COMMENT_ROW_VERTICAL_GAP;
            }
        }

        commView.scroller.contentSize = CGSizeMake(commView.scroller.frame.size.width, yPos);

        CGFloat halfScreen = self.view.bounds.size.height / 2;
        CGFloat newMasterSize = 0;
        CGFloat diffMasterHeight;
        
        /* It's covering more than half the screen!. */
        if (commView.frame.size.height > halfScreen)
        {
            diffMasterHeight = commView.frame.size.height - halfScreen;
            newMasterSize = halfScreen;
            commView.scroller.frame = CGRectMake(commView.scroller.frame.origin.x,
                                                 commView.scroller.frame.origin.y,
                                                 commView.scroller.frame.size.width,
                                                 commView.scroller.frame.size.height - diffMasterHeight);
            commView.frame = CGRectMake(commView.frame.origin.x,
                                        halfScreen - 1,
                                        commView.frame.size.width,
                                        newMasterSize);
        }
        else if (commView.frame.size.height < COMMENT_MAXIMUM_VIEW_HEIGHT)
        {
            /* 
             * To get here we know it's less than half the screen size and also
             * less than the maximum size; so let's grow it to whichever.
             */
            newMasterSize = (halfScreen > COMMENT_MAXIMUM_VIEW_HEIGHT) ? COMMENT_MAXIMUM_VIEW_HEIGHT : halfScreen;
            diffMasterHeight = newMasterSize - commView.frame.size.height;
            
            commView.scroller.frame = CGRectMake(commView.scroller.frame.origin.x,
                                                 commView.scroller.frame.origin.y,
                                                 commView.scroller.frame.size.width,
                                                 commView.scroller.frame.size.height + diffMasterHeight);
            
            commView.frame = CGRectMake(commView.frame.origin.x,
                                        (self.view.bounds.size.height - newMasterSize) - 1,
                                        commView.frame.size.width,
                                        newMasterSize);
        }

        commView.startingFrame = commView.frame;
        commView.startingScrollFrame = commView.scroller.frame;
    }

    return;
}

/**
 * @brief Called right before it's rotated.
 */
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation
                                   duration:duration];

    NSLog(@"willRotateToInterfaceOrientation");

    return;
}

/**
 * @brief This function is called once after the view is loaded.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];

    NSLog(@"%@:viewDidLoad", self);
    if ([self respondsToSelector:@selector(setRestorationIdentifier:)])
    {
        self.restorationIdentifier = @"YawningPandaViewController";
        self.restorationClass = [self class];
    }

    NSLog(@"Entered viewDidLoad for PrimaryViewController");
    
    self.view.backgroundColor = [UIColor blackColor];

    self.mainScroll = \
        [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0,
                                                       self.view.bounds.size.width,
                                                       self.view.bounds.size.height)];

    self.mainScroll.backgroundColor = [UIColor blackColor];
    self.mainScroll.scrollEnabled = NO;
    self.mainScroll.userInteractionEnabled = YES;
    self.mainScroll.multipleTouchEnabled = YES;
    self.mainScroll.minimumZoomScale = 1.0;
    self.mainScroll.maximumZoomScale = 6.0;
    self.mainScroll.delegate = self;
    self.mainScroll.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.mainScroll.scrollEnabled = YES;
    self.mainScroll.showsHorizontalScrollIndicator = NO;
    self.mainScroll.showsVerticalScrollIndicator = NO;

    self.display = \
        [[ImageSpinner alloc] initWithFrame:CGRectMake(0, 0,
                                                       self.view.bounds.size.width,
                                                       self.view.bounds.size.height)];
    self.display.contentMode = UIViewContentModeScaleAspectFit;
    self.display.backgroundColor = [UIColor blackColor];
    self.display.userInteractionEnabled = YES;
    self.display.multipleTouchEnabled = YES;

    [self.mainScroll addSubview:self.display];

    [self.view insertSubview:self.mainScroll atIndex:0];

    self.display.autoresizingMask = \
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight |
        UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
        UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;

    /*
     * This sets this viewcontroller instance as the delegate receiver for the 
     * text query.
     */

    // Add the horizontal swipe gesture handlers.
    UISwipeGestureRecognizer *leftSwipeRecognizer = \
        [[UISwipeGestureRecognizer alloc] initWithTarget:self 
                                                  action:@selector(handleSwipe:)];
    leftSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    leftSwipeRecognizer.numberOfTouchesRequired = 1;
    leftSwipeRecognizer.delegate = self;

    UISwipeGestureRecognizer *rightSwipeRecognizer = \
        [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                  action:@selector(handleSwipe:)];
    rightSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    rightSwipeRecognizer.numberOfTouchesRequired = 1;
    rightSwipeRecognizer.delegate = self;

    // Add pivot gesture handlers.
    UIRotationGestureRecognizer *rotationRecognizer = \
        [[UIRotationGestureRecognizer alloc] initWithTarget:self
                                                     action:@selector(pivotBtnHandler:)];
    rotationRecognizer.delegate = self;

    UISwipeGestureRecognizer *topDownRecognizer = \
        [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                  action:@selector(showPivotHistory:)];
    topDownRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
    topDownRecognizer.numberOfTouchesRequired = 1;
    topDownRecognizer.delegate = self;

    UISwipeGestureRecognizer *topDownRecognizer2 = \
        [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                  action:@selector(showLog)];
    topDownRecognizer2.direction = UISwipeGestureRecognizerDirectionDown;
    topDownRecognizer2.numberOfTouchesRequired = 3;
    topDownRecognizer2.delegate = self;

    UISwipeGestureRecognizer *bottomUpRecognizer = \
        [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                  action:@selector(launchMap:)];
    bottomUpRecognizer.direction = UISwipeGestureRecognizerDirectionUp;
    bottomUpRecognizer.numberOfTouchesRequired = 2;
    bottomUpRecognizer.delegate = self;
    
    UISwipeGestureRecognizer *bottomUpComments = \
        [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                  action:@selector(showComments:)];
    bottomUpComments.direction = UISwipeGestureRecognizerDirectionUp;
    bottomUpComments.numberOfTouchesRequired = 1;
    bottomUpComments.delegate = self;

    UITapGestureRecognizer *dtapRecognizer = \
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(dtappedDisplay:)];
    dtapRecognizer.numberOfTouchesRequired = 1;
    dtapRecognizer.numberOfTapsRequired = 2;
    dtapRecognizer.delegate = self;

    UITapGestureRecognizer *stapRecognizer = \
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(stappedDisplay:)];
    stapRecognizer.numberOfTouchesRequired = 1;
    stapRecognizer.numberOfTapsRequired = 1;
    stapRecognizer.delegate = self;
    
    UILongPressGestureRecognizer *lPressRecognizer = \
        [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                      action:@selector(showUserBar:)];
    lPressRecognizer.numberOfTouchesRequired = 1;
    lPressRecognizer.delegate = self;

    [stapRecognizer requireGestureRecognizerToFail:dtapRecognizer];

    [self.display addGestureRecognizer:leftSwipeRecognizer];
    [self.display addGestureRecognizer:rightSwipeRecognizer];
    [self.display addGestureRecognizer:rotationRecognizer];
    [self.display addGestureRecognizer:topDownRecognizer];
    [self.display addGestureRecognizer:topDownRecognizer2];
    [self.display addGestureRecognizer:bottomUpRecognizer];
    [self.display addGestureRecognizer:bottomUpComments];
    [self.display addGestureRecognizer:dtapRecognizer];
    [self.display addGestureRecognizer:stapRecognizer];
    [self.display addGestureRecognizer:lPressRecognizer];

    self.sinceLbl.text = @"";

    /* Set the outstanding label. */
    self.outstandingCreates = 0;
    self.outstandingItemsLbl.text = @"";
    self.outstandingItemsLbl.alpha = 0.0;
    self.outstandingItemsLbl.font = [UIFont boldSystemFontOfSize:10];
    self.outstandingItemsLbl.adjustsFontSizeToFitWidth = YES;

    /* Set the tag label, it'll be pushed down by the outstanding label. */
    self.tagLbl.textColor = [UIColor whiteColor];
    self.tagLbl.text = @"";
    self.tagLbl.adjustsFontSizeToFitWidth = YES;

    [self buildUserInfoBar];

    self.postInfoBtn.enabled = NO;
    self.refreshQuery = NO;
    self.watchingUser = NO;
    self.tilesVisible = NO;

    self.queryOnGoing = NO;
    self.currAction = USER_ACTION_INVALID;
    self.currSheet = USER_SHEET_INVALID;

    /* This should bring up an action sheet that lets you reply/repost, etc... */
    self.createPostToolbarBtn = \
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                                                      target:self
                                                      action:@selector(createPostHandler)];

    self.replyPostToolbarBtn = \
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemReply
                                                      target:self
                                                      action:@selector(replyRepostHandler)];
    self.replyPostToolbarBtn.enabled = NO;

    UIBarButtonItem *flexibleSpace = \
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                      target:nil
                                                      action:nil];

    self.queryToolbarBtn = \
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                                      target:self
                                                      action:@selector(queryBtnHandler)];

    self.refreshToolbarBtn = \
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                      target:self
                                                      action:@selector(refreshBtnHandler)];
    self.refreshToolbarBtn.enabled = NO;

    /* XXX: May be worth setting the font. */
    self.titleToolbarBtn = \
        [[UIBarButtonItem alloc] initWithTitle:@"0/0"
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(showTilesHandler:)];

    [self.upperToolBar \
        setItems:@[self.queryToolbarBtn,
                   self.refreshToolbarBtn,
                   flexibleSpace,
                   self.titleToolbarBtn,
                   flexibleSpace,
                   self.replyPostToolbarBtn,
                   self.createPostToolbarBtn]
        animated:YES];

    self.meToolbarBtn = \
        [[UIBarButtonItem alloc] initWithTitle:@"<>"
                                         style:UIBarButtonItemStyleBordered
                                        target:self
                                        action:@selector(displayJumpOut)];

    self.commentToolbarBtn = \
        [[UIBarButtonItem alloc] initWithTitle:@"0"
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(showComments:)];

    self.starToolbarBtn = \
        [[UIBarButtonItem alloc] initWithTitle:@"\ue32f" // star @"\ue00e" // heart: @"\ue32c"
                                         style:UIBarButtonItemStyleBordered
                                        target:self
                                        action:@selector(favPost)];

    self.starToolbarBtn.enabled = NO;

    self.actionToolbarBtn = \
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                      target:self
                                                      action:@selector(saveBtnHandler)];

    self.actionToolbarBtn.enabled = NO;

    UIBarButtonItem *launchTable = \
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize
                                                      target:self
                                                      action:@selector(launchTableView:)];
    
    
    [self.lowerToolBar \
        setItems:@[self.meToolbarBtn,
                   launchTable,
                   flexibleSpace,
                   self.commentToolbarBtn,
                   flexibleSpace,
                   self.starToolbarBtn,
                   self.actionToolbarBtn]
        animated:YES];

    self.upperToolBar.autoresizingMask |= UIViewAutoresizingFlexibleHeight;
    self.lowerToolBar.autoresizingMask |= UIViewAutoresizingFlexibleHeight;

    /* This is used when the user clicks the query button. */
    self.hiddenField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.hiddenField.inputAccessoryView = [self buildQueryFieldAccessory];
    [self.view addSubview:self.hiddenField];

    self.commentHiddenField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.commentHiddenField.inputAccessoryView = [self buildCommentFieldAccessory];
    [self.view addSubview:self.commentHiddenField];

    self.allHidden = NO;

    /* 
     * This is called before decode is called, but it's not always called.
     * But I think these are always going to be nil here.
     */
    self.cacheIndex = 0;
    if (self.userCache == nil)
    {
        self.userCache = [[NSMutableDictionary alloc] init];
    }
    if (self.queryCache == nil)
    {
        self.queryCache = [[NSMutableArray alloc] init];
    }
    if (self.eventLog == nil)
    {
        self.eventLog = [[NSMutableArray alloc] init];
    }
    if (self.postStorage == nil)
    {
        self.postStorage = [[NavigationCache alloc] init];
    }
    if (self.lastUsedTags == nil)
    {
        self.lastUsedTags = [[NSMutableArray alloc] init];
    }
    if (self.queryResults == nil)
    {
        self.queryResults = [[NSMutableDictionary alloc] init];
    }

    /* we don't save this. */
    self.downloadCache = [[NSMutableArray alloc] init];
    self.apiManager = [[APIManager alloc] initWithDelegate:self];

    /* we don't save this. */
    self.imageViewTiles = [[NSMutableArray alloc] init];

//    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent
//                                                animated:YES];
    //[[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    /* This is how you set the number on the icon. */

    NSString *path = [[NSBundle mainBundle] pathForResource:@"temp-avatar"
                                                     ofType:@"png"
                                                inDirectory:@""];

    self.defaultImage = [UIImage imageWithContentsOfFile:path];
    
    self.defaults = [NSUserDefaults standardUserDefaults];
    [defaults synchronize];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];

    self.downloadLargeImages = NO;
    self.currNetStatus = ReachableViaWWAN;
    self.reachNetStatus = [Reachability reachabilityForInternetConnection];
    [self.reachNetStatus startNotifier];
    self.currNetStatus = [self.reachNetStatus currentReachabilityStatus];

    if (self.currNetStatus == ReachableViaWiFi)
    {
        self.downloadLargeImages = YES;
    }
    else
    {
        self.downloadLargeImages = NO;
    }

    return;
}

/**
 * @brief This is called as the view is being reloaded, but not yet complete.
 *
 * @param animated hmmm..
 */
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    return;
}

/**
 * @brief This is called after the view is reloaded.
 *
 * @param animated hmmm..
 */
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    /* XXX: Maybe I should move this to viewWillAppear. */
    if (self.specifiedUser == nil)
    {
        NSLog(@"no user specified");
        [self loginBtnHandler];
    }

    // means they dismissed, I think.
    if ([self.specifiedUser isEqualToString:@""])
    {
        NSLog(@"user specified: ''");
        [self loginBtnHandler];
    }

    //NSLog(@"Entered viewDidAppear, specifiedUser: %@", self.specifiedUser);
    return;
}

/**
 * @brief The view has unloaded.
 */
- (void)viewDidUnload
{
    [super viewDidUnload];

    /* not all things are run through the apiManager. */
    [self.apiManager cancelAll];
    [self.reachNetStatus stopNotifier];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kReachabilityChangedNotification
                                                  object:nil];


    return;
}

/******************************************************************************
 * Delegate Callbacks
 ******************************************************************************/

#pragma mark - Delegate Callbacks

/**
 * @brief This function is called by the purge button in the 
 * LogTableViewController.
 */
- (void)handlePurgeEvents
{
    NSLog(@"Attempting to remove all objects from eventLog");
    
    [self.eventLog removeAllObjects];
    
    return;
}

/**
 * @brief This function is called by the PivotPopupViewController instance when
 * the user pivots on post information.
 *
 * @param pivot the pivot type, should be an enum later.
 * @param value the value associated with that pivot type (e.g. the tag itself).
 *
 * @note on pivot community, value must be a string "tag1,tag2"
 */
- (void)handlePivot:(NSString *)pivot
          withValue:(NSString *)value
{
    if (pivot == nil)
    {
        self.queryOnGoing = NO;
        return;
    }

    [self addGreyOverlay];
    self.view.userInteractionEnabled = NO;
    self.queryOnGoing = YES;

    /* I want to disable pivoting until this query returns... */
    NSLog(@"pivot on %@: %@", pivot, value);
    UIImage *img = nil;
    if ([self.postStorage.postId count] > 0)
    {
        Post *post = [self.postStorage postAtIndex:self.cacheIndex];
        img = post.image;
    }

    [self.queryCache insertObject:[[PivotDetails alloc] initWithPivot:pivot
                                                            withValue:value
                                                            withImage:img]
                          atIndex:0];

    /* just calls snapshot/get */
    if ([pivot isEqualToString:@"get"])
    {
        [self.apiManager getPost:value
                          asUser:self.specifiedUser];
    }
    else if ([pivot isEqualToString:@"home"])
    {
        [self.apiManager userHome:self.specifiedUser];
    }
    else if ([pivot isEqualToString:@"public"])
    {
        [self.apiManager publicStream:self.specifiedUser];
    }
    else
    {
        [self.apiManager queryPosts:pivot
                          withValue:value
                             asUser:self.specifiedUser];
    }

    return;
}

/**
 * @brief This function is called by the NewPostPopupViewController instance
 * when the user's selection is made and they chose to create the post.
 */
- (void)handlePostDetailed:(NSString *)user
                  withTags:(NSArray *)tags
                  withData:(NSData *)data
                atLocation:(NSArray *)point
                   forPost:(NSString *)post
{
    NSLog(@"handlePostDetailed called: %@, %@", user, tags);
    NSLog(@"Data Size: %d", [data length]);
    NSLog(@"Location: %@", point);

    self.lastUsedTags = tags; /* this should copy */

    self.outstandingCreates += 1;
    [self updateOutStandingPosts];

    switch (self.currAction)
    {
        case USER_ACTION_CREATE:
        {
            NSLog(@"Creating new post!");

            [self createEvent:EVENT_TYPE_POST_ATTEMPT
                     withInfo:@"create post"
                     withData:@{@"user": user,
                                @"tags": tags,
                                @"location": (point == nil) ? @"" : point,
                                @"data size": [NSString stringWithFormat:@"%d", [data length]]}];
            
            /* hm... if point is nil, this won't go well. */
//            [self.apiManager createPost:user
  //                             withTags:tags
    //                           withData:data
      //                     withLocation:[point componentsJoinedByString:@", "]];
            /* this does mean the app will crash if the view is freed before this finishes. */
            [[Util getHandler:self] createPost:user
                                      withTags:tags
                                      withData:data
                                  withLocation:[point componentsJoinedByString:@", "]];
            break;
        }
        case USER_ACTION_REPLY:
        {
            NSLog(@"Replying to post!");
            
            /*
             * Later when you can create() without running a query first, you will
             * still need something up for reply().
             */
            [self createEvent:EVENT_TYPE_REPLY_ATTEMPT
                     withInfo:@"reply post"
                     withData:@{@"user": user,
                                @"tags": tags,
                                @"location": (point == nil) ? @"" : point,
                                @"replyto": post,
                                @"data size": [NSString stringWithFormat:@"%d", [data length]]}];

//            [self.apiManager replyPost:user
  //                            withTags:tags
    //                          withData:data
      //                    withLocation:[point componentsJoinedByString:@", "]
        //                       asReply:post.postid];
            [[Util getHandler:self] replyPost:user
                                     withTags:tags
                                     withData:data
                                 withLocation:[point componentsJoinedByString:@", "]
                                      asReply:post];
            break;
        }
        case USER_ACTION_REPOST:
        {
            NSLog(@"Reposting!");

            [self createEvent:EVENT_TYPE_REPOST_ATTEMPT
                     withInfo:@"repost"
                     withData:@{@"user": user,
                                @"tags": tags,
                                @"repostof": post}];

//            [self.apiManager repostPost:user
  //                             withTags:tags
    //                           asRepost:post.postid];
            [[Util getHandler:self] repostPost:user
                                      withTags:tags
                                      asRepost:post];
            break;
        }
        default:
        {
            break;
        }
    }

    self.currAction = USER_ACTION_INVALID;

    return;
}

/**
 * @brief This function is called by the UserTableViewController instance if the
 *  user selects "Logout."
 */
- (void)handleLogoutSelected
{
    [self logoutBtnHandler];
}

/**
 * @brief This function is called by the LoginPopupViewController instance when
 * the user's screen_name checks out.
 *
 * @param userName This is not the user's screen_name, but rather the ID value.
 */
- (void)handleLoginEntered:(NSString *)userName withPrefs:(NSDictionary *)prefs
{
    bool watchingUsers = NO;
    NSLog(@"Protocol returned: %@", userName);
    NSLog(@"prefs retrieved: %@", prefs);

    if (prefs != nil)
    {
        User *usr = prefs[@"user"];

        [self createEvent:EVENT_TYPE_LOGIN
                 withInfo:[NSString stringWithFormat:@"login: %@", userName]
                 withData:@{@"screen_name": usr.screen_name,
                            @"user id": usr.userid,
                            @"communities on load": (prefs[@"community"] == nil) ? @"": prefs[@"community"]}];

        NSLog(@"died after log attempt.");
        
        usr.image = self.defaultImage;
        [self.apiManager userView:usr.userid];
        
        [self.defaults setObject:usr.display_name forKey:@"screenname"];
        [defaults synchronize];
        NSLog(@"setting default: %@", usr.display_name);
    }

    self.specifiedUser = userName;
    
    [self.apiManager getAuthor:self.specifiedUser asUser:self.specifiedUser];
    [self.downloadCache addObject:self.specifiedUser];

    if (prefs != nil) /* merge with code above, that is new. */
    {
        self.userPrefs = [NSMutableDictionary dictionaryWithDictionary:prefs];

        /* If they aren't in any communities, set to a valid array address */
        if ((self.userPrefs)[@"community"] == nil)
        {
            (self.userPrefs)[@"community"] = [[NSMutableArray alloc] init];
        }

        (self.userPrefs)[@"watching"] = [[WatchList alloc] init];
        WatchList *mywatches = (self.userPrefs)[@"watching"];
        
        if ([[prefs[@"user"] watches] count] > 0)
        {
            watchingUsers = YES;
        }
        
        /* If there are like a million of these it won't be good. */
        for (id watched in [prefs[@"user"] watches])
        {
            NSLog(@"watching: %@", watched);
            [mywatches.userids addObject:watched];
            
            if (![watched isEqualToString:self.specifiedUser])
            {
                /*
                 * So we don't re-download it if we see a post early enough in the
                 * loading.
                 */
                [self.downloadCache addObject:watched];
                
                [self.apiManager getAuthor:watched asUser:self.specifiedUser];
            }
        }
    }

    NSLog(@"user prefs: %@", self.userPrefs);

    if (watchingUsers)
    {
        [self.queryCache insertObject:[[PivotDetails alloc] initWithPivot:@"home"
                                                                withValue:self.specifiedUser
                                                                withImage:nil]
                              atIndex:0];

        [self addGreyOverlay];
        self.queryOnGoing = YES;
        self.view.userInteractionEnabled = NO;

        [self.apiManager userHome:self.specifiedUser];
    }
    else
    {
        UIAlertView *alert = \
            [[UIAlertView alloc] initWithTitle:@"Empty Watchlist"
                                       message:@"Adding Users to your watchlist can be fun."
                                      delegate:nil
                             cancelButtonTitle:@"OK"
                             otherButtonTitles:nil];

        [alert show];
    }

    return;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"%@",
          [NSString stringWithFormat:@"You selected: '%@'",
              [alertView buttonTitleAtIndex:buttonIndex]]);
    
    return;
}

/**
 * @brief This delegate is called by the Favorites List if you delete one of 
 * your favorites successfully.  The goal is to check and see if it's one of
 * ours in the cache.
 */
- (void)handleUnfavoritedPost:(NSString *)postId
{
    Post *post = [self.postStorage postWithId:postId];
    if (post != nil)
    {
        post.favorite_of_user = NO;
    }
    
    return;
}

/**
 * @brief This delegate is called by PostInfo in the event they want to join the
 *  community.
 */
- (void)handleNewCommunity:(NSString *)community
{
    NSLog(@"Should try to insert: %@ into list.", community);

    [self.apiManager joinCommunity:self.specifiedUser
                          withTags:[community componentsSeparatedByString:@","]];

    return;
}

/**
 * @brief This delegate is called by the APIHandler when a connection fails.
 *
 * @todo Depending on the type, we can probably figure out a bit more about what
 * should happen; including interrogating the apihandler object to see if it was
 * downloading a post's image or something useful.
 */
- (void)apihandler:(APIHandler *)apihandler didFail:(enum APICall)type
{
    [self.apiManager dropHandler:apihandler]; // no harm if not from apimanager.

    NSLog(@"apihandler connection failed for type: %d", type);

    [self createEvent:EVENT_TYPE_CONNECTION_FAILURE
             withInfo:[NSString stringWithFormat:@"connection error type: %@",
                       [APIHandler typeToString:type]]
             withData:nil];

    switch (type)
    {
        case API_POST_COMMENT:
        {
            self.commentOutstanding = NO;
            [self.createCommentSpinner stopAnimating];
            self.createCommentPostBtn.enabled = YES;
            
            /* set at the top of the view. */
            UILabel *connectionError = \
                [[UILabel alloc] initWithFrame:CGRectMake(0, 0,
                                                          self.view.bounds.size.width, 20)];
            connectionError.font = [UIFont boldSystemFontOfSize:18];
            connectionError.backgroundColor = [UIColor redColor];
            connectionError.textAlignment = UITextAlignmentCenter;
            connectionError.textColor = [UIColor whiteColor];
            connectionError.text = @"Connection Error";
            connectionError.autoresizingMask = UIViewAutoresizingFlexibleWidth; // | UIViewAutoresizingFlexibleTopMargin;
            
            [self.view addSubview:connectionError];

            [UIView animateWithDuration:0.2
                             animations:^{
                                 connectionError.alpha = 0.0;
                             }
                             completion:^(BOOL finished){
                                 [connectionError removeFromSuperview];
                             }];

            break;
        }
        case API_POST_COMMENTS:
        {
            UICommentList *view = (UICommentList *)[self.view viewWithTag:TAG_COMMENT_MAINVIEW];
                
            if (view != nil)
            {
                UIActivityIndicatorView *busy = (UIActivityIndicatorView *)[view viewWithTag:COMMENT_SUBVIEW_ACTIVITY];
                UILabel *result = (UILabel *)[view viewWithTag:COMMENT_SUBVIEW_STATUS];

                [busy stopAnimating];
                result.text = @"Connection Failed";
            }

            break;
        }
        case API_POST_QUERY:
        {
            self.queryOnGoing = NO;
            self.refreshQuery = NO;
            self.view.userInteractionEnabled = YES;
            
            [self setOverlayStatus:@"Connection Error."];
            [self performSelector:@selector(dropGreyOverlay)
                       withObject:nil
                       afterDelay:0.3];
            
            /* No harm in passing a message to nil, until everybody uses this. */
//            [self dropGreyOverlay];
            
            //UIAlertView *alert = \
            //    [[UIAlertView alloc] initWithTitle:@"Connection Error"
            //                               message:@"Failed to run query."
            //                              delegate:nil
            //                     cancelButtonTitle:@"OK"
            //                     otherButtonTitles:nil];

            //[alert show];
            break;
        }
        case API_POST_THUMBNAIL:
        {
            Post *post = [self.postStorage postWithId:apihandler.postId];
            if (post != nil)
            {
                post.cachingThumbnail = NO;
            }
            break;
        }
        case API_POST_VIEW:
        {
            Post *post = [self.postStorage postWithId:apihandler.postId];
            if (post != nil)
            {
                post.cachingImage = NO;
            }

            Post *cur = [self.postStorage postAtIndex:self.cacheIndex];

            if (cur.postid == apihandler.postId)
            {
                UIAlertView *alert = \
                    [[UIAlertView alloc] initWithTitle:@"Connection Error"
                                               message:@"Failed to download the post."
                                              delegate:nil
                                     cancelButtonTitle:@"OK"
                                     otherButtonTitles:nil];

                [alert show];
            }
            break;
        }
        case API_POST_REPORT:
        {
            break;
        }
        case API_POST_CREATE:
        case API_POST_REPLY:
        case API_POST_REPOST:
        {
            self.outstandingCreates -= 1;
            [self updateOutStandingPosts];
            break;
        }
        default:
        {
            break;
        }
    }

    return;
}

/**
 * @brief This is called when a user has reported a post.
 *
 * @param success whether it worked
 * @param postid the post you reported
 * @param theUser who reported it.
 */
- (void)apihandler:(APIHandler *)apihandler didCompleteReport:(bool)success
           forPost:(NSString *)postid
            asUser:(NSString *)theUser
{
    [self.apiManager dropHandler:apihandler];
    
    UIAlertView *alert = \
        [[UIAlertView alloc] initWithTitle:@"Post Reported"
                                   message:nil
                                  delegate:nil
                         cancelButtonTitle:@"OK"
                         otherButtonTitles:nil];

    if (success)
    {
        alert.message = @"You have successfully reported the post.";
    }
    else
    {
        alert.message = @"You failed to report the post.";
    }
    
    [alert show];
}

/**
 * @brief This is called when a user query returns.
 *
 * @param data the array of whatever
 * @param query the query returning
 * @param the user who made the query.
 */
- (void)apihandler:(APIHandler *)apihandler didCompleteUserQuery:(NSMutableArray *)data
         withQuery:(NSString *)query
           forUser:(NSString *)user
            asUser:(NSString *)theUser
{
    [self.apiManager dropHandler:apihandler];

    if (data == nil)
    {
        return;
    }

    /* Is it our favorites? */
    if ([query isEqualToString:@"favorites"]
        && [user isEqualToString:self.specifiedUser])
    {
    }

    return;
}

/**
 * @brief This is called when a user image is downloaded.
 *
 * @param image the image content or nil if there was no image for the user; 
 * should use a default avatar.
 * @param userid the user's image.
 *
 * @note These images are a bit small so there's no issue in keeping them or 
 * re-downloading them.
 */
- (void)apihandler:(APIHandler *)apihandler didCompleteUserView:(UIImage *)image
          withUser:(NSString *)userid
{
    [self.apiManager dropHandler:apihandler];

    NSLog(@"completed userview: %@ for %@", image, userid);

    /* 
     * We know valueForKey isn't nil because we've already successfully 
     * downloaded the user info.
     */
    User *valueForKey = (self.userCache)[userid];
    if (image == nil)
    {
        image = self.defaultImage;
    }
    valueForKey.image = image;

    WatchList *mywatches = (self.userPrefs)[@"watching"];

    if ([mywatches.userids containsObject:userid])
    {
        (mywatches.avatars)[userid] = image;
    }

    Post *curr = [self.postStorage postAtIndex:self.cacheIndex];
    if (curr != nil)
    {
        if ([curr.author isEqualToString:userid])
        {
            [self setUserInfoBarUser:valueForKey];
        }
    }

    return;
}

/**
 * @brief This is called when a post/reply/repost finishes.
 *
 * @param success
 */
- (void)apihandler:(APIHandler *)apihandler didCompletePost:(bool)success
            asUser:(NSString *)theUser
{
    [self.apiManager dropHandler:apihandler];

    [self createEvent:EVENT_TYPE_POST
             withInfo:[NSString stringWithFormat:@"new post: %d", success]
             withData:nil];

    if (![theUser isEqualToString:self.specifiedUser])
    {
        return;
    }

#if 0
    UIAlertView *alert = \
        [[UIAlertView alloc] initWithTitle:@"Note"
                                    message:[NSString stringWithFormat:@"Your Post Was Created: %@", (success ? @"YES" : @"NO")]
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];
    [alert show];
#endif

    self.outstandingCreates -= 1;
    [self updateOutStandingPosts];
    
    return;
}

/**
 * @brief This is a delegate function from APIHandler.  It is called when the
 * thumbnail view api call finishes.
 *
 * @param image the contents of the image returned from the view api.
 * @param postid the id of the corresponding post.
 */
- (void)apihandler:(APIHandler *)apihandler didCompleteThumbnail:(UIImage *)image
          withPost:(NSString *)postid
{
    [self.apiManager dropHandler:apihandler];

    NSLog(@"Setting thumbnail for Post %@.", postid);

    Post *post = [self.postStorage postWithId:postid];
    
    if (post != nil)
    {
        post.cachingThumbnail = NO;
        
        if (image != nil)
        {
            post.thumbnail = [Util centerCrop:image withMax:TILE_DIMENSION];
        }

        if (self.tilesVisible)
        {
            NSLog(@"Tiles visible.");
            int tileId = [self.postStorage indexForPost:post.postid];
            
            ImageSpinner *img = (self.imageViewTiles)[tileId];
            img.image = post.thumbnail;
            [img setNeedsDisplay];
            
            self.downloadTileCount -= 1;
            [self updateDownloadedTiles];
        }
    }

    return;
}

/**
 * @brief This is a delegate function from APIHandler.  It is called when the
 * view api call finishes.
 *
 * @param image the contents of the image returned from the view api.
 * @param postid the id of the corresponding post.
 *
 * @note This doesn't matter if it's the wrong user because we drop it if the
 * post isn't in the cache.
 */
- (void)apihandler:(APIHandler *)apihandler didCompleteView:(UIImage *)image
          withPost:(NSString *)postid
{
    [self.apiManager dropHandler:apihandler];

    Post *post = [self.postStorage postWithId:postid];

    if (post != nil)
    {
        /*
         * If we weren't waiting for the image, ignore it; this means we're
         * probably out of the window.
         */
        if (post.cachingImage == YES)
        {
            // don't need to retain because it's copied on assignment.
            post.image = image;
            post.cachingImage = NO;
            
            NSLog(@"Post %@ found in postCache", post.postid);
        }

        /* only update the screen if it's the correct image. */
        post = [self.postStorage postAtIndex:self.cacheIndex];
        
        if ([postid isEqualToString:post.postid])
        {
            NSLog(@"Updating Current Post");
            
            self.display.clipsToBounds = YES;
            self.display.image = image;
            [self.display setNeedsDisplay];
        }
    }

    return;
}

/**
 * @brief This is a delegate function from APIHandler.  It is called when the
 * community join finishes.
 *
 * @param success Did we join successful.
 * @param tags the community.
 * @param theUser the user who tried joining.
 */
- (void)apihandler:(APIHandler *)apihandler didCompleteJoin:(bool)success
           forComm:(NSArray *)tags
            asUser:(NSString *)theUser
{
    [self.apiManager dropHandler:apihandler];

    NSLog(@"didCompleteJoin: %d for %@", success, tags);

    /* XXX: Do */
    [self createEvent:EVENT_TYPE_JOIN
             withInfo:[NSString stringWithFormat:@"%@: %@",
                       (success) ? @"joined" : @"failed to join",
                       [tags componentsJoinedByString:@","]]
             withData:nil];

    if (![theUser isEqualToString:self.specifiedUser])
    {
        return;
    }

    if (success)
    {
        [(self.userPrefs)[@"community"] addObject:tags];
    }

    return;
}

/**
 * @brief This is a delegate function from APIHandler.  It is called when the 
 * favorite api call finishes.
 *
 * @param postid the identifier for the post they attempted to favorite, or nil
 * on failure.
 */
- (void)apihandler:(APIHandler *)apihandler didCompleteFavorite:(bool)success
           forPost:(NSString *)postid
            asUser:(NSString *)theUser
{
    [self.apiManager dropHandler:apihandler];

    if (postid == nil)
    {
        return;
    }

    if (success)
    {
        [self createEvent:EVENT_TYPE_FAVORITE
                 withInfo:[NSString stringWithFormat:@"favorited: %@", postid]
                 withData:nil];

        if (![theUser isEqualToString:self.specifiedUser])
        {
            return;
        }

        Post *post = [self.postStorage postWithId:postid];
        post.favorite_of_user = YES;
    }

    return;
}

/**
 * @brief This is a delegate function from APIHandler.  It is called when the
 * unfavorite api call finishes.
 *
 * @param postid the identifier for the post they attempted to favorite, or nil
 * on failure.
 */
- (void)apihandler:(APIHandler *)apihandler didCompleteUnFavorite:(bool)success
           forPost:(NSString *)postid
            asUser:(NSString *)theUser
{
    [self.apiManager dropHandler:apihandler];

    if (postid == nil)
    {
        return;
    }

    [self createEvent:EVENT_TYPE_UNFAVORITE
             withInfo:[NSString stringWithFormat:@"unfavorited: %@", postid]
             withData:nil];

    if (![theUser isEqualToString:self.specifiedUser])
    {
        return;
    }
    
    if (success)
    {
        Post *post = [self.postStorage postWithId:postid];
        post.favorite_of_user = NO;
    }

    return;
}

/**
 * @brief This is a delegate function from APIHandler.  It is called when you 
 * try to authorize a user to comment on your posts.
 */
- (void)apihandler:(APIHandler *)apihandler didCompleteAuthorize:(NSString *)user
        withResult:(bool)success
            asUser:(NSString *)theUser
{
    [self.apiManager dropHandler:apihandler];

    [self createEvent:EVENT_TYPE_AUTHORIZE
             withInfo:[NSString stringWithFormat:@"authorized: %@", user]
             withData:nil];

    if (![theUser isEqualToString:self.specifiedUser])
    {
        return;
    }
    
    if (success)
    {
        /* update our copy of the user in the user cache. */
        User *usr = (self.userCache)[user];
        if (usr != nil)
        {
            /* So, if we tried to authorize them and it failed and they were
             * already authorized.. so, just ya know, only update on success.
             */
            usr.authorized = YES;
        }
    }

    return;
}

/**
 * @brief This is a delegate function from APIHandler.  It is called when you
 * try to unauthorize a user to comment on your posts.
 */
- (void)apihandler:(APIHandler *)apihandler didCompleteUnauthorize:(NSString *)user
        withResult:(bool)success
            asUser:(NSString *)theUser
{
    [self.apiManager dropHandler:apihandler];

    [self createEvent:EVENT_TYPE_UNAUTHORIZE
             withInfo:[NSString stringWithFormat:@"unauthorized: %@", user]
             withData:nil];

    if (![theUser isEqualToString:self.specifiedUser])
    {
        return;
    }

    if (success)
    {
        /* update our copy of the user in the user cache. */
        User *usr = (self.userCache)[user];
        if (usr != nil)
        {
            /* So, if we tried to authorize them and it failed and they were
             * already authorized.. so, just ya know, only update on success.
             */
            usr.authorized = NO;
        }
    }

    return;
}

/**
 * @brief This is a delegate function from APIHandler.  It is called when you 
 * try to create a comment, which can only concern itself with one thing.
 */
- (void)apihandler:(APIHandler *)apihandler didCompleteComment:(bool)success
              with:(Comment *)comment
            asUser:(NSString *)theUser
           forPost:(NSString *)postId;
{
    // apihandler not handled via the apiManager.
    if (![theUser isEqualToString:self.specifiedUser])
    {
        return;
    }

    UICommentList *view = (UICommentList *)[self.view viewWithTag:TAG_COMMENT_MAINVIEW];

    self.commentOutstanding = NO;
    [self.createCommentSpinner stopAnimating];
    self.createCommentPostBtn.enabled = YES;

    if (success)
    {
        self.commentTextField.text = @"";

        /* XXX: This should be the current post. */
        Post *post = [self.postStorage postWithId:postId];
        [self.postStorage addComment:comment forPost:postId];
        
        [view addComment:comment
                withPost:post
                withUser:(self.userCache)[comment.author]];
        
        self.commentToolbarBtn.title = [NSString stringWithFormat:@"%d",
                                        post.num_comments];
    }
    else
    {
        view.status.text = @"Failed";
    }

    [self cancelCommentCreate];

    return;
}

/**
 * @brief This is a delegate function from APIHandler.  It is called when the
 * comment query completes.
 *
 * @param data an array of comments.
 * @param theUser the user.
 */
- (void)apihandler:(APIHandler *)apihandler didCompleteComments:(NSMutableArray *)data
            forPost:(NSString *)postId
            asUser:(NSString *)theUser
{
    [self.apiManager dropHandler:apihandler];

    if (![theUser isEqualToString:self.specifiedUser])
    {
        return;
    }

    NSLog(@"comments downloaded, count: %d", [data count]);

    [self.postStorage setComments:data forPost:postId];

    Post *curr = [self.postStorage postAtIndex:self.cacheIndex];
    if (curr.postid == postId)
    {
        if (data != nil)
        {
            self.commentToolbarBtn.title = [NSString stringWithFormat:@"%d",
                                            [data count]];
        }
        else
        {
            self.commentToolbarBtn.title = [NSString stringWithFormat:@"+"];
        }
    }

    /* If the data returned is nil and the comments viewer is up it should
     * do something intelligent, such as stop the spinner and present a view 
     * such as the ability to then add comments... unless it failed because you
     * don't have permission.
     */
    UICommentList *view = (UICommentList *)[self.view viewWithTag:TAG_COMMENT_MAINVIEW];
    
    if (view != nil)
    {
        [view loadComments:data withUser:(self.userCache)[curr.author]];
    }

    return;
}

/**
 * @brief This is a delegate function from APIHandler.  It is called when the
 * query api call finishes.
 *
 * @param data an array of Posts.
 */
- (void)apihandler:(APIHandler *)apihandler didCompleteQuery:(NSMutableArray *)data
            asUser:(NSString *)theUser
{
    [self.apiManager dropHandler:apihandler];

    if (self.tilesVisible)
    {
        [self showTilesHandler:nil];
    }

    self.queryTextField.text = @"";

    NSLog(@"didCompleteQuery:");
    NSLog(@"queryCache: %@", self.queryCache);

    /* Maybe I should have, an entry for the pivot query and the return */
    PivotDetails *tmp = (self.queryCache)[0];

    [self createEvent:EVENT_TYPE_PIVOT
             withInfo:[NSString stringWithFormat:@"%@ for %@",
                       tmp.value, tmp.pivot]
             withData:@{@"returned" : [NSString stringWithFormat:@"%d", [data count]],
                        @"refresh" : (self.refreshQuery) ? @"yes" : @"no"}];

    self.view.userInteractionEnabled = YES;
    self.queryOnGoing = NO;

    [self setOverlayStatus:@"Query Completed."];
    [self performSelector:@selector(dropGreyOverlay)
               withObject:nil
               afterDelay:0.3];

    if (![theUser isEqualToString:self.specifiedUser])
    {
        NSLog(@"Stale Query Returned, me: %@, querier: %@.",
              self.specifiedUser,
              theUser);

        return;
    }

    if ([data count] == 0)
    {
        UIAlertView *alert = \
            [[UIAlertView alloc] initWithTitle:@"Note"
                                       message:@"No Results"
                                      delegate:nil
                             cancelButtonTitle:@"OK"
                             otherButtonTitles:nil];
        [alert show];
        
        self.refreshQuery = NO;
        return;
    }
    
    [self handleQueryResults:data];

    return;
}

/**
 * @brief This is a delegate function from APIHandler.  It is called when the
 * get user api call finishes.
 *
 * @param success whether the action succeeded.
 * @param userid the id of the user you wanted to watch.
 */
- (void)apihandler:(APIHandler *)apihandler didCompleteWatch:(bool)success
          withUser:(NSString *)userid
            asUser:(NSString *)theUser
{
    [self.apiManager dropHandler:apihandler];

    NSDictionary *eventData = \
        @{@"success": [NSString stringWithFormat:@"%@", (success) ? @"yes" : @"no"]};
    [self createEvent:EVENT_TYPE_WATCH
             withInfo:[NSString stringWithFormat:@"watch: %@", userid]
             withData:eventData];

    if (![theUser isEqualToString:self.specifiedUser])
    {
        return;
    }

    /* 1) Add to array.
     * 2) Check if current Post has this userid as author.
     */
    if (success)
    {
        NSLog(@"Adding to user watchlist.");

        WatchList *mywatches = (self.userPrefs)[@"watching"];
        [mywatches.userids addObject:userid];
        
        if (![self.downloadCache containsObject:userid])
        {
            /* 
             * We're not already downloading it. so Download it.
             * didCompleteName will add it to the userPrefs once this is 
             * complete -- trying to keep things a bit async can be annoying.
             */
            [self.downloadCache addObject:userid];

            [self.apiManager getAuthor:userid asUser:self.specifiedUser];
        }

        Post *post = [self.postStorage postAtIndex:self.cacheIndex];
        
        if ([post.author isEqualToString:userid])
        {
            self.watchingUser = YES;
        }

    }
}

/**
 * @brief This is a delegate function from APIHandler.  It is called when the
 * get user api call finishes.
 *
 * @param success whether the action succeeded.
 * @param userid the id of the user you wanted to unwatch.
 */
- (void)apihandler:(APIHandler *)apihandler didCompleteUnWatch:(bool)success
          withUser:(NSString *)userid
            asUser:(NSString *)theUser
{
    [self.apiManager dropHandler:apihandler];

    NSDictionary *eventData = \
        @{@"success": [NSString stringWithFormat:@"%@", (success) ? @"yes" : @"no"]};
    [self createEvent:EVENT_TYPE_UNWATCH
             withInfo:[NSString stringWithFormat:@"unwatch: %@", userid]
             withData:eventData];

    if (![theUser isEqualToString:self.specifiedUser])
    {
        return;
    }

    /* 1) Remove from array.
     * 2) Check if current Post has this userid as author.
     */
    if (success)
    {
        WatchList *mywatches = (self.userPrefs)[@"watching"];
        [mywatches.userids removeObject:userid];
        [mywatches.avatars removeObjectForKey:userid];
        [mywatches.screennames removeObjectForKey:userid];

        Post *post = [self.postStorage postAtIndex:self.cacheIndex];
            
        if ([post.author isEqualToString:userid])
        {
            /*
             * So, in theory you could have an issue where the value
             * doesn't change but the cache was dropped.
             */
            self.watchingUser = NO;
        }
    }
}

/**
 * @brief This is a delegate function from APIHandler.  It is called when the
 * get user api call finishes.
 *
 * @param details the User instance for the requested user.
 * @param authorid the id of the user requested.
 */
- (void)apihandler:(APIHandler *)apihandler didCompleteName:(User *)details
        withAuthor:(NSString *)authorid
            asUser:(NSString *)theUser
{
    [self.apiManager dropHandler:apihandler];

    /* failed to retrieve information. */
    if (details == nil)
    {
        return;
    }

    NSLog(@"entered didCompleteName for %@", details.display_name);

    if (![theUser isEqualToString:self.specifiedUser])
    {
        return;
    }

    /* Are we watching this user? */
    WatchList *mywatches = (self.userPrefs)[@"watching"];
    if ([mywatches.userids containsObject:details.userid])
    {
        (mywatches.screennames)[details.userid] = details.display_name;
    }

    [self.postStorage setAuthor:details];

    /* Can drop this name. */
    [self.downloadCache removeObject:authorid];

    Post *curr = [self.postStorage postAtIndex:self.cacheIndex];

    if ([curr.author isEqualToString:authorid])
    {
        [self setUserInfoBarUser:details];
    }

    // search for duplicate entry.
    // it may not be totally useful to store this stuff.
    if ((self.userCache)[details.userid] == nil)
    {
        details.image = self.defaultImage;
        (self.userCache)[details.userid] = details;
        [self.apiManager userView:details.userid];
    }

    return;
}

- (void)image:(UIImage *)image finishedSavingWithError:(NSError *)error
  contextInfo:(void *)contextInfo
{
    if (error)
    {
        UIAlertView *alert = \
            [[UIAlertView alloc] initWithTitle:@"Save failed"
                                        message:@"Failed to save image/video"
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        
        [alert show];
    }
    
    return;
}

/**
 * @brief A delegate function for the action sheet that is called when a user
 * clicks a button.
 *
 * @param actionSheet a variable with actionsheet information.
 * @param buttonIndex which button the user selected.
 */
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"%@", [NSString stringWithFormat:@"You selected: '%@'",
                  [actionSheet buttonTitleAtIndex:buttonIndex]]);
    
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];

    if ([buttonTitle isEqualToString:@"Cancel"])
    {
        self.currSheet = USER_SHEET_INVALID;
        
        return;
    }

    if (self.currSheet == USER_SHEET_CREATE)
    {
        if ([buttonTitle isEqualToString:@"Reply"])
        {
            NSLog(@"Reply Selected.");
            [self replyPostHandler];
            
        }
        else if ([buttonTitle isEqualToString:@"Repost"])
        {
            NSLog(@"Repost Selected.");
            [self repostPostHandler];
        }
    }
    else if (self.currSheet == USER_SHEET_SAVE)
    {
        /* They either hit Save Image, or they hit something else. */
        Post *post = [self.postStorage postAtIndex:self.cacheIndex];
        
        if ([buttonTitle isEqualToString:@"Save Image"])
        {
            if ([self.postStorage.postId count] > 0)
            {
                UIImageWriteToSavedPhotosAlbum(
                                               post.image,
                                               self,
                                               @selector(image:finishedSavingWithError:contextInfo:),
                                               nil);
            }
        }
        else if ([buttonTitle isEqualToString:@"Report Post"])
        {
            [self.apiManager reportPost:post.postid asUser:self.specifiedUser];
        }
        else if ([buttonTitle isEqualToString:@"Watch User"])
        {
            [self.apiManager watchUser:self.specifiedUser
                           watchesUser:post.author];
        }
        else if ([buttonTitle isEqualToString:@"Unwatch User"])
        {
            [self.apiManager unwatchUser:self.specifiedUser
                           unwatchesUser:post.author];
        }
        else if ([buttonTitle isEqualToString:@"Authorize User for Comments"])
        {
            [self.apiManager authorizeUser:post.author
                                    asUser:self.specifiedUser];
        }
        else if ([buttonTitle isEqualToString:@"Unauthorize User for Comments"])
        {
            [self.apiManager unauthorizeUser:post.author
                                      asUser:self.specifiedUser];
        }
    }
    else if (self.currSheet == USER_SHEET_FAVORITE)
    {
        if (self.markAction == USER_MARK_FAVORITE)
        {
            NSLog(@"Mark as Favorite.");
            /*
             * self.currentPost is set on updateView -- what is a query returns with the prompt up?
             */
            [self.apiManager favoritePost:self.favoritePost
                                   asUser:self.specifiedUser];
        }
        else /* should be MARK_UNFAVORITE */
        {
            NSLog(@"Unmark as Favorite.");

            [self.apiManager unfavoritePost:self.favoritePost
                                     asUser:self.specifiedUser];
        }
        
        self.markAction = USER_MARK_INVALID;
    }
    else if (self.currSheet == USER_SHEET_REFRESH_COMMENTS)
    {
        [self refreshComments];
    }

    self.currSheet = USER_SHEET_INVALID;

    return;
}

/******************************************************************************
 * Button Handlers
 ******************************************************************************/

#pragma mark - Button Handlers

/**
 * @brief Display information about the author of the currently displayed post.
 */
- (void)userInfoBtnHandler
{
    Post *curr = [self.postStorage postAtIndex:self.cacheIndex];
    User *user = (self.userCache)[curr.author];

    UserTableViewController *uview = \
        [[UserTableViewController alloc] initWithStyle:UITableViewStyleGrouped];

    uview.fromPost = NO;
    uview.eventLogPtr = self.eventLog;
    uview.pivotDelegate = self;
    uview.userPtr = user;
    uview.meIdentifier = self.specifiedUser;
    uview.userCache = self.userCache;
    uview.readOnly = YES;
    uview.title = user.display_name;

    UINavigationController *nav = \
        [[UINavigationController alloc] initWithRootViewController:uview];

    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

    [self presentModalViewController:nav animated:YES];

    return;
}

/**
 * @brief Display information about the post currently displayed.
 */
- (IBAction)postInfoBtnHandler
{
    Post *pst = [self.postStorage postAtIndex:self.cacheIndex];
    User *usr = (self.userCache)[pst.author];

    if (pst == nil)
    {
        return;
    }

    PostInfoBundle *info = \
        [[PostInfoBundle alloc] initWithPost:pst withUser:usr];

    PostInfoTVC *uview = \
        [[PostInfoTVC alloc] initWithStyle:UITableViewStyleGrouped];

    uview.userCache = self.userCache;
    uview.infoBundle = info;

    uview.pivotDelegate = self;
    uview.joinDelegate = self;
    uview.meIdentifier = self.specifiedUser;

    uview.navigationItem.title = pst.postid;

    UINavigationController *nav = \
        [[UINavigationController alloc] initWithRootViewController:uview];

    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    nav.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;

    [self presentModalViewController:nav animated:YES];

    return;
}

/**
 * @brief Display information about the user currently logged into the app.
 */
- (void)meBtnHandler
{
    [self dropJumpOut];

    UserTableViewController *uview = \
        [[UserTableViewController alloc] initWithStyle:UITableViewStyleGrouped];

    NSLog(@"UserPrefs: %@", self.userPrefs);
    
    User *usr = (self.userCache)[self.specifiedUser];

    /*
     * These are assigned as a pointer; make sure it cannot be dropped in the 
     * background.
     */
    uview.userCache = self.userCache;
    uview.userPtr = usr;
    uview.communities = (self.userPrefs)[@"community"];
    uview.watching = (self.userPrefs)[@"watching"];
    uview.meIdentifier = self.specifiedUser;

    uview.eventLogPtr = self.eventLog;

    uview.pivotDelegate = self;
    uview.logoutDelegate = self;
    uview.unfavoriteDelegate = self;

    uview.navigationItem.title = usr.display_name;

    UINavigationController *nav = \
        [[UINavigationController alloc] initWithRootViewController:uview];

    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

    [self presentModalViewController:nav animated:YES];

    return;
}

/**
 * @brief Handle user selection of the home button.
 */
- (void)homeBtnHandler
{
    if (self.queryOnGoing)
    {
        return;
    }
    
    [self dropJumpOut];
    
    [self addGreyOverlay];
    self.view.userInteractionEnabled = NO;
    self.queryOnGoing = YES;
    
    UIImage *img = nil;
    if ([self.postStorage.postId count] > 0)
    {
        Post *post = [self.postStorage postAtIndex:self.cacheIndex];
        img = post.image;
    }
    
    [self.queryCache insertObject:[[PivotDetails alloc] initWithPivot:@"home"
                                                            withValue:self.specifiedUser
                                                            withImage:img]
                          atIndex:0];
    
    [self.apiManager userHome:self.specifiedUser];
    
    return;
}

/**
 * @brief This function is called when you click the pivot button.  Until I
 * transition to pivot gesture, this will handle building the pivot overlay.
 */
- (void)pivotBtnHandler:(UIRotationGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        NSLog(@"pivotBtnHandler");
        
        [self displayPivotTable];

        return;
    }

    return;
}

/**
 * @brief The user clicked refresh, this should re-run the last query (not
 * pushing it onto the query stack) and update the refreshs as necessary, with
 * the obvious goal of not re-downloading anything.  A lot of this work will be
 * handled within the didCompleteQuery delegate handler.
 */
- (void)refreshBtnHandler
{
    if (self.queryOnGoing)
    {
        return;
    }

    if ([self.postStorage.postId count] == 0)
    {
        return;
    }

    /* interestingly, this should never happen */
    if ([self.queryCache count] == 0)
    {
        return;
    }

    [self addGreyOverlay];
    self.view.userInteractionEnabled = NO;
    self.queryOnGoing = YES;
    self.refreshQuery = YES;

    PivotDetails *lastQuery = (self.queryCache)[0];
    NSLog(@"lastQuery: %@ as user: %@", lastQuery, self.specifiedUser);

    if ([lastQuery.pivot isEqualToString:@"home"])
    {
        [self.apiManager userHome:self.specifiedUser];
    }
    else if ([lastQuery.pivot isEqualToString:@"public"])
    {
        [self.apiManager publicStream:self.specifiedUser];
    }
    else if ([lastQuery.pivot isEqualToString:@"get"])
    {
        [self.apiManager getPost:lastQuery.value
                          asUser:self.specifiedUser];
    }
    else
    {
        Post *post = [self.postStorage postAtIndex:0];

        [self.apiManager queryPosts:lastQuery.pivot
                          withValue:lastQuery.value
                             asUser:self.specifiedUser
                              since:post.postid];
    }

    return;
}

/**
 * @brief This function is called when you click the login button.  It is also
 * called when the application first loads.  A user can use this to change who
 * they are.
 *
 * Later we'll likely have a variable title button that can be "Log On" or
 * "Log Off"
 */
- (void)loginBtnHandler
{
    NSLog(@"defaults: %@", self.defaults);
    NSString *screen = [self.defaults objectForKey:@"screenname"];
    
    LoginTVC *loginView = \
        [[LoginTVC alloc] initWithStyle:UITableViewStyleGrouped];
    
    loginView.delegate = self;
    
    if (screen != nil)
    {
        NSLog(@"screen: %@", screen);
        loginView.startingName = screen;
    }
    
    loginView.modalPresentationStyle = UIModalPresentationFullScreen;
    loginView.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self presentModalViewController:loginView animated:YES];
    
    return;
}

/**
 * @brief This function is called when you click the logout button.  It drops
 * the user information; and prompts login.
 */
- (void)logoutBtnHandler
{
    [self createEvent:EVENT_TYPE_LOGOUT withInfo:@"logout" withData:nil];

    [self resetView];

    /* Any running api things will be dropped with invalid user. */

    [self.userPrefs removeAllObjects];
    self.userPrefs = nil;
    self.specifiedUser = nil;

    self.cacheIndex = 0;

    [self.postStorage dropData];
    [self.queryCache removeAllObjects];
    [self.userCache removeAllObjects];
    [self.apiManager cancelAll];

    if (self.queryOnGoing == YES)
    {
        /*
         * QueryOnGoing on logout..., will be dropped if specifiedUser doesn't
         * match.
         */
        self.queryOnGoing = NO;
        self.refreshQuery = NO;
    }
    
    [self loginBtnHandler];
    
    return;
}

/**
 * @brief This button handler is called when they click a button to create a new
 *  post, either as a completely new post or a reply.
 *
 * @param sender the button's identifier.
 */
- (void)chooseImage
{
    /* If you use the navigation thing it acts very differently. */
    
    NewPostTableViewController *postPop = \
    [[NewPostTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    switch (self.currAction)
    {
        case USER_ACTION_REPLY:
        {
            NSLog(@"Reply Button Pushed.");
            
            postPop.title = @"Reply To Post";
            postPop.replyTo = YES;
            
            Post *post = [self.postStorage postAtIndex:self.cacheIndex];
            
            if (post == nil)
            {
                return;
            }
            
            postPop.repostReply = post.postid;
            
            break;
        }
        case USER_ACTION_CREATE:
        {
            NSLog(@"Create Post Button Pushed.");
            
            postPop.title = @"Create Post";
            
            break;
        }
        case USER_ACTION_REPOST:
        {
            NSLog(@"Repost Button Pushed.");
            
            if ([self.postStorage.postId count] == 0)
            {
                return;
            }
            
            postPop.title = @"Repost";
            postPop.repostOf = YES;
            
            Post *post = [self.postStorage postAtIndex:self.cacheIndex];
            
            if (post == nil)
            {
                return;
            }
            
            postPop.repostReply = post.postid;
            postPop.previewImage = [self.display image];
            postPop.tags = [[NSMutableArray alloc] initWithArray:post.tags
                                                       copyItems:YES];
            
            break;
        }
        default:
        {
            break;
        }
    }
    
    postPop.delegate = self;
    postPop.specifiedUser = self.specifiedUser;
    
    if (postPop.tags == nil)
    {
        postPop.tags = [NSMutableArray arrayWithArray:self.lastUsedTags];
    }
    
    if (self.userPrefs != nil)
    {
        if ((self.userPrefs)[@"community"] != nil)
        {
            NSMutableArray *tempArray = [[NSMutableArray alloc] init];
            
            for (id array in (self.userPrefs)[@"community"])
            {
                [tempArray addObject:[array componentsJoinedByString:@","]];
            }
            
            postPop.communities = tempArray;
            
            NSLog(@"postPop.communities: %@", postPop.communities);
        }
    }
    
    UINavigationController *nav = \
        [[UINavigationController alloc] initWithRootViewController:postPop];
    
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self presentModalViewController:nav animated:YES];
    
    NSLog(@"chooseImage returns.");
    return;
}

/**
 * @brief This button handler is for creating posts with the button in the
 * toolbar.
 */
- (void)createPostHandler
{
    NSLog(@"Create/Preview Button Handler Called.");
    
    self.currAction = USER_ACTION_CREATE;
    
    [self chooseImage];
    
    return;
}

/**
 * @brief This button handler is for replying to posts with the button in the
 * toolbar.
 */
- (void)replyPostHandler
{
    NSLog(@"Create/Preview Button Handler Called.");
    
    self.currAction = USER_ACTION_REPLY;
    
    [self chooseImage];
    
    return;
}

/**
 * @brief This button handler is for re-posting to posts with the button in the
 * toolbar.
 */
- (void)repostPostHandler
{
    NSLog(@"Create/Preview Button Handler Called.");
    
    self.currAction = USER_ACTION_REPOST;
    
    [self chooseImage];
    
    return;
}

/**
 * @brief This button handler is for the little reply icon.
 */
- (void)replyRepostHandler
{
    self.currSheet = USER_SHEET_CREATE;
    
    UIActionSheet *sheet = \
    [[UIActionSheet alloc] initWithTitle:nil
                                delegate:self
                       cancelButtonTitle:@"Cancel"
                  destructiveButtonTitle:nil
                       otherButtonTitles:@"Reply", @"Repost", nil];
    
    [sheet showFromBarButtonItem:self.replyPostToolbarBtn animated:YES];
    //    [sheet showInView:self.view];
    
    return;
}

/**
 * @brief This button handler is for the action button.
 */
- (void)saveBtnHandler
{
    self.currSheet = USER_SHEET_SAVE;
    UIActionSheet *sheet = nil;
    
    /* This button is disabled unless postcache is valid. */
    
    Post *post = [self.postStorage postAtIndex:self.cacheIndex];
    User *user = (self.userCache)[post.author];
    
    int buttonCount = 0;
    sheet = [[UIActionSheet alloc] initWithTitle:nil
                                        delegate:self
                               cancelButtonTitle:nil
                          destructiveButtonTitle:nil
                               otherButtonTitles:nil];
    
    if (post.image != nil)
    {
        [sheet addButtonWithTitle:@"Save Image"];
        buttonCount += 1;
    }
    
    if (self.watchingUser)
    {
        [sheet addButtonWithTitle:@"Unwatch User"];
    }
    else
    {
        [sheet addButtonWithTitle:@"Watch User"];
    }
    buttonCount += 1;
    
    /* We do not need to authorize ourselves. */
    if (user != nil && ![post.author isEqualToString:self.specifiedUser])
    {
        if (user.authorized_back)
        {
            [sheet addButtonWithTitle:@"Unauthorize User for Comments"];
        }
        else
        {
            [sheet addButtonWithTitle:@"Authorize User for Comments"];
        }
        buttonCount += 1;
    }
    
    [sheet addButtonWithTitle:@"Report Post"];
    buttonCount += 1;
    
    [sheet addButtonWithTitle:@"Cancel"];
    [sheet setCancelButtonIndex:buttonCount];
    
    [sheet setDestructiveButtonIndex:buttonCount - 1];
    
    [sheet showFromBarButtonItem:self.actionToolbarBtn animated:YES];
    
    return;
}

/**
 * @brief The function handler for either enjoying a post or marking it as a
 * favorite or dislike.
 *
 * @param action
 */
- (void)markPost
{
    if ([self.postStorage.postId count] == 0)
    {
        return;
    }
    
    Post *post = [self.postStorage postAtIndex:self.cacheIndex];
    
    if (post == nil)
    {
        return;
    }
    
    self.currSheet = USER_SHEET_FAVORITE;
    self.favoritePost = post.postid;
    
    UIActionSheet *sheet = nil;
    sheet = [[UIActionSheet alloc] initWithTitle:nil
                                        delegate:self
                               cancelButtonTitle:nil
                          destructiveButtonTitle:nil
                               otherButtonTitles:nil];
    
    if (post.favorite_of_user)
    {
        self.markAction = USER_MARK_UNFAVORITE;
        [sheet addButtonWithTitle:@"Unmark as Favorite"];
    }
    else
    {
        self.markAction = USER_MARK_FAVORITE;
        [sheet addButtonWithTitle:@"Mark as Favorite"];
    }
    
    [sheet addButtonWithTitle:@"Cancel"];
    [sheet setCancelButtonIndex:1];
    
    [sheet showFromBarButtonItem:self.starToolbarBtn animated:YES];
    
    return;
}

- (void)favPost
{
    [self markPost];
}

- (void)publicBtnHandler
{
    if (self.queryOnGoing)
    {
        return;
    }
    
    [self dropJumpOut];
    
    [self addGreyOverlay];
    self.view.userInteractionEnabled = NO;
    self.queryOnGoing = YES;
    
    UIImage *img = nil;
    if ([self.postStorage.postId count] > 0)
    {
        Post *post = [self.postStorage postAtIndex:self.cacheIndex];
        img = post.image;
    }
    
    [self.queryCache insertObject:[[PivotDetails alloc] initWithPivot:@"public"
                                                            withValue:self.specifiedUser
                                                            withImage:img]
                          atIndex:0];
    
    [self.apiManager publicStream:self.specifiedUser];
    
    return;
}

- (void)launchTableView:(id)sender
{
    TableOfContentsViewController *tab = \
        [[TableOfContentsViewController alloc] initWithStyle:UITableViewStylePlain];
    
    /*
     * These are assigned as a pointer; make sure it cannot be dropped in the
     * background.
     */
    tab.communities = (self.userPrefs)[@"community"];
    tab.watching = (self.userPrefs)[@"watching"];
    tab.userIdentifier = self.specifiedUser;
    tab.delegate = self;
    /* for updating. */
    tab.queryCache = self.queryCache;
    tab.queryResults = self.queryResults;
    
    UINavigationController *nav = \
        [[UINavigationController alloc] initWithRootViewController:tab];

    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

    [self presentModalViewController:nav animated:YES];

    return;
}

/******************************************************************************
 * Query TextField Code
 ******************************************************************************/

#pragma mark - Query TextField Code

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([textField.text length] == 0)
    {
        return NO;
    }
    
    if (textField == self.queryTextField)
    {
        /* Should probably do some processing. */
        self.view.userInteractionEnabled = NO;
        self.queryOnGoing = YES;

        [self handlePivot:@"screen_name" /* this sets the grey overlay. */
                withValue:[textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
        
        [textField resignFirstResponder];
    }

    return YES;
}

- (void)cancelQueryBtnHandler
{
    [self.queryTextField resignFirstResponder];
    [self.hiddenField resignFirstResponder];
    
    return;
}

- (void)fromHiddenToNonTextField
{
    //NSLog(@"changeFirstResponder: %@", self.queryTextField);
    [self.queryTextField becomeFirstResponder]; //will return TRUE;
}

/**
 * @brief Special pivot handler for the query button.
 */
- (void)queryBtnHandler
{
    if (self.queryOnGoing)
    {
        return;
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fromHiddenToNonTextField)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];

    /* Bring up the keyboard. */
    [self.hiddenField becomeFirstResponder];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];

    return;
}

/******************************************************************************
 * Thumbnail Tile Code
 ******************************************************************************/

#pragma mark - Thumbnail Tile Code

- (void)updateDownloadedTiles
{
    if (self.downloadTileCount > 0)
    {
        self.downloadTileLbl.text = \
            [NSString stringWithFormat:@"DOWNLOADING TILES: %d", 
             self.downloadTileCount];
    }
    else
    {
        /* 
         * So that if this gets hit repeatedly, which can happen it won't keep 
         * shrinking it.
         */
        if (self.downloadTileLbl == nil)
        {
            return;
        }
        
        NSLog(@"shrinking the view.");
        UIView *view = [self.view viewWithTag:TAG_THUMBNAIL_SCROLLVIEW];
        
        [self.downloadTileLbl removeFromSuperview];

        [view setFrame:view.frame];
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.3];
        [view setFrame:CGRectMake(view.frame.origin.x,
                                  view.frame.origin.y,
                                  view.frame.size.width,
                                  view.frame.size.height - 20)];
        [UIView commitAnimations];

        self.downloadTileLbl = nil; /* release our hold onto it. */
    }
}

/**
 * @brief They doubled tapped one of the thumbnails; dismiss the subview, and
 * flush the cache/re-build it from the item selected.
 */
- (void)thumbnailSelector:(UIGestureRecognizer *)gestureRecognizer
{
    UIImageView *tapped = (UIImageView *)gestureRecognizer.view;

    NSLog(@"selected: %d", tapped.tag);

    self.downloadTileLbl = nil;
    UIView *view = [self.view viewWithTag:TAG_THUMBNAIL_SCROLLVIEW];
    UIView *triview = [self.view viewWithTag:TAG_THUMBNAIL_TRIANGLE];

    view.alpha = 1.0;
    triview.alpha = 1.0;

    [UIView animateWithDuration:0.5
                     animations:^{
                         view.alpha = 0.0;
                         triview.alpha = 0.0;
                     }
                     completion:^(BOOL finished){
                         [view removeFromSuperview];
                         [triview removeFromSuperview];
                     }];

    [self.imageViewTiles removeAllObjects];
    [self flushCache];

    self.tilesVisible = NO;
    self.cacheIndex = tapped.tag;

    [self updateView:[self.postStorage postAtIndex:self.cacheIndex]];
    [self queueForward:self.cacheIndex];

    return;
}

/**
 * @brief This builds and displays the UIImageView tiles for the thumbnail jump
 * table.
 *
 * @note This can really be built apriori.
 */
- (void)showTilesHandler:sender
{
    if (self.tilesVisible)
    {
        NSLog(@"hiding tiles.");
        self.downloadTileLbl = nil;
        
        UIView *view = [self.view viewWithTag:TAG_THUMBNAIL_SCROLLVIEW];
        UIView *triview = [self.view viewWithTag:TAG_THUMBNAIL_TRIANGLE];
        
        view.alpha = 1.0;
        triview.alpha = 1.0;
        
        [UIView animateWithDuration:0.5
                         animations:^{
                             view.alpha = 0.0;
                             triview.alpha = 0.0;
                         }
                         completion:^(BOOL finished){
                             [view removeFromSuperview];
                             [triview removeFromSuperview];
                         }];
        
        [self.imageViewTiles removeAllObjects];
        self.tilesVisible = NO;
        
        return;
    }
    
    if (self.queryOnGoing || [self.postStorage.postId count] == 0)
    {
        return;
    }
    
    self.tilesVisible = YES;
    
    CGRect tagsFrm = self.tagLbl.frame;
    float posY = tagsFrm.origin.y + tagsFrm.size.height;
    
    float screenWidth = self.view.bounds.size.width;
    int number = [self.postStorage.postId count];
    
    UpwardTriangle *uptri = [[UpwardTriangle alloc] initWithFrame:CGRectMake(((screenWidth / 2) - 1) - 20,
                                                                             self.upperToolBar.frame.size.height,
                                                                             40, posY - self.upperToolBar.frame.size.height)];
    uptri.tag = TAG_THUMBNAIL_TRIANGLE;
    uptri.backgroundColor = [UIColor clearColor];
    /* this mask may work properly and not require me to manually animate. */
    //    uptri.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    /*
     * XXX: if we decide to do something with putting the tiles into frames, we
     * can use the border colors.
     */
    UIView *tileContainer = [[UIView alloc] initWithFrame:CGRectMake(0, posY, screenWidth, TILE_DIMENSION + 4 + 20)];
    tileContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    tileContainer.tag = TAG_THUMBNAIL_SCROLLVIEW;
    tileContainer.backgroundColor = [UIColor blackColor]; //so you can see the font.
    
    // need to asses that the UILabel is only 20 tall.
    // need to have a handle to this so I can update it.
    UILabel *statusLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, TILE_DIMENSION + 4, screenWidth, 20)];
    statusLbl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    statusLbl.backgroundColor = [UIColor blackColor];
    statusLbl.textAlignment = UITextAlignmentCenter;
    statusLbl.textColor = [UIColor whiteColor];
    statusLbl.font = [UIFont boldSystemFontOfSize:10];
    
    self.downloadTileLbl = statusLbl;
    self.downloadTileCount = 0;
    
    [tileContainer addSubview:statusLbl];
    
    /* each tile sits 2 pixels down from the top */
    CGRect frm = CGRectMake(0, 0, screenWidth, TILE_DIMENSION + 4); // posY
    /* there is a pixel row to the left of the tiles, and each tile has a row to the right */
    CGSize scrollarea = CGSizeMake(2 + ((TILE_DIMENSION + 2) * number), TILE_DIMENSION);
    
    BOOL badScrollW = NO;
    
    if (scrollarea.width < screenWidth)
    {
        scrollarea.width = screenWidth;
        badScrollW = YES;
    }
    
    UIScrollView *scroller = [[UIScrollView alloc] initWithFrame:frm];
    
    scroller.contentSize = scrollarea;
    scroller.scrollEnabled = YES;
    scroller.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    scroller.backgroundColor = [UIColor colorWithRed:211.0/255 green:211.0/255 blue:211.0/255 alpha:1];//[UIColor lightTextColor];
    /* this isn't quite right, but doing this dynamically is apparently less fun. lol. */
    scroller.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    float posX = 2; /* start it off one to the right so that you can see the left border */
    
    for (int i = 0; i < number; i++)
    {
        Post *obj = [self.postStorage postAtIndex:i];
        
        if ([obj.postid isEqualToString:self.currentPost])
        {
            scroller.contentOffset = CGPointMake(posX - 2, 0);
            
            if (badScrollW)
            {
                scrollarea.width += posX;
                scroller.contentSize = scrollarea;
            }
        }
        
        if (obj.thumbnail == nil)
        {
            /*
             * Because it's clearly still downloading or needs to be downloaded.
             */
            self.downloadTileCount += 1;
            
            if (obj.cachingThumbnail == NO)
            {
                [self.apiManager viewThumbnail:obj.postid];
                obj.cachingThumbnail = YES;
            }
        }
        
        /*
         * XXX: Need to work on a dequeue mechanism to only build those that are
         * displayed to save memory.
         */
        ImageSpinner *img = [[ImageSpinner alloc] initWithFrame:CGRectMake(posX, 2, TILE_DIMENSION, TILE_DIMENSION)];
        img.tag = i;
        img.image = obj.thumbnail;
        img.contentMode = UIViewContentModeScaleToFill;
        img.bounds = CGRectMake(0, 0, TILE_DIMENSION, TILE_DIMENSION);
        img.userInteractionEnabled = YES;
        img.multipleTouchEnabled = YES;
        img.clipsToBounds = YES; // unncessary. : P
        
        img.layer.cornerRadius = 9.0;
        img.layer.masksToBounds = YES;
        img.layer.borderColor = [UIColor clearColor].CGColor;
        img.layer.borderWidth = 1.0;
        
        UITapGestureRecognizer *dtapRecognizer = \
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(thumbnailSelector:)];
        dtapRecognizer.numberOfTouchesRequired = 1;
        dtapRecognizer.numberOfTapsRequired = 2;
        dtapRecognizer.delegate = self;
        
        [img addGestureRecognizer:dtapRecognizer];
        
        [scroller addSubview:img];
        
        [self.imageViewTiles addObject:img];
        
        posX += TILE_DIMENSION + 2;
    }
    
    [tileContainer addSubview:scroller];
    [self.view addSubview:tileContainer];
    [self.view addSubview:uptri];
    
    [self updateDownloadedTiles];
    
    tileContainer.alpha = 0.0;
    uptri.alpha = 0.0;
    [UIView beginAnimations:@"Fade-in" context:NULL];
    [UIView setAnimationDuration:0.5];
    tileContainer.alpha = 1.0;
    uptri.alpha = 1.0;
    [UIView commitAnimations];
    
    return;
}

/******************************************************************************
 * Comments Code
 ******************************************************************************/

#pragma mark - Comments Code

/**
 * @brief Refresh the comments.
 */
- (void)refreshComments
{
    Post *post = [self.postStorage postAtIndex:self.cacheIndex];
    UICommentList *masterview = (UICommentList *)[self.view viewWithTag:TAG_COMMENT_MAINVIEW];

    masterview.status.text = @"Fetching";
    [masterview.busy startAnimating];

    [self.apiManager getComments:post.postid asUser:self.specifiedUser];

    return;
}

/**
 * @brief Create a comment for the given post, this button only exist when the
 * user tries to create a comment.
 */
- (void)createCommentBtnHandler:(id)sender
{
    if (self.commentOutstanding == NO)
    {
        Post *post = [self.postStorage postAtIndex:self.cacheIndex];
        
        [self.createCommentSpinner startAnimating];
        self.createCommentPostBtn.enabled = NO;
        self.commentOutstanding = YES;
        [self.createCommentHandler comment:post.postid
                                    asUser:self.specifiedUser
                               withComment:self.commentTextField.text];
    }
}

/**
 * @brief This hides the scrollview.
 */
- (void)hideComments
{
    UICommentList *view = (UICommentList *)[self.view viewWithTag:TAG_COMMENT_MAINVIEW];
    
    if ([self.commentHiddenField isFirstResponder]) /* not likely */
    {
        [self.commentHiddenField resignFirstResponder];
    }
    if ([self.commentTextField isFirstResponder]) /* hide the comment create field. */
    {
        [self.commentTextField resignFirstResponder];
    }

    [UIView animateWithDuration:0.2
                     animations:^{
                         view.frame = CGRectMake(view.frame.origin.x,
                                                 view.frame.origin.y + view.frame.size.height,
                                                 view.frame.size.width,
                                                 0); // so it shrinks.
                     }
                     completion:^(BOOL finished){
                         [view removeFromSuperview];
                     }];

    return;
}

- (void)fromCommentHiddenToNonTextField
{
    [self.commentTextField becomeFirstResponder];
}

- (void)cancelCommentCreate
{
    [self.createCommentSpinner stopAnimating];
    [self.commentTextField resignFirstResponder];
    [self.commentHiddenField resignFirstResponder];
    
    [self.createCommentHandler cancel];
    self.commentOutstanding = NO;
    self.createCommentPostBtn.enabled = YES;
    
    // XXX: Kill APIHandler.
}

- (void)addCommentTextFieldButton
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fromCommentHiddenToNonTextField)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    /* Bring up the keyboard. */
    [self.commentHiddenField becomeFirstResponder];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    return;
}

/**
 * @brief This builds the comment viewer, or maybe launches the keyboard thing.
 *
 * @warning A lot of these hard-coded values, I wonder about that.
 */
- (void)showComments:(id)sender
{
    bool fetching = NO;
    
    // if post.num_comments == 0, bring up the comment adder.
    if ([self.postStorage.postId count] == 0)
    {
        return;
    }
    
    /* already visible. */
    if ([self.view viewWithTag:TAG_COMMENT_MAINVIEW] != nil)
    {
        return;
    }
    
    /* 
     * XXX: This will release what was there and assign a new one.  My
     * APIHandler is not really meant to be reusable.
     */
    self.commentOutstanding = NO;
    self.createCommentHandler = [[APIHandler alloc] init];
    self.createCommentHandler.delegate = self;

    Post *post = [self.postStorage postAtIndex:self.cacheIndex];
    
    /* maybe this should go below. */
    if (post.comments != nil)
    {
        double interval = [[NSDate date] timeIntervalSinceDate:post.commentsRefreshed];
        // interval is in seconds; if older than five minutes, re-download.
        // xxx: add button to refresh.
        if (interval > 300)
        {
            fetching = YES;
        }

        /* have we ever tried to download it? */
        if (post.commentsRefreshed == nil)
        {
            fetching = YES;
        }
    }
    else
    {
        fetching = YES;
    }
    
    CGFloat viewHeight = (self.view.bounds.size.height / 2);
    if (viewHeight > COMMENT_MAXIMUM_VIEW_HEIGHT)
    {
        viewHeight = COMMENT_MAXIMUM_VIEW_HEIGHT;
    }
    
    NSLog(@"viewHeight: %f", viewHeight);

    /* the height is full here so it should slide up versus grow up. */
    CGRect mFrm = CGRectMake(0,
                             self.view.bounds.size.height, // set to start at the bottom.
                             self.view.bounds.size.width,
                             0);

    UICommentList *master = [[UICommentList alloc] initWithFrame:mFrm
                                                         withTag:TAG_COMMENT_MAINVIEW
                                                  withViewHeight:viewHeight];
    master.delegate = self;

    if (fetching)
    {
        [master.busy startAnimating];
    }

    if (fetching)
    {
        master.status.text = @"Fetching";
    }

    [self.view addSubview:master];

    if (fetching == NO)
    {
        /* Really should have this code in a couple places. */
        self.commentToolbarBtn.title = [NSString stringWithFormat:@"%d",
                                        [post.comments count]];

        [master loadComments:post.comments
                    withUser:(self.userCache)[post.author]];
    }

    /* XXX: maybe set the duration to 0 for the keyboard thing since that takes time. */
    float duration = (post.num_comments == 0) ? 0.01 : 0.2;

    if (fetching) // fetch once the stuff is in place in the view.
    {
        [self.apiManager getComments:post.postid asUser:self.specifiedUser];
    }

    [UIView animateWithDuration:duration
                     animations:^{
                         /* Should grow from the bottom */
                         master.frame = CGRectMake(0,
                                                   (self.view.bounds.size.height - viewHeight) - 1,
                                                   self.view.bounds.size.width,
                                                   viewHeight);
                     }
                     completion:^(BOOL finished){
                         if (post.num_comments == 0)
                         {
                             [self addCommentTextFieldButton];
                         }
                         
                         master.startingFrame = master.frame;
                         master.startingScrollFrame = master.scroller.frame;
                     }];

    return;
}

/******************************************************************************
 * Grey Busy Overlay Code
 ******************************************************************************/

#pragma mark - Grey Busy Overlay Code

/**
 * @brief Update grey Overlay status value; the value in the label.
 */
- (void)setOverlayStatus:(NSString *)value
{
    UIView *greyView = [self.view viewWithTag:TAG_QUERY_LOADINGVIEW];
    UILabel *status = (UILabel *)[greyView viewWithTag:TAG_QUERY_STATUSLABEL];
    UIActivityIndicatorView *spinner = \
        (UIActivityIndicatorView *)[greyView viewWithTag:TAG_QUERY_ACTIVITY];

    [spinner stopAnimating];
    status.text = value;

    return;
}

/**
 * @brief Shrink away the grey overlay.
 */
- (void)dropGreyOverlay
{
    UIView *greyView = [self.view viewWithTag:TAG_QUERY_LOADINGVIEW];
    UIView *status = [greyView viewWithTag:TAG_QUERY_STATUSLABEL];
    UIView *spinner = [greyView viewWithTag:TAG_QUERY_ACTIVITY];
    [status removeFromSuperview];
    [spinner removeFromSuperview];

    /* This should shrink to nothing in the center of the view. */
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         greyView.frame = \
                            CGRectMake((self.view.bounds.size.width / 2) - 1,
                                       (self.view.bounds.size.height / 2) - 1,
                                       0, 0);
                     }
                     completion:^(BOOL finished){
                         [greyView removeFromSuperview];
                     }];

    return;
}

- (void)addGreyOverlay
{
    /* CGRectZero makes it grow weirdly. */
    CGRect startFrm = CGRectMake(0, self.view.bounds.size.height, 0, 0);
    
    UIView *greyView = [[UIView alloc] initWithFrame:startFrm];
    greyView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    greyView.tag = TAG_QUERY_LOADINGVIEW;
    greyView.backgroundColor = [UIColor darkGrayColor];
    greyView.alpha = 0.85;

    CGRect frm = self.view.bounds;

    CGFloat posX = (frm.size.width / 4) - 1;
    if (posX < 20)
    {
        posX = 30;
    }
    
    CGRect labelFrm = CGRectMake(posX,
                                 (frm.size.height / 2) - 1,
                                 (frm.size.width / 2), // width is half.
                                 20);

    UILabel *status = [[UILabel alloc] initWithFrame:labelFrm];
    status.tag = TAG_QUERY_STATUSLABEL;
    status.font = [UIFont boldSystemFontOfSize:20];
    status.textColor = [UIColor whiteColor];
    status.text = @"Loading...";
    status.backgroundColor = [UIColor clearColor];
    status.adjustsFontSizeToFitWidth = YES;

    CGRect middle = CGRectMake(labelFrm.origin.x - 20,
                               (frm.size.height / 2) - 1,
                               20, 20);

    UIActivityIndicatorView *spinner = \
        [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    spinner.tag = TAG_QUERY_ACTIVITY;
    spinner.frame = middle;
    spinner.hidesWhenStopped = YES;
    [spinner startAnimating];

    [greyView addSubview:spinner];
    [greyView addSubview:status];

    [self.view addSubview:greyView];

    [UIView beginAnimations:@"Bring-Up" context:NULL];
    [UIView setAnimationDuration:0.3];
    greyView.frame = self.view.bounds;
    [UIView commitAnimations];
    
    return;
}

/******************************************************************************
 * Jump Out Menu Code
 ******************************************************************************/

#pragma mark - Jump Out Menu Code

-(void)dropJumpOut
{
    UIView *greyView = [self.view viewWithTag:TAG_JUMPOUT_BACKVIEW];
    UIView *scroller = [self.view viewWithTag:TAG_JUMPOUT_SCROLLER];
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         greyView.frame = CGRectMake(0, self.view.bounds.size.height, 0, 0);
                         scroller.frame = CGRectMake(0, self.view.bounds.size.height, 0, 0);
                     }
                     completion:^(BOOL finished){
                         [greyView removeFromSuperview];
                         [scroller removeFromSuperview];
                     }];

    return;
}

/**
 * @brief If the user touches outside the jump menu it should slide back down.
 *
 * @note I'm not going to lie, this was easy for me to code because I got the
 * multi-view touching to work for iOS 5.
 */
- (void)handleOutsideJumpOut:(UITapGestureRecognizer *)recognizer
{
    UIView *grey = [self.view viewWithTag:TAG_JUMPOUT_BACKVIEW];
    UIView *jump = [self.view viewWithTag:TAG_JUMPOUT_SCROLLER];

    CGPoint tapPoint = [recognizer locationInView:recognizer.view];

    NSLog(@"tapPoint: (%f, %f)", tapPoint.x, tapPoint.y); // within self.userInfoBar

    CGRect x = [jump convertRect:jump.frame toView:grey];

    CGRect newSquare = CGRectMake(jump.frame.origin.x,
                                  x.origin.y - jump.frame.origin.y,
                                  jump.frame.size.width,
                                  jump.frame.size.height);

    if (!CGRectContainsPoint(newSquare, tapPoint))
    {
        NSLog(@"tapped outside menu.");
        [self dropJumpOut];
        
        return;
    }

    return;
}

/**
 * @brief Display the Jump-Out Menu.  This menu lets a user change their view
 * from a variety of options in a list.
 */
- (void)displayJumpOut
{
    UIView *greyView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height, 0, 0)];
    greyView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    greyView.tag = TAG_JUMPOUT_BACKVIEW;
    greyView.backgroundColor = [UIColor darkGrayColor];
    greyView.alpha = 0.50;

    UITapGestureRecognizer *tap = \
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(handleOutsideJumpOut:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;

    [greyView addGestureRecognizer:tap];

    // width, height
    CGSize buttonSz = CGSizeMake(150, 44);
    CGSize labelSz = CGSizeMake(buttonSz.width, 24);
    /* need to find a consistent way of doing this. */
    UIEdgeInsets imgEdge = UIEdgeInsetsMake(0, -20, 0, 0);

    /* Start it as dot in the lower left corner. */
    UIScrollView *scroller = [[UIScrollView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height, 0, 0)];
    scroller.backgroundColor = [UIColor whiteColor];
    scroller.alpha = 1.0;
    scroller.tag = TAG_JUMPOUT_SCROLLER;

    UILabel *youLbl = [[UILabel alloc] init];
    youLbl.backgroundColor = [UIColor darkGrayColor];
    youLbl.textColor = [UIColor whiteColor];
    youLbl.textAlignment = UITextAlignmentLeft;
    youLbl.text = @" You:";
    youLbl.font = [UIFont boldSystemFontOfSize:18];
    youLbl.adjustsFontSizeToFitWidth = NO;
    
    youLbl.layer.borderColor = [UIColor whiteColor].CGColor;
    youLbl.layer.borderWidth = 2.0;
    youLbl.tag = 901;
    youLbl.frame = CGRectMake(3, 3, buttonSz.width, labelSz.height);
    
    UIButton *acct = [UIButton buttonWithType:UIButtonTypeCustom];
    acct.backgroundColor = THEME_GREEN;
    acct.titleLabel.textColor = [UIColor whiteColor];
    acct.titleLabel.textAlignment = UITextAlignmentLeft;
    [acct setTitle:@"Account" forState:UIControlStateNormal];
    acct.titleLabel.font = [UIFont systemFontOfSize:18];
    acct.titleLabel.adjustsFontSizeToFitWidth = NO;
    acct.layer.borderColor = [UIColor whiteColor].CGColor;
    acct.layer.borderWidth = 2.0;
    acct.tag = youLbl.tag + 1;
    [acct addTarget:self
             action:@selector(meBtnHandler)
   forControlEvents:UIControlEventTouchUpInside];
    acct.frame = CGRectMake(3, youLbl.frame.origin.y + labelSz.height + 2, buttonSz.width, buttonSz.height);
    
    User *user = (self.userCache)[self.specifiedUser];
    if (user != nil && user.image != nil)
    {
        // do once elsewhere and store.
        CGSize shrink = CGSizeMake(30, 30);
        
        UIGraphicsBeginImageContext(shrink);
        [user.image drawInRect:CGRectMake(0, 0, shrink.width, shrink.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        [acct setImage:newImage forState:UIControlStateNormal];
        [acct setTitleEdgeInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
        acct.imageEdgeInsets = imgEdge;
        acct.adjustsImageWhenHighlighted = YES;
    }

    UIButton *outb = [UIButton buttonWithType:UIButtonTypeCustom];
    outb.backgroundColor = THEME_GREEN;

    outb.titleLabel.textColor = [UIColor whiteColor];
    outb.titleLabel.textAlignment = UITextAlignmentLeft;
    [outb setTitle:@"Outbox" forState:UIControlStateNormal];
    outb.titleLabel.font = [UIFont systemFontOfSize:18];
    outb.titleLabel.adjustsFontSizeToFitWidth = NO;
    
    [outb setImage:[UIImage imageNamed:@"target-button.png"] forState:UIControlStateNormal];
    [outb setTitleEdgeInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
    outb.imageEdgeInsets = imgEdge;
    outb.adjustsImageWhenHighlighted = YES;
    
    outb.layer.borderColor = [UIColor whiteColor].CGColor;
    outb.layer.borderWidth = 2.0;
    outb.tag = acct.tag + 1;
    [outb addTarget:nil
             action:nil
   forControlEvents:UIControlEventTouchUpInside];
    outb.frame = CGRectMake(3, acct.frame.origin.y + buttonSz.height + 2, buttonSz.width, buttonSz.height);

    UILabel *streamLbl = [[UILabel alloc] init];
    streamLbl.backgroundColor = [UIColor darkGrayColor];
    streamLbl.textColor = [UIColor whiteColor];
    streamLbl.textAlignment = UITextAlignmentLeft;
    streamLbl.text = @" Streams:";
    streamLbl.font = [UIFont boldSystemFontOfSize:18];
    streamLbl.adjustsFontSizeToFitWidth = NO;
    
    streamLbl.layer.borderColor = [UIColor whiteColor].CGColor;
    streamLbl.layer.borderWidth = 2.0;
    streamLbl.tag = outb.tag + 1;
    streamLbl.frame = CGRectMake(3, outb.frame.origin.y + buttonSz.height + 2, buttonSz.width, labelSz.height);

//    maybe apply this to all of them.
//    [startButton setTitleShadowColor:[UIColor redColor] forState:UIControlStateNormal];
//    startButton.titleLabel.shadowOffset = CGSizeMake(3.0f, 3.0f);

    UIButton *homeb = [UIButton buttonWithType:UIButtonTypeCustom];
    homeb.backgroundColor = THEME_GREEN;

    homeb.titleLabel.textColor = [UIColor whiteColor];
    homeb.titleLabel.textAlignment = UITextAlignmentLeft;
    [homeb setTitle:@"Home" forState:UIControlStateNormal];
    homeb.titleLabel.font = [UIFont systemFontOfSize:18];
    homeb.titleLabel.adjustsFontSizeToFitWidth = NO;
    
    [homeb setImage:[UIImage imageNamed:@"home-button.png"] forState:UIControlStateNormal];
    [homeb setTitleEdgeInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
    homeb.imageEdgeInsets = imgEdge;
    homeb.adjustsImageWhenHighlighted = YES;
    
    homeb.layer.borderColor = [UIColor whiteColor].CGColor;
    homeb.layer.borderWidth = 2.0;
    homeb.tag = streamLbl.tag + 1;
    [homeb addTarget:self
              action:@selector(homeBtnHandler)
    forControlEvents:UIControlEventTouchUpInside];
    homeb.frame = CGRectMake(3, streamLbl.frame.origin.y + labelSz.height + 2, buttonSz.width, buttonSz.height);

    UIButton *pubb = [UIButton buttonWithType:UIButtonTypeCustom];
    pubb.backgroundColor = THEME_GREEN;
    pubb.titleLabel.textColor = [UIColor whiteColor];
    pubb.titleLabel.textAlignment = UITextAlignmentLeft;
    [pubb setTitle:@"Public" forState:UIControlStateNormal];

    pubb.titleLabel.font = [UIFont systemFontOfSize:18];
    pubb.titleLabel.adjustsFontSizeToFitWidth = NO;

    [pubb setImage:[UIImage imageNamed:@"stream-button.png"] forState:UIControlStateNormal];
    [pubb setTitleEdgeInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
    pubb.imageEdgeInsets = imgEdge;
    pubb.adjustsImageWhenHighlighted = YES;

    pubb.layer.borderColor = [UIColor whiteColor].CGColor;
    pubb.layer.borderWidth = 2.0;
    pubb.tag = outb.tag + 1;
    [pubb addTarget:self
             action:@selector(publicBtnHandler)
   forControlEvents:UIControlEventTouchUpInside];
    pubb.frame = CGRectMake(3, homeb.frame.origin.y + buttonSz.height + 2, buttonSz.width, buttonSz.height);

    UIButton *backb = [UIButton buttonWithType:UIButtonTypeCustom];
    backb.backgroundColor = THEME_GREEN;
    backb.titleLabel.textColor = [UIColor whiteColor];
    backb.titleLabel.textAlignment = UITextAlignmentLeft;
    [backb setTitle:@"  <<" forState:UIControlStateNormal];
    backb.titleLabel.font = [UIFont systemFontOfSize:18];
    backb.titleLabel.adjustsFontSizeToFitWidth = NO;
    backb.layer.borderColor = [UIColor whiteColor].CGColor;
    backb.layer.borderWidth = 2.0;
    backb.tag = pubb.tag + 1;
    [backb addTarget:self
             action:@selector(dropJumpOut)
   forControlEvents:UIControlEventTouchUpInside];
    backb.frame = CGRectMake(3, pubb.frame.origin.y + buttonSz.height + 2, buttonSz.width, buttonSz.height);

    // width, height
    scroller.contentSize = CGSizeMake(buttonSz.width + 6,
                                      backb.frame.origin.y + buttonSz.height + 3);

    [scroller addSubview:youLbl];
    [scroller addSubview:acct];
    [scroller addSubview:outb];
    [scroller addSubview:streamLbl];
    [scroller addSubview:homeb];
    [scroller addSubview:pubb];
    [scroller addSubview:backb];

    [self.view addSubview:greyView];
    [self.view addSubview:scroller];

    /* The contentSize will at some point exceed the frame size. */
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         greyView.frame = CGRectMake(0, 0,
                                                     self.view.bounds.size.width,
                                                     self.view.bounds.size.height);

                         scroller.frame = CGRectMake(0,
                                                     self.view.bounds.size.height - scroller.contentSize.height,
                                                     scroller.contentSize.width,
                                                     scroller.contentSize.height);
                     }
     ];

    return;
}

/******************************************************************************
 * Pivot View Code
 *
 * It's worth mentioning that if I use a view controller container I can likely
 * handle this better (more easily).
 ******************************************************************************/

#pragma mark - Pivot View Code

/**
 * @brief Convert Button click to @selector(handlePivot:withValue:).
 */
- (void)pivotButton:(id)sender
{
    RowButton *row = (RowButton *)sender;
    [self handlePivot:row.pivot withValue:row.value];

    [self dropPivotTable];

    return;
}

/**
 * @brief Drop the pivot table.
 */
- (void)dropPivotTable
{
    UIView *greyView = [self.view viewWithTag:TAG_PIVOT_BACKVIEW];
    
    [UIView animateWithDuration:0.2
                     animations:^{
                         greyView.frame = CGRectMake((self.view.bounds.size.width / 2),
                                                     (self.view.bounds.size.height / 2),
                                                     0, 0);
                     }
                     completion:^(BOOL finished){
                         [greyView removeFromSuperview];
                     }];

    return;
}

/**
 * @brief Display the Jump-Out Menu.  This menu lets a user change their view
 * from a variety of options in a list.
 *
 * It's set up so you can remove the TAG_PIVOT_BACKVIEW and all else goes away.
 *
 * Frankly, I could just make the pivot table half the height of the view, or
 * smaller, versus trying to make it something neat with a 10 px border.
 */
- (void)displayPivotTable
{
    if ([self.postStorage.postId count] == 0)
    {
        return;
    }

    if (self.queryOnGoing)
    {
        return;
    }

    NSLog(@"displayPivotTable");

    Post *post = [self.postStorage postAtIndex:self.cacheIndex];

    CGRect greyStart = CGRectMake((self.view.bounds.size.width / 2) - 1,
                                  (self.view.bounds.size.height / 2) - 1,
                                  0,
                                  0);

    UIView *greyView = [[UIView alloc] initWithFrame:greyStart];
    greyView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    greyView.autoresizesSubviews = NO;
    greyView.tag = TAG_PIVOT_BACKVIEW;
    greyView.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.50];
    greyView.alpha = 1.0;

    /* The table will sit centered with 10 on each size; or it should. */
    CGSize frameSz = CGSizeMake(self.view.bounds.size.width - 20,
                                self.view.bounds.size.height - 20);

    CGRect frameStart = CGRectMake((self.view.bounds.size.width / 2) - 1,
                                   (self.view.bounds.size.height / 2) - 1,
                                   0,
                                   0);

    UIView *frameView = [[UIView alloc] initWithFrame:frameStart];
    frameView.tag = TAG_PIVOT_FRAMEVIEW;
    frameView.backgroundColor = [UIColor blackColor];
    frameView.autoresizingMask = UIViewAutoresizingNone;

    [greyView addSubview:frameView];
    
    /* the border may need some play. */
    frameView.layer.cornerRadius = 5;
    frameView.clipsToBounds = YES;

    /* 
     * If this looks how we want size-wise, etc, we should use a function to
     * create it.
     */
    UIButton *dismiss = [UIButton buttonWithType:UIButtonTypeCustom];
    dismiss.frame = CGRectMake(5, 5, 55, 25);
    dismiss.backgroundColor = THEME_GREEN;
    [dismiss setTitle:@"Done" forState:UIControlStateNormal];
    [dismiss addTarget:self
                action:@selector(dropPivotTable)
      forControlEvents:UIControlEventTouchUpInside];

    dismiss.layer.borderColor = [UIColor whiteColor].CGColor;
    dismiss.layer.borderWidth = 1;
    dismiss.layer.cornerRadius = 5;
    dismiss.clipsToBounds = YES;
    dismiss.layer.shadowOffset = CGSizeMake(0, 3);
    dismiss.layer.shadowRadius = 5.0;
    dismiss.layer.shadowColor = [UIColor whiteColor].CGColor;
    dismiss.layer.shadowOpacity = 0.8;

    [frameView addSubview:dismiss];

    /* five for the left side. */
    CGFloat otherPortion = dismiss.frame.origin.x + dismiss.frame.size.width + 5;

    UILabel *title = \
        [[UILabel alloc] initWithFrame:CGRectMake(otherPortion,
                                                  5,
                                                  frameSz.width - (otherPortion + 5), // extra +5 to account for the right side.
                                                  25)];
    title.backgroundColor = [UIColor clearColor];
    title.font = [UIFont boldSystemFontOfSize:25];
    title.text = @"Select to Pivot";
    title.textAlignment = UITextAlignmentCenter;
    title.textColor = [UIColor whiteColor];
    title.tag = 901;

    [frameView addSubview:title];

    /* set the scroller 5 below this. */
    CGFloat navBarHeight = dismiss.frame.size.height + dismiss.frame.origin.y + 5;

    /* Is 5 on each side enough? */
    CGSize tableSz = CGSizeMake(frameSz.width - 10,
                                frameSz.height - (navBarHeight + 5));

    UIScrollView *scroller = \
        [[UIScrollView alloc] initWithFrame:CGRectMake(5,
                                                       navBarHeight,
                                                       tableSz.width,
                                                       0)];
    scroller.tag = TAG_PIVOT_SCROLLER;
    /* 
     * The following three lines were added to fix the scroll indicators, but 
     * it doens't work.
     */
    scroller.layer.masksToBounds = YES;
//    scroller.autoresizesSubviews = YES;
    scroller.showsVerticalScrollIndicator = YES;

    CGFloat posY = 0;

    // could use macros for these.
    CGFloat lblHeight = 20.0;
    CGFloat rowHeight = 30.0;
    CGFloat fontSize = 24.0;
    CGFloat categoryFont = 18.0;
    
    int scrollerTags = 900;

    if (post.display_name != nil)
    {
        UILabel *disp = [[UILabel alloc] initWithFrame:CGRectMake(0, posY, tableSz.width, lblHeight)];
        disp.backgroundColor = [UIColor darkGrayColor];

        disp.text = @" Author";
        disp.textColor = [UIColor whiteColor];
        disp.font = [UIFont boldSystemFontOfSize:categoryFont];
        disp.tag = scrollerTags++;

        [scroller addSubview:disp];

        /* need to add border lines... */
        posY += disp.frame.size.height;
        
        RowButton *dispB = [RowButton buttonWithType:UIButtonTypeCustom];
        dispB.backgroundColor = [UIColor grayColor];
        dispB.titleLabel.textColor = [UIColor whiteColor];
        [dispB setTitle:post.display_name forState:UIControlStateNormal];
        dispB.titleLabel.font = [UIFont systemFontOfSize:fontSize];
        dispB.frame = CGRectMake(0, posY, tableSz.width, rowHeight);
        [dispB addTarget:self
                  action:@selector(pivotButton:)
        forControlEvents:UIControlEventTouchUpInside];
        dispB.pivot = @"screen_name";
        dispB.value = post.display_name;
        dispB.tag = scrollerTags++;

        [scroller addSubview:dispB];
        
        posY += dispB.frame.size.height;
    }
    else
    {
        UILabel *disp = [[UILabel alloc] initWithFrame:CGRectMake(0, posY, tableSz.width, lblHeight)];
        disp.backgroundColor = [UIColor darkGrayColor];
        
        disp.text = @" Author";
        disp.textColor = [UIColor whiteColor];
        disp.font = [UIFont boldSystemFontOfSize:categoryFont];
        disp.tag = scrollerTags++;
        
        [scroller addSubview:disp];
        
        /* need to add border lines... */
        posY += disp.frame.size.height;
        
        RowButton *dispB = [RowButton buttonWithType:UIButtonTypeCustom];
        dispB.backgroundColor = [UIColor grayColor];
        dispB.titleLabel.textColor = [UIColor whiteColor];
        [dispB setTitle:post.author forState:UIControlStateNormal];
        dispB.titleLabel.font = [UIFont systemFontOfSize:fontSize];
        dispB.frame = CGRectMake(0, posY, tableSz.width, rowHeight);
        [dispB addTarget:self
                  action:@selector(pivotButton:)
        forControlEvents:UIControlEventTouchUpInside];
        dispB.pivot = @"author";
        dispB.value = post.author;
        dispB.tag = scrollerTags++;

        [scroller addSubview:dispB];
        
        posY += dispB.frame.size.height;
    }
    
    if ([post.tags count] > 0)
    {
        int count = [post.tags count];
        
        UILabel *disp = [[UILabel alloc] initWithFrame:CGRectMake(0, posY, tableSz.width, lblHeight)];
        disp.backgroundColor = [UIColor darkGrayColor];
        
        disp.text = @" Tags";
        disp.textColor = [UIColor whiteColor];
        disp.font = [UIFont boldSystemFontOfSize:categoryFont];
        disp.tag = scrollerTags++;
        
        [scroller addSubview:disp];
        
        posY += disp.frame.size.height;
        
        for (unsigned int i = 0; i < count; i++)
        {
            RowButton *dispB = [RowButton buttonWithType:UIButtonTypeCustom];
            dispB.backgroundColor = [UIColor grayColor];
            dispB.titleLabel.textColor = [UIColor whiteColor];
            [dispB setTitle:post.tags[i] forState:UIControlStateNormal];
            dispB.titleLabel.font = [UIFont systemFontOfSize:fontSize];
            dispB.frame = CGRectMake(0, posY, tableSz.width, rowHeight);
            [dispB addTarget:self
                      action:@selector(pivotButton:)
            forControlEvents:UIControlEventTouchUpInside];
            dispB.pivot = @"tag";
            dispB.value = post.tags[i];
            dispB.titleLabel.adjustsFontSizeToFitWidth = YES;
            dispB.tag = scrollerTags++;

            [scroller addSubview:dispB];

            posY += dispB.frame.size.height;
            
            if (i < count - 1)
            {
                /* XXX: borders may be better... so, ya know, change later. */
                UIView *border = [[UIView alloc] initWithFrame:CGRectMake(0, posY, tableSz.width, 1)];
                border.backgroundColor = [UIColor whiteColor];
                border.tag = scrollerTags++;
                [scroller addSubview:border];
                posY += border.frame.size.height;
            }
        }
    }
    
    if ([post.communities count] > 0)
    {
        int count = [post.communities count];
        
        UILabel *disp = [[UILabel alloc] initWithFrame:CGRectMake(0, posY, tableSz.width, lblHeight)];
        disp.backgroundColor = [UIColor darkGrayColor];
        
        disp.text = @" Communities";
        disp.textColor = [UIColor whiteColor];
        disp.font = [UIFont boldSystemFontOfSize:categoryFont];
        disp.tag = scrollerTags++;
        
        [scroller addSubview:disp];
        
        posY += disp.frame.size.height;
        
        for (unsigned int i = 0; i < count; i++)
        {
            RowButton *dispB = [RowButton buttonWithType:UIButtonTypeCustom];
            dispB.backgroundColor = [UIColor grayColor];
            dispB.titleLabel.textColor = [UIColor whiteColor];
            [dispB setTitle:post.communities[i] forState:UIControlStateNormal];
            dispB.titleLabel.font = [UIFont systemFontOfSize:fontSize];
            dispB.frame = CGRectMake(0, posY, tableSz.width, rowHeight);
            [dispB addTarget:self
                      action:@selector(pivotButton:)
            forControlEvents:UIControlEventTouchUpInside];
            dispB.pivot = @"community";
            dispB.value = post.communities[i];
            dispB.titleLabel.adjustsFontSizeToFitWidth = YES;
            dispB.tag = scrollerTags++;

            [scroller addSubview:dispB];
            
            posY += dispB.frame.size.height;

            if (i < count - 1)
            {
                /* XXX: borders may be better... so, ya know, change later. */
                UIView *border = [[UIView alloc] initWithFrame:CGRectMake(0, posY, tableSz.width, 1)];
                border.backgroundColor = [UIColor whiteColor];
                border.tag = scrollerTags++;
                [scroller addSubview:border];
                posY += border.frame.size.height;
            }
        }
    }
    
    if (post.num_replies > 0)
    {
        UILabel *disp = [[UILabel alloc] initWithFrame:CGRectMake(0, posY, tableSz.width, lblHeight)];
        disp.backgroundColor = [UIColor darkGrayColor];
        
        disp.text = [NSString stringWithFormat:@" Number of Replies: %d", post.num_replies];
        disp.textColor = [UIColor whiteColor];
        disp.font = [UIFont boldSystemFontOfSize:categoryFont];
        disp.tag = scrollerTags++;
        
        [scroller addSubview:disp];
        
        /* need to add border lines... */
        posY += disp.frame.size.height;
        
        RowButton *dispB = [RowButton buttonWithType:UIButtonTypeCustom];
        dispB.backgroundColor = [UIColor grayColor];
        dispB.titleLabel.textColor = [UIColor whiteColor];
        [dispB setTitle:@"See Replies" forState:UIControlStateNormal];
        dispB.titleLabel.font = [UIFont systemFontOfSize:fontSize];
        dispB.frame = CGRectMake(0, posY, tableSz.width, rowHeight);
        [dispB addTarget:self
                  action:@selector(pivotButton:)
        forControlEvents:UIControlEventTouchUpInside];
        dispB.pivot = @"reply_to";
        dispB.value = post.postid;
        dispB.tag = scrollerTags++;

        [scroller addSubview:dispB];
        
        posY += dispB.frame.size.height;
    }
    
    NSLog(@"posY: %f", posY);

    scroller.contentSize = CGSizeMake(tableSz.width, posY);
    scroller.scrollEnabled = YES;

    if (posY > tableSz.height)
    {
        NSLog(@"scroller larger than table it's placed in.");
        scroller.frame = CGRectMake(scroller.frame.origin.x,
                                    scroller.frame.origin.y,
                                    scroller.frame.size.width,
                                    tableSz.height);
    }
    else
    {
        scroller.frame = CGRectMake(scroller.frame.origin.x,
                                    scroller.frame.origin.y,
                                    scroller.frame.size.width,
                                    posY);
    }

    [frameView addSubview:scroller];

    [self.view addSubview:greyView];

    CGSize newFrameSize = CGSizeZero;
    CGFloat newMiddle = 0;
    CGFloat contentSize = scroller.contentSize.height + navBarHeight + 5;

    /* If the box we provide is too larger, shrink it and adjust. */
    if (contentSize < tableSz.height)
    {
        /* the +5 at the bottom of the height accounts for the frame border. */
        newFrameSize = CGSizeMake(frameSz.width, contentSize);
        newMiddle = ((self.view.bounds.size.height - newFrameSize.height) / 2) - 1;
        
        NSLog(@"shrinking because contentSize is smaller than tablSz.");
        NSLog(@"newFrameSize: (%f, %f)", newFrameSize.width, newFrameSize.height);
        NSLog(@"newMiddle: %f", newMiddle);
    }

    NSLog(@"self.view.bounds: ");
    [Util printRectangle:self.view.bounds];
    NSLog(@"self.view.frame: ");
    [Util printRectangle:self.view.frame];

    [UIView animateWithDuration:0.3
                     animations:^{
                         greyView.frame = CGRectMake(0, 0,
                                                     self.view.bounds.size.width,
                                                     self.view.bounds.size.height);

                         if (newFrameSize.width == 0)
                         {
                             NSLog(@"regular frame size.");
                             frameView.frame = CGRectMake(10, 10, frameSz.width, frameSz.height);
                         }
                         else
                         {
                             NSLog(@"irregular frame size.");
                             frameView.frame = CGRectMake(10, newMiddle, frameSz.width, newFrameSize.height);
                         }
                     }
                     completion:^(BOOL finished) {
                         NSLog(@"pivotView frame: ");
                         [Util printRectangle:frameView.frame];
                         NSLog(@"scroller frame: ");
                         [Util printRectangle:scroller.frame];
                         NSLog(@"scroller.contentSizeHeight: %f", scroller.contentSize.height);
                     }
    ];

    return;
}

/******************************************************************************
 * Gesture Handlers
 ******************************************************************************/

#pragma mark - Gesture Handlers

/* Zoom to point code taken from Apple's Developer Site by Apple. */
- (CGRect)zoomRectForScrollView:(UIScrollView *)scrollView
                      withScale:(float)scale
                     withCenter:(CGPoint)center
{
    CGRect zoomRect;

    // The zoom rect is in the content view's coordinates.
    // At a zoom scale of 1.0, it would be the size of the
    // imageScrollView's bounds.
    // As the zoom scale decreases, so more content is visible,
    // the size of the rect grows.

    zoomRect.size.height = scrollView.frame.size.height / scale;
    zoomRect.size.width  = scrollView.frame.size.width  / scale;

    // choose an origin so as to get the right center.
    zoomRect.origin.x = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0);

    return zoomRect;
}

/**
 * @brief Hide items on the screen.
 */
- (void)hideDisplayItems
{
    if (self.tilesVisible)
    {
        [self showTilesHandler:nil];
    }
    
    self.upperToolBar.hidden = YES;
    self.lowerToolBar.hidden = YES;
    self.postInfoBtn.hidden = YES;
    self.tagLbl.hidden = YES;
    self.sinceLbl.hidden = YES;
    self.userInfoBar.hidden = YES;
    
    return;
}

/**
 * @brief Display items on the screen.
 */
- (void)showDisplayItems
{
    self.upperToolBar.hidden = NO;
    self.lowerToolBar.hidden = NO;
    self.postInfoBtn.hidden = NO;
    self.tagLbl.hidden = NO;
    self.sinceLbl.hidden = NO;
    self.userInfoBar.hidden = NO;
    
    return;
}

/**
 * @brief Hide the items.
 */
- (void)stappedDisplay:(UITapGestureRecognizer *)recognizer
{
    NSLog(@"Single tap: %@.", recognizer);
    
    if (self.allHidden)
    {
        [self showDisplayItems];

        self.allHidden = NO;
    }
    else
    {
        [self hideDisplayItems];

        self.allHidden = YES;
    }
    
    return;
}

/**
 * @brief Double-tap to zoom in or zoom all the way out.
 */
- (void)dtappedDisplay:(UITapGestureRecognizer *)recognizer
{
    NSLog(@"User double-tapped: %@.", recognizer);
    
    CGPoint tapped = [recognizer locationInView:self.display];
    CGFloat zoomScale;
    
    /* XXX: should zoom jump in phases. */
    if (self.mainScroll.zoomScale == 1.0)
    {
        zoomScale = 3.0;
    }
    else
    {
        zoomScale = 1.0;
    }
    
    NSLog(@"mainScroll: %@", self.mainScroll);
    
    CGRect zoomed = [self zoomRectForScrollView:self.mainScroll
                                      withScale:zoomScale
                                     withCenter:tapped];

    [self.mainScroll zoomToRect:zoomed animated:YES];

    NSLog(@"mainScroll: %@", self.mainScroll);

    return;
}

/**
 * @brief Bring up the Log View Table.
 */
- (void)showLog
{
    LogTVC *logView = [[LogTVC alloc] initWithStyle:UITableViewStyleGrouped];

    logView.events = self.eventLog;
    logView.delegate = self;

    UINavigationController *nav = \
        [[UINavigationController alloc] initWithRootViewController:logView];

    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

    [self presentModalViewController:nav animated:YES];

    return;
}

/**
 * @brief Place all posts on a map.
 */
- (void)launchMap:(UISwipeGestureRecognizer *)recognizer
{
    if ([self.postStorage.postId count] == 0)
    {
        return;
    }
    
    PostSetMapViewController *map = \
        [[PostSetMapViewController alloc] initWithNibName:nil bundle:nil];

    Post *curr = [self.postStorage postAtIndex:self.cacheIndex];

    if (curr.validCoordinates)
    {
        map.center = curr.coordinate;
    }

    [map.postSet addObjectsFromArray:[self.postStorage.posts allValues]];

    UINavigationController *nav = \
        [[UINavigationController alloc] initWithRootViewController:map];

    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

    [self presentModalViewController:nav animated:YES];

    return;
}

/**
 * @brief Bring up the pivot history, so the user can go back, etc.
 */
- (void)showPivotHistory:(UISwipeGestureRecognizer *)recognizer
{
    UIView *view = [self.view viewWithTag:TAG_COMMENT_MAINVIEW];
    
    if (view != nil)
    {
        [self hideComments];
    }
    else
    {
        NSLog(@"self.queryCache: %@", self.queryCache);

        PivotHistoryTVC *uview = \
            [[PivotHistoryTVC alloc] initWithStyle:UITableViewStylePlain];

        uview.pivotHistory = self.queryCache;
        uview.delegate = self;

        UINavigationController *nav = \
            [[UINavigationController alloc] initWithRootViewController:uview];

        nav.modalPresentationStyle = UIModalPresentationFormSheet;
        nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

        [self presentModalViewController:nav animated:YES];
    }

    return;
}

/**
 * @brief On long press it brings up the user info bar.
 */
- (void)showUserBar:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        NSLog(@"long press detected.");

        if ([self.postStorage.postId count] == 0)
        {
            return;
        }

        if (self.userInfoBar.alpha == 1.0) /* already visible. */
        {
            return;
        }

        Post *curr = [self.postStorage postAtIndex:self.cacheIndex];
        User *user = (self.userCache)[curr.author];

        [self setUserInfoBarUser:user];
        [self displayUserInfoBar];

        [self.hideUserTimer invalidate];
        self.hideUserTimer = \
            [NSTimer scheduledTimerWithTimeInterval:5.0
                                             target:self
                                           selector:@selector(hideUserInfoBar)
                                           userInfo:nil
                                            repeats:NO];
    }

    return;
}

/**
 * @brief This is called when the user swipes horizontally.
 *
 * @param recognizer a variable that provides information about the action.
 */
- (void)handleSwipe:(UISwipeGestureRecognizer *)recognizer
{
    [self.hideUserTimer invalidate];
    self.hideUserTimer = nil;

    /* No need to fade-out. */
    self.userInfoBar.alpha = 0.0; /* not the same as hidden. */

    if (recognizer.direction == UISwipeGestureRecognizerDirectionLeft)
    {
        [self nextHandler];
    }
    else
    {
        [self prevHandler];
    }

    return;
}

/**
 * @brief If the user taps the user info bar.
 *
 * There is extra code for iOS 5.1.
 */
- (void)userInfoHandler:(UITapGestureRecognizer *)recognizer
{
    if ([self.postStorage.postId count] == 0)
    {
        return;
    }

    if (self.userInfoGrown)
    {
        /* you need this crap for iOS 5 */
        UIButton *uBtn = (UIButton *)[self.userInfoBar viewWithTag:904];
        UIButton *pBtn = (UIButton *)[self.userInfoBar viewWithTag:905];

        CGPoint tapPoint = [recognizer locationInView:recognizer.view];
        NSLog(@"tapPoint: (%f, %f)", tapPoint.x, tapPoint.y); // within self.userInfoBar

        CGRect x = [uBtn convertRect:uBtn.frame toView:self.userInfoBar];
        CGRect newSquare = CGRectMake(uBtn.frame.origin.x,
                                      x.origin.y - uBtn.frame.origin.y,
                                      uBtn.frame.size.width,
                                      uBtn.frame.size.height);
        
        if (CGRectContainsPoint(newSquare, tapPoint))
        {
            NSLog(@"tapped button.");
            [self userInfoBtnHandler];
            
            return;
        }

        x = [pBtn convertRect:pBtn.frame toView:self.userInfoBar];
        newSquare = CGRectMake(pBtn.frame.origin.x,
                               x.origin.y - pBtn.frame.origin.y,
                               pBtn.frame.size.width,
                               pBtn.frame.size.height);

        if (CGRectContainsPoint(newSquare, tapPoint))
        {
            [self postInfoBtnHandler];

            return;
        }

        /* shrink it, and hide it. */
        [self hideUserInfoBar];

        return;
    }

    [self.hideUserTimer invalidate];

    UIView *triangle = [self.userInfoBar viewWithTag:903];
    CGRect infoFrm = self.userInfoBar.frame;

    UIView *userBtn = [self.userInfoBar viewWithTag:904];

    float newHeight = userBtn.frame.origin.y + userBtn.frame.size.height + 5;

    /*
     * Needs to add a couple buttons, user info and post info, and then below
     * scrollview with some info?
     */
    [UIView animateWithDuration:0.5
                     animations:^{
                         triangle.transform = CGAffineTransformMakeRotation(DEGREES_TO_RANDIANS(-90));
                         self.userInfoBar.frame = CGRectMake(infoFrm.origin.x,
                                                             infoFrm.origin.y,
                                                             infoFrm.size.width,
                                                             newHeight);
                     }
                     completion:^(BOOL finished){
                         if (finished)
                         {
                             self.userInfoGrown = YES;
                         }
                     }];

    return;
}

@end

