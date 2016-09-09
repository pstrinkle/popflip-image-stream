//
//  PivotHistoryTVC.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 10/5/12.
//
//

#import "PivotHistoryTVC.h"
#import "PivotDetails.h"

@implementation PivotHistoryTVC

@synthesize pivotHistory;
@synthesize delegate;

/* For certain buttons I think I can honestly just set them to call dismiss:YES */
- (void)dismiss
{
    NSLog(@"Dismissing.");
    
    [self dismissModalViewControllerAnimated:YES];
}

- (void)purgeBtnHandler
{
    [self.pivotHistory removeAllObjects];

    [self.tableView reloadData];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = @"Pivot History";
    
    UIBarButtonItem *backBtn = \
        [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                         style:UIBarButtonItemStyleDone
                                        target:self
                                        action:@selector(dismiss)];

    self.navigationItem.leftBarButtonItem = backBtn;

    UIBarButtonItem *purgeBtn = \
        [[UIBarButtonItem alloc] initWithTitle:@"Clear"
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(purgeBtnHandler)];

    self.navigationItem.rightBarButtonItem = purgeBtn;

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if ([self.pivotHistory count] == 0)
    {
        return 1;
    }

    return [self.pivotHistory count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
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
    cell.detailTextLabel.text = @"";

    if ([self.pivotHistory count] == 0)
    {
        cell.textLabel.text = @"Empty History";
        cell.imageView.image = nil;
    }
    else
    {
        PivotDetails *query = (self.pivotHistory)[indexPath.row];
        
        cell.imageView.image = query.thumbnail;

        cell.textLabel.text = query.pivot;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;

        cell.detailTextLabel.text = query.value;
        cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
        
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    if ([self.pivotHistory count] == 0)
    {
        return;
    }

    PivotDetails *query = (self.pivotHistory)[indexPath.row];
    [self.delegate handlePivot:query.pivot
                     withValue:query.value];

    [self dismiss];

    return;
}

@end
