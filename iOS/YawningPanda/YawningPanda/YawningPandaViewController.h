//
//  YawningPandaViewController.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 7/18/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LoginTVC.h" // for delegate
#import "LogTVC.h" // for delegate
#import "PivotTableViewController.h" // for delegate
#import "UserTableViewController.h" // for delegate
#import "FavoriteTableViewController.h" // for delegate
#import "NewPostTableViewController.h" // for delegate
#import "CommunityTVC.h" // for delegate
#import "TableOfContentsViewController.h"
#import "UICommentList.h"

#import "APIHandler.h" // for completiondelegate
#import "APIManager.h"
#import "NavigationCache.h"
#import "ImageSpinner.h"

#import "Reachability.h"

/*
 * As I add other views, this list may shrink.
 *
 * This view will probably be the image view; versus a log-in view and other
 * appropriate views.
 */

@interface YawningPandaViewController : UIViewController \
    <UITextFieldDelegate, UITextViewDelegate,
    UIGestureRecognizerDelegate, UINavigationControllerDelegate,
    UIActionSheetDelegate, UIAlertViewDelegate,
    UIScrollViewDelegate, UIViewControllerRestoration,
    CompletionDelegate,
    LoginPopupDelegate,
    LogoutPopupDelegate,
    NewPostPopupDelegate,
    PivotPopupDelegate,
    EventLogDelegate,
    JoinCommunityDelegate,
    UnfavoriteDelegate,
    ChangeStreamDelegate,
    CommentDelegate>
{
}

/**
 * @brief Are the screen elements hidden?
 */
@property bool allHidden;
/**
 * @brief This only applies to reply/repost/create; and keeps track of what you
 * selected so on return it is handled properly.
 */
@property int currAction;
/**
 * @brief Which action sheet is currently in use.
 */
@property int currSheet;
/**
 * @brief How many new posts are outstanding.
 */
@property(atomic,assign) int outstandingCreates;
/**
 * @brief Are we watching the current post's author?
 */
@property bool watchingUser;
/**
 * @brief Our index into the postCache.
 */
@property int cacheIndex;
/**
 * @brief Is the current outstanding query a refresh?
 */
@property bool refreshQuery;
/**
 * @brief Is there a query outstanding?
 */
@property bool queryOnGoing;

@property(copy) NSString *currentPost;
/**
 * @brief The user logged in.
 */
@property(copy) NSString *specifiedUser;
/**
 * @brief This is used in case a query changes the postcache while a user is
 * marking a post as favorite
 */
@property(copy) NSString *favoritePost;
/**
 * @brief Are we marking the post as favorite or unfavorite?
 */
@property int markAction;

@property(strong) NSMutableDictionary *userPrefs;

@property(strong) NavigationCache *postStorage;

@property(strong) NSMutableDictionary *userCache;
@property(strong) NSMutableArray *downloadCache;
@property(strong) NSMutableArray *eventLog;
/* This should store each query run, as a dictionary object, query and value. */
@property(strong) NSMutableArray *queryCache;
/**
 * @brief this dictionary holds the results of the table of contents view
 * queries, which includes the WatchList and Communities.
 */
@property(strong) NSMutableDictionary *queryResults;

@property(copy) NSArray *lastUsedTags;

@property(copy) UIImage *defaultImage;

@property(strong) NSUserDefaults *defaults;

enum
{
    USER_MARK_INVALID = 0,
    USER_MARK_FAVORITE,
    USER_MARK_UNFAVORITE,
};

enum
{
    USER_ACTION_INVALID = 0,
    USER_ACTION_CREATE,
    USER_ACTION_REPLY,
    USER_ACTION_REPOST,
};

enum
{
    USER_SHEET_INVALID = 0,
    USER_SHEET_CREATE,
    USER_SHEET_SAVE,
    USER_SHEET_FAVORITE,
    USER_SHEET_REFRESH_COMMENTS,
};

/* These should all appear on self.view, but some don't.  c'est la vie. */
enum
{
    TAG_THUMBNAIL_SCROLLVIEW = 0x10000,
    TAG_THUMBNAIL_TRIANGLE   = 0x10001,
    TAG_QUERY_LOADINGVIEW    = 0x10002,
    TAG_QUERY_STATUSLABEL    = 0x10003,
    TAG_QUERY_ACTIVITY       = 0x10004,
    TAG_COMMENT_MAINVIEW     = 0x10005,
    TAG_JUMPOUT_BACKVIEW     = 0x10006,
    TAG_JUMPOUT_SCROLLER     = 0x10007,
    TAG_PIVOT_BACKVIEW       = 0x10008,
    TAG_PIVOT_SCROLLER       = 0x10009,
    TAG_PIVOT_FRAMEVIEW      = 0x1000a,
};

/* information labels */
@property(nonatomic,strong) IBOutlet UILabel *tagLbl;
@property(nonatomic,strong) IBOutlet UILabel *sinceLbl;

@property(nonatomic,strong) IBOutlet UIButton *postInfoBtn;

/* image view controller */
@property(nonatomic,strong) UIScrollView *mainScroll;
@property(nonatomic,strong) ImageSpinner *display;

/* toolbars */
//@property(nonatomic,retain) IBOutlet UIToolbar *pivotToolBar;
@property(nonatomic,strong) IBOutlet UILabel *outstandingItemsLbl;

@property(nonatomic,strong) UITextField *queryTextField;
@property(nonatomic,strong) UITextField *hiddenField;

@property(strong) APIHandler *createCommentHandler;
@property(assign) bool commentOutstanding;
@property(nonatomic,strong) UIActivityIndicatorView *createCommentSpinner;
@property(nonatomic,strong) UIBarButtonItem *createCommentPostBtn;
@property(nonatomic,strong) UITextView *commentTextField;
@property(nonatomic,strong) UITextField *commentHiddenField;
@property(nonatomic,strong) UIView *commentAccessory;

/* buttons on the toolbars. */
@property(nonatomic,strong) IBOutlet UIToolbar *upperToolBar;
@property(nonatomic,strong) UIBarButtonItem *createPostToolbarBtn;
@property(nonatomic,strong) UIBarButtonItem *replyPostToolbarBtn;
@property(nonatomic,strong) UIBarButtonItem *queryToolbarBtn;
@property(nonatomic,strong) UIBarButtonItem *refreshToolbarBtn;
@property(nonatomic,strong) UIBarButtonItem *titleToolbarBtn;

@property(nonatomic,strong) IBOutlet UIToolbar *lowerToolBar;
@property(nonatomic,strong) UIBarButtonItem *meToolbarBtn;
@property(nonatomic,strong) UIBarButtonItem *commentToolbarBtn;
@property(nonatomic,strong) UIBarButtonItem *starToolbarBtn;
@property(nonatomic,strong) UIBarButtonItem *actionToolbarBtn;

@property bool tilesVisible;
@property(strong) NSMutableArray *imageViewTiles;
@property(strong) UILabel *downloadTileLbl;
@property(atomic,assign) int downloadTileCount;

@property bool userInfoGrown;
@property(nonatomic,strong) UIView *userInfoBar;

@property(nonatomic,strong) APIManager *apiManager;
@property(nonatomic,strong) NSTimer *hideUserTimer;

- (IBAction)postInfoBtnHandler;

@property(assign) NetworkStatus currNetStatus;
@property(retain) Reachability *reachNetStatus;
@property(assign) bool downloadLargeImages;

@end
