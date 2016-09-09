//
//  LoginTVCViewController.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/30/12.
//
//

#import "LoginTVC.h"

#import "Util.h"

@implementation LoginTVC

@synthesize textFields;
@synthesize headerViews;
@synthesize currentField;
@synthesize keyboardSize;
@synthesize activity;
@synthesize loginBtn;
@synthesize startingName;
@synthesize apiManager;
@synthesize userData;
@synthesize queriesFinished;
@synthesize delegate;
@synthesize cachedId;

/******************************************************************************
 * Button Handlers
 ******************************************************************************/

- (void)loginBtnHandler
{
    UITextField *userField = (self.textFields)[0];

    if ([userField.text length] == 0)
    {
        NSLog(@"userfield must have value...");
        return;
    }

    self.loginBtn.enabled = NO;
    userField.enabled = NO;

    [self.activity startAnimating];

    [self.apiManager loginUser:[[userField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString]];

    return;
}

- (void)dismiss
{
    NSLog(@"Dismissing.");

    [self dismissModalViewControllerAnimated:YES];

    self.userData = nil;
    self.cachedId = nil;
    [self.apiManager cancelAll];

    return;
}

/******************************************************************************
 * Delegate Callbacks
 ******************************************************************************/

- (void)apihandler:(APIHandler *)apihandler didFail:(enum APICall)type
{
    [self.activity stopAnimating];
    [self.apiManager cancelAll];

    UITextField *userField = (self.textFields)[0];
    userField.enabled = YES;
    self.loginBtn.enabled = YES;

    return;
}

- (void)apihandler:(APIHandler *)apihandler didCompleteName:(User *)details
        withAuthor:(NSString *)authorid
            asUser:(NSString *)theUser
{
    self.queriesFinished += 1;
    [self.apiManager dropHandler:apihandler];
    
    if (details == nil)
    {
        NSLog(@"Failed to download user information.");
    }
    
    /*
     * Apparently when the other view tries to free their userData it explodes,
     * I think because it was already freed when the APIHandler collapsed and
     * this was auto-released.
     *
     * I am not 100% certain why dropping the postCache doesn't create the same
     * problem.
     *
     * The value is autorelease, which means I think we're supposed to retain it
     *  if we don't use a 'copy' property.
     */
    (self.userData)[@"user"] = details;
    
    NSLog(@"login: didCompleteName: %@", self.userData);
    
    if (self.queriesFinished == 2)
    {
        [self.activity stopAnimating];
        [delegate handleLoginEntered:self.cachedId withPrefs:self.userData];
        [self dismiss];
    }
}

- (void)apihandler:(APIHandler *)apihandler didCompleteUserQuery:(NSMutableArray *)data
         withQuery:(NSString *)query
           forUser:(NSString *)user
            asUser:(NSString *)theUser
{
    self.queriesFinished += 1;
    [self.apiManager dropHandler:apihandler];
    
    if (data == nil)
    {
    }
    else
    {
        NSLog(@"login: didCompleteUserQuery from query: %@", data);
        
        (self.userData)[query] = data;
    }
    
    NSLog(@"didCompleteUserQuery: %@", self.userData);
    
    if (self.queriesFinished == 2)
    {
        [self.activity stopAnimating];
        [delegate handleLoginEntered:self.cachedId withPrefs:self.userData];
        [self dismiss];
    }
    
    return;
}

- (void)apihandler:(APIHandler *)apihandler didCompleteLogin:(NSString *)userid
{
    [self.apiManager dropHandler:apihandler];
    
    if (userid == nil)
    {
        [self.activity stopAnimating];
        
        UITextField *userField = (self.textFields)[0];
        userField.enabled = YES;
        self.loginBtn.enabled = YES;

        return;
    }

    self.cachedId = userid;
    NSLog(@"cacheId: %@", self.cachedId);

    [self.apiManager userQuery:self.cachedId
                   withRequest:@"community"
                        asUser:self.cachedId];
    [self.apiManager getAuthor:self.cachedId
                        asUser:self.cachedId];
    
    return;
}

/******************************************************************************
 * Keyboard Event Delegate Code
 ******************************************************************************/

/**
 * @brief Stop asking for stuff... I'm not sure this is required.
 */
- (void)unregisterForKeyboardNotifications
{
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}


// Call this method somewhere in your view controller setup code.
/* code from apple. */
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    return;
}

- (void)slideIntoView
{
    CGRect aRect = self.view.frame;
    CGFloat keyHeight;
    if (self.interfaceOrientation == UIInterfaceOrientationPortrait)
    {
        keyHeight = self.keyboardSize.height;
        aRect.origin.y -= 20;
    }
    else
    {
        keyHeight = self.keyboardSize.width;
    }

    NSLog(@"keyHeight: %f", keyHeight);
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your application might not need or want this behavior.
    aRect.size.height -= keyHeight;

    UIView *activeField = self.currentField.superview.superview;
    
    NSLog(@"currentField: %@", self.currentField);

    NSLog(@"aRect: ");
    [Util printRectangle:aRect];

    NSLog(@"active view: %@", activeField);
    [Util printRectangle:activeField.frame];

    if (activeField == nil)
    {
        NSLog(@"active field was nil...");
        return;
    }

    if (!CGRectContainsPoint(aRect, activeField.frame.origin))
    {
        NSLog(@"keyboard hides it.");
        
        float absHeight = self.view.bounds.size.height - keyHeight;

        CGPoint scrollPoint = CGPointMake(0, activeField.frame.origin.y - (absHeight - self.tableView.rowHeight));
        
        NSLog(@"scrollPoint (%f, %f)", scrollPoint.x, scrollPoint.y);

        [self.tableView setContentOffset:scrollPoint animated:YES];
    }
}

// Called when the UIKeyboardDidShowNotification is sent.
/* code from apple. */
- (void)keyboardWasShown:(NSNotification *)aNotification
{
    NSLog(@"keyboardWasShown");
    
    NSDictionary *info = [aNotification userInfo];
    CGSize kbSize = [info[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    self.keyboardSize = kbSize;
    
    [self slideIntoView];
    
    return;
}

// Called when the UIKeyboardWillHideNotification is sent
/* code from apple. */
- (void)keyboardWillBeHidden:(NSNotification *)aNotification
{
    NSLog(@"keyboardWillBeHidden");

    return;
}

- (void)dropKeyboard:(UITapGestureRecognizer *)recognizer
{
    NSLog(@"drop keyboard called.");

    /* This is all a hack for iOS 5 that has issues with parented tap things. */
    CGPoint tapPoint = [recognizer locationInView:recognizer.view];

//    NSLog(@"tapPoint: (%f, %f)", tapPoint.x, tapPoint.y);
//    NSLog(@"button frame: ");
//    [Util printRectangle:self.loginBtn.frame];
    
    CGRect x = [self.loginBtn convertRect:self.loginBtn.frame toView:self.tableView];
//    NSLog(@"button new frame: ");
//    [Util printRectangle:x];
    
    CGRect newSquare = CGRectMake(self.loginBtn.frame.origin.x,
                                  x.origin.y - self.loginBtn.frame.origin.y,
                                  self.loginBtn.frame.size.width,
                                  self.loginBtn.frame.size.height);
    
    if (CGRectContainsPoint(newSquare, tapPoint))
    {
        NSLog(@"tapped button.");
        [self loginBtnHandler];
    }
    
    UITextField *field1 = (self.textFields)[0];
    [field1 resignFirstResponder];
    
    UITextField *field2 = (self.textFields)[1];
    [field2 resignFirstResponder];
    
    NSLog(@"recognizer: %@", recognizer);
    
    return;
}

/******************************************************************************
 * TextField Delegate Code
 ******************************************************************************/

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    self.currentField = textField;
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    //NSLog(@"textField: %@, tag: %d", textField, textField.tag);
    self.currentField = textField;

    if (textField.tag == 900) // index:0
    {
        UITextField *field = (self.textFields)[1];

        //NSLog(@"new field: %@", field);

        [field performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.0];
        [self performSelector:@selector(slideIntoView) withObject:nil afterDelay:0.1];
    }
    else // index: 2
    {
        [textField resignFirstResponder];
    }

    return NO;
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
        self.textFields = [[NSMutableArray alloc] initWithCapacity:3];
        
        for (int i = 0; i < 2; i++)
        {
            UITextField *inputField = \
                [[UITextField alloc] initWithFrame:CGRectZero];
            
            /*
             * All but the last tag, later they'll be able to swipe clear tags
             * and add with '+'
             */
            if (i == 0)
            {
                inputField.returnKeyType = UIReturnKeyNext;
                inputField.placeholder = @"Username";
            }
            else
            {
                inputField.returnKeyType = UIReturnKeyGo;
                inputField.placeholder = @"Password";
                inputField.secureTextEntry = YES;
            }
            
            inputField.adjustsFontSizeToFitWidth = YES;
            inputField.borderStyle = UITextBorderStyleNone;
            inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            inputField.autocorrectionType = UITextAutocorrectionTypeNo;
            inputField.clearButtonMode = UITextFieldViewModeAlways;
            inputField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            inputField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            inputField.delegate = self;
            inputField.tag = 900 + i;
            
            [self.textFields addObject:inputField];
        }
        
        self.headerViews = [[NSMutableDictionary alloc] init];
        self.userData = [[NSMutableDictionary alloc] init];
        self.apiManager = [[APIManager alloc] initWithDelegate:self];
    }

    return self;
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    self.headerViews = nil;
    self.textFields = nil;

    [self unregisterForKeyboardNotifications];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (![self.startingName isEqualToString:@""])
    {
        UITextField *userField = (self.textFields)[0];
        userField.text = self.startingName;
    }

    self.tableView.backgroundView = nil;

    UIColor *back = \
        [UIColor colorWithRed:39.0/255 green:99.0/255 blue:24.0/255 alpha:1.0];
    UIView *backView = \
        [[UIView alloc] initWithFrame:CGRectMake(0, 0,
                                                 self.tableView.frame.size.width,
                                                 self.tableView.frame.size.height)];
    backView.backgroundColor = back;
    self.tableView.backgroundView = backView;

    UITapGestureRecognizer *tap = \
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(dropKeyboard:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;

    [self.tableView addGestureRecognizer:tap];

    [self registerForKeyboardNotifications];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
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
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 200;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 100;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *customView = self.headerViews[@"main"];
    
    if (customView == nil)
    {
        CGFloat tableWidth = tableView.frame.size.width;
        
        customView = \
            [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableWidth, 200)];
        
        customView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        customView.backgroundColor = [UIColor clearColor]; //[UIColor clearColor]; //[UIColor colorWithRed:39 green:99 blue:24 alpha:1];

        UILabel *sectionHeader = [[UILabel alloc] initWithFrame:CGRectZero];
        sectionHeader.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        sectionHeader.backgroundColor = [UIColor clearColor];
        sectionHeader.tag = 900;
        sectionHeader.frame = CGRectMake(0, 50, tableWidth, 100);
        sectionHeader.contentMode = UIViewContentModeBottom;
        sectionHeader.shadowColor = [UIColor blackColor];
        sectionHeader.shadowOffset = CGSizeMake(0, 1);
        
        sectionHeader.textAlignment = UITextAlignmentCenter;
        sectionHeader.textColor = [UIColor whiteColor];
        sectionHeader.text = @"YAWNINGPANDA";
        sectionHeader.font = [UIFont fontWithName:@"Bradley Hand" size:36];
        
        customView.contentMode = UIViewContentModeBottom;
        
        [customView addSubview:sectionHeader];
        
        (self.headerViews)[@"main"] = customView;
    }

    return customView;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *customView = self.headerViews[@"footer"];
    
    if (customView == nil)
    {
        customView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 100)];

        customView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        customView.backgroundColor = [UIColor clearColor];

        UIButton *login = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        self.loginBtn = login;

        [login setFrame:CGRectMake(150, 10, 80, 30)];

        [login setTitle:@"Login" forState:UIControlStateNormal];
        login.showsTouchWhenHighlighted = YES;
        login.enabled = YES;
//        login.backgroundColor = [UIColor colorWithRed:39.0/255 green:99.0/255 blue:24.0/255 alpha:1.0];

        [login addTarget:self
                   action:@selector(loginBtnHandler)
         forControlEvents:UIControlEventTouchUpInside];

        [customView addSubview:login];
        
        self.activity = \
            [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [self.activity setFrame:CGRectMake(login.frame.origin.x - 25,
                                           login.frame.origin.y + 5,
                                          20, 20)];
        self.activity.hidesWhenStopped = YES;
        
        [customView addSubview:self.activity];

        (self.headerViews)[@"footer"] = customView;
    }

    return customView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    // Configure the cell...
    UITextField *field = (self.textFields)[indexPath.row];

    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:CellIdentifier];

        CGRect fieldFrame = CGRectMake(cell.frame.origin.x + 10,
                                       cell.frame.origin.y + 5,
                                       cell.contentView.frame.size.width - 20,
                                       tableView.rowHeight - 10);

        [field setFrame:fieldFrame];

        [cell.contentView addSubview:field];
    }

    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
