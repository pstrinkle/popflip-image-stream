//
//  TableOfContentsViewController.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 12/30/12.
//
//

#import <UIKit/UIKit.h>

#import "APIManager.h"

#import "WatchList.h"

#import "PullToRefreshView.h"

@protocol ChangeStreamDelegate
- (void)handleQueryResults:(NSMutableArray *)data;
@end

@interface TableOfContentsViewController : UITableViewController \
    <UIGestureRecognizerDelegate,
     CompletionDelegate,
     PullToRefreshViewDelegate>

/** @brief This is a pointer to the watchlist information stored in userPrefs. */
@property(weak) WatchList *watching;
/** @brief This is a pointer to the community information stored in userPrefs. */
@property(weak) NSMutableArray *communities;
/** @brief Updating this here will allow you to hit refresh properly. */
@property(weak) NSMutableArray *queryCache;
/** @brief Outstanding API Calls... */
@property(atomic, assign) NSInteger outstanding;

/**
 * @brief This is passed to us from the application.  It is this guy's job to
 * update it.
 *
 * {
 *      "watchlist" :
 *                   [ { "identifier" : value, "results" : [posts], "thumbnail" : image },
 *                   ],
 *      "communities" :
 *                     [ { "identifier" : value, "results" : [posts], "thumbnail" : image },
 *                     ]
 *  }
 */
@property(weak) NSMutableDictionary *queryResults;

@property(strong) NSMutableArray *headers;

@property(strong) APIManager *apiManager;
@property(copy) NSString *userIdentifier;
@property(assign) int currentTag;

@property(nonatomic,unsafe_unretained) id<ChangeStreamDelegate> delegate;

@property(strong) PullToRefreshView *pull;

@end
