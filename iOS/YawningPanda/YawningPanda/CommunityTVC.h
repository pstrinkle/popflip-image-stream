//
//  CommunityTVC.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/20/12.
//
//

#import <UIKit/UIKit.h>
#import "APIHandler.h"
#import "APIManager.h"

#import "PivotTableViewController.h"
#import "PullToRefreshView.h"

@protocol JoinCommunityDelegate
- (void)handleNewCommunity:(NSString *)community;
@end

@interface CommunityTVC : UITableViewController \
    <UITextFieldDelegate, CompletionDelegate, PullToRefreshViewDelegate>

/*
 * weak properties are automatically set to nil when the thing to which they
 * refer to is freed.  whereas assign can lead to dangling pointers.  weak is more
 * how things should be done with iOS 5.0+, but iOS 4 doesn't support this.  weak
 * is a lot safer to use than assign.
 *
 * strong properties grab ahold of the thing
 * copy literally copies the object
 *
 * unsafe_unretained is analagous to assign.
 */
// The following declaration is similar to "@property(assign) MyClass *myObject;"
// except that if the MyClass instance is deallocated,
// the property value is set to nil instead of remaining as a dangling pointer.
// @property(weak) MyClass *myObject;

@property(weak) NSMutableArray *eventLogPtr;
/* this points to our communities stored in userPrefs, because this cannot be dropped in the background */
@property(weak) NSMutableArray *communities;

/** @brief Me. */
@property(copy) NSString *userIdentifier;
/** @brief The User whose communities we're querying. */
@property(copy) NSString *theUser;
@property(strong) NSMutableArray *localCommunities;
@property(strong) APIManager *apiManager;

@property(assign) bool readOnly;
@property(assign) bool receivedResults;
@property(assign) int busyWaiting;
@property(assign) bool addEntrySelected;

@property(strong) APIHandler *joiningCall;

@property(nonatomic,strong) UIActivityIndicatorView *activity;

@property(nonatomic,unsafe_unretained) id<PivotPopupDelegate> delegate;

@property(strong) PullToRefreshView *pull;

@end
