//
//  APIManager.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/11/12.
//
//

#import "APIManager.h"
#import "Util.h"

@implementation APIManager

@synthesize apiCache;
@synthesize delegate;

- (id)initWithDelegate:(id<CompletionDelegate>)apidelegate
{
    if (self = [super init])
    {
        self.apiCache = [[NSMutableArray alloc] init];
        self.delegate = apidelegate;
    }
    
    return self;
}

- (void)dropHandler:(APIHandler *)apihandler
{
    [self.apiCache removeObject:apihandler];
}

- (void)cancelAll
{
    NSLog(@"Canceling all: %@", self.apiCache);

    for (APIHandler *api in self.apiCache)
    {
        [api cancel];
    }
    
    [self.apiCache removeAllObjects];
}

- (int)outStanding
{
    return [self.apiCache count];
}

/**
 * @todo Seriously, time to refactor.  There couldn't readily be more duplicate
 * code.
 */

- (void)getAuthor:(NSString *)user asUser:(NSString *)myId
{
    APIHandler *api = [[APIHandler alloc] init];
    api.delegate = self.delegate;

    [self.apiCache addObject:api];

    [api getAuthor:user asUser:myId];

    return;
}

- (void)userView:(NSString *)userid
{
    APIHandler *api = [[APIHandler alloc] init];
    api.delegate = self.delegate;
    
    [self.apiCache addObject:api];
    
    [api userView:userid];
    
    return;
}

- (void)loginUser:(NSString *)screenName
{
    APIHandler *api = [[APIHandler alloc] init];
    api.delegate = self.delegate;

    [self.apiCache addObject:api];

    [api loginUser:screenName];

    return;
}

- (void)userQuery:(NSString *)userid withRequest:(NSString *)query asUser:(NSString *)myId
{
    APIHandler *api = [[APIHandler alloc] init];
    api.delegate = self.delegate;

    [self.apiCache addObject:api];

    [api userQuery:userid withRequest:query asUser:myId];

    return;
}

- (void)viewPost:(NSString *)identifier asLarge:(bool)large
{
    APIHandler *api = [[APIHandler alloc] init];
    api.delegate = self.delegate;
    
    [self.apiCache addObject:api];
    
    [api viewPost:identifier asLarge:(bool)large];
    
    return;
}

- (void)viewThumbnail:(NSString *)identifier
{
    APIHandler *api = [[APIHandler alloc] init];
    api.delegate = self.delegate;
    
    [self.apiCache addObject:api];
    
    [api viewThumbnail:identifier];
    
    return;
}

- (void)viewThumbnail:(NSString *)identifier withID:(NSString *)key
{
    APIHandler *api = [[APIHandler alloc] init];
    api.delegate = self.delegate;
    api.callerIdentifier = key;
    
    [self.apiCache addObject:api];
    
    [api viewThumbnail:identifier];
    
    return;
}

- (void)getPost:(NSString *)identifier asUser:(NSString *)querierid
{
    APIHandler *api = [[APIHandler alloc] init];
    api.delegate = self.delegate;
    
    [self.apiCache addObject:api];
    
    [api getPost:identifier asUser:querierid];
    
    return;
}

- (void)queryPosts:(NSString *)query
         withValue:(NSString *)value
            asUser:(NSString *)querierid
{
    [self queryPosts:query withValue:value asUser:querierid withID:nil since:nil];
    
    return;
}

- (void)queryPosts:(NSString *)query
         withValue:(NSString *)value
            asUser:(NSString *)querierid
             since:(NSString *)sinceId
{
    [self queryPosts:query withValue:value asUser:querierid withID:nil since:sinceId];

    return;
}

- (void)queryPosts:(NSString *)query
         withValue:(NSString *)value
            asUser:(NSString *)querierid
            withID:(NSString *)key
{
    [self queryPosts:query withValue:value asUser:querierid withID:key since:nil];
    
    return;
}

/**
 * @brief This one does all the work, kind of.  There isn't a lot of 
 * documentation here because this is really just a wrapper for APIHandler.
 */
- (void)queryPosts:(NSString *)query
         withValue:(NSString *)value
            asUser:(NSString *)querierid
            withID:(NSString *)key
             since:(NSString *)sinceId
{
    APIHandler *api = [[APIHandler alloc] init];
    api.delegate = self.delegate;
    api.callerIdentifier = key;
    
    [self.apiCache addObject:api];
    
    [api queryPosts:query withValue:value asUser:querierid since:sinceId];
    
    return;
}

- (void)publicStream:(NSString *)user
{
    APIHandler *api = [[APIHandler alloc] init];
    api.delegate = self.delegate;
    
    [self.apiCache addObject:api];
    
    [api publicStream:user];
    
    return;
}

- (void)userHome:(NSString *)myId
{
    APIHandler *api = [[APIHandler alloc] init];
    api.delegate = self.delegate;
    
    [self.apiCache addObject:api];
    
    [api userHome:myId];
    
    return;
}

- (void)watchUser:(NSString *)myId watchesUser:(NSString *)userid
{
    APIHandler *api = [[APIHandler alloc] init];
    api.delegate = self.delegate;
    
    [self.apiCache addObject:api];
    
    [api watchUser:myId watchesUser:userid];
    
    return;
}

- (void)unwatchUser:(NSString *)myId unwatchesUser:(NSString *)userid
{
    APIHandler *api = [[APIHandler alloc] init];
    api.delegate = self.delegate;
    
    [self.apiCache addObject:api];
    
    [api unwatchUser:myId unwatchesUser:userid];
    
    return;
}

/** @todo: You can just use Util getHandler:self.delegate */
- (void)joinCommunity:(NSString *)myId withTags:(NSArray *)tags
{
    APIHandler *api = [[APIHandler alloc] init];
    api.delegate = self.delegate;
    
    [self.apiCache addObject:api];
    
    [api joinCommunity:myId withTags:tags];
    
    return;
}

- (void)leaveCommunity:(NSString *)myId withTags:(NSArray *)tags
{
    APIHandler *api = [[APIHandler alloc] init];
    api.delegate = self.delegate;
    
    [self.apiCache addObject:api];
    
    [api leaveCommunity:myId withTags:tags];
    
    return;
}

- (void)favoritePost:(NSString *)identifier asUser:(NSString *)userid
{
    APIHandler *api = [[APIHandler alloc] init];
    api.delegate = self.delegate;
    
    [self.apiCache addObject:api];
    
    [api favoritePost:identifier asUser:userid];
    
    return;
}

- (void)unfavoritePost:(NSString *)identifier asUser:(NSString *)userid
{
    APIHandler *api = [[APIHandler alloc] init];
    api.delegate = self.delegate;
    
    [self.apiCache addObject:api];
    
    [api unfavoritePost:identifier asUser:userid];
    
    return;
}

- (void)reportPost:(NSString *)identifier asUser:(NSString *)userid
{
    APIHandler *api = [[APIHandler alloc] init];
    api.delegate = self.delegate;

    [self.apiCache addObject:api];

    [api reportPost:identifier asUser:userid];

    return;
}

- (void)createPost:(NSString *)author
          withTags:(NSArray *)tags
          withData:(NSData *)image
      withLocation:(NSString *)point
{
    APIHandler *api = [[APIHandler alloc] init];
    api.delegate = self.delegate;
    
    [self.apiCache addObject:api];
    
    [api createPost:author withTags:tags withData:image withLocation:point];
    
    return;
}

- (void)replyPost:(NSString *)author
         withTags:(NSArray *)tags
         withData:(NSData *)image
     withLocation:(NSString *)point
          asReply:(NSString *)replyTo
{
    APIHandler *api = [[APIHandler alloc] init];
    api.delegate = self.delegate;
    
    [self.apiCache addObject:api];
    
    [api replyPost:author
          withTags:tags
          withData:image
      withLocation:point
           asReply:replyTo];
    
    return;
}

- (void)repostPost:(NSString *)author
          withTags:(NSArray *)tags
          asRepost:(NSString *)repostOf
{
    APIHandler *api = [[APIHandler alloc] init];
    api.delegate = self.delegate;
    
    [self.apiCache addObject:api];
    
    [api repostPost:author withTags:tags asRepost:repostOf];
    
    return;
}

- (void)userUpdate:(NSString *)userid
          forField:(NSString *)field
         withValue:(NSString *)value
{
    APIHandler *api = [[APIHandler alloc] init];
    api.delegate = self.delegate;

    [self.apiCache addObject:api];

    [api userUpdate:userid forField:field withValue:value];

    return;
}

- (void)userUpdate:(NSString *)userid withData:(NSData *)data
{
    APIHandler *api = [[APIHandler alloc] init];
    api.delegate = self.delegate;

    [self.apiCache addObject:api];

    [api userUpdate:userid withData:data];

    return;
}

- (void)getComments:(NSString *)identifier asUser:(NSString *)userid
{
    APIHandler *api = [[APIHandler alloc] init];
    api.delegate = self.delegate;

    [self.apiCache addObject:api];

    [api getComments:identifier asUser:userid];

    return;
}

- (void)authorizeUser:(NSString *)user asUser:(NSString *)requester
{
    APIHandler *api = [[APIHandler alloc] init];
    api.delegate = self.delegate;

    [self.apiCache addObject:api];

    [api authorizeUser:user asUser:requester];

    return;
}

- (void)unauthorizeUser:(NSString *)user asUser:(NSString *)requester
{
    APIHandler *api = [[APIHandler alloc] init];
    api.delegate = self.delegate;

    [self.apiCache addObject:api];

    [api unauthorizeUser:user asUser:requester];

    return;
}

@end
