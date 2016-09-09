//
//  PostInfoTVC.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/20/12.
//
//

#import "PostInfoTVC.h"
#import "UserTableViewController.h"
#import "PostLocationViewController.h"

#import "Util.h"

#import <QuartzCore/QuartzCore.h>

@implementation PostInfoTVC

@synthesize pivotDelegate, joinDelegate;
@synthesize selectedRow, selectedPath;
@synthesize mapView;
@synthesize infoBundle;

@synthesize apiManager;
@synthesize replyToTile;
@synthesize postInfo;
@synthesize userCache;
@synthesize meIdentifier;

/******************************************************************************
 * Delegate Callbacks
 ******************************************************************************/

- (void)apihandler:(APIHandler *)apihandler didFail:(enum APICall)type
{
    [self.apiManager dropHandler:apihandler];

    return;
}

- (void)apihandler:(APIHandler *)apihandler didCompleteQuery:(NSMutableArray *)data
            asUser:(NSString *)theUser
{
    [self.apiManager dropHandler:apihandler];
    if ([data count] == 0)
    {
        return;
    }

    self.postInfo = data[0];

    [self.tableView reloadData];
    
    return;
}

/**
 * @brief This is a delegate function from APIHandler.  It is called when the
 * thumbnail view api call finishes.
 *
 * @param image the contents of the image returned from the view api.
 * @param postid the id of the corresponding post.
 */
- (void)apihandler:(APIHandler *)apihandler didCompleteThumbnail:(UIImage *)image
          withPost:(NSString *)postid
{
    [self.apiManager dropHandler:apihandler];

    if (image == nil)
    {
        NSLog(@"Failed to download thumbnail for: %@", postid);
        return;
    }

    CGSize shrink = CGSizeMake(self.tableView.rowHeight, self.tableView.rowHeight);
    UIGraphicsBeginImageContext(shrink);
    [image drawInRect:CGRectMake(0, 0, shrink.width, shrink.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    self.replyToTile = newImage;

    [self.tableView reloadData];

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
        self.apiManager = [[APIManager alloc] initWithDelegate:self];
    }

    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/* For certain buttons I think I can honestly just set them to call dismiss:YES */
- (void)dismiss
{
    NSLog(@"Dismissing.");
    
    [self.apiManager cancelAll];
    
    [self dismissModalViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //    [self.view setBackgroundColor:[UIColor clearColor]];
    //    [self.view.superview setBackgroundColor:[UIColor clearColor]];
    // just makes it white.

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

    UIBarButtonItem *backBtn = \
        [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                         style:UIBarButtonItemStyleDone
                                        target:self
                                        action:@selector(dismiss)];

    self.navigationItem.leftBarButtonItem = backBtn;
    
    if (self.infoBundle.postContents.reply_to != nil)
    {
        [self.apiManager viewThumbnail:self.infoBundle.postContents.reply_to];
        [self.apiManager getPost:self.infoBundle.postContents.reply_to
                          asUser:self.meIdentifier];
    }

    return;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                         duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];

    /* I have to do this, because when it shrinks it doesn't lower itself
     * enough; so often you can see the post underneath.
     */
    if (self.mapView != nil)
    {
        self.mapView.frame = CGRectMake(15, 5, self.tableView.bounds.size.width - 30, 180);
    }

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
        [self.tableView deselectRowAtIndexPath:self.selectedPath animated:YES];
        return;
    }
    
    if ([buttonTitle isEqualToString:@"Pivot"])
    {
        NSLog(@"Pivot Selected.");
        
        /* Communities are stored as strings of the pairs within the post. */
        [pivotDelegate handlePivot:@"community"
                         withValue:(self.infoBundle.postContents.communities)[self.selectedRow]];
    }
    else if ([buttonTitle isEqualToString:@"Join"])
    {
        NSLog(@"Join Selected.");
        
        [joinDelegate handleNewCommunity:(self.infoBundle.postContents.communities)[self.selectedRow]];
    }
    
    [self dismiss];
    
    return;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [self.infoBundle.sections count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *sec = (self.infoBundle.sections)[section];
    
    if ([sec isEqualToString:@"created"])
    {
        return @"Created";
    }
    else if ([sec isEqualToString:@"actions"])
    {
        return @"Your Actions";
    }
    else if ([sec isEqualToString:@"replies"])
    {
        return @"Replies";
    }
    else if ([sec isEqualToString:@"reposts"])
    {
        return @"Reposts";
    }
    else if ([sec isEqualToString:@"postid"])
    {
        return @"Post ID";
    }
    else if ([sec isEqualToString:@"replyto"])
    {
        return @"Reply To";
    }
    else if ([sec isEqualToString:@"repostof"])
    {
        return @"Repost Of";
    }
    else if ([sec isEqualToString:@"authorview"])
    {
        return @"Author";
    }
    else if ([sec isEqualToString:@"tags"])
    {
        return @"Tags";
    }
    else if ([sec isEqualToString:@"location"])
    {
        return @"Location";
    }
    else if ([sec isEqualToString:@"communities"])
    {
        return @"Communities";
    }
    else
    {
        return @"";
    }
}

/** @note Having variable sections makes things more complicated than this. */
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSString *sec = (self.infoBundle.sections)[section];
    
    if ([sec isEqualToString:@"replies"])
    {
        return @"Click to See Replies";
    }
    else if ([sec isEqualToString:@"tags"])
    {
        return @"Click on Tag to Pivot";
    }
    else if ([sec isEqualToString:@"communities"])
    {
        return @"Click on Community to Pivot or Join";
    }
    else if ([sec isEqualToString:@"replyto"])
    {
        return @"Click to see Original Post";
    }
    else if ([sec isEqualToString:@"repostof"])
    {
        return @"Click to see Original Post";
    }
    else if ([sec isEqualToString:@"reposts"])
    {
        return @"Click to See Reposts"; // XXX: Need to have a new view for this.
    }
    else if ([sec isEqualToString:@"location"])
    {
        if (self.infoBundle.postContents.validCoordinates)
        {
            return @"Click for full-sized Map";
        }
    }

    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSString *sec = (self.infoBundle.sections)[section];
    
    if ([sec isEqualToString:@"tags"])
    {
        return [self.infoBundle.postContents.tags count];
    }
    else if ([sec isEqualToString:@"communities"])
    {
        return [self.infoBundle.postContents.communities count];
    }
    else if ([sec isEqualToString:@"created"])
    {
        return 2;
    }
    else
    {
        return 1;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *section = (self.infoBundle.sections)[indexPath.section];
    
    if ([section isEqualToString:@"location"] && self.infoBundle.postContents.validCoordinates)
    {
        return 180 + 10;
    }
    
    return tableView.rowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    static NSString *CellIdentifier2 = @"Cell2"; /* call it locationCell or something */
    
    UITableViewCell *cell;
    NSString *section = (self.infoBundle.sections)[indexPath.section];
    
    if ([section isEqualToString:@"location"] && self.infoBundle.postContents.validCoordinates)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier2];
        
        // Configure the cell...
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:CellIdentifier2];
            
            CGRect mapFrm = CGRectMake(15, 5, self.tableView.bounds.size.width - 30, 180);
            
            MKMapView *tmp = [[MKMapView alloc] initWithFrame:mapFrm];
            
            CLLocationCoordinate2D center;
            
            center.latitude = self.infoBundle.postContents.coordinate.latitude;
            center.longitude = self.infoBundle.postContents.coordinate.longitude;
            
            MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(center, 0.5*METERS_PER_MILE, 0.5*METERS_PER_MILE);
            MKCoordinateRegion adjustedRegion = [tmp regionThatFits:viewRegion];
            
            [tmp setRegion:adjustedRegion animated:YES];
            tmp.autoresizingMask |= (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
            tmp.scrollEnabled = NO;
            tmp.clipsToBounds = YES;
            tmp.zoomEnabled = YES;
            //photo.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
            
            [tmp addAnnotation:self.infoBundle.postContents];
            
            UITapGestureRecognizer *tapRecognizer = \
                [[UITapGestureRecognizer alloc] initWithTarget:self
                                                        action:@selector(mapSelector:)];
            tapRecognizer.numberOfTouchesRequired = 1;
            tapRecognizer.numberOfTapsRequired = 1;
            tapRecognizer.delegate = self;
            
            [tmp addGestureRecognizer:tapRecognizer];
            
            self.mapView = tmp;
            
            [cell addSubview:self.mapView];
            
            cell.autoresizesSubviews = NO;
            cell.autoresizingMask |= UIViewAutoresizingFlexibleHeight; // do i need this?
        }
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        // Configure the cell...
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:CellIdentifier];
        }
    }

    cell.imageView.image = nil;
    cell.textLabel.text = @"";
    cell.detailTextLabel.text = @"";
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if ([section isEqualToString:@"actions"])
    {
        cell.textLabel.text = \
            [NSString stringWithFormat:@"Favorite of Yours: %@",
             (self.infoBundle.postContents.favorite_of_user) ? @"Yes" : @"No"];
    }
    else if ([section isEqualToString:@"created"])
    {
        if (indexPath.row == 0)
        {
            cell.textLabel.text = self.infoBundle.postContents.created;
        }
        else
        {
            cell.textLabel.text = \
                [Util timeSinceWhen:self.infoBundle.postContents.createdStamp];
        }

    }
    else if ([section isEqualToString:@"replies"])
    {
        cell.textLabel.text = \
            [NSString stringWithFormat:@"%d",
             self.infoBundle.postContents.num_replies];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    else if ([section isEqualToString:@"reposts"])
    {
        cell.textLabel.text = \
            [NSString stringWithFormat:@"%d",
             self.infoBundle.postContents.num_reposts];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    else if ([section isEqualToString:@"postid"])
    {
        cell.textLabel.text = self.infoBundle.postContents.postid;
    }
    else if ([section isEqualToString:@"replyto"])
    {
        cell.textLabel.text = self.infoBundle.postContents.reply_to;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;

        if (self.replyToTile != nil)
        {
            cell.imageView.image = self.replyToTile;
            
            cell.imageView.layer.cornerRadius = 9.0;
            cell.imageView.layer.masksToBounds = YES;
        }
        
        if (self.postInfo != nil)
        {
            cell.detailTextLabel.text = [self.postInfo.tags componentsJoinedByString:@", "];
            cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
        }
    }
    else if ([section isEqualToString:@"repostof"])
    {
        cell.textLabel.text = self.infoBundle.postContents.repost_of;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    else if ([section isEqualToString:@"tags"])
    {
        cell.textLabel.text = \
            (self.infoBundle.postContents.tags)[indexPath.row];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    else if ([section isEqualToString:@"communities"])
    {
        cell.textLabel.text = \
            (self.infoBundle.postContents.communities)[indexPath.row];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    else if ([section isEqualToString:@"location"])
    {
        if (self.infoBundle.postContents.validCoordinates)
        {
            /*
             * Really I should add the mapview above and just adjust its
             * location here. --- But since there's only one map, there's
             * no point.
             */
        }
        else
        {
            cell.textLabel.text = self.infoBundle.postContents.location;
        }
    }
    else if ([section isEqualToString:@"authorview"])
    {
        cell.textLabel.text = self.infoBundle.postContents.display_name;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        if (self.infoBundle.userContents.image != nil) /* if authorview is there, then this isn't NULL */
        {
            CGSize shrink = CGSizeMake(self.tableView.rowHeight, self.tableView.rowHeight);

            UIGraphicsBeginImageContext(shrink);
            [self.infoBundle.userContents.image drawInRect:CGRectMake(0, 0, shrink.width, shrink.height)];
            UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();

            cell.imageView.image = newImage;
            cell.imageView.layer.cornerRadius = 9.0;
            cell.imageView.layer.masksToBounds = YES;

            cell.detailTextLabel.text = self.infoBundle.userContents.realish_name;
        }
    }
    else
    {
        cell.textLabel.text = @"";
    }

    return cell;
}

#pragma mark - Table view delegate

- (void)mapSelector:(UIGestureRecognizer *)gestureRecognizer
{
    int section = 0;
    
    for (NSString *sec in self.infoBundle.sections)
    {
        if ([sec isEqualToString:@"location"])
        {
            [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
            break;
        }

        section += 1;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIActionSheet *sheet = nil;
    
    NSString *section = (self.infoBundle.sections)[indexPath.section];

    if ([section isEqualToString:@"communities"])
    {
        self.selectedRow = indexPath.row;
        self.selectedPath = indexPath;
        sheet = [[UIActionSheet alloc] initWithTitle:nil
                                            delegate:self
                                   cancelButtonTitle:@"Cancel"
                              destructiveButtonTitle:nil
                                   otherButtonTitles:@"Pivot", @"Join", nil];
        
        [sheet showInView:self.view];
        // If they select either pivot or join it calls dismiss.
    }
    else if ([section isEqualToString:@"tags"])
    {
        [pivotDelegate handlePivot:@"tag"
                         withValue:(self.infoBundle.postContents.tags)[indexPath.row]];

        [self dismiss];
    }
    else if ([section isEqualToString:@"location"])
    {
        if (self.infoBundle.postContents.validCoordinates)
        {
            PostLocationViewController *pview = [[PostLocationViewController alloc] init];

            pview.center = self.infoBundle.postContents.coordinate;
            pview.postInfo = self.infoBundle.postContents;

            [self.navigationController pushViewController:pview animated:YES];
        }
    }
    else if ([section isEqualToString:@"replies"])
    {
        [pivotDelegate handlePivot:@"reply_to"
                         withValue:self.infoBundle.postContents.postid];

        [self dismiss];
    }
    else if ([section isEqualToString:@"replyto"])
    {
        [pivotDelegate handlePivot:@"get"
                         withValue:self.infoBundle.postContents.reply_to];

        [self dismiss];
    }
    else if ([section isEqualToString:@"repostof"])
    {
        [pivotDelegate handlePivot:@"get"
                         withValue:self.infoBundle.postContents.repost_of];
        
        [self dismiss];
    }
    else if ([section isEqualToString:@"reposts"])
    {
        [pivotDelegate handlePivot:@"repost_of"
                         withValue:self.infoBundle.postContents.postid];
        
        [self dismiss];
    }
    else if ([section isEqualToString:@"authorview"])
    {
        UserTableViewController *cview = \
            [[UserTableViewController alloc] initWithStyle:UITableViewStyleGrouped];

        cview.fromPost = YES;
        cview.userCache = self.userCache;
        cview.pivotDelegate = self.pivotDelegate;
        
        cview.userPtr = self.userCache[self.infoBundle.postContents.author];

        cview.readOnly = YES;
        cview.meIdentifier = self.meIdentifier;
        
        cview.title = self.infoBundle.userContents.display_name;

        [self.apiManager cancelAll]; // in case they pivot from the user view.
        [self.navigationController pushViewController:cview animated:YES];
    }
    
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
        (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:identifier];

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

@end
