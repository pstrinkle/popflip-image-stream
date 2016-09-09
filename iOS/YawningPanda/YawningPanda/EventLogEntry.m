//
//  EventLogEntry.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 8/8/12.
//
//

#import "EventLogEntry.h"

@implementation EventLogEntry

@synthesize eventType;
@synthesize image;
@synthesize note;
@synthesize result;
@synthesize date;
@synthesize details;

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.date forKey:@"date"];
    [coder encodeObject:self.note forKey:@"note"];
    [coder encodeObject:self.image forKey:@"image"];
    [coder encodeObject:self.details forKey:@"details"];
    [coder encodeBool:self.result forKey:@"result"];
    [coder encodeInt:self.eventType forKey:@"eventType"];

    return;
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [super init])
    {
        self.date = [coder decodeObjectForKey:@"date"];
        self.note = [coder decodeObjectForKey:@"note"];
        self.image = [coder decodeObjectForKey:@"image"];
        self.details = [coder decodeObjectForKey:@"details"];
        self.result = [coder decodeBoolForKey:@"result"];
        self.eventType = [coder decodeIntForKey:@"eventType"];
    }

    return self;
}

- (id)init
{
    if (self = [super init])
    {
        NSDate *tmp = [[NSDate alloc] init];
        self.date = tmp;
    }
    
    return self;
}

+ (NSString *)typeToString:(enum EventType)type
{
    switch (type)
    {
        case EVENT_TYPE_POST:
            return @"Post";
        case EVENT_TYPE_POST_ATTEMPT:
            return @"Post Attempt";
        case EVENT_TYPE_REPLY_ATTEMPT:
            return @"Reply Attempt";
        case EVENT_TYPE_REPOST_ATTEMPT:
            return @"Repost Attempt";
        case EVENT_TYPE_JOIN:
            return @"Join";
        case EVENT_TYPE_LEAVE:
            return @"Leave";
        case EVENT_TYPE_LOGIN:
            return @"Login";
        case EVENT_TYPE_LOGOUT:
            return @"Logout";
        case EVENT_TYPE_PIVOT:
            return @"Pivot";
        case EVENT_TYPE_ENJOY:
            return @"Enjoy";
        case EVENT_TYPE_FAVORITE:
            return @"Favorite";
        case EVENT_TYPE_UNFAVORITE:
            return @"Unfavorite";
        case EVENT_TYPE_WATCH:
            return @"Watch";
        case EVENT_TYPE_UNWATCH:
            return @"Unwatch";
        case EVENT_TYPE_UPDATE:
            return @"Update";
        case EVENT_TYPE_MEMORY_WARNING:
            return @"Memory Warning";
        case EVENT_TYPE_CONNECTION_FAILURE:
            return @"Connection Error";
        case EVENT_TYPE_AUTHORIZE:
            return @"Authorize";
        case EVENT_TYPE_UNAUTHORIZE:
            return @"Unauthorizer";
        default:
            return @"";
    }
}

@end
