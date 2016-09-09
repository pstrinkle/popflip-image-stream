//
//  NewPostTableViewController.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/16/12.
//
//

#import "NewPostTableViewController.h"
#import "Util.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <ImageIO/ImageIO.h>
#import <ImageIO/CGImageSource.h>
#import <AssetsLibrary/AssetsLibrary.h>

enum PostSections
{
    SECTION_PREVIEW = 0,
    SECTION_COMMUNITY_SELECTOR,
    SECTION_TAGS,
    SECTION_LOCATION,
    SECTION_REPLYREPOST,
};

#define METERS_PER_MILE 1609.344
#define IMAGE_PREVIEW_HEIGHT 184

@implementation NewPostTableViewController

@synthesize replyTo, repostOf;

@synthesize locationFound, locationHidden, coordinate, locationManager;

@synthesize choseCamera;
@synthesize chosenCommunity;

@synthesize currentSheet;

@synthesize specifiedUser;
@synthesize tags, originalTags;

@synthesize chosenImage, previewImage;

@synthesize communities;

@synthesize textFields;

@synthesize repostReply;

@synthesize delegate;

@synthesize mapPreview, imgPreview;

@synthesize headerViews;
@synthesize currentField;
@synthesize keyboardSize;

/******************************************************************************
 * Utility Code
 ******************************************************************************/

#pragma mark - Utility Code

/**
 * @brief Update the Map View.
 */
- (void)updateMapView
{
    /*
     * LOAD THE MAPVIEW.
     */
    /* these should be the coordinates within the parent view. */
    MKMapView *tmp = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, 280, 90)];
    
    CLLocationCoordinate2D center;
    
    center.latitude = coordinate.latitude;
    center.longitude = coordinate.longitude;
    
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(center, 0.25*METERS_PER_MILE, 0.25*METERS_PER_MILE);
    MKCoordinateRegion adjustedRegion = [tmp regionThatFits:viewRegion];
    
    NSLog(@"adjustedRegion center: %f, %f",
          adjustedRegion.center.latitude, adjustedRegion.center.longitude);
    NSLog(@"adjustedRegion span:   %f, %f",
          adjustedRegion.span.latitudeDelta, adjustedRegion.span.longitudeDelta);
    
    [tmp setRegion:adjustedRegion];
    tmp.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    tmp.scrollEnabled = NO;
    tmp.zoomEnabled = NO;
    
    tmp.clipsToBounds = YES;
    
    self.mapPreview = tmp;
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SECTION_LOCATION]
                  withRowAnimation:UITableViewRowAnimationAutomatic];
}

/******************************************************************************
 * Keyboard Event Delegate Code
 ******************************************************************************/

#pragma mark - Keyboard Event Delegate Code

/**
 * @brief Stop asking for stuff... I'm not sure this is required.
 */
- (void)unregisterForKeyboardNotifications
{
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}


// Call this method somewhere in your view controller setup code.
/* code from apple. */
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    return;
}

- (void)slideIntoView
{
    CGFloat keyHeight;
    if (self.interfaceOrientation == UIInterfaceOrientationPortrait)
    {
        keyHeight = self.keyboardSize.height;
    }
    else
    {
        keyHeight = self.keyboardSize.width;
    }
    //UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyHeight, 0.0);
    //self.tableView.contentInset = contentInsets;
    //self.tableView.scrollIndicatorInsets = contentInsets;

    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your application might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= keyHeight;

    UIView *activeField = self.currentField.superview.superview;

    if (activeField == nil)
    {
        NSLog(@"active field was nil...");
        return;
    }

    if (!CGRectContainsPoint(aRect, activeField.frame.origin))
    {
        float absHeight = self.view.bounds.size.height - keyHeight;

        CGPoint scrollPoint = CGPointMake(0, activeField.frame.origin.y - (absHeight - self.tableView.rowHeight));

        [self.tableView setContentOffset:scrollPoint animated:YES];
    }
}

// Called when the UIKeyboardDidShowNotification is sent.
/* code from apple. */
- (void)keyboardWasShown:(NSNotification *)aNotification
{
    NSLog(@"keyboardWasShown");

    NSDictionary *info = [aNotification userInfo];
    CGSize kbSize = [info[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    self.keyboardSize = kbSize;

    [self slideIntoView];

    return;
}

// Called when the UIKeyboardWillHideNotification is sent
/* code from apple. */
- (void)keyboardWillBeHidden:(NSNotification *)aNotification
{
    NSLog(@"keyboardWillBeHidden");

    //UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    //self.tableView.contentInset = contentInsets;
    //self.tableView.scrollIndicatorInsets = contentInsets;

    return;
}

/******************************************************************************
 * TextField Delegate Code
 ******************************************************************************/

#pragma mark - TextField Delegate Code

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    self.currentField = textField;
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSLog(@"textField: %@, tag: %d", textField, textField.tag);
    self.currentField = textField;

    if (textField.tag == 900) // index:0
    {
        UITextField *field = (self.textFields)[1];
        NSLog(@"new field: %@", field);

//        [field becomeFirstResponder];
  //      NSLog(@"is firstresponder? %d", [field isFirstResponder]);
  //      NSLog(@"can become responder? %d", [field canBecomeFirstResponder]);

        [field performSelector:@selector(becomeFirstResponder)
                    withObject:nil
                    afterDelay:0.0];
        [self performSelector:@selector(slideIntoView)
                   withObject:nil
                   afterDelay:0.1];
    }
    else if (textField.tag == 901) // index: 1
    {
        UITextField *field = (self.textFields)[2];
        NSLog(@"new field: %@", field);

        BOOL x = [field becomeFirstResponder];
        NSLog(@"becomeFirstResponder: %@", (x) ? @"yes" : @"no");

        [self slideIntoView];
    }
    else // index: 2
    {
        [textField resignFirstResponder];
    }

    return NO;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    NSLog(@"Typed: %@ for tag: %d", textField.text, textField.tag);

    [self.tags setObject:textField.text
      atIndexedSubscript:(textField.tag - 900)];

    return YES;
}

/******************************************************************************
 * Community Selector Code
 ******************************************************************************/

#pragma mark - Community Selector Code

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)thePickerView numberOfRowsInComponent:(NSInteger)component
{
    NSLog(@"pickerView:numberOfRowsInComponent: %d", [self.communities count]);
    return [self.communities count];
}

- (NSString *)pickerView:(UIPickerView *)thePickerView titleForRow:(NSInteger)row
            forComponent:(NSInteger)component
{
    NSLog(@"pickerView:titleForRow: %@", (self.communities)[row]);
    return (self.communities)[row];
}

- (void)pickerView:(UIPickerView *)thePickerView didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component
{
    NSLog(@"Selected Community: %@. Index of selected community: %i", (self.communities)[row], row);
    
    self.chosenCommunity = row;
}

- (void)dismissActionSheet:(UISegmentedControl *)actionSheetBtn
{
    [self.currentSheet dismissWithClickedButtonIndex:0 animated:YES];
    self.currentSheet = nil;
    
    NSLog(@"dismissing action sheet.");
    
    /* or the None community */
    if (self.chosenCommunity != 0)
    {
        NSArray *selectedComm = \
            [(self.communities)[self.chosenCommunity]
                componentsSeparatedByString:@","];

        NSString *val1 = [selectedComm[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        UITextField *field1 = (UITextField *)(self.textFields)[0];
        field1.text = val1;
        [self.tags setObject:val1 atIndexedSubscript:0];

        NSString *val2 = [selectedComm[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        UITextField *field2 = (UITextField *)(self.textFields)[1];
        field2.text = val2;
        [self.tags setObject:val2 atIndexedSubscript:1];

        NSLog(@"self.tags: %@", self.tags);

        [self.tableView reloadData];

        /* 
         * Bullshit, but if you dont' reload the whole damn thing it has some
         * weird fucking shit where cells go crazy.
         */
    }
    
    return;
}

/******************************************************************************
 * Button Handlers
 ******************************************************************************/

#pragma mark - Button Handlers

/**
 * @brief Create Post button handler.
 */
- (void)createAction
{
    NSLog(@"Create Action Called.");
    
    if (self.chosenImage == nil)
    {
        NSLog(@"imagepreview was nil.");
        
        /* Maybe we should fire an alert asking for them to select an image. */
        return;
    }
    
    /* Update our view of the tags. */
    NSMutableArray *typedTags = \
        [[NSMutableArray alloc] initWithCapacity:3];
    
    NSLog(@"self.textFields: %@", self.textFields);

    for (UITextField *field in self.textFields)
    {
        if (![field.text isEqualToString:@""])
        {
            NSString *tag = [[field.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
            [typedTags addObject:[tag stringByReplacingOccurrencesOfString:@" " withString:@""]];
        }
    }
    
    if ([typedTags count] == 0)
    {
        NSLog(@"typed tags were all empty.");
        return;
    }

    if (self.originalTags != nil)
    {
        NSLog(@"Repost array comparison");
        
        // must be a re-post
        if ([self.originalTags isEqualToArray:typedTags])
        {
            UIAlertView *alert = \
                [[UIAlertView alloc] initWithTitle:@"Error"
                                           message:@"A Re-Post Requires Different Tags"
                                          delegate:nil
                                 cancelButtonTitle:@"OK"
                                 otherButtonTitles:nil];
            [alert show];
            return;
        }
    }
    
    NSData *dataObj = UIImageJPEGRepresentation(self.chosenImage, 1.0);

    NSLog(@"Tags: %@", typedTags);
    NSLog(@"Data Size: %d", [dataObj length]);

    NSArray *loc = nil;

    if (self.locationFound && self.locationHidden == NO)
    {
        loc = \
        @[[NSNumber numberWithFloat:self.coordinate.latitude],
          [NSNumber numberWithFloat:self.coordinate.longitude]];
    }

    [delegate handlePostDetailed:self.specifiedUser
                        withTags:typedTags
                        withData:dataObj
                      atLocation:loc
                         forPost:self.repostReply];
    
    [self dismiss];
    
    return;
}

- (IBAction)dismiss
{
    NSLog(@"Dismissing.");
    
    [self dismissModalViewControllerAnimated:YES];
    
    self.originalTags = nil;
    self.tags = nil;
    self.communities = nil;
    self.specifiedUser = nil;
    self.chosenImage = nil; // just added this in case it no longer works. :P
    self.locationManager = nil;
    self.headerViews = nil;
}

/******************************************************************************
 * Image Selector Code
 ******************************************************************************/

#pragma mark - Image Selector Code

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
 */
- (void)imagePickerController:(UIImagePickerController *)pickerVar didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	[pickerVar dismissModalViewControllerAnimated:YES];
    
    NSLog(@"author: %@", self.specifiedUser);
    NSLog(@"tags  : %@", self.tags);
    NSLog(@"info  : %@", info);
    
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
#if 0
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(video))
        {
            UISaveVideoAtPathToSavedPhotosAlbum(video,
                                                self,
                                                @selector(video:finishedSavingWithError:contextInfo:),
                                                nil);
        }
#endif
        
    }

    // do I want to retain it?
    UIImage *image = info[@"UIImagePickerControllerOriginalImage"];

    /* Can do this by checking if the key I need exists. */
    if (self.choseCamera)
    {
        UIImageWriteToSavedPhotosAlbum(image,
                                       self,
                                       @selector(image:finishedSavingWithError:contextInfo:),
                                       nil);
        
        /**
         * @todo, we need to have it save the gps info to the phone; if they
         * allow that sort of behavior.
         */
    }
    else
    {
        /**
         * @note I wonder if this will break if they pick a photo twice in a 
         * row?
         */
        NSURL *assetURL = info[UIImagePickerControllerReferenceURL];
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        
        [library assetForURL:assetURL
                 resultBlock:^(ALAsset *asset) {
                     [locationManager stopUpdatingLocation];

                     NSDictionary *metadata = asset.defaultRepresentation.metadata;
                     NSMutableDictionary *imageMetadata = [[NSMutableDictionary alloc] initWithDictionary:metadata];

                     /**
                      * @todo What about when it comes back without coordinates?
                      * Or if we don't have permission.
                      */
                     
                     NSNumber *lat = (NSNumber *)imageMetadata[@"{GPS}"][@"Latitude"];
                     CGFloat latV = lat.floatValue;
                     NSNumber *longt = (NSNumber *)imageMetadata[@"{GPS}"][@"Longitude"];
                     CGFloat longV = longt.floatValue;

                     NSString *latDir = (NSString *)imageMetadata[@"{GPS}"][@"LatitudeRef"];
                     NSString *longDir = (NSString *)imageMetadata[@"{GPS}"][@"LongitudeRef"];
                     
                     /* Our system stores this in NxE */
                     if ([latDir isEqualToString:@"S"])
                     {
                         latV = 0.0 - latV;
                     }
                     
                     if ([longDir isEqualToString:@"W"])
                     {
                         longV = 0.0 - longV;
                     }

                     NSLog(@"from asset: ");
                     NSLog(@"%@", imageMetadata[@"{GPS}"]);
                     NSLog(@"latitude: %f", latV);
                     NSLog(@"longitude: %f", longV);

                     self.locationFound = YES;
                     coordinate.latitude = latV;
                     coordinate.longitude = longV;
                     
                     [self updateMapView];
                 }
                failureBlock:^(NSError *error) {
                    NSLog(@"Failed to get location from photo album.");
                }];
    }

    NSLog(@"Image pulled.");
    bool horizontal = NO;
    
    CGSize x = [image size];
    NSLog(@"x.height: %f, y.width: %f", x.height, x.width);
    
    // x.height: 2448.000000, y.width: 3264.000000 on my iphone 4S
    
    if (x.width > x.height)
    {
        horizontal = YES;
        NSLog(@"Horizontal everything.");
    }
    else
    {
        NSLog(@"Vertical everything.");
    }
    
    /*
     * XXX: Upload size is still larger than where it lands, but this is
     * assuming the user is non-HD.
     */
    CGSize uploadSize;
    
    uploadSize = CGSizeMake(x.width / 2, x.height / 2);

    CGSize previewSize;
    
    if (horizontal)
    {
        NSLog(@"horizontal sizes.");
        /* width, height */
        previewSize = CGSizeMake(480, 320);
        
    }
    else
    {
        NSLog(@"verical sizes.");
        /* width, height */
        previewSize = CGSizeMake(320, 480);
        //        uploadSize = CGSizeMake(x.height / 2, x.width / 2);
    }

    UIGraphicsBeginImageContext(previewSize);
    /* x, y, width, height */
    [image drawInRect:CGRectMake(0, 0, previewSize.width, previewSize.height)];
    // You should call this function from the main thread of your application only.
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    self.previewImage = newImage;

    /* This gives us the row. */
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SECTION_PREVIEW]
                  withRowAnimation:UITableViewRowAnimationAutomatic];

    UIGraphicsBeginImageContext(uploadSize);
    [image drawInRect:CGRectMake(0, 0, uploadSize.width, uploadSize.height)];
    UIImage *uploadImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    self.chosenImage = uploadImage;
    [self.navigationItem.rightBarButtonItem setEnabled:YES];

    /* Is this safe to release? */
    return;
}

/******************************************************************************
 * Delegates (non-image or action sheet)
 ******************************************************************************/

#pragma mark - Delegates (non-image or action sheet)

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"%@", [NSString stringWithFormat:@"You selected: '%@'",
                  [alertView buttonTitleAtIndex:buttonIndex]]);
    
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
    picker.mediaTypes = @[(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie];

    if ([buttonTitle isEqualToString:@"Photo Album"])
    {
        NSLog(@"Photo Album Selected.");
        
        self.choseCamera = NO;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    else if ([buttonTitle isEqualToString:@"Camera"])
    {
        NSLog(@"Camera Selected.");
        
        self.choseCamera = YES;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    }
    
    [self presentModalViewController:picker animated:YES];

    return;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    [locationManager stopUpdatingLocation];
    // If it's a relatively recent event, turn off updates to save power
    //NSDate *eventDate = newLocation.timestamp;
    //NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    
    NSLog(@"Setting from locationManager: ");
    NSLog(@"latitude %+.6f, longitude %+.6f\n",
          newLocation.coordinate.latitude,
          newLocation.coordinate.longitude);
    
    /** @warning This seems to come in as degrees North by East. */
    self.coordinate = newLocation.coordinate;
    self.locationFound = YES;

    [self updateMapView];

    // else skip the event and process the next one.
    return;
}

/**
 * @brief This is called for each annotation, similarly to the cell is a
 * UITableView.
 */
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    static NSString *identifier = @"Location";
    
    MKPinAnnotationView *annotationView = \
        (MKPinAnnotationView *)[self.mapPreview dequeueReusableAnnotationViewWithIdentifier:identifier];

    if (annotationView == nil)
    {
        annotationView = \
            [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                            reuseIdentifier:identifier];
    }
    else
    {
        annotationView.annotation = annotation;
    }

    annotationView.enabled = YES;

    return annotationView;
}

/******************************************************************************
 * Normal View Loading Code
 ******************************************************************************/

#pragma mark - Normal View Loading Code

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                         duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];

    /* I have to do this, because when it shrinks it doesn't lower itself
     * enough; so often you can see the post underneath.
     */
    if (self.mapPreview != nil)
    {
        self.mapPreview.frame = CGRectMake(20, 5, self.tableView.bounds.size.width - 40, 90);
    }
    
    if (self.imgPreview != nil)
    {
        self.imgPreview.frame = CGRectMake(20, 5, self.tableView.bounds.size.width - 40, IMAGE_PREVIEW_HEIGHT);
    }

    return;
}

/* for iOS 5. */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

/* for iOS 6. */
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (bool)shouldAutorotate
{
    return NO;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];

    if (self)
    {
        // Custom initialization
        self.textFields = [[NSMutableArray alloc] initWithCapacity:3];
        
        for (int i = 0; i < 3; i++)
        {
            UITextField *inputField = \
                [[UITextField alloc] initWithFrame:CGRectZero];

            /*
             * All but the last tag, later they'll be able to swipe clear tags
             * and add with '+'
             */
            if (i < 2)
            {
                inputField.returnKeyType = UIReturnKeyNext;
            }
            else
            {
                inputField.returnKeyType = UIReturnKeyDone;
            }
            
            inputField.adjustsFontSizeToFitWidth = YES;
            inputField.borderStyle = UITextBorderStyleRoundedRect;
            inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            inputField.autocorrectionType = UITextAutocorrectionTypeNo;
            inputField.clearButtonMode = UITextFieldViewModeAlways;
            inputField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            inputField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            inputField.delegate = self;
            inputField.tag = 900 + i;
            
            [self.textFields addObject:inputField];
        }
        
        self.headerViews = [[NSMutableDictionary alloc] init];
    }

    return self;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.headerViews = nil;
    self.textFields = nil;
    
    [self unregisterForKeyboardNotifications];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    while ([self.tags count] < 3)
    {
        [self.tags addObject:@""];
    }

    UIBarButtonItem *cancelBtn = \
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                      target:self
                                                      action:@selector(dismiss)];
    UIBarButtonItem *postBtn = \
        [[UIBarButtonItem alloc] initWithTitle:@"Post"
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(createAction)];
    
    self.navigationItem.leftBarButtonItem = cancelBtn;
    self.navigationItem.rightBarButtonItem = postBtn;

    if (![self.title isEqualToString:@"Repost"])
    {
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
    }
    else
    {
        self.originalTags = \
            [[NSMutableArray alloc] initWithArray:tags
                                        copyItems:YES];
    }
    
    self.chosenCommunity = 0;

    if (self.communities != nil && [self.communities count] > 0)
    {
        [self.communities insertObject:@"None" atIndex:0];
    }

    self.locationFound = NO;
    self.locationHidden = NO;
    
    /* XXX: need to set this in defaults? */

    /* this checks if the user has enabled any location services. */
    if ([CLLocationManager locationServicesEnabled])
    {
        NSLog(@"location services enabled.");
        /* if they have never run before this will prompt them.
         * if they say no, I have no idea how to check.
         */
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.purpose = @"To tag post with your current location.";
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest; // kCLLocationAccuracyKilometer;
        self.locationManager.distanceFilter = 500;
        [self.locationManager startUpdatingLocation];
        
        if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied)
        {
            NSLog(@"Not denied!");
        }
        else
        {
            NSLog(@"denied.");
        }
        
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized)
        {
            NSLog(@"this is the important one.");
        }
    }

#if 0 /* this works but leads to weirdness when the parent is dismissed. */
    if (self.repostOf == NO)
    {
        [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:SECTION_PREVIEW]];
    }
#endif
    
    [self registerForKeyboardNotifications];

    return;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *customView = nil;

    /* (copied from the internet)
     * That's because the UITableView automatically sets the frame of the header
     * view you provide to: 
     *
     * (0, y, table view width, header view height)
     * 
     * y is the computed position of the view and header view height is the 
     * value returned by tableView:heightForHeaderInSection:
     */

    if (section == SECTION_TAGS)
    {
        customView = self.headerViews[@"tags"];
        
        if (customView == nil)
        {
            customView = \
                [Util basicLabelViewWithWidth:tableView.frame.size.width
                                   withHeight:tableView.rowHeight];
            
            UILabel *title = (UILabel *)[customView viewWithTag:900];
            title.text = @"Tags";
            
            (self.headerViews)[@"tags"] = customView;
        }
        //return  tableView.tableHeaderView;
    }
    else if (section == SECTION_LOCATION)
    {
        if (self.locationFound)
        {
            customView = self.headerViews[@"location"];

            if (customView == nil)
            {
                customView = [[UIView alloc] initWithFrame:CGRectZero];
                customView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                customView.autoresizesSubviews = NO;

                self.mapPreview.frame = CGRectMake(20,
                                                   5,
                                                   tableView.frame.size.width - 40,
                                                   90);
                self.mapPreview.tag = 900;
                self.mapPreview.clipsToBounds = YES;

                //self.mapPreview.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                //the above doesn't matter because I prevent the customView from
                // mucking with its subviews, because when it did it broke the map.

                [customView addSubview:self.mapPreview];
                (self.headerViews)[@"location"] = customView;
            }

//            MKMapView *map = (MKMapView *)[customView viewWithTag:900];
//            map.frame = CGRectMake(20, 5, 280, 90); /* it just doesn't believe me. */
        }
        else
        {
            customView = self.headerViews[@"loctxt"];
            
            if (customView == nil)
            {
                customView = \
                    [Util basicLabelViewWithWidth:tableView.frame.size.width - 40
                                       withHeight:tableView.rowHeight];
                
                UILabel *title = (UILabel *)[customView viewWithTag:900];
                title.text = @"Location";
                
                (self.headerViews)[@"loctxt"] = customView;
            }
        }
    }
    else if (section == SECTION_PREVIEW)
    {
        if (self.repostOf || self.previewImage != nil)
        {
            customView = self.headerViews[@"preview"];
            
            if (customView == nil)
            {
//                CGRect frm = CGRectMake(0, 0,
//                                        tableView.frame.size.width,
//                                        IMAGE_PREVIEW_HEIGHT + 10);

                customView = [[UIView alloc] initWithFrame:CGRectZero];
                customView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                customView.autoresizesSubviews = NO;

                /* the imageview is set all the way to the left... */
                UIImageView *img = [[UIImageView alloc] initWithImage:self.previewImage];
                img.frame = CGRectMake(20, 5,
                                       tableView.frame.size.width - 40,
                                       IMAGE_PREVIEW_HEIGHT);
                img.contentMode = UIViewContentModeScaleAspectFit;
                img.tag = 900;
                
                self.imgPreview = img;
                
                //customView.contentMode = UIViewContentModeBottom;
                [customView addSubview:img];
                
                (self.headerViews)[@"preview"] = customView;
            }
        }
    }

//    NSLog(@"customView for Section: %d, %@, subviews: %@", section, customView, [customView subviews]);
    return customView;
}
/* prior to iOS 5.0 returning nil from viewforheaderinsection would automatically set the section height to 0. */
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == SECTION_TAGS)
    {
        return 30;
    }

    if (section == SECTION_PREVIEW)
    {
        if (self.repostOf || self.previewImage != nil)
        {
            return IMAGE_PREVIEW_HEIGHT + 10;
        }
    }

    if (section == SECTION_LOCATION)
    {
        if (self.locationFound)
        {
            return 100;
        }
        else
        {
            //return tableView.rowHeight;
            return 30;
        }
    }

    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return tableView.rowHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if (self.replyTo || self.repostOf)
    {
        return SECTION_REPLYREPOST + 1;
    }

    return SECTION_LOCATION + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == SECTION_TAGS)
    {
        // empty sections leave weird gaps.
        NSLog(@"tags: %@", self.tags);
        return 3;
    }
    
    if (section == SECTION_PREVIEW)
    {
        if (self.repostOf)
        {
            return 0;
        }
    }
    
    if (section == SECTION_LOCATION)
    {
        if (self.locationFound && self.locationHidden == NO)
        {
            return 2;
        }
    }
    
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifierBla = @"Uninteresting";
    static NSString *CellIdentifierTag = @"Tag";

    UITableViewCell *cell = nil;

    NSLog(@"cellForRowAtIndexPath: %d, %d", indexPath.section, indexPath.row);

    if (indexPath.section == SECTION_PREVIEW)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierBla];

        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                reuseIdentifier:CellIdentifierBla];
        }
    }
    else if (indexPath.section == SECTION_TAGS)
    {
        UITextField *field = (self.textFields)[indexPath.row];
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierTag];

        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:CellIdentifierTag];

            CGRect fieldFrame = CGRectMake(cell.frame.origin.x + 10,
                                           cell.frame.origin.y + 5,
                                           cell.contentView.frame.size.width - 20,
                                           tableView.rowHeight - 10);

            [field setFrame:fieldFrame];

            [cell.contentView addSubview:field];
        }
        
        BOOL foundField = NO;
        
        for (UIView *view in [cell.contentView subviews])
        {
            if ([view isKindOfClass:[UITextField class]])
            {
                foundField = YES;
                break;
            }
        }
        
        if (foundField == NO)
        {
            NSLog(@"Add missing field...????");
            CGRect fieldFrame = CGRectMake(cell.frame.origin.x + 10,
                                           cell.frame.origin.y + 5,
                                           cell.contentView.frame.size.width - 20,
                                           tableView.rowHeight - 10);
            [field setFrame:fieldFrame];
            [cell.contentView addSubview:field];
        }
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierBla];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:CellIdentifierBla];
        }
    }

    // Configure the cell...
    /* XXX: Add custom cell types, that are entirely custom soon. */
    switch (indexPath.section)
    {
        case SECTION_PREVIEW:
        {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = @"Choose Image";
            break;
        }
        case SECTION_COMMUNITY_SELECTOR:
        {
            cell.textLabel.text = @"Community Selector";
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            break;
        }
        case SECTION_TAGS:
        {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            UITextField *txt = (UITextField *)[cell.contentView viewWithTag:900+indexPath.row];
            
            if (txt != nil) // weirdly this can happen.
            {
                [txt setText:(self.tags)[indexPath.row]];
            }

            break;
        }
        case SECTION_LOCATION:
        {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

            if (self.locationFound)
            {
                if (indexPath.row == 0)
                {
                    if (self.locationHidden == NO)
                    {
                        cell.textLabel.adjustsFontSizeToFitWidth = YES;
                        cell.textLabel.text = \
                            [NSString stringWithFormat:@"%+.6f, %+.6f",
                             self.coordinate.latitude, self.coordinate.longitude];
                    }
                    else
                    {
                        cell.textLabel.text = @"Add Location";
                    }
                }
                else
                {
                    cell.textLabel.text = @"Hide Location";
                }
            }
            else
            {
                if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized)
                {
                    cell.textLabel.text = @"Location Indicator";
                }
                else
                {
                    cell.textLabel.text = @"Add Location";
                }
                
            }

            break;
        }
        case SECTION_REPLYREPOST:
        {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            
            if (self.replyTo)
            {
                cell.textLabel.text = \
                    [NSString stringWithFormat:@"Reply to: %@", self.repostReply];
            }
            else
            {
                cell.textLabel.text = \
                    [NSString stringWithFormat:@"Repost of: %@", self.repostReply];
            }

            break;
        }
        default:
        {
            cell.textLabel.text = @"Default";
            
            break;
        }
    }

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSLog(@"selected indexpath: %@", indexPath);
    
    switch (indexPath.section)
    {
        case SECTION_PREVIEW:
        {
            if (self.repostOf == NO)
            {
                NSLog(@"Create/Preview Button Handler Called.");
                
                UIActionSheet *sheet = nil;

                sheet = [[UIActionSheet alloc] initWithTitle:@"Choose Source:"
                                                    delegate:self
                                           cancelButtonTitle:nil
                                      destructiveButtonTitle:nil
                                           otherButtonTitles:nil];
                
                int buttonCount = 0;
                
                if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum])
                {
                    [sheet addButtonWithTitle:@"Photo Album"];
                    buttonCount += 1;
                }

                if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
                {
                    [sheet addButtonWithTitle:@"Camera"];
                    buttonCount += 1;
                }

                [sheet addButtonWithTitle:@"Cancel"];
                [sheet setCancelButtonIndex:buttonCount];

                [sheet showInView:self.view];
            }
            break;
        }
        case SECTION_COMMUNITY_SELECTOR:
        {
            if (self.communities == nil || [self.communities count] == 0)
            {
                return;
            }

            UIActionSheet *sheet = \
                [[UIActionSheet alloc] initWithTitle:nil //@"Choose Community"
                                            delegate:nil
                                   cancelButtonTitle:nil
                              destructiveButtonTitle:nil
                                   otherButtonTitles:nil];

            /* copied code */
            UISegmentedControl *closeButton = \
                [[UISegmentedControl alloc] initWithItems:@[@"Close"]];

            closeButton.momentary = YES;
            closeButton.frame = CGRectMake(self.view.bounds.size.width - 53, 7, 50, 28);
            closeButton.segmentedControlStyle = UISegmentedControlStyleBar;
            closeButton.tintColor = [UIColor blackColor];

            [closeButton addTarget:self
                            action:@selector(dismissActionSheet:)
                  forControlEvents:UIControlEventValueChanged];

            [sheet addSubview:closeButton];

            CGRect pickerFrame = CGRectMake(0, 40, 0, 0);
            UIPickerView *pickerView = \
                [[UIPickerView alloc] initWithFrame:pickerFrame];

            pickerView.showsSelectionIndicator = YES;
            pickerView.dataSource = self;
            pickerView.delegate = self;

            [pickerView selectRow:self.chosenCommunity
                      inComponent:0
                         animated:NO];

            [sheet addSubview:pickerView];

            self.currentSheet = sheet; // so I can dismiss later.

            [sheet showInView:self.view];
            
            CGFloat sheetH = pickerView.frame.size.height + 40;
            CGFloat sheetY = self.view.bounds.size.height - sheetH;
            
            CGRect shfrm = CGRectMake(0, sheetY, self.view.bounds.size.width, sheetH);
            [sheet setFrame:shfrm];

            break;
        }
        case SECTION_TAGS:
        {
            break;
        }
        case SECTION_LOCATION:
        {
            if (indexPath.row == 0)
            {
                if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized)
                {
                    NSLog(@"Should prompt to add location.");
                
                    /* XXX: name application! */
                    UIAlertView *alert = \
                        [[UIAlertView alloc] initWithTitle:@"Location Disabled"
                                                   message:@"Please enter settings and enable location services for this application."
                                                  delegate:nil
                                         cancelButtonTitle:@"OK"
                                         otherButtonTitles:nil];

                    [alert show];

                    // [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs://"]];
                }
                else
                {
                    if (self.locationFound)
                    {
                        self.locationHidden = NO;
                    }
                    
                    [self.tableView reloadData];
                }
            }
            else
            {
                if (self.locationHidden)
                {
                    self.locationHidden = NO;
                }
                else
                {
                    self.locationHidden = YES;
                }
                
                [self.tableView reloadData];
            }
            
            break;
        }
        default:
        {
            break;
        }
    }

    return;
}

@end
