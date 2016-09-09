//
//  NewAvatarViewController.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/11/12.
//
//

#import <UIKit/UIKit.h>
#import "APIManager.h"

@interface NewAvatarViewController : UIViewController \
    <UIImagePickerControllerDelegate,
    UINavigationControllerDelegate,
    UIActionSheetDelegate,
    UIAlertViewDelegate,
    CompletionDelegate>

@property(weak) NSMutableArray *eventLogPtr;

@property(assign) bool choseCamera;
@property(assign) int dataSize;

@property(copy) UIImage *chosenImage;
@property(copy) NSString *userIdentifier;

@property(nonatomic,strong) APIManager *apiManager;

@property(nonatomic,strong) IBOutlet UIImageView *imagePreview;
@property(nonatomic,strong) UIBarButtonItem *cameraBtn;
@property(nonatomic,strong) UIBarButtonItem *saveBtn;
@property(nonatomic,strong) UIBarButtonItem *cancelBtn;

@property(nonatomic,strong) UIActivityIndicatorView *activity;

@end
