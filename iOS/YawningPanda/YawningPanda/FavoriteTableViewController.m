//
//  FavoriteTableViewController.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/12/12.
//
//

#import "FavoriteTableViewController.h"
#import "EventLogEntry.h"
#import "Post.h"
#import "Util.h"

#import <QuartzCore/QuartzCore.h>

@implementation FavoriteTableViewController

@synthesize favIcons;
@synthesize apiManager;
@synthesize readOnly, busyWaiting, navigationStatus;
@synthesize userIdentifier;
@synthesize eventLogPtr;
@synthesize localFavorites;
@synthesize selected;
@synthesize pivotDelegate, unfavoriteDelegate;
@synthesize receivedResults;
@synthesize pull;
@synthesize meIdentifier;

/******************************************************************************
 * Delegate Callbacks
 ******************************************************************************/

#pragma mark - Delegate Callbacks

- (void)refreshData
{
    [self.apiManager cancelAll];

    self.receivedResults = YES;
    [self.localFavorites removeAllObjects];
    [self.tableView reloadData];

    [self.apiManager userQuery:self.userIdentifier
                   withRequest:@"favorites"
                        asUser:self.meIdentifier];
    
    return;
}

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view;
{
    //[self refreshData];
    
    [self performSelectorOnMainThread:@selector(refreshData)
                           withObject:nil
                        waitUntilDone:YES];
    
    /*
     * Refresh all the queries... what about outstanding ones?  well there
     * can't really be if it refreshes onload.
     */
}

- (void)apihandler:(APIHandler *)apihandler didFail:(enum APICall)type
{
    [self.apiManager dropHandler:apihandler];
    if ([self.apiManager outStanding] == 0)
    {
        [pull finishedLoading];
    }
    
    NSLog(@"Failed on type: %d", type);
    
    return;
}

- (void)apihandler:(APIHandler *)apihandler didCompleteQuery:(NSMutableArray *)data
            asUser:(NSString *)theUser
{
    [self.apiManager dropHandler:apihandler];
    if ([self.apiManager outStanding] == 0)
    {
        [pull finishedLoading];
    }

    if (data == nil || [data count] == 0)
    {
        NSLog(@"Query returned empty results.");
        return;
    }

    Post *post = data[0];

    (self.posts)[post.postid] = data[0];

    [self updateTable:post.postid];

    return;
}

- (void)apihandler:(APIHandler *)apihandler didCompleteUserQuery:(NSMutableArray *)data
         withQuery:(NSString *)query
           forUser:(NSString *)user
            asUser:(NSString *)theUser
{
    [self.apiManager dropHandler:apihandler];
    if ([data count] == 0)
    {
        [pull finishedLoading];
    }

    self.receivedResults = YES;
    
    [self.localFavorites removeAllObjects];
    [self.localFavorites addObjectsFromArray:data];

    [self.tableView reloadData];

    /* 
     * XXX: If the list is like 500, then this isn't great, but then again I 
     * have to add a caching mechanism AND check it to make sure I didn't 
     * already try to download it.
     */
    int newOutstanding = 0;
    
    for (NSString *post in data)
    {
        if (self.favIcons[post] == nil)
        {
            [self.apiManager viewThumbnail:post];
            newOutstanding += 1;
        }

        if (self.posts[post] == nil)
        {
            [self.apiManager getPost:post asUser:self.userIdentifier];
            newOutstanding += 1;
        }
    }
    
    /* 
     * If we didn't fire off anymore queries, call finish loading.  If we did,
     * then this will happen when they call finish.
     */
    if (0 == newOutstanding)
    {
        [pull finishedLoading];
    }

    return;
}

- (void)apihandler:(APIHandler *)apihandler didCompleteUnFavorite:(bool)success
           forPost:(NSString *)postid
            asUser:(NSString *)theUser
{
    [self.apiManager dropHandler:apihandler];
    if ([self.apiManager outStanding] == 0)
    {
        [pull finishedLoading];
    }

    if (success)
    {
        EventLogEntry *event = [[EventLogEntry alloc] init];
        event.eventType = EVENT_TYPE_UNFAVORITE;
        event.note = [NSString stringWithFormat:@"unfavorited: %@", postid];

        [self.eventLogPtr insertObject:event atIndex:0];
        
        [unfavoriteDelegate handleUnfavoritedPost:postid];
    }
    
    self.busyWaiting = NO;
    
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
    if ([self.apiManager outStanding] == 0)
    {
        [pull finishedLoading];
    }

    if (image == nil)
    {
        NSLog(@"Failed to download thumbnail for: %@", postid);
        return;
    }

    /* interesting that the rowHeight here remains the same. */
    CGSize shrink = CGSizeMake(self.tableView.rowHeight, self.tableView.rowHeight);
    UIGraphicsBeginImageContext(shrink);
    [image drawInRect:CGRectMake(0, 0, shrink.width, shrink.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    (self.favIcons)[postid] = newImage;

    [self updateTable:postid];

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
    NSString *postid = nil;
    Post *post = nil;

    postid = (self.localFavorites)[self.selected.row];
    post = self.posts[postid];

    NSLog(@"%@", [NSString stringWithFormat:@"You selected: [%d]:'%@'",
                  buttonIndex,
                  [actionSheet buttonTitleAtIndex:buttonIndex]]);
    
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];

    [self.tableView deselectRowAtIndexPath:self.selected animated:YES];

    if ([buttonTitle isEqualToString:@"Cancel"])
    {
        return;
    }
    
    [self.apiManager cancelAll];
    
    /* They want the snapshot/get */
    if (buttonIndex == 0)
    {
        [pivotDelegate handlePivot:@"get" withValue:postid];
    }
    else
    {
        [pivotDelegate handlePivot:@"tag"
                         withValue:(post.tags)[buttonIndex - 1]];
    }
    
    [self dismissModalViewControllerAnimated:YES];

    return;
}

/******************************************************************************
 * Button Handlers
 ******************************************************************************/

/* For certain buttons I think I can honestly just set them to call dismiss:YES */
- (IBAction)dismiss
{
    NSLog(@"Dismissing.");
    
    if (self.busyWaiting)
    {
        return;
    }
    
    [self.apiManager cancelAll];
    [self.navigationController popViewControllerAnimated:YES];
}

/******************************************************************************
 * Normal View Loading Code
 ******************************************************************************/

#pragma mark - View Life Cycle

- (void)updateTable:(NSString *)postid
{
    int favoriteCount = [self.localFavorites count];

    for (int i = 0; i < favoriteCount; i++)
    {
        if ([(self.localFavorites)[i] isEqualToString:postid])
        {
            /* This gives us the row. */
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];

            [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];

            break;
        }
    }

    return;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];

    if (self)
    {
        // Custom initialization
        self.apiManager = [[APIManager alloc] initWithDelegate:self];
        self.favIcons = [[NSMutableDictionary alloc] init];
        self.localFavorites = [[NSMutableArray alloc] init];
        self.posts = [[NSMutableDictionary alloc] init];
        
        self.receivedResults = NO;
        self.navigationStatus = NO;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;

    self.navigationItem.title = @"Favorites";
    
    UIBarButtonItem *backBtn = nil;

    if (self.readOnly)
    {
        // navigationBar:didPopItem: maybe overload this?
        backBtn = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                   style:UIBarButtonItemStylePlain
                                                  target:self
                                                  action:@selector(dismiss)];
    }
    else
    {
        backBtn = [[UIBarButtonItem alloc] initWithTitle:@"You"
                                                   style:UIBarButtonItemStylePlain
                                                  target:self
                                                  action:@selector(dismiss)];
        
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
    }

    self.navigationItem.leftBarButtonItems = @[backBtn];

    self.pull = [[PullToRefreshView alloc] initWithScrollView:self.tableView];
    self.pull.delegate = self;
    [self.tableView addSubview:self.pull];

    self.tableView.contentOffset = CGPointMake(0, -65);
    [pull setState:PullToRefreshViewStateLoading];

    [self.apiManager userQuery:self.userIdentifier
                   withRequest:@"favorites"
                        asUser:self.meIdentifier];

    return;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.

    [self.apiManager cancelAll];
    
    [self.localFavorites removeAllObjects];
    [self.posts removeAllObjects];
    [self.favIcons removeAllObjects];
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"numberOfRowsInSection");
    
    // Return the number of rows in the section.
    if ([self.localFavorites count] == 0)
    {
        return 1;
    }

    return [self.localFavorites count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    static NSString *CellIdentifier2 = @"Cell2";

    UITableViewCell *cell = nil;
    UIImage *tmp = nil;
    Post *tmpPost = nil;
    NSString *postId = nil;

    // Configure the cell...
    if ([self.localFavorites count] == 0 && self.receivedResults == NO)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier2];
        
        /* This builds a lovely download spinner thing. */
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:CellIdentifier2];
            
            UIActivityIndicatorView *spinner = \
                [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            CGRect frm = CGRectMake((cell.frame.size.width / 2) - (self.tableView.rowHeight / 2),
                                    1,
                                    self.tableView.rowHeight,
                                    self.tableView.rowHeight);
            
            [spinner setFrame:frm];
            [spinner startAnimating];
            
            [cell addSubview:spinner];
            
            return cell;
        }
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:CellIdentifier];
        }
    }
    
    cell.imageView.image = nil;
    cell.detailTextLabel.text = @"";

    if ([self.localFavorites count] == 0 && self.receivedResults == YES)
    {
        cell.textLabel.text = @"No Favorite Posts";
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        return cell;
    }
    
    postId = (self.localFavorites)[indexPath.row];

    if (postId != nil)
    {
        cell.textLabel.text = @"-";
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        
        tmpPost = self.posts[postId];
        if (tmpPost != nil)
        {
            cell.textLabel.text = [tmpPost.tags componentsJoinedByString:@", "];
        }

        tmp = self.favIcons[postId];
        if (tmp != nil)
        {
            //CGRect myCropRect = CGRectMake(0, 0, tableView.rowHeight, tableView.rowHeight);
            //CGImageRef myImageRef = CGImageCreateWithImageInRect([tmp CGImage], myCropRect);
            //UIImage *myImage = [UIImage imageWithCGImage:myImageRef];
            //CGImageRelease(myImageRef);

            CGRect frm = CGRectMake(cell.imageView.frame.origin.x,
                                    cell.imageView.frame.origin.y,
                                    tableView.rowHeight,
                                    tableView.rowHeight);

            //[Util printRectangle:frm];

            //cell.imageView.image = myImage;

            cell.imageView.frame = frm;
            cell.imageView.image = tmp;

            cell.imageView.layer.cornerRadius = 9.0;
            cell.imageView.layer.masksToBounds = YES;
            cell.imageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
            cell.imageView.layer.borderWidth = 1.0;

            cell.imageView.autoresizingMask = \
                UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
            cell.imageView.clipsToBounds = YES;

  //          cell.imageView.autoresizesSubviews = YES;
//            [cell.imageView sizeToFit];

//            cell.autoresizesSubviews = YES;
        }
        else
        {
            cell.imageView.image = nil;

          //  [self.activity startAnimating];
          //  [self.apiManager viewThumbnail:postId];
        }
    }

    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    if (self.readOnly)
    {
        return NO;
    }
    
    if (self.receivedResults == YES && [self.localFavorites count] == 0)
    {
        return NO;
    }
    
    return YES;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Un-Favorite";
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSLog(@"Delete!");
        
        NSString *postid = (self.localFavorites)[indexPath.row];

        [tableView beginUpdates];

        self.busyWaiting = YES;

        // Delete the row from the data source
        [self.favIcons removeObjectForKey:postid];
        [self.localFavorites removeObjectAtIndex:indexPath.row];
        [self.apiManager unfavoritePost:postid asUser:self.userIdentifier];

        NSLog(@"Deleting entry.");
        
        if ([self.localFavorites count] == 0)
        {
            [tableView reloadData];
        }
        else
        {
            [tableView deleteRowsAtIndexPaths:@[indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
        }
        
        [tableView endUpdates];
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    NSString *post = nil;
    Post *tmpPost = nil;
    
    if ([self.localFavorites count] == 0 && self.receivedResults == YES)
    {
        return;
    }

    post = (self.localFavorites)[indexPath.row];

    tmpPost = self.posts[post];
    if (tmpPost == nil)
    {
        return;
    }

    self.selected = indexPath;

    UIActionSheet *sheet = nil;

    sheet = [[UIActionSheet alloc] initWithTitle:@"View Item:"
                                        delegate:self
                               cancelButtonTitle:nil
                          destructiveButtonTitle:nil
                               otherButtonTitles:nil];
    
    [sheet addButtonWithTitle:@"Display Post"];
    for (NSString *tmp in tmpPost.tags)
    {
        [sheet addButtonWithTitle:[NSString stringWithFormat:@"Pivot on %@",
                                   tmp]];
    }
    [sheet addButtonWithTitle:@"Cancel"];
    
    [sheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
    [sheet setCancelButtonIndex:(1 + [tmpPost.tags count])];

    [sheet showInView:self.view];
    
    return;
}

@end
