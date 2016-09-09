//
//  PostInfoBundle.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/22/12.
//
//

#import <Foundation/Foundation.h>
#import "Post.h"
#import "User.h"

@interface PostInfoBundle : NSObject

@property(strong) NSMutableArray *sections;
@property(copy) Post *postContents;
@property(copy) User *userContents;

- (id)initWithPost:(Post *)post withUser:(User *)user;

@end
