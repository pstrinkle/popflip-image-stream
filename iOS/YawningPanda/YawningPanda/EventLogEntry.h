//
//  EventLogEntry.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 8/8/12.
//
//

#import <Foundation/Foundation.h>

enum EventType
{
    EVENT_TYPE_POST = 0,
    EVENT_TYPE_POST_ATTEMPT,
    EVENT_TYPE_REPLY_ATTEMPT,
    EVENT_TYPE_REPOST_ATTEMPT,
    EVENT_TYPE_JOIN,
    EVENT_TYPE_LEAVE,
    EVENT_TYPE_LOGIN,
    EVENT_TYPE_LOGOUT,
    EVENT_TYPE_PIVOT,
    EVENT_TYPE_ENJOY,
    EVENT_TYPE_FAVORITE,
    EVENT_TYPE_UNFAVORITE,
    EVENT_TYPE_WATCH,
    EVENT_TYPE_UNWATCH,
    EVENT_TYPE_UPDATE,
    EVENT_TYPE_MEMORY_WARNING,
    EVENT_TYPE_CONNECTION_FAILURE,
    EVENT_TYPE_AUTHORIZE,
    EVENT_TYPE_UNAUTHORIZE
};

@interface EventLogEntry : NSObject <NSCoding>

@property enum EventType eventType;
@property bool result;

@property(copy) NSDate *date;
@property(copy) NSString *note;
@property(copy) UIImage *image;
/* Be careful how much crap you store here. */
@property(copy) NSDictionary *details;

- (id)init;
+ (NSString *)typeToString:(enum EventType)type;

@end
