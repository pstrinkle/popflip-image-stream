//
//  LogEntryTVC.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/20/12.
//
//

#import "LogEntryTVC.h"

@implementation LogEntryTVC

@synthesize details;
@synthesize event;

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
    
    //    [self dismissModalViewControllerAnimated:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    self.navigationItem.titleView can add custom barbutton with activity spinner.
//    can definitely add icon for the event types, we have no icons at present.

    /* * XXX: Store these strings in a static array thing and then just pull out
     * by index.
     */
    self.navigationItem.title = [EventLogEntry typeToString:self.event];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
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
    return [[self.details allKeys] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [NSString stringWithFormat:@"%@", [self.details allKeys][section]];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    id value = (self.details)[[self.details allKeys][section]];
    
    if ([value isKindOfClass:[NSArray class]])
    {
        return [value count];
    }
    
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:CellIdentifier];
    }
    
    NSObject *key = [self.details allKeys][indexPath.section];
    
    /* then we care about row. */
    if ([(self.details)[key] respondsToSelector:@selector(count)])
    {
        /* hopefully it is a dictionary of arrays, not a dictionary of dictionaries or this code will fall over. */
        cell.textLabel.text = [NSString stringWithFormat:@"%@", (self.details)[key][indexPath.row]];
    }
    else
    {
        cell.textLabel.text = [NSString stringWithFormat:@"%@", (self.details)[key]];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

@end
