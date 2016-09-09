//
//  APIManager.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/11/12.
//
//

#import <Foundation/Foundation.h>
#import "APIHandler.h"

/**
 * @todo: If this inherits the APIHandler can it just call super and the thing?
 *
 * I don't think so.
 */
@interface APIManager : NSObject

@property(strong) NSMutableArray *apiCache;
@property(nonatomic, unsafe_unretained) id<CompletionDelegate> delegate;

- (id)initWithDelegate:(id<CompletionDelegate>)apidelegate;

/**
 * @brief Get rid of our handle to this pointer, so that it can be released.
 */
- (void)dropHandler:(APIHandler *)apihandler;

/**
 * @brief Cancel all outstanding API handlers; there should be no harm in 
 * calling cancel on one with a nil pointer.
 *
 * Of interest this will also release its hold on the instances.
 *
 * @note Currently there is no call to cancel each one individually; this is
 * very all or none --- and as such will likely only be used in a couple places.
 *  Basically, whenever you want to stop everything that view is doing.
 *
 */
- (void)cancelAll;

/**
 * @brief How many API calls are outstanding.
 */
- (int)outStanding;

/**
 * @brief This just creates an APIHandler for you, sets the delegate and calls
 * this method --- when the API method calls back, call drop with the pointer
 * you're provided, and we can lose the thing.
 *
 * @note Consider merging.
 */
- (void)getAuthor:(NSString *)user asUser:(NSString *)myId;
- (void)userView:(NSString *)userid;

- (void)loginUser:(NSString *)screenName;
- (void)userQuery:(NSString *)userid withRequest:(NSString *)query asUser:(NSString *)myId;

/**
 * @note Consider merging.
 */
- (void)viewPost:(NSString *)identifier asLarge:(bool)large;
- (void)viewThumbnail:(NSString *)identifier; /** @todo combine with viewPost() */
- (void)viewThumbnail:(NSString *)identifier withID:(NSString *)key;
- (void)getPost:(NSString *)identifier asUser:(NSString *)querierid;

- (void)queryPosts:(NSString *)query withValue:(NSString *)value asUser:(NSString *)querierid;
- (void)queryPosts:(NSString *)query withValue:(NSString *)value asUser:(NSString *)querierid since:(NSString *)sinceId;
- (void)queryPosts:(NSString *)query withValue:(NSString *)value asUser:(NSString *)querierid withID:(NSString *)key;
- (void)queryPosts:(NSString *)query withValue:(NSString *)value asUser:(NSString *)querierid withID:(NSString *)key since:(NSString *)sinceId;
- (void)publicStream:(NSString *)user;
- (void)userHome:(NSString *)myId;

- (void)watchUser:(NSString *)myId watchesUser:(NSString *)userid;
- (void)unwatchUser:(NSString *)myId unwatchesUser:(NSString *)userid;

- (void)joinCommunity:(NSString *)myId withTags:(NSArray *)tags;
- (void)leaveCommunity:(NSString *)myId withTags:(NSArray *)tags;

- (void)favoritePost:(NSString *)identifier asUser:(NSString *)userid;
- (void)unfavoritePost:(NSString *)identifier asUser:(NSString *)userid;
- (void)reportPost:(NSString *)identifier asUser:(NSString *)userid;

- (void)createPost:(NSString *)author withTags:(NSArray *)tags withData:(NSData *)image withLocation:(NSString *)point;
- (void)replyPost:(NSString *)author withTags:(NSArray *)tags withData:(NSData *)image withLocation:(NSString *)point asReply:(NSString *)replyTo;
- (void)repostPost:(NSString *)author withTags:(NSArray *)tags asRepost:(NSString *)repostOf;

- (void)userUpdate:(NSString *)userid forField:(NSString *)field withValue:(NSString *)value;
- (void)userUpdate:(NSString *)userid withData:(NSData *)data;

- (void)getComments:(NSString *)identifier asUser:(NSString *)userid;

- (void)authorizeUser:(NSString *)user asUser:(NSString *)requester;
- (void)unauthorizeUser:(NSString *)user asUser:(NSString *)requester;

@end
