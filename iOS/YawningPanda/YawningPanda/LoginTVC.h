//
//  LoginTVCViewController.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/30/12.
//
//

#import <UIKit/UIKit.h>

#import "APIHandler.h"
#import "APIManager.h"

@protocol LoginPopupDelegate
- (void)handleLoginEntered:(NSString *)userName withPrefs:(NSDictionary *)prefs;
@end

@interface LoginTVC : UITableViewController <UITextFieldDelegate, CompletionDelegate>

@property(strong) NSMutableArray *textFields;
@property(strong) NSMutableDictionary *headerViews;
@property(assign) UITextField *currentField;
@property(assign) CGSize keyboardSize;
@property(nonatomic,strong) UIActivityIndicatorView *activity;
@property(nonatomic,strong) UIButton *loginBtn;

@property(strong) NSMutableDictionary *userData;
@property(nonatomic,strong) APIManager *apiManager;
@property(copy) NSString *startingName;
@property(assign) int queriesFinished;
@property(nonatomic,strong) NSString *cachedId; /* why is this set like this? */

@property(nonatomic,unsafe_unretained) id<LoginPopupDelegate> delegate;

@end
