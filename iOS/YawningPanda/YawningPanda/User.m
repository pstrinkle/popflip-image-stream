//
//  User.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 7/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "User.h"
#import "Util.h"

@implementation User

@synthesize userid;
@synthesize bio;
@synthesize created;
@synthesize screen_name, display_name, realish_name;
@synthesize email;
@synthesize home;
@synthesize location;
@synthesize watches, badges;
@synthesize watching, watched;
@synthesize image;
@synthesize createdStamp;
@synthesize authorized;
@synthesize coordinate;
@synthesize validCoordinates;

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate
{
    /* do not use self here, or it'll infinite loop as self. calls the synthesized accessors. */
    coordinate = newCoordinate;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.realish_name forKey:@"realish_name"];
    [coder encodeObject:self.screen_name forKey:@"screen_name"];
    [coder encodeObject:self.display_name forKey:@"display_name"];

    [coder encodeObject:self.userid forKey:@"userid"];
    [coder encodeObject:self.bio forKey:@"bio"];
    [coder encodeObject:self.created forKey:@"created"];
    [coder encodeObject:self.email forKey:@"email"];
    [coder encodeObject:self.home forKey:@"home"];
    [coder encodeObject:self.location forKey:@"location"];

    [coder encodeObject:self.watches forKey:@"watches"];
    [coder encodeObject:self.badges forKey:@"badges"];
    [coder encodeInteger:self.watching forKey:@"watching"];
    [coder encodeInteger:self.watched forKey:@"watched"];

    [coder encodeObject:self.createdStamp forKey:@"createdStamp"];
    [coder encodeObject:self.image forKey:@"image"];
    [coder encodeBool:self.authorized forKey:@"authorized"];
    [coder encodeBool:self.authorized_back forKey:@"authorized_back"];

    [coder encodeDouble:self.coordinate.latitude forKey:@"latitude"];
    [coder encodeDouble:self.coordinate.longitude forKey:@"longitude"];
    [coder encodeBool:self.validCoordinates forKey:@"validCoordinates"];

    return;
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [super init])
    {
        self.realish_name = [coder decodeObjectForKey:@"realish_name"];
        self.screen_name = [coder decodeObjectForKey:@"screen_name"];
        self.display_name = [coder decodeObjectForKey:@"display_name"];

        self.userid = [coder decodeObjectForKey:@"userid"];
        self.bio = [coder decodeObjectForKey:@"bio"];
        self.created = [coder decodeObjectForKey:@"created"];
        self.email = [coder decodeObjectForKey:@"email"];
        self.home = [coder decodeObjectForKey:@"home"];
        self.location = [coder decodeObjectForKey:@"location"];

        self.watches = [coder decodeObjectForKey:@"watches"];
        self.badges = [coder decodeObjectForKey:@"badges"];
        self.watching = [coder decodeIntegerForKey:@"watching"];
        self.watched = [coder decodeIntegerForKey:@"watched"];

        self.createdStamp = [coder decodeObjectForKey:@"createdStamp"];
        self.image = [coder decodeObjectForKey:@"image"];
        self.authorized = [coder decodeBoolForKey:@"authorized"];
        self.authorized_back = [coder decodeBoolForKey:@"authorized_back"];

        coordinate.latitude = [coder decodeDoubleForKey:@"latitude"];
        coordinate.longitude = [coder decodeDoubleForKey:@"longitude"];
        self.validCoordinates = [coder decodeBoolForKey:@"validCoordinates"];
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
        NSLog(@"input: %@", jsonDict);

        self.screen_name = jsonDict[@"screen_name"];
        self.display_name = jsonDict[@"display_name"];
        self.realish_name = jsonDict[@"realish_name"];

        self.userid = jsonDict[@"id"];
        self.bio = jsonDict[@"bio"];
        self.created = jsonDict[@"created"];
        self.email = jsonDict[@"email"];
        self.home = jsonDict[@"home"];

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

        self.watches = jsonDict[@"watches"];
        self.badges = jsonDict[@"badges"];

        NSNumber *tmp = nil;

        tmp = jsonDict[@"watched"];
        self.watched = tmp.integerValue;

        tmp = jsonDict[@"watching"];
        self.watching = tmp.integerValue;

        // This tells you if you're authorized to see this person's comments.
        // NOT if they're authorized to see yours.
        self.authorized = NO;
        tmp = jsonDict[@"authorized"];
        if (tmp != nil)
        {
            self.authorized = (bool)tmp.intValue;
        }
        
        self.authorized_back = NO;
        tmp = jsonDict[@"authorized_back"];
        if (tmp != nil)
        {
            self.authorized_back = (bool)tmp.intValue;
        }

        self.image = nil;

        // convert to date
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        // "Sat Jul 28 14:52:26 2012"
        [dateFormat setDateFormat:@"EEE MMM dd HH:mm:ss yyyy"];
        [dateFormat setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
        self.createdStamp = [dateFormat dateFromString:self.created];
        //NSLog(@"Post Date In: %@ Out: %@", self.created, self.createdStamp);
    }
    
    return self;
}

// In the implementation
- (id)copyWithZone:(NSZone *)zone
{
    // We'll ignore the zone for now
    User *another = [[User alloc] init];

    another.screen_name = self.screen_name;
    another.realish_name = self.realish_name;
    another.display_name = self.display_name;

    another.userid = self.userid;
    another.bio = self.bio;
    another.created = self.created;
    another.email = self.email;
    another.home = self.home;

    another.watched = self.watched;
    another.watching = self.watching;

    another.watches = self.watches;
    another.badges = self.badges;

    another.image = self.image;
    another.createdStamp = self.createdStamp;
    
    another.authorized = self.authorized;

    another.location = self.location;
    another.coordinate = self.coordinate;
    another.validCoordinates = self.validCoordinates;

    return another;
}

@end
