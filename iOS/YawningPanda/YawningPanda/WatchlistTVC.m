//
//  WatchlistTVC.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/20/12.
//
//

#import "WatchlistTVC.h"
#import "APIHandler.h"
#import "EventLogEntry.h"
#import "Util.h"

#import <QuartzCore/QuartzCore.h>

@implementation WatchlistTVC

@synthesize eventLogPtr;
@synthesize watchlist;
@synthesize userIdentifier, userCache;
@synthesize delegate;
@synthesize readOnly;
@synthesize busyWaiting;
@synthesize watchlistProper;
@synthesize apiManager;
@synthesize userIcons;
@synthesize meIdentifier;
@synthesize pull;
@synthesize outStanding;

/******************************************************************************
 * Pull-to-Refresh Code
 ******************************************************************************/

#pragma mark - Pull-to-Refresh Code

- (void)refreshData
{
    [self.apiManager cancelAll];

    [self.apiManager userQuery:self.userIdentifier
                   withRequest:@"watchlist"
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
    return;
}

/******************************************************************************
 * Delegate Callbacks
 ******************************************************************************/

#pragma mark - Delegate Callbacks

- (void)apihandler:(APIHandler *)apihandler didFail:(enum APICall)type
{
    [self.apiManager dropHandler:apihandler];
    
    if (API_USER_QUERY == type)
    {
        /* the refresh query failed... */
        /* maybe add layer with failure info that fades out. */
        [pull finishedLoading];
    }
    else
    {
        self.outStanding -= 1;
        if (self.outStanding == 0)
        {
            [pull finishedLoading];
        }
    }

    return;
}

- (void)apihandler:(APIHandler *)apihandler didCompleteUserQuery:(NSMutableArray *)data
         withQuery:(NSString *)query
           forUser:(NSString *)user
            asUser:(NSString *)theUser
{
    /* for each user returned in data, check if they have the view and info. */
    /* if they have the view and info, we don't re-download. */
    /* if it's not readonly we need to update the watchlist thing. */
    NSLog(@"didcomplete user query returned.");
    
    if ([data count] == 0)
    {
        [pull finishedLoading];
        
        return;
    }
    
    NSMutableArray *drop = [[NSMutableArray alloc] init];

    if (self.readOnly)
    {
        for (NSString *userId in self.watchlist)
        {
            if (![data containsObject:userId])
            {
                [drop addObject:userId];
            }
        }
        
        for (NSString *userId in data)
        {
            if (![self.watchlist containsObject:userId])
            {
                self.outStanding += 2;
                [self.watchlist addObject:userId];
                
                [self.apiManager userView:userId];
                [self.apiManager getAuthor:userId asUser:self.meIdentifier];
            }
        }
        
        for (NSString *userId in drop)
        {
            [self.watchlist removeObject:userId];
        }
        
        User *them = self.userCache[self.userIdentifier];
        them.watching = [self.watchlist count];
    }
    else
    {
        for (NSString *userId in self.watchlistProper.userids)
        {
            if (![data containsObject:userId])
            {
                [drop addObject:userId];
            }
        }
        
        for (NSString *userId in data)
        {
            if (![self.watchlistProper.userids containsObject:userId])
            {
                self.outStanding += 2;
                [self.watchlistProper.userids addObject:userId];
                
                [self.apiManager userView:userId];
                [self.apiManager getAuthor:userId asUser:self.meIdentifier];
            }
        }
        
        for (NSString *userId in drop)
        {
            [self.watchlistProper.userids removeObject:userId];

        }
        
        [self.watchlistProper.avatars removeObjectsForKeys:drop];
        [self.watchlistProper.screennames removeObjectsForKeys:drop];

        /* should still be ok as userIdentifier, they should match. */
        User *them = self.userCache[self.meIdentifier];
        them.watching = [self.watchlist count];
    }
    
    if (self.outStanding == 0)
    {
        [pull finishedLoading];
    }

    return;
}

/*
 * XXX: This should really just build a watchlist object, ya know, fill it in.
 */

- (void)apihandler:(APIHandler *)apihandler didCompleteName:(User *)details
        withAuthor:(NSString *)authorid
            asUser:(NSString *)theUser
{
    [self.apiManager dropHandler:apihandler];

    self.outStanding -= 1;
    if (self.outStanding == 0)
    {
        [pull finishedLoading];
    }
    
    if (details == nil)
    {
        return;
    }
    
    (self.userNames)[details.userid] = details;
    
    [self updateRows:details.userid];
    
    return;
}

/**
 * @brief This is called when a user image is downloaded.
 *
 * @param image the image content or nil if there was no image for the user;
 * should use a default avatar.
 * @param userid the user's image.
 *
 * @note These images are a bit small so there's no issue in keeping them or
 * re-downloading them.
 */
- (void)apihandler:(APIHandler *)apihandler didCompleteUserView:(UIImage *)image
          withUser:(NSString *)userid
{
    [self.apiManager dropHandler:apihandler];
    self.outStanding -= 1;
    if (self.outStanding == 0)
    {
        [pull finishedLoading];
    }
    
    NSLog(@"completed userview: %@ for %@", image, userid);
    
    if (image == nil)
    {
        return;
    }

    CGSize shrink = CGSizeMake(self.tableView.rowHeight, self.tableView.rowHeight);

    UIGraphicsBeginImageContext(shrink);
    [image drawInRect:CGRectMake(0, 0, shrink.width, shrink.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    (self.userIcons)[userid] = newImage;
    
    [self updateRows:userid];
    
    return;
}

- (void)apihandler:(APIHandler *)apihandler didCompleteUnWatch:(bool)success
          withUser:(NSString *)userid
            asUser:(NSString *)theUser
{
    EventLogEntry *event = [[EventLogEntry alloc] init];
    event.eventType = EVENT_TYPE_UNWATCH;
    event.note = [NSString stringWithFormat:@"unwatched: %@", userid];
    
    [self.eventLogPtr insertObject:event atIndex:0];
    
    self.busyWaiting = NO;
    
    return;
}

/******************************************************************************
 * Button Handlers
 ******************************************************************************/

#pragma mark - Button Handlers

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

- (void)updateRows:(NSString *)userid
{
    int userCount;
    int i = 0;

    if (self.readOnly)
    {
        userCount = [self.watchlist count];

        for (i = 0; i < userCount; i++)
        {
            if ([(self.watchlist)[i] isEqualToString:userid])
            {
                break;
            }
        }
    }
    else
    {
        userCount = [self.watchlistProper.userids count];

        for (i = 0; i < userCount; i++)
        {
            if ([(self.watchlistProper.userids)[i] isEqualToString:userid])
            {
                break;
            }
        }
    }

    /* This gives us the row. */
    NSIndexPath *indexPath1 = [NSIndexPath indexPathForRow:i inSection:0];

    [self.tableView reloadRowsAtIndexPaths:@[indexPath1]
                          withRowAnimation:UITableViewRowAnimationAutomatic];

    return;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    
    if (self)
    {
        // Custom initialization
        self.apiManager = [[APIManager alloc] initWithDelegate:self];
        self.userIcons = [[NSMutableDictionary alloc] init];
        self.userNames = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.title = @"Watching";
    
    UIBarButtonItem *backBtn = nil;
    
    if (self.readOnly)
    {
        backBtn = \
        [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(dismiss)];
    }
    else
    {
        backBtn = \
        [[UIBarButtonItem alloc] initWithTitle:@"You"
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
    
    self.outStanding = 0;
    
    bool kickedOff = NO;

    if (self.readOnly)
    {
        if ([self.watchlist count] > 0)
        {
            kickedOff = YES;

            for (NSString *user in self.watchlist)
            {
                self.outStanding += 2;
                [self.apiManager userView:user];
                [self.apiManager getAuthor:user asUser:self.meIdentifier];
            }
        }
    }
    else
    {
        if ([self.watchlistProper.userids count] > 0)
        {
            kickedOff = YES;

            for (NSString *user in self.watchlistProper.userids)
            {
                self.outStanding += 2;
                [self.apiManager userView:user];
                [self.apiManager getAuthor:user asUser:self.meIdentifier];
            }
        }
    }
    
    /* No questions asked... */
    if (NO == kickedOff)
    {
        [pull finishedLoading];
    }

    return;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [self.apiManager cancelAll];
    [self.userIcons removeAllObjects];
    [self.userNames removeAllObjects];
    
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
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Select to Pivot";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (self.readOnly)
    {
        return [self.watchlist count];
    }
    
    return [self.watchlistProper.userids count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if (cell == nil)
    {
        cell = \
            [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                   reuseIdentifier:CellIdentifier];
    }

    cell.imageView.image = nil;
    cell.detailTextLabel.text = @"";
    NSString *userid = nil;

    if (self.readOnly)
    {
        userid = (self.watchlist)[indexPath.row];
    }
    else // this isn't quite necessary to do this way.
    {
        userid = (self.watchlistProper.userids)[indexPath.row];
    }

    cell.textLabel.text = userid;

    UIImage *tmp = (self.userIcons)[userid];
    if (tmp != nil)
    {
        cell.imageView.image = tmp;
        cell.imageView.contentMode = UIViewContentModeScaleToFill;
        cell.imageView.layer.cornerRadius = 9.0;
        cell.imageView.layer.masksToBounds = YES;
    }

    User *tmpN = (self.userNames)[userid];
    if (tmpN != nil)
    {
        cell.textLabel.text = tmpN.display_name;
        cell.detailTextLabel.text = tmpN.realish_name;
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
    
    return YES;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Unwatch";
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSLog(@"Delete!");
        
        [tableView beginUpdates];
        
        NSString *userid = (self.watchlistProper.userids)[indexPath.row];
        self.busyWaiting = YES;
        
        /* The only thing that can't get canceled. */
        [[Util getHandler:self] unwatchUser:self.userIdentifier
                              unwatchesUser:userid];
        
        // Delete the row from the data source
        [self.watchlistProper.userids removeObjectAtIndex:indexPath.row];
        [self.watchlistProper.screennames removeObjectForKey:userid];
        [self.watchlistProper.avatars removeObjectForKey:userid];
        
        if ([self.watchlistProper.userids count] == 0)
        {
            [tableView reloadData];
        }
        else
        {
            NSLog(@"Deleting entry.");
            [tableView deleteRowsAtIndexPaths:@[indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
        }
        
        [tableView endUpdates];
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.readOnly)
    {
        NSLog(@"readonly author pivot: %@", (self.watchlist)[indexPath.row]);
        [delegate handlePivot:@"author"
                    withValue:(self.watchlist)[indexPath.row]]; /* technically a faster pivot */
    }
    else
    {
        NSLog(@"nonreadonly author pivot: %@", (self.watchlistProper.userids)[indexPath.row]);
        [delegate handlePivot:@"author"
                    withValue:(self.watchlistProper.userids)[indexPath.row]]; /* technically a faster pivot */
    }
    
    [self.apiManager cancelAll];
    [self dismissModalViewControllerAnimated:YES];
    
    return;
}

@end
