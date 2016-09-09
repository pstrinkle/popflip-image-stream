//
//  PostInfoBundle.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/22/12.
//
//

#import "PostInfoBundle.h"

@implementation PostInfoBundle

@synthesize sections;
@synthesize postContents;
@synthesize userContents;

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.sections forKey:@"sections"];
    [coder encodeObject:self.postContents forKey:@"postContents"];
    [coder encodeObject:self.userContents forKey:@"userContents"];
    
    return;
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [super init])
    {
        self.sections = [coder decodeObjectForKey:@"sections"];
        self.postContents = [coder decodeObjectForKey:@"postContents"];
        self.userContents = [coder decodeObjectForKey:@"userContents"];
    }
    
    return self;
}

- (id)initWithPost:(Post *)post withUser:(User *)user
{
    if (self = [super init])
    {
        self.sections = [[NSMutableArray alloc] init];
        self.postContents = post;
        self.userContents = user;

        [self.sections addObject:@"postid"];

        [self.sections addObject:@"actions"];

        if (user != nil)
        {
            [self.sections addObject:@"authorview"];
        }
        else
        {
            /* We don't have the user... */
            [self.sections addObject:@"authorid"];
        }

        if (post.num_replies > 0)
        {
            [self.sections addObject:@"replies"];
        }

        if (post.num_reposts > 0)
        {
            [self.sections addObject:@"reposts"];
        }

        if (post.reply_to != nil)
        {
            [self.sections addObject:@"replyto"];
        }

        if (post.repost_of != nil)
        {
            [self.sections addObject:@"repostof"];
        }

        [self.sections addObject:@"created"];

        if ([post.tags count] > 0)
        {
            [self.sections addObject:@"tags"];
        }

        if ([post.communities count] > 0)
        {
            [self.sections addObject:@"communities"];
        }

        if (post.location != nil && [post.location length] > 0)
        {
            [self.sections addObject:@"location"];
        }
    }

    return self;
}

// In the implementation
- (id)copyWithZone:(NSZone *)zone
{
    /* This init function should handle everything since it's all handled there. */
    PostInfoBundle *another = \
        [[PostInfoBundle alloc] initWithPost:self.postContents
                                    withUser:self.userContents];
    
    return another;
}

@end
