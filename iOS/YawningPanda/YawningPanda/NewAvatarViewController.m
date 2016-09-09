//
//  NewAvatarViewController.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/11/12.
//
//

#import "NewAvatarViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>

#import "EventLogEntry.h"

@implementation NewAvatarViewController

@synthesize imagePreview;
@synthesize activity;
@synthesize choseCamera;
@synthesize chosenImage;
@synthesize apiManager;
@synthesize userIdentifier;
@synthesize eventLogPtr;
@synthesize dataSize;

@synthesize cameraBtn, cancelBtn, saveBtn;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    self.cancelBtn = \
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                      target:self
                                                      action:@selector(dismiss)];

    self.activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.activity.hidesWhenStopped = YES;

    UIBarButtonItem *spinner = [[UIBarButtonItem alloc] initWithCustomView:self.activity];

    self.navigationItem.leftBarButtonItems = @[self.cancelBtn, spinner];
    
    self.cameraBtn = \
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                      target:self
                                                      action:@selector(chooseImage:)];

    self.saveBtn = \
        [[UIBarButtonItem alloc] initWithTitle:@"Save"
                                         style:UIBarButtonItemStyleBordered
                                        target:self
                                        action:@selector(updateValue)];

    self.navigationItem.rightBarButtonItems = @[self.saveBtn, self.cameraBtn];

    self.imagePreview.backgroundColor = [UIColor blackColor];
    self.imagePreview.contentMode = UIViewContentModeScaleAspectFit;

    /* I use the API Manager so I can readily track and cancel. */
    self.apiManager = [[APIManager alloc] initWithDelegate:self];

    self.choseCamera = NO;
    [self chooseImage:nil];

    return;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)alertBadness
{
    UIAlertView *alert = \
        [[UIAlertView alloc] initWithTitle:@"Update failed"
                                   message:@": ("
                                  delegate:nil
                         cancelButtonTitle:@"OK"
                         otherButtonTitles:nil];

    [alert show];

    return;
}

/******************************************************************************
 * API Delegate Code
 ******************************************************************************/

- (void)apihandler:(APIHandler *)apihandler didFail:(enum APICall)type
{
    [self.apiManager dropHandler:apihandler];

    [self.activity stopAnimating];
    self.cameraBtn.enabled = YES;
    self.saveBtn.enabled = YES;

    [self alertBadness];
}

- (void)apihandler:(APIHandler *)apihandler didCompleteUpdate:(bool)success asUser:(NSString *)theUser
{
    [self.apiManager dropHandler:apihandler];
    
    [self.activity stopAnimating];
    self.cameraBtn.enabled = YES;
    self.saveBtn.enabled = YES;

    if (success)
    {
        EventLogEntry *eventEntry = [[EventLogEntry alloc] init];
        eventEntry.note = @"update user field";
        eventEntry.eventType = EVENT_TYPE_UPDATE;
        eventEntry.details = @{@"field" : @"avatar",
        @"value" : [NSString stringWithFormat:@"data size: %d", self.dataSize],
        @"user" : self.userIdentifier,
        @"success" : [NSString stringWithFormat:@"%d", success]};
        
        [self.eventLogPtr insertObject:eventEntry atIndex:0];

        [self dismiss];
    }
    else
    {
        [self alertBadness];
    }

    return;
}

/******************************************************************************
 * Image Selector Code
 ******************************************************************************/

- (void)image:(UIImage *)image finishedSavingWithError:(NSError *)error
  contextInfo:(void *)contextInfo
{
    if (error)
    {
        UIAlertView *alert = \
            [[UIAlertView alloc] initWithTitle:@"Save failed"
                                       message:@"Failed to save image/video"
                                      delegate:nil
                             cancelButtonTitle:@"OK"
                             otherButtonTitles:nil];

        [alert show];
    }
    
    return;
}

/**
 * @brief A delegate function that is called when the user cancels from the
 * UIImagePickerController modal view.
 *
 * @param pickerVar a variable with loads of information.
 */
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)pickerVar
{
    [pickerVar dismissModalViewControllerAnimated:YES];
    
    NSLog(@"You canceled from image picker.");
    
    return;
}

/**
 * @brief A delegate function that is called when the user selects something
 * from the UIImagePickerController modal view.
 *
 * @param pickerVar a variable with loads of information.
 * @param info a variable with information about what was chosen.
 *
 * @todo Set it up so they edit it and have a crop ability.
 */
- (void)imagePickerController:(UIImagePickerController *)pickerVar didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	[pickerVar dismissModalViewControllerAnimated:YES];

    // need to make sure it's an image and not a video; for the time being.
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    
    if (![mediaType isEqualToString:(NSString *)kUTTypeImage])
    {
        NSLog(@"mediaType: not Image: %@", mediaType);
        // alert("Currently Only Supports Images");
        
        UIAlertView *alert = \
            [[UIAlertView alloc] initWithTitle:@"Error"
                                       message:@"Currently Only Supports Images"
                                      delegate:nil
                             cancelButtonTitle:@"OK"
                             otherButtonTitles:nil];

        [alert show];

        return;
    }
    
    // do I want to retain it?
    UIImage *image = info[@"UIImagePickerControllerOriginalImage"];
    
    if (self.choseCamera)
    {
        UIImageWriteToSavedPhotosAlbum(image,
                                       self,
                                       @selector(image:finishedSavingWithError:contextInfo:),
                                       nil);
    }
    
    NSLog(@"Image pulled.");

    CGSize x = [image size];
    NSLog(@"x.height: %f, y.width: %f", x.height, x.width);

    // x.height: 2448.000000, y.width: 3264.000000 on my iphone 4S

    CGSize uploadSize = CGSizeMake(x.width / 4, x.height / 4);

    UIGraphicsBeginImageContext(uploadSize);
    [image drawInRect:CGRectMake(0, 0, uploadSize.width, uploadSize.height)];
    UIImage *uploadImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    self.imagePreview.image = uploadImage;
    [self.imagePreview setNeedsDisplay];
    
    self.chosenImage = uploadImage;
    self.navigationItem.rightBarButtonItem.enabled = YES;
    
    /* Is this safe to release? */
    return;
}

/**
 * @brief A delegate function for the action sheet that is called when a user
 * clicks a button.
 *
 * @param actionSheet a variable with actionsheet information.
 * @param buttonIndex which button the user selected.
 */
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"%@", [NSString stringWithFormat:@"You selected: '%@'",
                  [actionSheet buttonTitleAtIndex:buttonIndex]]);
    
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle isEqualToString:@"Cancel"])
    {
        return;
    }
    
    // We know they selected something that wasn't cancel.
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.mediaTypes = @[(NSString *)kUTTypeImage];
    
    if ([buttonTitle isEqualToString:@"Photo Album"])
    {
        NSLog(@"Photo Album Selected.");
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    else if ([buttonTitle isEqualToString:@"Camera"])
    {
        NSLog(@"Camera Selected.");
        
        self.choseCamera = YES;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    }
    
    [self presentModalViewController:picker
                            animated:YES];

    return;
}

/******************************************************************************
 * Button Handlers
 ******************************************************************************/

- (IBAction)dismiss
{
    NSLog(@"Dismissing.");

    [self.apiManager cancelAll];
    [self.navigationController popViewControllerAnimated:YES];

    return;
}

- (IBAction)updateValue
{
    if (self.chosenImage == nil)
    {
        return;
    }
    
    self.cameraBtn.enabled = NO;
    self.saveBtn.enabled = NO;
    
    [self.activity startAnimating];
    
    NSData *dataObj = UIImageJPEGRepresentation(self.chosenImage, 1.0);
    
    self.dataSize = [dataObj length];

    NSLog(@"user avatar update size: %d", self.dataSize);

    [self.apiManager userUpdate:self.userIdentifier
                       withData:dataObj];

    return;
}

/**
 * @brief This button handler is called when they click a button to create a new
 *  post, either as a completely new post or a reply.
 *
 * @param sender the button's identifier.
 */
- (IBAction)chooseImage:(id)sender
{
    NSLog(@"Create/Preview Button Handler Called.");
    
    UIActionSheet *sheet = nil;

    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        sheet = [[UIActionSheet alloc] initWithTitle:@"Choose Source:"
                                            delegate:self
                                   cancelButtonTitle:@"Cancel"
                              destructiveButtonTitle:nil
                                   otherButtonTitles:@"Photo Album", @"Camera", nil];
    }
    else
    {
        sheet = [[UIActionSheet alloc] initWithTitle:@"Choose Source:"
                                            delegate:self
                                   cancelButtonTitle:@"Cancel"
                              destructiveButtonTitle:nil
                                   otherButtonTitles:@"Photo Album", nil];
    }
    
    [sheet showInView:self.view];
    
    NSLog(@"chooseImage returns.");
    
    return;
}

@end
