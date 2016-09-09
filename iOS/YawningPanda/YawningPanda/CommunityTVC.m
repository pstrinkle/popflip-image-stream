//
//  CommunityTVC.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/20/12.
//
//

#import "CommunityTVC.h"

#import "EventLogEntry.h"
#import "Util.h"

#import <QuartzCore/QuartzCore.h>

@implementation CommunityTVC

@synthesize communities;
@synthesize localCommunities;
@synthesize userIdentifier;

@synthesize eventLogPtr;
@synthesize delegate;

@synthesize busyWaiting, addEntrySelected, readOnly;
@synthesize receivedResults;
@synthesize apiManager;
@synthesize activity;
@synthesize joiningCall;
@synthesize theUser;

@synthesize pull;

/******************************************************************************
 * Pull-to-Refresh Code
 ******************************************************************************/

#pragma mark - Pull-to-Refresh Code

- (void)refreshData
{
    [self.apiManager cancelAll];
    
    [self.apiManager userQuery:self.theUser
                   withRequest:@"community"
                        asUser:self.userIdentifier];

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
 * TextField Delegate Code
 ******************************************************************************/

#pragma mark - TextField Delegate Code

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSLog(@"textField: %@, tag: %d", textField, textField.tag);
    UIView *content = textField.superview;
    
    if (textField.tag == 900) // index:0
    {
        UITextField *field = (UITextField *)[content viewWithTag:901];
        
        NSLog(@"new field: %@", field);
        
        [field becomeFirstResponder];
    }
    else // index: 2
    {
        [textField resignFirstResponder];
    }
    
    return NO;
}

/******************************************************************************
 * Delegate Callbacks
 ******************************************************************************/

#pragma mark - Delegate Callbacks

- (void)apihandler:(APIHandler *)apihandler didFail:(enum APICall)type
{
    [self.apiManager dropHandler:apihandler];
    if ([self.apiManager outStanding] == 0)
    {
        [self.activity stopAnimating];
        [pull finishedLoading];
    }
    
    if (apihandler == self.joiningCall)
    {
        /* XXX: joining failed. */
        self.joiningCall = nil;
    }
    
    return;
}

- (void)apihandler:(APIHandler *)apihandler didCompleteUserQuery:(NSMutableArray *)data
         withQuery:(NSString *)query
           forUser:(NSString *)user
            asUser:(NSString *)theUser
{
    [self.apiManager dropHandler:apihandler];
    if ([self.apiManager outStanding] == 0)
    {
        [self.activity stopAnimating];
        [pull finishedLoading];
    }
    
    self.receivedResults = YES;
    
    if (self.readOnly)
    {
        /* purge, surge. */
        [self.localCommunities removeAllObjects];
        [self.localCommunities addObjectsFromArray:data];
    }
    else
    {
        /* purge, surge. */
        [self.communities removeAllObjects];
        [self.communities addObjectsFromArray:data];
    }

    [self.tableView reloadData];

    return;
}

- (void)apihandler:(APIHandler *)apihandler didCompleteLeave:(bool)success
           forComm:(NSArray *)tags
            asUser:(NSString *)theUser
{
    if (success)
    {
        EventLogEntry *event = [[EventLogEntry alloc] init];
        event.eventType = EVENT_TYPE_LEAVE;
        event.note = [NSString stringWithFormat:@"left: %@",
                      [tags componentsJoinedByString:@","]];
    
        [self.eventLogPtr insertObject:event atIndex:0];
    }

    self.busyWaiting -= 1;

    return;
}

- (void)apihandler:(APIHandler *)apihandler didCompleteJoin:(bool)success
           forComm:(NSArray *)tags
            asUser:(NSString *)theUser
{
    self.addEntrySelected = NO;
    
    [self.tableView reloadData]; // maybe call this later.
    
    if (apihandler == self.joiningCall)
    {
        self.joiningCall = nil;
    }

    [self.activity stopAnimating];

    if (success)
    {
        EventLogEntry *event = [[EventLogEntry alloc] init];
        event.eventType = EVENT_TYPE_JOIN;
        event.note = [NSString stringWithFormat:@"joined: %@",
                      [tags componentsJoinedByString:@","]];

        [self.eventLogPtr insertObject:event atIndex:0];

        [self.communities addObject:tags];

        NSLog(@"handleNewCommunity: self.communities (%@): %d",
              self.communities,
              [self.communities count]);

        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.communities.count-1 inSection:0]]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
    }

    self.busyWaiting -= 1;

    return;
}

/******************************************************************************
 * Button Handlers
 ******************************************************************************/

#pragma mark - Button Handlers

- (IBAction)addEntry
{
    self.addEntrySelected = YES;
    [self.tableView reloadData];

    return;
}

- (void)cancelAddEntry:(id)sender
{
    UIButton *theBtn = (UIButton *)sender;
    theBtn.enabled = NO;

    UIView *contentView = theBtn.superview;    
    UITextField *textFieldA = (UITextField *)[contentView viewWithTag:900];
    UITextField *textFieldB = (UITextField *)[contentView viewWithTag:901];

    [textFieldA resignFirstResponder];
    [textFieldB resignFirstResponder];

    self.addEntrySelected = NO;

    if (self.joiningCall != nil)
    {
        [self.joiningCall cancel];
        self.busyWaiting -= 1;
        self.joiningCall = nil;
        
        [self.activity stopAnimating];
    }

    [self.tableView performSelector:@selector(reloadData)
                         withObject:nil
                         afterDelay:0.1];

    return;
}

- (void)tryToJoin:(id)sender
{
    UIButton *theBtn = (UIButton *)sender;
    UIView *contentView = theBtn.superview;
    UITextField *textFieldA = (UITextField *)[contentView viewWithTag:900];
    UITextField *textFieldB = (UITextField *)[contentView viewWithTag:901];

    [textFieldA resignFirstResponder];
    [textFieldB resignFirstResponder];

    if ([textFieldA.text length] == 0 || [textFieldB.text length] == 0)
    {
        NSLog(@"saveBtnHandler provided invalid values.");
        // must fill in both, XXX: add status label.
        return;
    }

    self.busyWaiting += 1;

    theBtn.enabled = NO;

    NSString *tagA = \
        [[textFieldA.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
    NSString *tagB = \
        [[textFieldB.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];

    /* we don't like commas -- loads of other stuff is also bad.... */

    /* XXX: although. there's no real reason we should exclude commas if we just
     * change the API to expect an array of input on the POST or GET.
     */
    tagA = [tagA stringByReplacingOccurrencesOfString:@"," withString:@""];
    tagB = [tagB stringByReplacingOccurrencesOfString:@"," withString:@""];

    NSArray *community = @[[tagA stringByReplacingOccurrencesOfString:@" " withString:@""],
                          [tagB stringByReplacingOccurrencesOfString:@" " withString:@""]];

    NSLog(@"community: %@", community);

    [self.activity startAnimating];

    APIHandler *api = [Util getHandler:self];
    [api joinCommunity:self.userIdentifier withTags:community];

    self.joiningCall = api;
    
    return;
}

/* For certain buttons I think I can honestly just set them to call dismiss:YES */
- (IBAction)dismiss
{
    NSLog(@"Dismissing.");
    
    if (self.busyWaiting > 0)
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

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    
    if (self)
    {
        NSLog(@"initialized.");
        // Custom initialization
        self.localCommunities = [[NSMutableArray alloc] init];
        self.apiManager = [[APIManager alloc] initWithDelegate:self];
        
        self.receivedResults = NO;
        self.busyWaiting = 0;
        self.addEntrySelected = NO;
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
    
    self.navigationItem.title = @"Communities";
    
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
    
    self.activity = \
        [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.activity.hidesWhenStopped = YES;
    
    UIBarButtonItem *activityBtn = \
        [[UIBarButtonItem alloc] initWithCustomView:self.activity];

    self.navigationItem.leftBarButtonItems = @[backBtn, activityBtn];

    self.pull = [[PullToRefreshView alloc] initWithScrollView:self.tableView];
    self.pull.delegate = self;
    [self.tableView addSubview:self.pull];

    if (self.readOnly)
    {
        self.tableView.contentOffset = CGPointMake(0, -65);
        [pull setState:PullToRefreshViewStateLoading];

        [self.apiManager userQuery:self.theUser
                       withRequest:@"community"
                            asUser:self.userIdentifier];
    }
    
    return;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    [self.apiManager cancelAll];
    [self.localCommunities removeAllObjects];
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

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    NSLog(@"entered setEditing, %d", editing);
    
    [super setEditing:editing animated:animated];
    
    [self.tableView setEditing:editing animated:YES]; /* not sure this part is required. */
    
    UIBarButtonItem *backBtn = \
        [[UIBarButtonItem alloc] initWithTitle:@"You"
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(dismiss)];
    if (editing)
    {
        UIBarButtonItem *addBtn = \
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                          target:self
                                                          action:@selector(addEntry)];

        self.navigationItem.leftBarButtonItem = addBtn;
    }
    else
    {
        self.addEntrySelected = NO;
        
        UIBarButtonItem *activityBtn = \
            [[UIBarButtonItem alloc] initWithCustomView:self.activity];
        
        self.navigationItem.leftBarButtonItems = @[backBtn, activityBtn];
        
        [self.tableView reloadData];
    }
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if (self.addEntrySelected == YES)
    {
        return 2;
    }
    else
    {
        return 1;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.addEntrySelected == YES)
    {
        if (section == 0)
        {
            return @"Enter in two tags";
        }
    }

    return @"Select to Pivot";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.addEntrySelected && indexPath.section == 0)
    {
        return tableView.rowHeight * 3;
    }

    return tableView.rowHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (self.readOnly)
    {
        if ([self.localCommunities count] == 0)
        {
            return 1; /* one with spinner. */
        }
        
        return [self.localCommunities count];
    }
    
    // cannot be true with readonly.
    if (self.addEntrySelected)
    {
        if (section == 0)
        {
            return 1;
        }
    }
    
    return [self.communities count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellId1 = @"Cell";
    static NSString *CellId2 = @"Cell2";
    static NSString *CellId3 = @"NewCell";
    
    UITableViewCell *cell = nil;
    
    // Configure the cell...
    if (self.readOnly && [self.localCommunities count] == 0 && self.receivedResults == NO)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:CellId2];
        
        /* This builds a lovely download spinner thing. */
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellId2];
            
            UIActivityIndicatorView *spinner = \
                [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            CGRect frm = CGRectMake((cell.frame.size.width / 2) - (self.tableView.rowHeight / 2),
                                    1,
                                    self.tableView.rowHeight,
                                    self.tableView.rowHeight);
            
            [spinner setFrame:frm];
            [spinner startAnimating];
            
            [cell.contentView addSubview:spinner];
        }
    }
    else
    {
        if (self.addEntrySelected && indexPath.section == 0)
        {
            // special cell.
            cell = [tableView dequeueReusableCellWithIdentifier:CellId3];

            if (cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellId3];

                CGFloat height = tableView.rowHeight - 10;
                CGFloat xoffset = cell.frame.origin.x + 10;
                CGSize inputSz = CGSizeMake(cell.contentView.frame.size.width - 20, height);
                
                UITextField *inputField = \
                    [[UITextField alloc] initWithFrame:CGRectMake(xoffset,
                                                                  cell.frame.origin.y + 5,
                                                                  inputSz.width,
                                                                  inputSz.height)];

                /* all but the last tag, later they'll be able to swipe clear tags and add with '+' */
                inputField.returnKeyType = UIReturnKeyNext;
                inputField.adjustsFontSizeToFitWidth = YES;
                inputField.borderStyle = UITextBorderStyleRoundedRect;
                inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
                inputField.autocorrectionType = UITextAutocorrectionTypeNo;
                inputField.clearButtonMode = UITextFieldViewModeAlways;
                inputField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
                inputField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                inputField.delegate = self;
                inputField.tag = 900;

                [cell.contentView addSubview:inputField];

                UITextField *inputField2 = \
                    [[UITextField alloc] initWithFrame:CGRectMake(xoffset,
                                                                  inputField.frame.origin.y + 10 + height,
                                                                  inputSz.width,
                                                                  inputSz.height)];

                /* all but the last tag, later they'll be able to swipe clear tags and add with '+' */
                inputField2.returnKeyType = UIReturnKeyDone;
                inputField2.adjustsFontSizeToFitWidth = YES;
                inputField2.borderStyle = UITextBorderStyleRoundedRect;
                inputField2.autocapitalizationType = UITextAutocapitalizationTypeNone;
                inputField2.autocorrectionType = UITextAutocorrectionTypeNo;
                inputField2.clearButtonMode = UITextFieldViewModeAlways;
                inputField2.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
                inputField2.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                inputField2.delegate = self;
                inputField2.tag = 901;

                [cell.contentView addSubview:inputField2];

                // (cell.contentView.frame.size.width - 30) / 2
                CGSize buttonSize = CGSizeMake((inputSz.width - 36) / 2, height);
                
                NSLog(@"buttonSize, width: %f, height: %f", buttonSize.width, buttonSize.height);
                
                CGPoint buttonPos = CGPointMake(0, inputField2.frame.origin.y + height + 10);

                UIButton *cancel = [UIButton buttonWithType:UIButtonTypeRoundedRect];
                [cancel setFrame:CGRectMake(xoffset, buttonPos.y,
                                            buttonSize.width, buttonSize.height)];
                [cancel setTitle:@"Cancel" forState:UIControlStateNormal];
                [cancel setShowsTouchWhenHighlighted:YES];
                [cancel setEnabled:YES];
                cancel.tag = 902;
                
                [cancel addTarget:self
                           action:@selector(cancelAddEntry:)
                 forControlEvents:UIControlEventTouchUpInside];

                [cell.contentView addSubview:cancel];
                
                UIButton *join = [UIButton buttonWithType:UIButtonTypeRoundedRect];
                [join setFrame:CGRectMake(cancel.frame.origin.x + buttonSize.width + 15,
                                          buttonPos.y,
                                          buttonSize.width, buttonSize.height)];
                [join setTitle:@"Join" forState:UIControlStateNormal];
                [join setShowsTouchWhenHighlighted:YES];
                [join setEnabled:YES];
                join.tag = 903;
                
                [join addTarget:self
                         action:@selector(tryToJoin:)
               forControlEvents:UIControlEventTouchUpInside];

                [cell.contentView addSubview:join];
                
                [Util printRectangle:inputField.frame];
                [Util printRectangle:inputField2.frame];
                [Util printRectangle:cancel.frame];
                [Util printRectangle:join.frame];
            }
            
            UIButton *can = (UIButton *)[cell.contentView viewWithTag:902];
            can.enabled = YES;
            UIButton *joi = (UIButton *)[cell.contentView viewWithTag:903];
            joi.enabled = YES;
        }
        else
        {
            cell = [tableView dequeueReusableCellWithIdentifier:CellId1];
        
            if (cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellId1];
            }
        }
    }
    
    if (self.readOnly)
    {
        if ([self.localCommunities count] == 0)
        {
            if (self.receivedResults == YES)
            {
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.textLabel.text = @"No Communities Bookmarked";
            }
        }
        else
        {
            cell.textLabel.text = [(self.localCommunities)[indexPath.row] componentsJoinedByString:@","];
        }
        
    }
    else
    {
        if (self.addEntrySelected && indexPath.section == 0)
        {
        }
        else
        {
            cell.textLabel.text = [(self.communities)[indexPath.row] componentsJoinedByString:@","];
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
    
    if (self.addEntrySelected)
    {
        if (indexPath.section == 0)
        {
            return NO;
        }
    }
    
    return YES;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Leave";
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSLog(@"Delete!");
        
        [tableView beginUpdates];
        
        self.busyWaiting += 1;

        /* It should be safe and copy and all that. */
        [[Util getHandler:self] leaveCommunity:self.userIdentifier
                                      withTags:(self.communities)[indexPath.row]];
        
        // Delete the row from the data source
        [self.communities removeObjectAtIndex:indexPath.row];
        if ([self.communities count] == 0)
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
    if (self.busyWaiting > 0)
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    // Navigation logic may go here. Create and push another view controller.
    if (self.readOnly)
    {
        if ([self.localCommunities count] > 0)
        {
            [delegate handlePivot:@"community"
                        withValue:[(self.localCommunities)[indexPath.row] componentsJoinedByString:@","]];
            
            [self dismissModalViewControllerAnimated:YES];
        }
    }
    else
    {
        [delegate handlePivot:@"community"
                    withValue:[(self.communities)[indexPath.row] componentsJoinedByString:@","]];
        
        [self dismissModalViewControllerAnimated:YES];
    }
    
    return;
}

@end
