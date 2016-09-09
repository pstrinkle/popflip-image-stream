//
//  YawningPandaTests.h
//  YawningPandaTests
//
//  Created by Patrick Trinkle on 7/18/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

//#import "Post.h"
#import "APIHandler.h"
#import "YawningPandaAppDelegate.h"
#import "YawningPandaViewController.h"

@interface YawningPandaTests : SenTestCase <CompletionDelegate>
{
    BOOL done;

@private
    YawningPandaAppDelegate *app_delegate;
    YawningPandaViewController *yawning_view_controller;
    UIView *yawning_view;
}

@property(copy) NSString *userId;
@property(copy) NSString *postId;
@property(copy) UIImage *imageValue;
@property(copy) NSMutableArray *queryResponse;
@property(copy) Post *thePost;

@end
