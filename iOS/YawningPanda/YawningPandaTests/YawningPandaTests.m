//
//  YawningPandaTests.m
//  YawningPandaTests
//
//  Created by Patrick Trinkle on 7/18/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "YawningPandaTests.h"

@implementation YawningPandaTests

@synthesize userId;
@synthesize postId;
@synthesize queryResponse;
@synthesize thePost;
@synthesize imageValue;

/**
 * @brief Return an APIHandler instance that will release itself.
 */
- (APIHandler *)getHandler
{
    APIHandler *api = [[APIHandler alloc] init];
    /* this sets up the callback function required for the viewPost call */
    api.delegate = self;
    
    //[api autorelease];
    
    return api;
}

- (void)apihandler:(APIHandler *)apihandler didFail:(enum APICall)type
{
    return;
}

- (void)didCompleteLogin:(NSString *)userid
{
    self.userId = userid;

    done = YES;
    
    return;
}

- (void)didCompleteQuery:(NSMutableArray *)data asUser:(NSString *)theUser
{
    self.queryResponse = data;

    done = YES;

    return;
}

- (void)didCompleteView:(UIImage *)image withPost:(NSString *)postid
{
    done = YES;
    
    self.postId = postid;
    self.imageValue = image;
    
    return;
}


// code from: http://www.infinite-loop.dk/blog/2011/04/unittesting-asynchronous-network-access/
- (BOOL)waitForCompletion:(NSTimeInterval)timeoutSecs
{
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeoutSecs];
    
    do
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:timeoutDate];
        
        if ([timeoutDate timeIntervalSinceNow] < 0.0)
        {
            break;
        }

    } while (!done);
    
    return done;
}

- (void)setUp
{
    [super setUp];

//    app_delegate = [[UIApplication sharedApplication] delegate];
//    yawning_view_controller = app_delegate.viewController;
//    yawning_view = yawning_view_controller.view;

    done = NO;

    self.queryResponse = nil;
    self.thePost = nil;
    self.userId = nil;
    self.postId = nil;
    self.imageValue = nil;

    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    [super tearDown];
}

/**
 * @brief This tests that we can test.
 */
- (void)testAppDelegate
{
//    STAssertNotNil(app_delegate, @"Cannot find the application delegate");
}

- (void)testViewControllerLoads
{
//    STAssertNotNil(yawning_view_controller, @"Cannot find the view controller.");
}

- (void)testViewControllerView
{
//    STAssertNotNil(yawning_view, @"Cannot find the view.");
}

/*
 * ----------------------------------------------------------------------------
 * ----------------------------------------------------------------------------
 */
- (void)testApiHandlerLogin
{
    self.userId = nil;
    done = NO;

    [[self getHandler] loginUser:@"user1"];

    STAssertTrue([self waitForCompletion:90.0],
                 @"Failed to get any results in time");
    
    STAssertNotNil(self.userId, @"Userid should have a value.");
    
    return;
}

- (void)testApiHandlerLoginBad
{
    self.userId = nil;
    done = NO;
    
    [[self getHandler] loginUser:@"invalid"];
    
    STAssertTrue([self waitForCompletion:90.0],
                 @"Failed to get any results in time");
    
    STAssertNil(self.userId, @"Userid should not have a value.");
    
    return;
}

/*
 * ----------------------------------------------------------------------------
 * ----------------------------------------------------------------------------
 */
- (void)testApiHandlerQueryScreenName
{
    self.queryResponse = nil;
    self.userId = nil; // yeah. this needs to be not nil.
    done = NO;

    [[self getHandler] queryPosts:@"screen_name"
                        withValue:@"user1"
                           asUser:self.userId];
    
    STAssertTrue([self waitForCompletion:90.0],
                 @"Failed to get any results in time");
    
    STAssertNotNil(self.queryResponse, @"Query should have a valid response.");
    
    STAssertTrue([self.queryResponse count] > 0,
                 @"Should have several entries.");
    
    return;
}

/*
 * ----------------------------------------------------------------------------
 * ----------------------------------------------------------------------------
 */
- (void)testApiHandlerGetPostImage
{
    done = NO;

    [[self getHandler] queryPosts:@"screen_name" withValue:@"user1" asUser:self.userId];

    STAssertTrue([self waitForCompletion:90.0],
                 @"Failed to get any results in time");

    STAssertNotNil(self.queryResponse, @"Query should have a valid response.");

    STAssertTrue([self.queryResponse count] > 0,
                 @"Should have several entries.");
    
    Post *currPost = (self.queryResponse)[0];
    
    [[self getHandler] viewPost:currPost.postid];

    STAssertTrue([self waitForCompletion:90.0],
                 @"Failed to get any results in time");
    
    STAssertNotNil(self.imageValue, @"Image should be not nil.");
    
    STAssertTrue([currPost.postid isEqualToString:self.postId], @"The post ids should match.");
    
    return;
}

#if 0
- (void)testLoginPopsupValidUser
{
    [yawning_view_controller loginBtnHandler];
    
    LoginPopupViewController *login = \
        (LoginPopupViewController *)[yawning_view_controller presentedViewController];
    
    STAssertTrue([login.navBar.title isEqualToString:@"Login"], @"Login Popup does not have correct title.");

    STAssertTrue([login.navBar.rightBarButtonItem isEnabled] == NO, @"Login Button Should Not Be Enabled");
    
    [login.userField setText:@"user1"];
    
    [login loginBtnHandler];
    
    /* Should dismiss when it's done..? */
    while (login == [yawning_view_controller presentedViewController])
    {
        sleep(5);
    }

    STAssertNotNil(yawning_view_controller.userPrefs, @"User Preferences should not be nil");
    STAssertNotNil(yawning_view_controller.specifiedUser, @"Specified user should not be nil");
    
    NSLog(@"%@", yawning_view_controller.userPrefs);
    
    //STAssertTrue([login.navBar.rightBarButtonItem isEnabled] == YES, @"Login Button Should Be Enabled");
}
#endif

- (void)testExample
{
//    STFail(@"Unit tests are not implemented yet in YawningPandaTests");
    
//    [[self getHandler] loginUser:@"user1"];
}

@end
