//
//  YawningPandaAppDelegate.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 7/18/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class YawningPandaViewController;

@interface YawningPandaAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, strong) IBOutlet UIWindow *window;

@property (nonatomic, strong) IBOutlet YawningPandaViewController *viewController;

@end
