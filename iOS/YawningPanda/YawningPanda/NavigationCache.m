//
//  NavigationCache.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/15/12.
//
//

#import "NavigationCache.h"

@implementation NavigationCache

@synthesize postId;
@synthesize posts;

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.posts forKey:@"posts"];
    [coder encodeObject:self.postId forKey:@"postId"];
    
    return;
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [super init])
    {
        self.posts = [coder decodeObjectForKey:@"posts"];
        self.postId = [coder decodeObjectForKey:@"postId"];
    }
    
    return self;
}

- (id)init
{
    if (self = [super init])
    {
        self.postId = [[NSMutableArray alloc] init];
        self.posts = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

/**
 * @brief Grab a post at the index.
 *
 * @param index
 */
- (Post *)postAtIndex:(int)index
{
    if ([self.postId count] == 0)
    {
        return nil;
    }

    return (self.posts)[(self.postId)[index]];
}

/**
 * @brief Grab post with the ID.
 *
 * @param idValue 
 */
- (Post *)postWithId:(NSString *)idValue
{
    return self.posts[idValue];
}

/**
 * @brief Update the cache with the posts received; doesn't handle refresh, etc.
 *
 * @param postArray the posts downloaded from the query.
 */
- (void)setCache:(NSArray *)postArray
{
    [self.posts removeAllObjects];
    [self.postId removeAllObjects];

    for (Post *post in postArray)
    {
        [self.postId addObject:post.postid];
        (self.posts)[post.postid] = post;
    }
    
    return;
}

/**
 * @brief Set the user screen_name and display_name for the posts stored.
 *
 * @param user a user's info.
 */
- (void)setAuthor:(User *)user
{
    for (NSString *pid in self.postId)
    {
        Post *post = self.posts[pid];
        if ([post.author isEqualToString:user.userid])
        {
            post.screen_name = user.screen_name;
            post.display_name = user.display_name;
            post.cachingUser = NO;
        }
    }
    
    return;
}

/**
 * @brief Set the comments for the specified post with the comment array 
 * provided.
 *
 * @param comments the comments array.
 * @param idvalue the post's ID.
 */
- (void)setComments:(NSMutableArray *)comments forPost:(NSString *)idValue
{
    int comm_cnt = [comments count];
    Post *post = [self postWithId:idValue];
    if (post != nil)
    {
        post.commentsRefreshed = [[NSDate alloc] init];
        post.comments = comments;
        if (comm_cnt > 0) // did we download no results, then don't update.
        {
            post.num_comments = [comments count];
        }
    }
    
    return;
}

/**
 * Insert a lead comment.
 */
- (void)addComment:(Comment *)comment forPost:(NSString *)idValue
{
    Post *post = [self postWithId:idValue];
    if (post != nil)
    {
        [post.comments insertObject:comment atIndex:0];
        post.num_comments += 1;
    }
    
    return;
}

/**
 * @brief Get the index for the post with the id, yeah, should be in there.
 *
 * @param idValue the identifier.
 */
- (int)indexForPost:(NSString *)idValue
{
    int postCount = [self.postId count];
    int i;

    for (i = 0; i < postCount; i++)
    {
        if ([idValue isEqualToString:(self.postId)[i]])
        {
            break;
        }
    }
    
    return i;
}

/**
 * @brief Drop all data.
 */
- (void)dropData
{
    [self.postId removeAllObjects];
    [self.posts removeAllObjects];
    
    return;
}

/**
 * @brief Drop off the last items, those beyond index 199.
 */
- (void)prune
{
    int postCount = [self.postId count];
    int i;
    
    if (postCount > 200)
    {
        for (i = 199; i < postCount; i++)
        {
            [self.posts removeObjectForKey:(self.postId)[i]];
        }
        
        /*
         * I'm assumign this means delete objects start at 200 and going for 
         * the remaining ones.
         */
        [self.postId removeObjectsInRange:NSMakeRange(200, postCount - 200)];
    }

    return;
}

/**
 * @brief Get rid of all images stored with posts.
 */
- (void)flushImages
{
    /*
     * This is faster than going through the keys; as each access would be 
     * constant time, but those add up.
     */
    [self.posts enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
    {
        Post *post = (Post *)obj;
        post.image = nil;
    }];
    
    return;
}

@end
