//
//  PivotTableViewController.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 8/26/12.
//
//

#import "PivotTableViewController.h"

@implementation PivotTableViewController

@synthesize details;
@synthesize delegate;

/******************************************************************************
 * State Preservation and Restoration Code
 ******************************************************************************/

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    NSLog(@"%@:encodeRestorableStateWithCoder:%@", self, coder);

    [coder encodeObject:self.details forKey:@"details"];

    /* viewdidload needs to save/restore whatever query they were in the middle of. */
    [super encodeRestorableStateWithCoder:coder];
    
    return;
}

/*
 * This is called after viewDidLoad
 */
- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    NSLog(@"%@:decodeRestorableStateWithCoder:%@", self, coder);

    /*
     * We need to let the view re-build stuff, which is fine, but then it needs
     * to be set with certain stuff.  I am fairly certain it's OK to drop the
     * keyboard, etc.
     */
    if ([coder containsValueForKey:@"details"])
    {
        id x = [coder decodeObjectForKey:@"details"];
        if (x != nil)
        {
            self.details = x;
        }
    }

    [super decodeRestorableStateWithCoder:coder];

    return;
}

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    NSLog(@"yp: viewControllerWithRestorationIdentifierPath:%@ :%@", identifierComponents, coder);
    
    PivotTableViewController *myViewController = [[PivotTableViewController alloc] initWithNibName:@"PivotTableViewController" bundle:nil];
    
    NSLog(@"allocated yp: %@", myViewController);
    return myViewController;
}

/******************************************************************************
 * Normal View Loading Code
 ******************************************************************************/

/* For certain buttons I think I can honestly just set them to call dismiss:YES */
- (IBAction)dismiss
{
    NSLog(@"Dismissing.");
    
    [self dismissModalViewControllerAnimated:YES];
}

- (id)initWithStyle:(UITableViewStyle)style
        withDetails:(NSDictionary *)theDetails
       withDelegate:(id<PivotPopupDelegate>)pivotDelegate
{
    self = [super initWithStyle:style];
    
    if (self)
    {
        // Custom initialization
        self.modalInPopover = YES;

        self.details = theDetails;
        self.delegate = pivotDelegate;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Select to Pivot";
//    self.restorationClass = [self class];
//    self.restorationIdentifier = @"PivotTableViewController";
    
//    self.tableView.backgroundColor = [UIColor clearColor];
//    [self.tableView setOpaque:NO];
    //self.parentViewController.view.backgroundColor = [UIColor colorWithRed:0.0 green:0.2 blue:0.5 alpha:0.7];
#if 1
    UIBarButtonItem *backBtn = \
        [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                         style:UIBarButtonItemStyleDone
                                        target:self
                                        action:@selector(dismiss)];
    
    self.navigationItem.leftBarButtonItem = backBtn;
#endif
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
#if 0
    /* argh */
    if ([self.tableView respondsToSelector:@selector(backgroundView)])
    {
        self.tableView.backgroundView = nil;
    }
    
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.tableView setOpaque:NO];
    
    self.view.backgroundColor = [UIColor clearColor];
    [self.view setOpaque:NO];
    
    [self.parentViewController.view setBackgroundColor:[UIColor clearColor]];
    [self.parentViewController.view setOpaque:NO];
    
    [self.tableView.tableHeaderView setBackgroundColor:[UIColor clearColor]];
    [self.tableView.tableHeaderView setOpaque:NO];
    
    [self.tableView.tableFooterView setBackgroundColor:[UIColor clearColor]];
    [self.tableView.tableFooterView setOpaque:NO];

//    [self.tableView setSeparatorColor:[UIColor clearColor]];
    /* XXX: We should set the inputView if that's what's required. */
#endif

    return;
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    return;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
//    NSLog(@"numberOfSectionsInTableView");
    // Return the number of sections.
    return [self.details count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
//    NSLog(@"titleForHeaderInSection: %@", [self.details allKeys]);
    return [self.details allKeys][section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//    NSLog(@"numberOfRowsInSection: %d", section);

    // Return the number of rows in the section.
    id value = (self.details)[[self.details allKeys][section]];
    
    if ([value isKindOfClass:[NSArray class]])
    {
        return [value count];
    }
    
    return 1;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
//    cell.backgroundColor = [UIColor clearColor];
//    cell.textLabel.backgroundColor = [UIColor clearColor];
//    cell.detailTextLabel.backgroundColor = [UIColor clearColor];
//    cell.imageView.backgroundColor = [UIColor clearColor];
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

#if 0
    UIView *backView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
    backView.backgroundColor = [UIColor clearColor];
    cell.backgroundView = backView;

    [[cell contentView] setBackgroundColor:[UIColor clearColor]];
    [[cell backgroundView] setBackgroundColor:[UIColor clearColor]];
    [cell setBackgroundColor:[UIColor clearColor]];
#endif

#if 0
    cell.backgroundColor = [UIColor clearColor];
    [cell.contentView setBackgroundColor:[UIColor clearColor]];
    [cell.backgroundView setBackgroundColor:[UIColor clearColor]];
#endif

    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;

    NSObject *value = \
        (self.details)[[self.details allKeys][indexPath.section]];

    if ([value respondsToSelector:@selector(count)])
    {
        cell.textLabel.text = \
            [NSString stringWithFormat:@"%@",
             ((NSArray *)value)[indexPath.row]];
    }
    else
    {
        cell.textLabel.text = [NSString stringWithFormat:@"%@", value];
    }

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    NSString *key = [self.details allKeys][indexPath.section];
    
    /* this doens't quite make sense. :P */
    if ([key isEqualToString:@"post_id"])
    {
        return;
    }
    
    /* handle non-standard first */
    if ([key isEqualToString:@"num_replies"])
    {
        [delegate handlePivot:@"reply_to"
                    withValue:(self.details)[@"post_id"]];
    }
    else
    {
        if ([(self.details)[key] respondsToSelector:@selector(count)])
        {
            /* the value is a subordinate. */
            [delegate handlePivot:key
                        withValue:(self.details)[key][indexPath.row]];
        }
        else
        {
            [delegate handlePivot:key withValue:(self.details)[key]];
        }
    }

    [self dismissModalViewControllerAnimated:YES];

    return;
}

@end
