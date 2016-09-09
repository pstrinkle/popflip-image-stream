//
//  Post.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

/*
 author = 50044d1f5e358e174600002d;
 "content-type" = image;
 created = "2012-07-16 17:20:09.554000";
 disliked = 0;
 enjoyed = 0;
 file = placeholder;
 flagged = 0;
 id = 50044d495e358e1747000016;
 location = temp;
 "num_replies" = 0;
 "remote_addr" = "69.136.226.114";
 "reply_to" = 50044d2d5e358e174700008d;
 tags =     (
 couch,
 attack,
 jack
 );
 "user_agent" = "Python-urllib/2.7";
 viewed = 0;
 */

#import "Post.h"
#import "Util.h"

@implementation Post

/* accessors */
@synthesize image, thumbnail;
@synthesize num_replies, num_reposts;
@synthesize reply_to, repost_of;
@synthesize author;
@synthesize created;
@synthesize postid;
@synthesize tags;
@synthesize screen_name;
@synthesize cachingImage;
@synthesize cachingUser;
@synthesize cachingThumbnail;
@synthesize favorite_of_user;
@synthesize communities;
@synthesize display_name;
@synthesize createdStamp;
@synthesize location;
@synthesize coordinate;
@synthesize validCoordinates;
@synthesize comments, commentsRefreshed;

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate
{
    /* do not use self here, or it'll infinite loop as self. calls the synthesized accessors. */
    coordinate = newCoordinate;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeBool:self.favorite_of_user forKey:@"favorite_of_user"];
    [coder encodeBool:self.validCoordinates forKey:@"validCoordinates"];

    [coder encodeInteger:self.num_replies forKey:@"num_replies"];
    [coder encodeInteger:self.num_reposts forKey:@"num_reposts"];
    [coder encodeInteger:self.num_comments forKey:@"num_comments"];

    [coder encodeObject:self.reply_to forKey:@"reply_to"];
    [coder encodeObject:self.repost_of forKey:@"repost_of"];
    [coder encodeObject:self.author forKey:@"author"];
    [coder encodeObject:self.screen_name forKey:@"screen_name"];
    [coder encodeObject:self.display_name forKey:@"display_name"];
    [coder encodeObject:self.created forKey:@"created"];
    [coder encodeObject:self.postid forKey:@"postid"];
    [coder encodeObject:self.location forKey:@"location"];
    [coder encodeObject:self.tags forKey:@"tags"];
    
    [coder encodeObject:self.comments forKey:@"comments"];
    [coder encodeObject:self.commentsRefreshed forKey:@"commentsRefreshed"];
    
    [coder encodeObject:self.createdStamp forKey:@"createdStamp"];
    [coder encodeObject:self.communities forKey:@"communities"];
    [coder encodeObject:self.image forKey:@"image"];
    [coder encodeObject:self.thumbnail forKey:@"thumbnail"];

    [coder encodeDouble:self.coordinate.latitude forKey:@"latitude"];
    [coder encodeDouble:self.coordinate.longitude forKey:@"longitude"];

    return;
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [super init])
    {
        self.favorite_of_user = [coder decodeBoolForKey:@"favorite_of_user"];
        self.validCoordinates = [coder decodeBoolForKey:@"validCoordinates"];
    
        self.num_replies = [coder decodeIntegerForKey:@"num_replies"];
        self.num_reposts = [coder decodeIntegerForKey:@"num_reposts"];
        self.num_comments = [coder decodeIntegerForKey:@"num_comments"];
        
        self.reply_to = [coder decodeObjectForKey:@"reply_to"];
        self.repost_of = [coder decodeObjectForKey:@"repost_of"];
        self.author = [coder decodeObjectForKey:@"author"];
        self.screen_name = [coder decodeObjectForKey:@"screen_name"];
        self.display_name = [coder decodeObjectForKey:@"display_name"];
        self.created = [coder decodeObjectForKey:@"created"];
        self.postid = [coder decodeObjectForKey:@"postid"];
        self.location = [coder decodeObjectForKey:@"location"];
        self.tags = [coder decodeObjectForKey:@"tags"];
        self.comments = [coder decodeObjectForKey:@"comments"];
        self.commentsRefreshed = [coder decodeObjectForKey:@"commentsRefreshed"];
        self.createdStamp = [coder decodeObjectForKey:@"createdStamp"];
        self.communities = [coder decodeObjectForKey:@"communities"];
        self.image = [coder decodeObjectForKey:@"image"];
        self.thumbnail = [coder decodeObjectForKey:@"thumbnail"];
        
        coordinate.latitude = [coder decodeDoubleForKey:@"latitude"];
        coordinate.longitude = [coder decodeDoubleForKey:@"longitude"];

        self.cachingImage = NO;
        self.cachingUser = NO;
        self.cachingThumbnail = NO;
    }
    
    return self;
}

- (id)init
{
    if (self = [super init])
    {
        
    }
    
    return self;
}

- (id)initWithJSONDict:(NSDictionary *)jsonDict
{
    if (self = [super init])
    {
//        NSLog(@"input: %@", jsonDict);

        self.favorite_of_user = NO;

        self.cachingImage = NO;
        self.cachingUser = NO;
        self.cachingThumbnail = NO;

        self.created = jsonDict[@"created"];

        // convert to date
//        NSLog(@"%@", [NSTimeZone knownTimeZoneNames]);
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        // "Sat Jul 28 14:52:26 2012"
        [dateFormat setDateFormat:@"EEE MMM dd HH:mm:ss yyyy"];
        [dateFormat setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
        self.createdStamp = [dateFormat dateFromString:self.created];
        //NSLog(@"Post Date In: %@ Out: %@", self.created, self.createdStamp);

        self.location = jsonDict[@"location"];
        self.validCoordinates = NO;
        
        if ([Util locationIs2DCoordinate:self.location])
        {
            NSArray *points = [self.location componentsSeparatedByString:@", "];
            
            float latitude = [points[0] floatValue];
            float longitude = [points[1] floatValue];
            
            coordinate.longitude = longitude;
            coordinate.latitude = latitude;
            
            self.validCoordinates = YES;
        }

        NSNumber *tmp = nil;

        tmp = jsonDict[@"num_replies"];
        self.num_replies = tmp.integerValue;

        tmp = jsonDict[@"num_reposts"];
        self.num_reposts = tmp.integerValue;

        tmp = jsonDict[@"comments"];
        self.num_comments = tmp.integerValue;

        self.author = jsonDict[@"author"];
        self.postid = jsonDict[@"id"];
        
        self.reply_to = jsonDict[@"reply_to"]; // returns nil on failure.
        self.repost_of = jsonDict[@"repost_of"]; // returns nil on failure.
        
        self.tags = jsonDict[@"tags"];

        /* This may seem crazy; but it's the only way to pull a boolean from it. */
        tmp = jsonDict[@"favorite_of_user"];
        self.favorite_of_user = (bool)tmp.intValue;

        // I am pretty sure I want to make this nil.
        self.image = nil;
        self.thumbnail = nil;
        self.screen_name = nil;
        self.display_name = nil;
        self.commentsRefreshed = nil;

        /* turning off this code didn't change anything. =/ */
        NSMutableArray *tmpArray = [[NSMutableArray alloc] init];
        self.communities = tmpArray;
        
        if ([self.tags count] > 1)
        {
            [self.communities addObject:[NSString stringWithFormat:@"%@,%@",
                                         (self.tags)[0],
                                         (self.tags)[1]]];
            
            if ([self.tags count] > 2)
            {
                [self.communities addObject:[NSString stringWithFormat:@"%@,%@",
                                             (self.tags)[1],
                                             (self.tags)[2]]];
                [self.communities addObject:[NSString stringWithFormat:@"%@,%@",
                                             (self.tags)[0],
                                             (self.tags)[2]]];
            }
        }
        
        self.comments = [[NSMutableArray alloc] init];
    }
    
    return self;
}

// In the implementation
- (id)copyWithZone:(NSZone *)zone
{
    // We'll ignore the zone for now
    Post *another = [[Post alloc] init];
    
    another.location = self.location;
    another.num_replies = self.num_replies;
    another.num_reposts = self.num_reposts;
    another.author = self.author;
    another.created = self.created;
    another.postid = self.postid;
    another.reply_to = self.reply_to;
    another.repost_of = self.repost_of;
    another.tags = self.tags;
    another.favorite_of_user = self.favorite_of_user;
    
    another.image = self.image;
    another.thumbnail = self.thumbnail;
    another.screen_name = self.screen_name;
    another.display_name = self.display_name;
    
    /* should these not be copied? */
    another.cachingImage = self.cachingImage;
    another.cachingUser = self.cachingUser;
    another.cachingThumbnail = self.cachingThumbnail;
    
    another.communities = self.communities;
    
    another.createdStamp = self.createdStamp;
    
    another.coordinate = self.coordinate;
    another.validCoordinates = self.validCoordinates;
    
    another.comments = self.comments;
    another.commentsRefreshed = self.commentsRefreshed;
    
    return another;
}

@end
