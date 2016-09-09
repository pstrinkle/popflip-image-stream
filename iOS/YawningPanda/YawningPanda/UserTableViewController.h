//
//  UserTableViewController.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 8/9/12.
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#import "User.h"
#import "WatchList.h"
#import "APIHandler.h"
#import "APIManager.h"

#import "FavoriteTableViewController.h"
#import "PivotTableViewController.h"

#define METERS_PER_MILE 1609.344

@protocol LogoutPopupDelegate
- (void)handleLogoutSelected;
@end

enum UserMembers
{
    USER_MEMBER_LOGOUT = 0,
    USER_MEMBER_AVATAR,
    USER_MEMBER_ID,
    USER_MEMBER_BIO,
    USER_MEMBER_CREATED,
    USER_MEMBER_REALISHNAME,
    USER_MEMBER_EMAIL,
    USER_MEMBER_HOMEURL,
    USER_MEMBER_LOCATION,
    USER_MEMBER_GROUPS,
};

enum UserSubGroups
{
    USER_MEMBER_BADGES = 0,
    USER_MEMBER_WATCHLIST,
    USER_MEMBER_FAVORITES,
    USER_MEMBER_POSTS,
    USER_MEMBER_COMMUNITIES,
};

@interface UserTableViewController : UITableViewController <\
    UITextFieldDelegate,
    UIGestureRecognizerDelegate,
    CLLocationManagerDelegate,
    CompletionDelegate>

@property(assign) bool readOnly; /* if this about us? */
@property(assign) bool fromPost;
@property(assign) bool editPushed; /* if they clicked to edit. */
@property(assign) bool subViewPushed;
@property(assign) bool avatarSelected;
@property(assign) bool busyWaiting;

@property(assign) bool locationFound;
@property(assign) CLLocationCoordinate2D coordinate;
@property(strong) CLLocationManager *locationManager;

/** @brief This is a pointer to the event log. */
@property(weak) NSMutableArray *eventLogPtr;
/** @brief This is a pointer to the watchlist information stored in userPrefs. */
@property(weak) WatchList *watching;
/** @brief This is a pointer to the community information stored in userPrefs. */
@property(weak) NSMutableArray *communities; /* if launched from post click this is nil */
@property(weak) NSMutableArray *favorites; /* if launched from post click this is nil. */

@property(strong) NSMutableDictionary *headerViews;

/** @brief The user cache! */
@property(weak) NSMutableDictionary *userCache;

/** @brief This is a pointer to the user information in the userCache. */
@property(weak) User *userPtr;

/** @brief Just an identifier of the user that is logged in. */
@property(copy) NSString *meIdentifier;

@property(nonatomic,strong) UITextField *hiddenField;
@property(nonatomic,strong) UITextField *updateTextField;
@property(nonatomic,strong) UIActivityIndicatorView *activity;
@property(nonatomic,strong) UIBarButtonItem *saveBtn;
@property(nonatomic,strong) NSMutableArray *textFields;
@property(nonatomic,strong) MKMapView *mapPreview;
@property(nonatomic,strong) UIImageView *avatarView;
@property(assign) int savingSection;
@property(copy) NSString *savingText;

@property(strong) APIManager *apiManager;

@property(nonatomic,unsafe_unretained) id<PivotPopupDelegate> pivotDelegate;
@property(nonatomic,unsafe_unretained) id<LogoutPopupDelegate> logoutDelegate;
@property(nonatomic,unsafe_unretained) id<UnfavoriteDelegate> unfavoriteDelegate;

@end
