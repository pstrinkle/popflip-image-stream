//
//  WatchList.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/7/12.
//
//

#import <Foundation/Foundation.h>

@interface WatchList : NSObject

/**
 * The properies of: avatars and screennames are key'd by the userid.  The list
 * of userids is stored in userids.
 */
@property(strong) NSMutableDictionary *avatars;
@property(strong) NSMutableArray *userids;
@property(strong) NSMutableDictionary *screennames;

- (id)init;

/**
 * @brief How many users are in array.
 */
- (NSUInteger)count;

/**
 * @brief Add user to array.
 */
- (void)addUser:(NSString *)user;

/**
 * @brief Drop info for this user.
 */
- (void)dropUser:(NSString *)user;

/**
 * @brief Empty out the data.
 */
- (void)dropAllUsers;

/**
 * @brief Drop stale data.
 */
- (void)dropInvalid;

@end
