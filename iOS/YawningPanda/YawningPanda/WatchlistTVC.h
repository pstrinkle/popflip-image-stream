//
//  WatchlistTVC.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/20/12.
//
//

#import <UIKit/UIKit.h>

#import "PivotTableViewController.h"
#import "APIHandler.h"
#import "WatchList.h"
#import "APIManager.h"
#import "PullToRefreshView.h"

@interface WatchlistTVC : UITableViewController <CompletionDelegate, PullToRefreshViewDelegate>

@property(weak) NSMutableArray *eventLogPtr;
/*
 * This points to our watchlist stored in userPrefs, because this cannot be
 * dropped in the background.
 *
 * XXX: Except when it's readOnly and about a user... Then the user could go
 * away... albeit, at present the User's are only dropped entirely on memory
 * errors.  In the future, the user information will only be downloaded if they
 * specifically request it.
 */
@property(weak) NSMutableArray *watchlist;
@property(weak) WatchList *watchlistProper;
@property(copy) NSString *userIdentifier;
@property(copy) NSString *meIdentifier;
@property(weak) NSMutableDictionary *userCache;

@property(assign) bool readOnly; /* if this about us? */
@property(assign) bool busyWaiting;
@property(atomic,assign) int outStanding;

/* Only use the APIManager for downloading the icons. */
@property(strong) APIManager *apiManager;

/* XXX: These are part of a proper Watchlist. */
@property(strong) NSMutableDictionary *userIcons;
@property(strong) NSMutableDictionary *userNames;

@property(nonatomic,unsafe_unretained) id<PivotPopupDelegate> delegate;

@property(strong) PullToRefreshView *pull;

@end
