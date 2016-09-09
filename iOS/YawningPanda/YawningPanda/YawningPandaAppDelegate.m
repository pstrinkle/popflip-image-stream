//
//  YawningPandaAppDelegate.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 7/18/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "YawningPandaAppDelegate.h"

#import "YawningPandaViewController.h"

@implementation YawningPandaAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    NSLog(@"launchOptions: %@", launchOptions);
    
    if (self.viewController == nil)
    {
        NSLog(@"loading new viewcontroller...");
        self.viewController = [[YawningPandaViewController alloc] initWithNibName:@"YawningPandaViewController" bundle:nil];
    }
     
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    NSLog(@"applicationWillResignActive");
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    NSLog(@"applicationDidEnterBackground");
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
    NSLog(@"applicationWillEnterForeground");
    
    /* XXX: UIApplicationSignificantTimeChangeNotification */
    /* we can use this to automatically refresh the inboxes. */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    NSLog(@"applicationDidBecomeActive");
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
    NSLog(@"applicationWillTerminate");
}

/*
 * The following App State Preservation only work with iOS 6.
 *
 * Once these are nicely completed it should be more obvious how to handle state
 *  preservation for iOS 5 (our minimum, or there just isn't any? or we do a 
 * better job through other means.
 *
 * Feel free to examine the coder to verify we should restore from it.
 *
 * We can encode/decode our information because none of the data is not 
 * re-retrievable.
 */
- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder
{
    NSLog(@"shouldSaveApplicationState: %@", coder);
    return YES;
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder
{
    NSLog(@"shouldRestoreApplicationState: %@", coder);

    return YES;
}

- (void)application:(UIApplication *)application willEncodeRestorableStateWithCoder:(NSCoder *)coder
{
    NSLog(@"willEncodeRestorableStateWithCoder: %@", coder);
    NSLog(@"self.window.rootViewController:%@", self.window.rootViewController);

    // I do wonder if encoding this here is the best option.
    // hmmm...
    [coder encodeObject:self.window.rootViewController forKey:@"RootVC"];
    return;
}

- (void)application:(UIApplication *)application didDecodeRestorableStateWithCoder:(NSCoder *)coder
{
    NSLog(@"didDecodeRestorableStateWithCoder: %@", coder);
    UIViewController *vc = [coder decodeObjectForKey:@"RootVC"];
    
    if (vc)
    {
        NSLog(@"vc found!");
        self.viewController = (YawningPandaViewController *)vc;
    }
    
    return;
}

- (UIViewController *)application:(UIApplication *)application viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents
                            coder:(NSCoder *)coder
{
    NSLog(@"viewControllerWithRestorationIdentifierPath: %@, %@", identifierComponents, coder);
    return nil;
}


@end
