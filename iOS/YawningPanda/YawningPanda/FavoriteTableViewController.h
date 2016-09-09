//
//  FavoriteTableViewController.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/12/12.
//
//

#import <UIKit/UIKit.h>
#import "APIHandler.h"
#import "APIManager.h"
#import "PivotTableViewController.h"
#import "PullToRefreshView.h"

@protocol UnfavoriteDelegate
- (void)handleUnfavoritedPost:(NSString *)postId;
@end

@interface FavoriteTableViewController : UITableViewController <\
    UINavigationControllerDelegate,
    UIActionSheetDelegate,
    CompletionDelegate,
    PullToRefreshViewDelegate>

/* always */
@property(assign) bool readOnly; /* if this about us? */
@property(assign) bool receivedResults;
@property(assign) bool navigationStatus; /* does it have the spinner? */
@property(weak) NSMutableArray *eventLogPtr;
@property(copy) NSString *userIdentifier;
@property(copy) NSString *meIdentifier;
@property(copy) NSIndexPath *selected;

@property(strong) NSMutableDictionary *posts;
@property(strong) NSMutableArray *localFavorites;

@property(nonatomic,unsafe_unretained) id<PivotPopupDelegate> pivotDelegate;
@property(nonatomic,unsafe_unretained) id<UnfavoriteDelegate> unfavoriteDelegate;

/* if readonly: */
@property(strong) NSMutableDictionary *favIcons;
@property(strong) APIManager *apiManager;
/* else: */
@property(assign) bool busyWaiting;

@property(strong) PullToRefreshView *pull;

@end
