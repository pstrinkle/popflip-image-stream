//
//  Comment.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 10/21/12.
//
//

#import "Comment.h"

@implementation Comment

@synthesize author, created, createdStamp, comment;

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.author forKey:@"author"];
    [coder encodeObject:self.created forKey:@"created"];
    [coder encodeObject:self.createdStamp forKey:@"createdStamp"];
    [coder encodeObject:self.comment forKey:@"comment"];
    
    return;
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [super init])
    {
        self.author = [coder decodeObjectForKey:@"author"];
        self.created = [coder decodeObjectForKey:@"created"];
        self.createdStamp = [coder decodeObjectForKey:@"createdStamp"];
        self.comment = [coder decodeObjectForKey:@"comment"];
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
        self.author = jsonDict[@"user"];
        self.comment = jsonDict[@"comment"];
        self.created = jsonDict[@"created"];

        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        // "Sat Jul 28 14:52:26 2012"
        [dateFormat setDateFormat:@"EEE MMM dd HH:mm:ss yyyy"];
        [dateFormat setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];

        self.createdStamp = [dateFormat dateFromString:self.created];
    }
    
    return self;
}

@end
