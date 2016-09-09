//
//  PostInfoTVC.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/20/12.
//
//

#import <UIKit/UIKit.h>

#import "Post.h"
#import "PostInfoBundle.h"
#import "User.h"
#import "APIHandler.h"
#import "APIManager.h"

#import "PivotTableViewController.h"
#import "CommunityTVC.h"

#define METERS_PER_MILE 1609.344

@interface PostInfoTVC : UITableViewController <\
    UIGestureRecognizerDelegate,
    UIActionSheetDelegate,
    MKMapViewDelegate,
    CompletionDelegate>

@property(assign) int selectedRow;
@property(copy) NSIndexPath *selectedPath;
@property(copy) PostInfoBundle *infoBundle;
@property(strong) APIManager *apiManager;
@property(copy) UIImage *replyToTile;
@property(copy) NSString *meIdentifier;
@property(weak) NSMutableDictionary *userCache;

/** @brief postInfo is used to store the replyto result. */
@property(copy) Post *postInfo;

@property(strong,nonatomic) MKMapView *mapView;

@property(nonatomic,unsafe_unretained) id<PivotPopupDelegate> pivotDelegate;
@property(nonatomic,unsafe_unretained) id<JoinCommunityDelegate> joinDelegate;

@end
