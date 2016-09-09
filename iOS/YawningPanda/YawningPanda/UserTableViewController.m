//
//  UserTableViewController.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 8/9/12.
//
//

#import "UserTableViewController.h"

#import "NewAvatarViewController.h"

/* Sub Table Views. */
#import "CommunityTVC.h"
#import "WatchlistTVC.h"
#import "FavoriteTableViewController.h"
#import "PostsTVC.h"

#import "Util.h"

#import <QuartzCore/QuartzCore.h>

#define IMAGE_PREVIEW_HEIGHT 184

@implementation UserTableViewController

@synthesize readOnly, editPushed, subViewPushed, fromPost;
@synthesize busyWaiting, avatarSelected;
@synthesize communities;
@synthesize watching;
@synthesize favorites;
@synthesize headerViews;
@synthesize hiddenField, updateTextField, saveBtn;

@synthesize eventLogPtr, userPtr;
@synthesize pivotDelegate, logoutDelegate, unfavoriteDelegate;

@synthesize locationFound;
@synthesize coordinate;
@synthesize locationManager;

@synthesize apiManager;
@synthesize activity;
@synthesize textFields;
@synthesize savingSection, savingText;
@synthesize mapPreview, avatarView;

@synthesize meIdentifier, userCache;

/******************************************************************************
 * Query TextField Code
 ******************************************************************************/

- (void)cancelTextBtnHandler
{
    self.savingSection = -1;
    [self.apiManager cancelAll];

    for (UITextField *text in self.textFields)
    {
        NSLog(@"TextField.tag: %d", text.tag);
        
        if ([text isFirstResponder])
        {
            [text resignFirstResponder];
        }
    }
    
    return;
}

- (void)saveTextBtnHandler
{
    self.savingSection = -1;

    /*
     * Grab the current text field and based on tag, figure out what we're
     * updating.
     */
    for (UITextField *text in self.textFields)
    {
        if ([text isFirstResponder])
        {
            self.savingSection = text.tag;
            self.savingText = text.text;
            [text resignFirstResponder];
            break;
        }
    }

    NSString *updateField = nil;

    switch (self.savingSection)
    {
        case USER_MEMBER_REALISHNAME:
            updateField = @"realish_name";
            break;
        case USER_MEMBER_HOMEURL:
            updateField = @"home";
            break;
        case USER_MEMBER_BIO:
            updateField = @"bio";
            break;
        case USER_MEMBER_LOCATION:
            updateField = @"location";
            break;
        default:
            return;
    }

    NSLog(@"updating %@ with %@", updateField, self.savingText);

    [self.activity startAnimating];
    [self.saveBtn setEnabled:NO];

    self.busyWaiting = YES;

    [self.apiManager userUpdate:self.userPtr.userid
                       forField:updateField
                      withValue:self.savingText];
    return;
}

- (UIView *)buildInputAccessory
{
    UIToolbar *buttonView = \
        [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    buttonView.backgroundColor = [UIColor clearColor];
    [buttonView sizeToFit];
    buttonView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    UIBarButtonItem *flexible = \
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                  target:nil
                                                  action:nil];
    
    UIBarButtonItem *cancel = \
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                  target:self
                                                  action:@selector(cancelTextBtnHandler)];
    
    UIBarButtonItem *saveIt = \
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                  target:self
                                                  action:@selector(saveTextBtnHandler)];

    [buttonView setItems:@[cancel, flexible, saveIt]
                animated:YES];
    
    return buttonView;
}

/******************************************************************************
 * Delegate Callbacks
 ******************************************************************************/

- (void)apihandler:(APIHandler *)apihandler didFail:(enum APICall)type
{
    self.busyWaiting = NO;
    [self.apiManager dropHandler:apihandler];
    [self.activity stopAnimating];
    [self.updateTextField resignFirstResponder];
    
    NSLog(@"Need to tell the user it failed.");
}

- (void)apihandler:(APIHandler *)apihandler didCompleteUpdate:(bool)success
            asUser:(NSString *)theUser
{
    self.busyWaiting = NO;
    
    [self.apiManager dropHandler:apihandler];
    [self.activity stopAnimating];
    [self.updateTextField resignFirstResponder];
    
    if (theUser == nil)
    {
        NSLog(@"didCompleteUpdate returned in error.");
    }

    /* The user information is not updated. */
    if (success == YES)
    {
        switch (self.savingSection)
        {
            case USER_MEMBER_REALISHNAME:
            {
                self.userPtr.realish_name = self.savingText;
                break;
            }
            case USER_MEMBER_HOMEURL:
            {
                self.userPtr.home = self.savingText;
                break;
            }
            case USER_MEMBER_BIO:
            {
                self.userPtr.bio = self.savingText;
                break;
            }
            case USER_MEMBER_LOCATION:
            {
                NSLog(@"location updated.");
                
                if (self.userPtr.validCoordinates == NO)
                {
                    NSLog(@"invalid coordinates.");
                    self.userPtr.location = self.savingText;
                }
                else
                {
                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:USER_MEMBER_LOCATION]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
                }
                break;
            }
            default:
                break;
        }
        
        [self.tableView reloadData];
    }
    
    return;
}

- (void)apihandler:(APIHandler *)apihandler didCompleteUserView:(UIImage *)image
          withUser:(NSString *)userid
{
    [self.apiManager dropHandler:apihandler];
    if ([self.apiManager outStanding] == 0)
    {
        [self.activity stopAnimating];
    }
    
    NSLog(@"completed userview: %@ for %@", image, userid);
    
    if (image == nil)
    {
        return;
    }
    else
    {
        userPtr.image = image;
    }

    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:USER_MEMBER_AVATAR]
                  withRowAnimation:UITableViewRowAnimationAutomatic];

    return;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    NSLog(@"latitude %+.6f, longitude %+.6f\n",
          newLocation.coordinate.latitude,
          newLocation.coordinate.longitude);
    
    self.coordinate = newLocation.coordinate;
    self.locationFound = YES;
    self.busyWaiting = YES;
    self.savingSection = USER_MEMBER_LOCATION;

    [locationManager stopUpdatingLocation];

    User *userData = nil;

    userData = self.userPtr;

    userData.validCoordinates = YES;
    userData.coordinate = newLocation.coordinate;
    userData.location = \
        [@[[NSNumber numberWithFloat:newLocation.coordinate.latitude],
          [NSNumber numberWithFloat:newLocation.coordinate.longitude]] componentsJoinedByString:@", "];

    [self.activity startAnimating];
    [self.apiManager userUpdate:userData.userid
                       forField:@"location"
                      withValue:userData.location];

    /* these should be the coordinates within the parent view. */

    // else skip the event and process the next one.
    return;
}

/******************************************************************************
 * Button Handlers
 ******************************************************************************/

- (IBAction)nonEditHandler
{
    if (self.busyWaiting)
    {
        return;
    }
    
    self.editPushed = NO;
    
    UIBarButtonItem *backBtn = nil;
    
    if (self.readOnly)
    {
        NSString *backName;
        
        if (self.fromPost)
        {
            backName = @"Post";
        }
        else
        {
            backName = @"Done";
        }

        backBtn = [[UIBarButtonItem alloc] initWithTitle:backName
                                                   style:UIBarButtonItemStyleDone
                                                  target:self
                                                  action:@selector(dismiss)];
    }
    else
    {
        backBtn = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                   style:UIBarButtonItemStyleDone
                                                  target:self
                                                  action:@selector(dismiss)];
        
        UIBarButtonItem *editBtn = \
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                          target:self
                                                          action:@selector(editBtnhandler)];

        self.navigationItem.rightBarButtonItems = @[editBtn];
    }

    self.activity = \
        [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.activity.hidesWhenStopped = YES;

    UIBarButtonItem *activityBtn = \
        [[UIBarButtonItem alloc] initWithCustomView:self.activity];

    self.navigationItem.leftBarButtonItems = @[backBtn, activityBtn];

    [self.tableView reloadData];

    return;
}

- (IBAction)editBtnhandler
{
    self.editPushed = YES;

    self.navigationItem.leftBarButtonItem = nil;
    
    UIBarButtonItem *backBtn = \
        [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                         style:UIBarButtonItemStyleDone
                                        target:self
                                        action:@selector(nonEditHandler)];
    
    self.navigationItem.rightBarButtonItem = backBtn;

    [self.tableView reloadData];

    return;
}

- (IBAction)logoutBtnHandler
{
    [self dismissModalViewControllerAnimated:YES];
    
    [self.apiManager cancelAll];

    [logoutDelegate handleLogoutSelected];
    
    return;
}

/* For certain buttons I think I can honestly just set them to call dismiss:YES */
- (IBAction)dismiss
{
    NSLog(@"Dismissing.");
    
    if (self.busyWaiting)
    {
        return;
    }
    
    [self.apiManager cancelAll];
    
    if (self.readOnly) /* then subview */
    {
        if (self.fromPost)
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
        else
        {
            [self.navigationController dismissModalViewControllerAnimated:YES];
        }
    }
    else
    {
        [self dismissModalViewControllerAnimated:YES];
    }
    
    return;
}

/******************************************************************************
 * Normal View Loading Code
 ******************************************************************************/

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    
    if (self)
    {
        // Custom initialization
        self.headerViews = [[NSMutableDictionary alloc] init];
        self.apiManager = [[APIManager alloc] initWithDelegate:self];
        self.textFields = [[NSMutableArray alloc] init];
        
        self.busyWaiting = NO;
        self.subViewPushed = NO;
        self.avatarSelected = NO;
        self.savingSection = -1;
    }
    
    return self;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                         duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    if (self.mapPreview != nil)
    {
        self.mapPreview.frame = CGRectMake(15,
                                           5,
                                           self.tableView.bounds.size.width - 30,
                                           100);
    }

    if (self.avatarView != nil)
    {
        self.avatarView.frame = CGRectMake(0,
                                           0,
                                           self.tableView.frame.size.width,
                                           IMAGE_PREVIEW_HEIGHT);
    }

    return;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;

    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest; // kCLLocationAccuracyKilometer;
    locationManager.distanceFilter = 500;

    self.hiddenField = [[UITextField alloc] initWithFrame:CGRectZero];
    [self.hiddenField setHidden:YES];

    /* Bring up the keyboard. */
    self.hiddenField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.hiddenField.inputAccessoryView = [self buildInputAccessory];
    [self.view addSubview:self.hiddenField];

    [self nonEditHandler];

    return;
}

/**
 * @brief This is called as the view is being reloaded, but not yet complete.
 *
 * @param animated hmmm..
 */
- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"UserTableViewController Will Appear.");

    [super viewWillAppear:animated];
    
    if (self.editPushed || self.subViewPushed)
    {
        NSLog(@"editPushed");
        [self.tableView reloadData];
    }

    if (self.avatarSelected)
    {
        [self.activity startAnimating];
        [self.apiManager userView:self.userPtr.userid];
    }

    self.subViewPushed = NO;
    self.avatarSelected = NO;
    
    return;
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    return;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if (interfaceOrientation == UIInterfaceOrientationPortrait)
    {
        return YES;
    }
    
    if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft)
    {
        return YES;
    }
    
    if (interfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
        return YES;
    }
    
    return NO;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return (USER_MEMBER_GROUPS + 1);
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *customView = nil;

    User *userData = nil;

    userData = self.userPtr;
    
    /* (copied from the internet)
     * That's because the UITableView automatically sets the frame of the header
     * view you provide to:
     *
     * (0, y, table view width, header view height)
     *
     * y is the computed position of the view and header view height is the
     * value returned by tableView:heightForHeaderInSection:
     */
    if (section == USER_MEMBER_AVATAR)
    {
        customView = \
            (self.headerViews)[@(section)];

        if (customView == nil)
        {
            CGRect frm = CGRectMake(0, 0,
                                    tableView.frame.size.width,
                                    IMAGE_PREVIEW_HEIGHT + 10);

            customView = [[UIView alloc] initWithFrame:frm];
            customView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            customView.autoresizesSubviews = NO;

            /* the imageview is set all the way to the left... */
            UIImageView *img = \
                [[UIImageView alloc] initWithImage:userData.image];
            img.frame = CGRectMake(20, 5,
                                   tableView.frame.size.width - 40,
                                   IMAGE_PREVIEW_HEIGHT);
            img.contentMode = UIViewContentModeScaleAspectFit;
            img.tag = 900;
            self.avatarView = img;

            UITapGestureRecognizer *tapRecognizer = \
                [[UITapGestureRecognizer alloc] initWithTarget:self
                                                        action:@selector(newAvatar:)];
            tapRecognizer.numberOfTouchesRequired = 1;
            tapRecognizer.numberOfTapsRequired = 1;
            tapRecognizer.delegate = self;
            
            [img addGestureRecognizer:tapRecognizer]; // this alone doesn't seem to work. : (

            //img.layer.cornerRadius = 9.0;
            //img.layer.masksToBounds = YES;
            //img.layer.borderColor = [UIColor lightGrayColor].CGColor;
            //img.layer.borderWidth = 1.0;

            [customView addGestureRecognizer:tapRecognizer];
            [customView addSubview:img];

            (self.headerViews)[@(section)] = customView;
        }
        else
        {
            UIImageView *img = (UIImageView *)[customView viewWithTag:900];
            img.image = userData.image;
        }
    }
    else
    {
        customView = \
            (self.headerViews)[@(section)];
        
        if (customView == nil)
        {
            customView = \
                [Util basicLabelViewWithWidth:tableView.frame.size.width
                                   withHeight:tableView.rowHeight];
            
            UILabel *title = (UILabel *)[customView viewWithTag:900];
            title.text = [self tableView:tableView
                 titleForHeaderInSection:section];
            
            (self.headerViews)[@(section)] = customView;
        }
    }

    //    NSLog(@"customView for Section: %d, %@, subviews: %@", section, customView, [customView subviews]);
    return customView;
}
/* prior to iOS 5.0 returning nil from viewforheaderinsection would automatically set the section height to 0. */
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == USER_MEMBER_AVATAR)
    {
        return IMAGE_PREVIEW_HEIGHT + 10;
    }

    return 30;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case USER_MEMBER_LOGOUT:
            return @"";

        case USER_MEMBER_AVATAR:
            return @"";

        case USER_MEMBER_BIO:
            return @"Bio";

        case USER_MEMBER_CREATED:
            return @"Created";

        case USER_MEMBER_REALISHNAME:
            return @"Real Name";

        case USER_MEMBER_EMAIL:
            return @"Email";

        case USER_MEMBER_HOMEURL:
            return @"Homepage";

        case USER_MEMBER_ID:
            return @"User ID";

        case USER_MEMBER_LOCATION:
            return @"Location";

        case USER_MEMBER_GROUPS:
            return @"Groups";

        default:
            return @"";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == USER_MEMBER_AVATAR)
    {
        if (self.editPushed)
        {
            return 2;
        }
        
        return 1;
    }

    if (section == USER_MEMBER_GROUPS)
    {
        return 5;
    }
    
    if (section == USER_MEMBER_CREATED)
    {
        return 2;
    }
    
    if (section == USER_MEMBER_LOGOUT)
    {
        if (self.readOnly)
        {
            return 0;
        }
        
        return 1;
    }
    
    if (section == USER_MEMBER_LOCATION)
    {
        if (self.editPushed)
        {
            return 2;
        }
        
        return 1;
    }

    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    User *userData = nil;

    userData = self.userPtr;

    /* XXX: This is a bad way to do this -- and there is! */
    if (indexPath.section == USER_MEMBER_BIO)
    {
        int lines = [[userData.bio componentsSeparatedByString:@"\n"] count];
        int size = (10 + (lines * 20));
        return (size < tableView.rowHeight) ? tableView.rowHeight : size;
    }

    if (indexPath.section == USER_MEMBER_LOCATION && userData.validCoordinates)
    {
        if (indexPath.row == 0)
        {
            return 100 + 10;
        }
        else
        {
            return tableView.rowHeight;
        }
    }

    return tableView.rowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    static NSString *CellIdentifier2 = @"Loc";
    static NSString *CellIdentifier3 = @"Single";
    static NSString *CellIdentifier4 = @"MultiLine";

    UITableViewCell *cell = nil;

    User *userData = nil;
    int watchCount = 0;

    userData = self.userPtr;

    NSLog(@"section: %d; row: %d", indexPath.section, indexPath.row);
    
    if (userData.validCoordinates
        && indexPath.section == USER_MEMBER_LOCATION
        && indexPath.row == 0)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier2];
        
        // Configure the cell...
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:CellIdentifier2];

            CGRect mapFrm = CGRectMake(15, 5, self.tableView.bounds.size.width - 30, 100);

            MKMapView *tmp = [[MKMapView alloc] initWithFrame:mapFrm];
            self.mapPreview = tmp;

            CLLocationCoordinate2D center;

            center = userData.coordinate;

            MKCoordinateRegion viewRegion = \
                MKCoordinateRegionMakeWithDistance(center, 0.5*METERS_PER_MILE, 0.5*METERS_PER_MILE);
            MKCoordinateRegion adjustedRegion = [tmp regionThatFits:viewRegion];

            [tmp setRegion:adjustedRegion animated:YES];
            tmp.autoresizingMask |= (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
            tmp.scrollEnabled = NO;
            tmp.clipsToBounds = YES;
            tmp.zoomEnabled = YES;

            //photo.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;

            UITapGestureRecognizer *tapRecognizer = \
                [[UITapGestureRecognizer alloc] initWithTarget:self
                                                        action:@selector(mapSelector:)];
            tapRecognizer.numberOfTouchesRequired = 1;
            tapRecognizer.numberOfTapsRequired = 1;
            tapRecognizer.delegate = self;

            [tmp addGestureRecognizer:tapRecognizer];

            [cell addSubview:tmp];

            //[cell sizeToFit];
            cell.autoresizesSubviews = NO;
            cell.autoresizingMask |= UIViewAutoresizingFlexibleHeight; // do i need this?
        }
    }
    else
    {
        if (self.editPushed
            && (indexPath.section == USER_MEMBER_REALISHNAME || indexPath.section == USER_MEMBER_HOMEURL
                || (indexPath.section == USER_MEMBER_LOCATION && indexPath.row == 0 && userData.validCoordinates == NO)))
        {
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier3];
            
            if (cell == nil)
            {
                NSLog(@"Allocating new cell3");

                cell = \
                    [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                           reuseIdentifier:CellIdentifier3];
                UITextField *inputField = \
                    [[UITextField alloc] initWithFrame:CGRectMake(cell.frame.origin.x + 10,
                                                                  cell.frame.origin.y + 5,
                                                                  cell.contentView.frame.size.width - 20,
                                                                  tableView.rowHeight - 10)];

                inputField.adjustsFontSizeToFitWidth = YES;
                inputField.borderStyle = UITextBorderStyleRoundedRect;
                inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
                inputField.autocorrectionType = UITextAutocorrectionTypeNo;
                inputField.clearButtonMode = UITextFieldViewModeAlways;
                inputField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
                inputField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                inputField.delegate = self;
                inputField.inputAccessoryView = [self buildInputAccessory];
                inputField.tag = indexPath.section;

                [cell.contentView addSubview:inputField];
            }
        }
        else if (self.editPushed && indexPath.section == USER_MEMBER_BIO)
        {
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier4];
            
            if (cell == nil)
            {
                NSLog(@"Allocating new cell4");
                
                cell = \
                    [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                           reuseIdentifier:CellIdentifier4];
                
                int lines = [[userData.bio componentsSeparatedByString:@"\n"] count];
                int size = (10 + (lines * 20));
                int height = (size < tableView.rowHeight) ? tableView.rowHeight - 10 : size - 10;
                
                UITextView *inputField = \
                    [[UITextView alloc] initWithFrame:CGRectMake(cell.frame.origin.x + 10,
                                                                  cell.frame.origin.y + 5,
                                                                  cell.contentView.frame.size.width - 20,
                                                                  height)];

//                inputField.adjustsFontSizeToFitWidth = YES;
  //              inputField.borderStyle = UITextBorderStyleRoundedRect;
                inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
                inputField.autocorrectionType = UITextAutocorrectionTypeNo;
    //            inputField.clearButtonMode = UITextFieldViewModeAlways;
      //          inputField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
                inputField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        //        inputField.delegate = self;
                inputField.inputAccessoryView = [self buildInputAccessory];
                inputField.tag = indexPath.section;

                [cell.contentView addSubview:inputField];
            }
        }
        else
        {
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
            // Configure the cell...
            if (cell == nil)
            {
                cell = \
                    [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                           reuseIdentifier:CellIdentifier];
            }
        }
    }

    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.textAlignment = UITextAlignmentLeft;
    cell.textLabel.textColor = [UIColor darkTextColor];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.numberOfLines = 1;

    switch (indexPath.section)
    {
        case USER_MEMBER_LOGOUT:
        {
            cell.textLabel.text = @"Logout";
            cell.textLabel.textAlignment = UITextAlignmentCenter;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            break;
        }
        case USER_MEMBER_AVATAR:
        {
            if (self.editPushed)
            {
                if (indexPath.row == 0)
                {
                    cell.textLabel.text = @"Update Avatar";
                    cell.textLabel.textColor = [UIColor lightGrayColor];
                    break;
                }
            }
            cell.textLabel.text = userData.display_name; /* either row 0 normally, or 1 otherwise. */
            break;
        }
        case USER_MEMBER_BIO:
        {
            if (self.editPushed)
            {
                UITextView *text = (UITextView *)[cell viewWithTag:indexPath.section];
                text.keyboardType = UIKeyboardTypeDefault;
                text.text = userData.bio;
                text.textColor = [UIColor lightGrayColor];
                
                if (![self.textFields containsObject:text] && text != nil)
                {
                    NSLog(@"Adding Text Field");
                    [self.textFields addObject:text];
                }
            }
            else
            {
                cell.textLabel.text = userData.bio;
                cell.textLabel.numberOfLines = 5;
                cell.textLabel.adjustsFontSizeToFitWidth = YES;
            }

            break;
        }
        case USER_MEMBER_CREATED:
        {
            if (indexPath.row == 0)
            {
                cell.textLabel.text = userData.created;
            }
            else
            {
                cell.textLabel.text = [Util timeSinceWhen:userData.createdStamp];
            }
            break;
        }
        case USER_MEMBER_REALISHNAME:
        {
            if (self.editPushed)
            {
                UITextField *text = (UITextField *)[cell viewWithTag:indexPath.section];
                text.keyboardType = UIKeyboardTypeDefault;
                text.text = userData.realish_name;
                text.textColor = [UIColor lightGrayColor];

                if (![self.textFields containsObject:text] && text != nil)
                {
                    NSLog(@"Adding Text Field");
                    [self.textFields addObject:text];
                }
            }
            else
            {
                cell.textLabel.text = userData.realish_name;
            }

            break;
        }
        case USER_MEMBER_EMAIL:
        {
            cell.textLabel.text = userData.email;

            break;
        }
        case USER_MEMBER_HOMEURL:
        {
            if (self.editPushed)
            {
                UITextField *text = (UITextField *)[cell viewWithTag:indexPath.section];
                text.keyboardType = UIKeyboardTypeURL;
                text.text = userData.home;
                text.textColor = [UIColor lightGrayColor];

                if (![self.textFields containsObject:text] && text != nil)
                {
                    NSLog(@"Adding Text Field");
                    [self.textFields addObject:text];
                }
            }
            else
            {
                cell.textLabel.text = userData.home;
            }

            break;
        }
        case USER_MEMBER_ID:
        {
            cell.textLabel.text = userData.userid;
            break;
        }
        case USER_MEMBER_LOCATION:
        {
            if (indexPath.row == 0 && userData.validCoordinates)
            {
                break;
            }
            
            if (self.editPushed)
            {
                cell.textLabel.textColor = [UIColor lightGrayColor];
                
                if (indexPath.row == 0)
                {
                    UITextField *text = (UITextField *)[cell viewWithTag:indexPath.section];
                    text.keyboardType = UIKeyboardTypeURL;
                    text.text = userData.location;
                    text.textColor = [UIColor lightGrayColor];
                        
                    if (![self.textFields containsObject:text] && text != nil)
                    {
                        NSLog(@"Adding Text Field");
                        [self.textFields addObject:text];
                    }
                }
                else if (indexPath.row == 1)
                {
                    cell.textLabel.text = @"Set with Current Location";
                }
            }
            else
            {
                if (indexPath.row == 0)
                {
                    cell.textLabel.text = userData.location;
                }
            }

            break;
        }
        case USER_MEMBER_GROUPS:
        {
            switch (indexPath.row)
            {
                case USER_MEMBER_BADGES:
                {
                    cell.textLabel.text = @"Badges";
                    
                    if ([userData.badges count] > 0)
                    {
                        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    }
                    break;
                }
                case USER_MEMBER_WATCHLIST:
                {
                    if (self.readOnly)
                    {
                        watchCount = [userData.watches count];
                    }
                    else
                    {
                        watchCount = [self.watching.userids count];
                    }

                    cell.textLabel.text = @"Watching";

                    if (watchCount > 0)
                    {
                        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    }
                    break;
                }
                case USER_MEMBER_FAVORITES:
                {
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;

                    cell.textLabel.text = @"Favorites";
                    break;
                }
                case USER_MEMBER_POSTS:
                {
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    
                    cell.textLabel.text = @"Posts";
                    break;
                }
                case USER_MEMBER_COMMUNITIES:
                {
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;

                    cell.textLabel.text = @"Communities";
                    break;
                }
                default:
                {
                    break;
                }
            }
        }
        default:
        {
            break;
        }
    }

    return cell;
}

#pragma mark - Table view delegate

- (void)mapSelector:(UIGestureRecognizer *)gestureRecognizer
{
    [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:USER_MEMBER_LOCATION]];
}

- (void)newAvatar:(UIGestureRecognizer *)gestureRecognizer
{
    if (self.readOnly || self.editPushed == NO)
    {
        return;
    }

    if (self.busyWaiting)
    {
        return;
    }

    self.avatarSelected = YES;

    NewAvatarViewController *nview = \
        [[NewAvatarViewController alloc] initWithNibName:nil bundle:nil];

    nview.userIdentifier = self.userPtr.userid;
    nview.eventLogPtr = self.eventLogPtr;

    [self.navigationController pushViewController:nview
                                         animated:YES];
    return;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    if (self.busyWaiting)
    {
        return;
    }

    switch (indexPath.section)
    {
        case USER_MEMBER_LOGOUT:
        {
            [self logoutBtnHandler];
            break;
        }
        case USER_MEMBER_AVATAR:
        {
            if (self.readOnly || self.editPushed == NO)
            {
                return;
            }

            if (indexPath.row == 0)
            {
                [self newAvatar:nil];
            }
            
            break;
        }
        case USER_MEMBER_LOCATION:
        {
            if (self.readOnly)
            {
                return;
            }
            
            if (self.editPushed == YES)
            {
                if (indexPath.row == 1)
                {
                    /* Set to current location... */
                    self.locationFound = NO;
                    [locationManager startUpdatingLocation];
                }
            }
            break;
        }
        case USER_MEMBER_GROUPS:
        {
            switch (indexPath.row)
            {
                case USER_MEMBER_WATCHLIST:
                {
                    if (self.readOnly && [self.userPtr.watches count] == 0)
                    {
                        /*
                         * This is only a button if it's your members, or someone's and
                         * they have watched users.
                         */
                        return;
                    }

                    self.subViewPushed = YES;
                    WatchlistTVC *wview = \
                        [[WatchlistTVC alloc] initWithStyle:UITableViewStyleGrouped];

                    /* Is this a view of You or some other user? */
                    if (self.readOnly)
                    {
                        wview.watchlist = self.userPtr.watches;
                    }
                    else
                    {
                        /**
                         * @todo A proper watchlist doesn't really make sense 
                         * because we might end up storing avatars, etc in 
                         * multiple places. why not just store everything in 
                         * the userCache and make sure it doesn't grow to a
                         * million; which it readily could.
                         *
                         * So... if we keep everyone's full watchlist stuff in
                         * the userCache it could get weirdly large, so maybe
                         * for all users we just maintain their list but don't
                         * store the avatars or user info, because those can be
                         * easily downloaded and are pretty low bandwidth 
                         * requirements.
                         */
                        wview.watchlistProper = self.watching;
                    }

                    wview.userIdentifier = self.userPtr.userid;
                    wview.meIdentifier = self.meIdentifier;
                    wview.userCache = self.userCache;
                    wview.eventLogPtr = self.eventLogPtr;
                    wview.delegate = self.pivotDelegate;
                    wview.readOnly = self.readOnly;
                    
                    [self.navigationController pushViewController:wview
                                                         animated:YES];
                    break;
                }
                case USER_MEMBER_FAVORITES:
                {
                    self.subViewPushed = YES;
                    
                    /* Plain may make more sense. */
                    FavoriteTableViewController *fview = \
                        [[FavoriteTableViewController alloc] initWithStyle:UITableViewStylePlain];

                    fview.userIdentifier = self.userPtr.userid;
                    fview.meIdentifier = self.meIdentifier; /* Me. */
                    fview.readOnly = self.readOnly;
                    fview.eventLogPtr = self.eventLogPtr;
                    fview.pivotDelegate = self.pivotDelegate;
                    fview.unfavoriteDelegate = self.unfavoriteDelegate;

                    [self.navigationController pushViewController:fview
                                                         animated:YES];
                    break;
                }
                case USER_MEMBER_POSTS:
                {
                    self.subViewPushed = YES;

                    PostsTVC *pview = \
                        [[PostsTVC alloc] initWithStyle:UITableViewStylePlain];

                    pview.userIdentifier = self.userPtr.userid;
                    pview.meIdentifier = self.meIdentifier;
                    pview.pivotDelegate = self.pivotDelegate;
                    pview.readOnly = self.readOnly;
                    
                    [self.navigationController pushViewController:pview
                                                         animated:YES];

                    break;
                }
                case USER_MEMBER_COMMUNITIES:
                {
                    self.subViewPushed = YES;

                    CommunityTVC *cview = \
                        [[CommunityTVC alloc] initWithStyle:UITableViewStyleGrouped];

                    cview.userIdentifier = self.meIdentifier; /* Me. */

                    if (self.readOnly) /* we don't have their community info yet. */
                    {
                    }
                    else
                    {
                        cview.communities = self.communities;
                        cview.eventLogPtr = self.eventLogPtr;
                    }
                    
                    cview.theUser = self.userPtr.userid;
                    cview.delegate = self.pivotDelegate;
                    cview.readOnly = self.readOnly;
                    
                    [self.navigationController pushViewController:cview
                                                         animated:YES];
                    
                    break;
                }
                default:
                {
                    break;
                }
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
