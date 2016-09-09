//
//  TableOfContentsViewController.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 12/30/12.
//
//

#import "TableOfContentsViewController.h"

#import "Post.h"
#import "Util.h"

#import "PivotDetails.h"

#import "ImageSpinner.h"
#import "UITableCell.h"

#import <QuartzCore/QuartzCore.h>

/** @brief How many seconds old a stream gets before we update it on reload. */
#define STALE_INTERVAL 150
/** @brief The gap between things. */
#define MARGIN 10

@implementation TableOfContentsViewController

@synthesize watching, communities;
@synthesize queryResults;
@synthesize apiManager, userIdentifier;
@synthesize currentTag;
@synthesize outstanding;

@synthesize pull;

/******************************************************************************
 * Pull-to-Refresh Code
 ******************************************************************************/

#pragma mark - Pull-to-Refresh Code

- (void)refreshData
{
    [self.apiManager cancelAll];
    self.outstanding = 0;
    
    for (NSMutableDictionary *dict in self.queryResults[@"Watching"])
    {
        [dict removeObjectForKey:@"thumbnail"];
        
        self.outstanding += 1;
        if (dict[@"results"] != nil)
        {
            Post *post = (Post *)dict[@"results"][0];
            
            [self.apiManager queryPosts:@"author"
                              withValue:dict[@"identifier"]
                                 asUser:self.userIdentifier
                                 withID:dict[@"key"]
                                  since:post.postid];
        }
        else
        {
            [self.apiManager queryPosts:@"author"
                              withValue:dict[@"identifier"]
                                 asUser:self.userIdentifier
                                 withID:dict[@"key"]];
        }
    }

    for (NSMutableDictionary *dict in self.queryResults[@"Communities"])
    {
        [dict removeObjectForKey:@"thumbnail"];
        
        self.outstanding += 1;
        if (dict[@"results"] != nil)
        {
            Post *post = (Post *)dict[@"results"][0];
            
            [self.apiManager queryPosts:@"community"
                              withValue:dict[@"identifier"]
                                 asUser:self.userIdentifier
                                 withID:dict[@"key"]
                                  since:post.postid];
        }
        else
        {
            [self.apiManager queryPosts:@"community"
                              withValue:dict[@"identifier"]
                                 asUser:self.userIdentifier
                                 withID:dict[@"key"]];
        }
    }
    
    [self.tableView reloadData];
    
    /** @todo You need to maybe cancel any outstanding API calls. */
    //[pull finishedLoading];

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

/******************************************************************************
 * Utility Code
 ******************************************************************************/

#pragma mark - Utility Code

/**
 * @brief Checks to see if you're missing a stream or if any are already 
 * out-of-date.
 */
- (void)checkStaleMissing:(NSMutableDictionary *)dict withPivot:(NSString *)pivot
{
    /**
     * @todo: This always refreshes, but doesn't identify it as
     * a refresh, so it doesn't just pre-pend.
     */
    double interval = [[NSDate date] timeIntervalSinceDate:dict[@"date"]];
    if (interval > STALE_INTERVAL || dict[@"results"] == nil)
    {
        [dict removeObjectForKey:@"thumbnail"];
        
        self.outstanding += 1;
        if (dict[@"results"] != nil)
        {
            Post *post = (Post *)dict[@"results"][0];
            
            [self.apiManager queryPosts:pivot
                              withValue:dict[@"identifier"]
                                 asUser:self.userIdentifier
                                 withID:dict[@"key"]
                                  since:post.postid];
        }
        else
        {
            [self.apiManager queryPosts:pivot
                              withValue:dict[@"identifier"]
                                 asUser:self.userIdentifier
                                 withID:dict[@"key"]];
        }
    }
    else if (dict[@"thumbnail"] == nil)
    {
        NSArray *data = dict[@"results"];
        
        if ([data count] > 0)
        {
            Post *post = (Post *)data[0];
            
            self.outstanding += 1;
            [self.apiManager viewThumbnail:post.postid
                                    withID:dict[@"key"]];
        }
    }

    return;
}

/**
 * @brief Called in the background initially while loading.
 *
 * @todo Maybe NavigationCache should store everything!
 */
- (void)initialLoad
{
    /* This code is nearly identical... to the community version... ugh. */
    if ([self.watching count] > 0)
    {
        /*
         * First load, basically ever.  We'll need to consider also adding,
         * and removing entries so the data doesn't get stale.  Of interest, if
         * you are in like fifty million communities --- this could be a
         * problem.
         */
        if (self.queryResults[@"Watching"] == nil)
        {
            NSMutableArray *watches = [[NSMutableArray alloc] init];
            NSMutableArray *shorts = [[NSMutableArray alloc] init];
            
            self.queryResults[@"Watching"] = watches;
            self.queryResults[@"watch-shorts"] = shorts;
            
            for (NSString *user in self.watching.userids)
            {
                NSMutableDictionary *userdict = [[NSMutableDictionary alloc] init];
                
                userdict[@"identifier"] = user;
                userdict[@"key"] = [NSString stringWithFormat:@"watch=%@", user];
                
                [watches addObject:userdict];
                [shorts addObject:user];
                
                self.outstanding += 1;
                [self.apiManager queryPosts:@"author"
                                  withValue:user
                                     asUser:self.userIdentifier
                                     withID:userdict[@"key"]];
            }
        }
        else
        {
            /* They already have results. */
            NSMutableArray *watches = self.queryResults[@"Watching"];
            NSMutableArray *shorts = self.queryResults[@"watch-shorts"];
            
            /* Remove Old & Update Stale */
            for (NSMutableDictionary *dict in watches)
            {
                if (![self.watching.userids containsObject:dict[@"identifier"]])
                {
                    [watches removeObject:dict];
                    [shorts removeObject:dict[@"identifier"]];
                }
                else
                {
                    /* Check if it's stale. */
                    [self checkStaleMissing:dict withPivot:@"author"];
                }
            }
            
            /* Add New. */
            for (NSString *user in self.watching.userids)
            {
                if (![shorts containsObject:user])
                {
                    NSMutableDictionary *userdict = [[NSMutableDictionary alloc] init];
                    
                    userdict[@"identifier"] = user;
                    userdict[@"key"] = [NSString stringWithFormat:@"watch=%@", user];
                    
                    NSLog(@"Adding new watchlist stream: %@", userdict);
                    
                    [watches addObject:userdict];
                    [shorts addObject:user];
                    
                    self.outstanding += 1;
                    [self.apiManager queryPosts:@"author"
                                      withValue:user
                                         asUser:self.userIdentifier
                                         withID:userdict[@"key"]];
                }
            }
        }
    }
    
    if ([self.communities count] > 0)
    {
        if (self.queryResults[@"Communities"] == nil)
        {
            NSMutableArray *watches = [[NSMutableArray alloc] init];
            /* This array can be used for quick lookups. */
            NSMutableArray *shorts = [[NSMutableArray alloc] init];
            
            self.queryResults[@"Communities"] = watches;
            self.queryResults[@"comms"] = shorts;
            
            for (NSArray *community in self.communities)
            {
                NSMutableDictionary *userdict = [[NSMutableDictionary alloc] init];
                NSString *commId = [community componentsJoinedByString:@","];
                
                userdict[@"identifier"] = commId;
                userdict[@"key"] = [NSString stringWithFormat:@"comm=%@", commId];
                
                [watches addObject:userdict];
                [shorts addObject:commId];
                
                self.outstanding += 1;
                [self.apiManager queryPosts:@"community"
                                  withValue:commId
                                     asUser:self.userIdentifier
                                     withID:userdict[@"key"]];
            }
        }
        else
        {
            /* They already have results. */
            NSMutableArray *watches = self.queryResults[@"Communities"];
            NSMutableArray *shorts = self.queryResults[@"comms"];
            
            /* Remove Old & Update Stale */
            for (NSMutableDictionary *dict in watches)
            {
                NSString *commId = dict[@"identifier"];
                
                if (![self.communities containsObject:[commId componentsSeparatedByString:@","]])
                {
                    [watches removeObject:dict];
                    [shorts removeObject:dict[@"identifier"]];
                }
                else
                {
                    /* Check if it's stale. */
                    [self checkStaleMissing:dict withPivot:@"community"];
                }
            }
            
            /* Add New. */
            for (NSArray *community in self.communities)
            {
                NSString *commId = [community componentsJoinedByString:@","];
                
                if (![shorts containsObject:commId])
                {
                    NSMutableDictionary *userdict = [[NSMutableDictionary alloc] init];
                    
                    userdict[@"identifier"] = commId;
                    userdict[@"key"] = [NSString stringWithFormat:@"comm=%@", commId];
                    
                    NSLog(@"Adding new community stream: %@", userdict);
                    
                    [watches addObject:userdict];
                    [shorts addObject:commId];

                    self.outstanding += 1;
                    [self.apiManager queryPosts:@"community"
                                      withValue:commId
                                         asUser:self.userIdentifier
                                         withID:userdict[@"key"]];
                }
            }
        }
    }
    
    return;
}

/******************************************************************************
 * Delegate Callbacks
 ******************************************************************************/

#pragma mark - Delegate Callbacks

- (void)apihandler:(APIHandler *)apihandler didFail:(enum APICall)type
{
    [self.apiManager dropHandler:apihandler];
    
    self.outstanding -= 1;
    if (self.outstanding == 0)
    {
        [pull finishedLoading];
    }
}

- (void)apihandler:(APIHandler *)apihandler didCompleteQuery:(NSMutableArray *)data
            asUser:(NSString *)theUser
{
    [self.apiManager dropHandler:apihandler];
    self.outstanding -= 1;
    
    if (data == nil)
    {
        return;
    }

    NSArray *details = [apihandler.callerIdentifier componentsSeparatedByString:@"="];

    NSLog(@"didCompleteQuery: details: %@", apihandler.callerIdentifier);

    if ([details[0] isEqualToString:@"watch"])
    {
        /* It was a watch query. */
        NSMutableArray *watches = self.queryResults[@"Watching"];

        for (NSMutableDictionary *userdict in watches)
        {
            /** @todo Could use key. */
            if ([userdict[@"identifier"] isEqualToString:details[1]])
            {
                NSMutableArray *ldata = userdict[@"results"];
                userdict[@"refresh"] = [NSNumber numberWithInteger:[data count]];
                
                if (ldata != nil)
                {
                    NSLog(@"Refresh returned!: %d", [data count]);
                    [ldata replaceObjectsInRange:NSMakeRange(0,0)
                            withObjectsFromArray:data];
                }
                else
                {
                    userdict[@"results"] = data;
                    ldata = userdict[@"results"]; /* set the pointer somewhere useful. */
                }
                
                userdict[@"date"] = [[NSDate alloc] init];
                
                NSInteger length = [ldata count];

                if (length > 0)
                {
                    Post *post = (Post *)ldata[0];

                    // this is identical to apihandler.callerIdentifier
                    self.outstanding += 1;
                    [self.apiManager viewThumbnail:post.postid
                                            withID:[NSString stringWithFormat:@"watch=%@", details[1]]];
                }

                if (length > 200)
                {
                    NSLog(@"Dropping items %d of %d", length - 200, length);
                    [ldata removeObjectsInRange:NSMakeRange(200, length - 200)];
                }
            }
        }
    }
    else if ([details[0] isEqualToString:@"comm"])
    {
        NSMutableArray *comms = self.queryResults[@"Communities"];

        for (NSMutableDictionary *commdict in comms)
        {
            if ([commdict[@"identifier"] isEqualToString:details[1]])
            {
                NSLog(@"Found matching identifier.");
                
                NSMutableArray *ldata = commdict[@"results"];
                commdict[@"refresh"] = [NSNumber numberWithInteger:[data count]];
                
                if (ldata != nil)
                {
                    NSLog(@"Refresh returned!: %d", [data count]);
                    [ldata replaceObjectsInRange:NSMakeRange(0,0)
                            withObjectsFromArray:data];
                }
                else
                {
                    commdict[@"results"] = data;
                    ldata = commdict[@"results"]; /* set the pointer somewhere useful. */
                }
                
                commdict[@"date"] = [[NSDate alloc] init];
                
                NSInteger length = [ldata count];

                NSLog(@"ldata length: %d", length);
                
                if (length > 0)
                {
                    Post *post = (Post *)ldata[0];
                    
                    NSLog(@"Downloading thumbnail for post: %@", post.postid);
                    self.outstanding += 1;
                    [self.apiManager viewThumbnail:post.postid
                                            withID:[NSString stringWithFormat:@"comm=%@", details[1]]];
                }

                if (length > 200)
                {
                    NSLog(@"Dropping items %d of %d", length - 200, length);
                    [ldata removeObjectsInRange:NSMakeRange(200, length - 200)];
                }
            }
        }
    }

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
    int i = 0;
    NSInteger numberPerRow = (NSInteger)floor((self.view.bounds.size.width - MARGIN) / (CELL_WIDTH + MARGIN));
    
    [self.apiManager dropHandler:apihandler];
    
    if (image == nil)
    {
        NSLog(@"Failed to download thumbnail for: %@", postid);
        return;
    }
    
    NSLog(@"Received Thumbnail for: %@, as %@", postid, apihandler.callerIdentifier);

    UIImage *newImage = [Util centerCrop:image withMax:THUMBNAIL_SIZE];

    NSArray *details = [apihandler.callerIdentifier componentsSeparatedByString:@"="];
    
    NSLog(@"details: %@", details);

    if ([details[0] isEqualToString:@"watch"])
    {
        /* It was a watch query. */
        NSMutableArray *watches = self.queryResults[@"Watching"];
        
        for (NSMutableDictionary *userdict in watches)
        {
            if ([userdict[@"identifier"] isEqualToString:details[1]])
            {
                userdict[@"thumbnail"] = newImage;
                
                /* cell == i, leveraging the flooring nature of integer division */
                NSInteger row = i / numberPerRow;
                
                /* This gives us the row. */
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
                
                [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            
            i++;
        }
    }
    else if ([details[0] isEqualToString:@"comm"])
    {
        NSLog(@"Community Detected");
        
        NSMutableArray *comms = self.queryResults[@"Communities"];
        
        for (NSMutableDictionary *commdict in comms)
        {
            if ([commdict[@"identifier"] isEqualToString:details[1]])
            {
                commdict[@"thumbnail"] = newImage;

                /* cell == i, leveraging the flooring nature of integer division */
                NSInteger row = i / numberPerRow;
                
                /* This gives us the row. */
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:1];
                
                [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            
            i++;
        }
    }
    
    self.outstanding -= 1;
    if (self.outstanding == 0)
    {
        [pull finishedLoading];
    }

    return;
}

/******************************************************************************
 * Button Handlers
 ******************************************************************************/

#pragma mark - Button Handlers

/**
 * @todo This is here because I don't know how to pass parameter values via
 * the selector method.
 */
- (void)dismissAnimated
{
    [self dismiss:YES];
}

- (void)dismiss:(BOOL)animated
{
    [self.apiManager cancelAll];

    [self dismissModalViewControllerAnimated:animated];
}

/******************************************************************************
 * Normal View Loading Code
 ******************************************************************************/

#pragma mark - Normal View Loading Code

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];

    if (self)
    {
        self.apiManager = [[APIManager alloc] initWithDelegate:self];
        self.headers = [[NSMutableArray alloc] init];
        
        [self.headers addObject:@"Watching"];
        [self.headers addObject:@"Communities"];
        self.outstanding = 0;
    }

    return self;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                         duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    NSLog(@"willAnimateRotationToInterfaceOrientation");
    
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem *backBtn = \
        [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                         style:UIBarButtonItemStyleDone
                                        target:self
                                        action:@selector(dismissAnimated)];

    self.navigationItem.leftBarButtonItem = backBtn;
    self.navigationItem.title = @"Your Streams";
    
    /** @todo If you're not watching anyone and have no communities then we 
     * need to display something special, like, Add some?  With a big plus sign 
     * or something.
     */

    self.currentTag = 901;

    /**
     * @todo If you canceled and had results but not downloaded the thumbnail 
     * yet, you'll need to detect it and download it.
     */

//    [self performSelectorInBackground:@selector(initialLoad) withObject:nil];
    // this doesn't work for what I'm doing, apparently.

    self.pull = [[PullToRefreshView alloc] initWithScrollView:self.tableView];
    self.pull.delegate = self;
    [self.tableView addSubview:self.pull];

    [self initialLoad];

    if (self.outstanding > 0)
    {
        self.tableView.contentOffset = CGPointMake(0, -65);
        [pull setState:PullToRefreshViewStateLoading];
    }

#if 0
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(foregroundRefresh:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
#endif

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
}

#if 0
-(void)foregroundRefresh:(NSNotification *)notification
{
    self.tableView.contentOffset = CGPointMake(0, -65);
    [pull setState:PullToRefreshViewStateLoading];
    [self performSelectorInBackground:@selector(reloadTableData) withObject:nil];
}
#endif

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [self.headers count];
}

/** @todo This is a temporary thing before I replace it with headerForSection. */
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.headers[section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*
     * ----10----
     * CELL_HEIGHT
     * ----10----
     */
    return (CELL_HEIGHT + MARGIN + MARGIN);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    /*
     * I account for the border to the left then add the right border to each 
     * thumbnail.
     */
    CGFloat numberPerRow = (NSInteger)floor((self.view.bounds.size.width - MARGIN) / (CELL_WIDTH + MARGIN));

    NSLog(@"numberPerRow: %f", numberPerRow);

    if ([self.headers[section] isEqualToString:@"Watching"])
    {
        NSInteger numberOfCells = [self.watching count];
        NSInteger numberOfRows = (NSInteger)ceil(numberOfCells / numberPerRow);

        NSLog(@"number of watchlist cells: %d, rows: %d", numberOfCells, numberOfRows);
        
        if (numberOfCells == 0)
        {
            return 1;
        }

        return numberOfRows;
    }
    else if ([self.headers[section] isEqualToString:@"Communities"])
    {
        NSInteger numberOfCells = [self.communities count];
        NSInteger numberOfRows = (NSInteger)ceil(numberOfCells / numberPerRow);

        NSLog(@"number of community cells: %d, rows: %d", numberOfCells, numberOfRows);
        
        if (numberOfCells == 0)
        {
            return 1;
        }

        return numberOfRows;
    }

    // Return the number of rows in the section.
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat numberPerRow = (NSInteger)floor((self.view.bounds.size.width - 10) / (CELL_WIDTH + 10));
    
    static NSString *CellIdentifier = @"VertCell";
    static NSString *CellIdentifier2 = @"HorizCell";
    
    UITableViewCell *cell = nil;
    BOOL newCell = NO;
    
    if (self.interfaceOrientation == UIInterfaceOrientationPortrait)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        // Configure the cell...
        if (cell == nil)
        {
            cell = \
                [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                       reuseIdentifier:CellIdentifier];
            
            newCell = YES;
        }
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier2];

        // Configure the cell...
        if (cell == nil)
        {
            cell = \
                [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                       reuseIdentifier:CellIdentifier2];
            
            newCell = YES;
        }
    }
    
    NSMutableArray *tiles = [[NSMutableArray alloc] init];
    
    if (newCell)
    {
        CGFloat curX = 10;
        
        for (int i = 0; i < numberPerRow; i++)
        {
            UITableCell *tblC = [[UITableCell alloc] initWithFrame:CGRectMake(curX, MARGIN, CELL_WIDTH, CELL_HEIGHT)];
            
            tblC.tag = self.currentTag++;
            tblC.hidden = YES;

            UITapGestureRecognizer *tapRecognizer = \
                [[UITapGestureRecognizer alloc] initWithTarget:self
                                                        action:@selector(changeStream:)];
            tapRecognizer.numberOfTouchesRequired = 1;
            tapRecognizer.numberOfTapsRequired = 1;
            tapRecognizer.delegate = self;

            [tblC addGestureRecognizer:tapRecognizer];
            
            [cell addSubview:tblC];
            curX += (CELL_WIDTH + MARGIN);
            
            [tiles addObject:tblC]; /* temporary hold. */
        }
    }
    else
    {
        for (UIView *view in [cell subviews])
        {
            if (view.tag > 900)
            {
                [tiles addObject:view];
                view.hidden = YES;
            }
        }
    }
    
    /* Tiles has a pointer to each guy, in what should be order. */

    cell.textLabel.text = @"";
    cell.detailTextLabel.text = @"";
    cell.imageView.image = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if ([self.headers[indexPath.section] isEqualToString:@"Watching"])
    {
        if ([self.watching count] == 0)
        {
            cell.textLabel.text = @"Feel free to watch users.";
            return cell;
        }
        
        NSArray *watches = self.queryResults[@"Watching"];
        
        NSInteger remains = [watches count] - (indexPath.row * numberPerRow);
        NSInteger forRow = MIN(remains, numberPerRow);

        NSLog(@"row: %d, remains: %d, forRow: %d", indexPath.row, remains, forRow);
        
        int index = indexPath.row * numberPerRow;
        
        for (int i = 0; i < forRow; i++)
        {
            UITableCell *tblC = tiles[i];
            
            [tblC setText:self.watching.screennames[watches[index][@"identifier"]]];
            [tblC setImage:watches[index][@"thumbnail"]];
            tblC.key = watches[index][@"key"];
            
            if (watches[index][@"refresh"] == nil)
            {
                [tblC setRefreshCount:0];
            }
            else
            {
                [tblC setRefreshCount:((NSNumber *)watches[index][@"refresh"]).integerValue];
            }
            
            tblC.hidden = NO;
            
            index++;

        }
    }
    else if ([self.headers[indexPath.section] isEqualToString:@"Communities"])
    {
        if ([self.communities count] == 0)
        {
            cell.textLabel.text = @"Feel free to join communities.";
            return cell;
        }
        
        NSArray *comms = self.queryResults[@"Communities"];
        
        NSInteger remains = [comms count] - (indexPath.row * numberPerRow);
        NSInteger forRow = MIN(remains, numberPerRow);
        
        NSLog(@"row: %d, remains: %d, forRow: %d", indexPath.row, remains, forRow);
        
        int index = indexPath.row * numberPerRow;
        
        for (int i = 0; i < forRow; i++)
        {
            UITableCell *tblC = tiles[i];
            
            [tblC setText:comms[index][@"identifier"]];
            [tblC setImage:comms[index][@"thumbnail"]];
            tblC.key = comms[index][@"key"];

            if (comms[index][@"refresh"] == nil)
            {
                [tblC setRefreshCount:0];
            }
            else
            {
                [tblC setRefreshCount:((NSNumber *)comms[index][@"refresh"]).integerValue];
            }
            
            [tblC setFont:[UIFont boldSystemFontOfSize:10]];
            
            tblC.hidden = NO;

            index++;
        }
    }

    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return;
}

- (void)changeStream:(UITapGestureRecognizer *)gestureRecognizer
{
    BOOL chosen = NO;
    UITableCell *master = (UITableCell *)gestureRecognizer.view;
    ImageSpinner *tapped = master.spin;

    NSArray *details = [master.key componentsSeparatedByString:@"="];
    
    NSLog(@"details: %@", details);
    
    if ([details[0] isEqualToString:@"watch"])
    {
        NSMutableArray *watches = self.queryResults[@"Watching"];
        
        for (NSMutableDictionary *userdict in watches)
        {
            /** @todo Could use key. */
            if ([userdict[@"identifier"] isEqualToString:details[1]])
            {
                [userdict removeObjectForKey:@"refresh"];
                [self.delegate handleQueryResults:userdict[@"results"]];
                chosen = YES;
                
                [self.queryCache insertObject:[[PivotDetails alloc] initWithPivot:@"author"
                                                                        withValue:userdict[@"identifier"]
                                                                        withImage:nil]
                                      atIndex:0];
            }
        }
    }
    else if ([details[0] isEqualToString:@"comm"])
    {
        NSMutableArray *comms = self.queryResults[@"Communities"];
        
        for (NSMutableDictionary *commdict in comms)
        {
            if ([commdict[@"identifier"] isEqualToString:details[1]])
            {
                [commdict removeObjectForKey:@"refresh"];
                [self.delegate handleQueryResults:commdict[@"results"]];
                chosen = YES;
                
                [self.queryCache insertObject:[[PivotDetails alloc] initWithPivot:@"community"
                                                                        withValue:commdict[@"identifier"]
                                                                        withImage:nil]
                                      atIndex:0];
            }
        }
    }
    
    CGRect startFrm = tapped.frame;
    
    /* Not sure this quite makes sense. */
    if (chosen)
    {
        [UIView animateWithDuration:0.2
                         animations:^{
                             /* 
                              * This should make it 20x20 larger than it was 
                              * originally.  This leverages that there is a 10px
                              * border on all sides.
                              */
                             tapped.frame = CGRectMake(tapped.frame.origin.x - 10,
                                                       tapped.frame.origin.y - 10,
                                                       tapped.frame.size.width + 20,
                                                       tapped.frame.size.width + 20);
                         }
                         completion:^(BOOL finished){
                             [UIView animateWithDuration:0.1
                                              animations:^{
                                                  /* 
                                                   * This should make it 20x20 
                                                   * smaller than it was
                                                   * originally.
                                                   */
                                                  tapped.frame = CGRectMake(startFrm.origin.x + 10,
                                                                            startFrm.origin.y + 10,
                                                                            startFrm.size.width - 20,
                                                                            startFrm.size.height - 20);
                                              }
                                              completion:^(BOOL finished){
                                                  [self dismiss:NO];
                                              }];
                         }];
    }

    return;
}

@end
