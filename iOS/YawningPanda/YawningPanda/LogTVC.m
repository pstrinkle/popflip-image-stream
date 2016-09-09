//
//  LogTVC.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/20/12.
//
//

#import "LogTVC.h"
#import "EventLogEntry.h"
#import "LogEntryTVC.h"

@implementation LogTVC

@synthesize events;
@synthesize delegate;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self)
    {
        // Custom initialization
    }
    
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/* For certain buttons I think I can honestly just set them to call dismiss:YES */
- (IBAction)dismiss
{
    NSLog(@"Dismissing.");
    
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)purgeBtnHandler
{
    NSLog(@"Sending Command to Purge.");
    
    [self dismissModalViewControllerAnimated:YES];
    
    [delegate handlePurgeEvents];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Event Log";
    
    UIBarButtonItem *backBtn = \
    [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                     style:UIBarButtonItemStyleDone
                                    target:self
                                    action:@selector(dismiss)];
    
    self.navigationItem.leftBarButtonItem = backBtn;
    
    UIBarButtonItem *purgeBtn = \
    [[UIBarButtonItem alloc] initWithTitle:@"Delete All"
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(purgeBtnHandler)];
    
    self.navigationItem.rightBarButtonItem = purgeBtn;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    return;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
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
    return @"Events";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if ([self.events count] == 0)
    {
        return 1;
    }
    
    return [self.events count];
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
    
    cell.accessoryType = UITableViewCellAccessoryNone; // default it.
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if ([self.events count] == 0)
    {
        cell.textLabel.text = @"No Events";
    }
    else
    {
        EventLogEntry *event = (self.events)[indexPath.row];
        
        cell.textLabel.text = [NSString stringWithFormat:@"%@", event.note];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", event.date];
        cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
        
        if (event.details != nil)
        {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        }
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.events count] == 0)
    {
        return;
    }
    
    // Navigation logic may go here. Create and push another view controller.
    EventLogEntry *event = (self.events)[indexPath.row];
    
    if (event.details == nil)
    {
        return;
    }
    
    LogEntryTVC *cview = \
        [[LogEntryTVC alloc] initWithStyle:UITableViewStyleGrouped];
    
    /*
     * XXX: may have to make our version of communities mutable in case they
     * edit from the pushed view, of interest, need to fix the backbutton in
     * the pushed view so that we surived.
     */
    cview.details = event.details;
    cview.title = [NSString stringWithFormat:@"%d", event.eventType];
    cview.event = event.eventType;
    
    [self.navigationController pushViewController:cview animated:YES];
}

@end
