//
//  NavigationCache.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/15/12.
//
//

#import <Foundation/Foundation.h>
#import "Post.h"
#import "User.h"
#import "Comment.h"

/* Not yet in-use, because I have to determine a good way to say, okay -- we
 * need it to tell the view to update, or something.
 */

@interface NavigationCache : NSObject

@property(strong) NSMutableArray *postId; /* really just [self.posts keys] */
@property(strong) NSMutableDictionary *posts;

- (id)init;
- (Post *)postAtIndex:(int)index;
- (Post *)postWithId:(NSString *)idValue;
- (int)indexForPost:(NSString *)idValue;
- (void)setCache:(NSArray *)posts;
- (void)setAuthor:(User *)user;
- (void)setComments:(NSMutableArray *)comments forPost:(NSString *)idValue;
- (void)addComment:(Comment *)comment forPost:(NSString *)idValue;
- (void)dropData;
- (void)prune;
- (void)flushImages;

@end
