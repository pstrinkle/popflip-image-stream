//
//  NewPostTableViewController.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/16/12.
//
//

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <UIKit/UIKit.h>

@protocol NewPostPopupDelegate
/**
 *
 */
- (void)handlePostDetailed:(NSString *)user withTags:(NSArray *)tags withData:(NSData *)data atLocation:(NSArray *)point forPost:(NSString *)post;
@end

@interface NewPostTableViewController : UITableViewController <\
    UIImagePickerControllerDelegate,
    CLLocationManagerDelegate,
    UIActionSheetDelegate,
    UIPickerViewDataSource,
    UIPickerViewDelegate,
    UITextFieldDelegate,
    UIActionSheetDelegate,
    UINavigationControllerDelegate,
    MKMapViewDelegate>

@property(assign) bool replyTo;
@property(assign) bool repostOf;
@property(copy) NSString *repostReply;

@property(assign) bool locationFound;
@property(assign) bool locationHidden;
@property(assign) CLLocationCoordinate2D coordinate;
@property(strong) CLLocationManager *locationManager;

@property(assign) bool choseCamera;
@property(assign) int chosenCommunity;

@property(assign) UIActionSheet *currentSheet;

@property(copy) NSString *specifiedUser;
@property(copy) NSArray *originalTags;
@property(strong) NSMutableArray *tags;

@property(copy) UIImage *chosenImage;
@property(copy) UIImage *previewImage;

@property(strong) NSMutableArray *communities;
@property(strong) MKMapView *mapPreview;
@property(strong) UIImageView *imgPreview;

/* textField array. */
@property(strong) NSMutableArray *textFields;
@property(strong) NSMutableDictionary *headerViews;
@property(assign) UITextField *currentField;
@property(assign) CGSize keyboardSize;

@property(nonatomic,unsafe_unretained) id<NewPostPopupDelegate> delegate;

@end
