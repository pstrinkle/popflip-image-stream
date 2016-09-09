//
//  WatchList.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/7/12.
//
//

#import "WatchList.h"

@implementation WatchList

@synthesize avatars, userids, screennames;

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.userids forKey:@"userids"];
    [coder encodeObject:self.avatars forKey:@"avatars"];
    [coder encodeObject:self.screennames forKey:@"screennames"];
    
    return;
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [super init])
    {
        self.userids = [coder decodeObjectForKey:@"userids"];
        self.avatars = [coder decodeObjectForKey:@"avatars"];
        self.screennames = [coder decodeObjectForKey:@"screennames"];
    }
    
    return self;
}

- (id)init
{
    if (self = [super init])
    {
        self.userids = [[NSMutableArray alloc] init];
        self.avatars = [[NSMutableDictionary alloc] init];
        self.screennames = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (NSUInteger)count
{
    return [self.userids count];
}

- (void)addUser:(NSString *)user
{
    if (![self.userids containsObject:user])
    {
        [self.userids addObject:user];
    }
}

- (void)dropUser:(NSString *)user
{
    [self.userids removeObject:user];
    [self.avatars removeObjectForKey:user];
    [self.screennames removeObjectForKey:user];
}

- (void)dropAllUsers
{
    [self.userids removeAllObjects];
    [self.avatars removeAllObjects];
    [self.screennames removeAllObjects];
}

- (void)dropInvalid
{
    NSArray *avas = [self.avatars allKeys];
    NSArray *scrs = [self.screennames allKeys];
    NSMutableArray *drops = [[NSMutableArray alloc] init];
    
    for (NSString *user in avas)
    {
        if (![self.userids containsObject:user])
        {
            [drops addObject:user];
        }
    }

    for (NSString *user in scrs)
    {
        if (![self.userids containsObject:user])
        {
            [drops addObject:user];
        }
    }

    [self.avatars removeObjectsForKeys:drops];
    [self.screennames removeObjectsForKeys:drops];
}

@end
