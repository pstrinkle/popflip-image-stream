//
//  PostsTVC.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/22/12.
//
//

#import <UIKit/UIKit.h>

#import "APIHandler.h"
#import "APIManager.h"
#import "PivotTableViewController.h"
#import "PullToRefreshView.h"

@interface PostsTVC : UITableViewController <\
    UINavigationControllerDelegate,
    UIActionSheetDelegate,
    CompletionDelegate,
    PullToRefreshViewDelegate>

@property(assign) bool readOnly; /* if this about us? */
@property(copy) NSString *userIdentifier;
@property(copy) NSString *meIdentifier;
@property(copy) NSIndexPath *selected;
@property(assign) bool receivedResults;

@property(strong) NSMutableDictionary *posts;
@property(strong) NSMutableArray *localFavorites;

@property(nonatomic,unsafe_unretained) id<PivotPopupDelegate> pivotDelegate;

@property(strong) NSMutableDictionary *favIcons;
@property(strong) APIManager *apiManager;

@property(strong) PullToRefreshView *pull;

@end
