//
//  APIHandler.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 7/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"
#import "Comment.h"

/* these are the fundamental api calls currently implemented that I handle. */
enum APICall
{
    API_POST_ADMIN = 0,
    API_POST_COMMENT,
    API_POST_COMMENTS,
    API_POST_CREATE,
    API_POST_FAVORITE,
    API_POST_UNFAVORITE,
    API_POST_QUERY,
    API_POST_REPLY,
    API_POST_REPORT,
    API_POST_REPOST,
    API_POST_THUMBNAIL,
    API_POST_VIEW,
    API_USER_AUTHORIZE,
    API_USER_FAVORITED, // not implemented
    API_USER_GET,
    API_USER_JOIN,
    API_USER_LEAVE,
    API_USER_LOGIN,
    API_USER_QUERY,
    API_USER_UNAUTHORIZE,
    API_USER_UPDATE,
    API_USER_UNWATCH,
    API_USER_WATCH,
    API_USER_VIEW,
};

/* If you're using this class, implement those that you need. */
@protocol CompletionDelegate;

@interface APIHandler : NSObject
{
    NSMutableData *receivedData;
    NSString *base;
    NSURLConnection *conn;

    BOOL downloadComplete;
}

@property(assign) enum APICall type;
@property(assign) int lastCode;
@property(assign) bool canceled;

@property(copy) NSArray *providedTags;
@property(copy) NSString *userQueryType;
@property(copy) NSString *postId;
@property(copy) NSString *userIdentifier;
@property(copy) NSString *me;
@property(copy) NSString *callerIdentifier;

@property(nonatomic, unsafe_unretained) id<CompletionDelegate> delegate;

+ (NSString *)typeToString:(enum APICall)type;

- (id)init;

- (void)createPost:(NSString *)author withTags:(NSArray *)tags withData:(NSData *)image withLocation:(NSString *)point;
- (void)replyPost:(NSString *)author withTags:(NSArray *)tags withData:(NSData *)image withLocation:(NSString *)point asReply:(NSString *)replyTo;
- (void)repostPost:(NSString *)author withTags:(NSArray *)tags asRepost:(NSString *)repostOf;

- (void)loginUser:(NSString *)screenName;
- (void)viewPost:(NSString *)identifier asLarge:(bool)large;
- (void)viewThumbnail:(NSString *)identifier; /* combine with viewPost() */
- (void)getPost:(NSString *)identifier asUser:(NSString *)querierid;
- (void)favoritePost:(NSString *)identifier asUser:(NSString *)userid;
- (void)unfavoritePost:(NSString *)identifier asUser:(NSString *)userid;

- (void)watchUser:(NSString *)myId watchesUser:(NSString *)userid;
- (void)unwatchUser:(NSString *)myId unwatchesUser:(NSString *)userid;

- (void)reportPost:(NSString *)identifier asUser:(NSString *)userid;

- (void)joinCommunity:(NSString *)myId withTags:(NSArray *)tags;
- (void)leaveCommunity:(NSString *)myId withTags:(NSArray *)tags;

/* generic handler, transition code to this */
- (void)publicStream:(NSString *)user;
- (void)queryPosts:(NSString *)query withValue:(NSString *)value asUser:(NSString *)querierid;
- (void)queryPosts:(NSString *)query withValue:(NSString *)value asUser:(NSString *)querierid since:(NSString *)sinceId;

- (void)userQuery:(NSString *)userid withRequest:(NSString *)query asUser:(NSString *)myId;
- (void)getAuthor:(NSString *)user asUser:(NSString *)myId;
- (void)userView:(NSString *)userid;

- (void)userUpdate:(NSString *)userid forField:(NSString *)field withValue:(NSString *)value;
- (void)userUpdate:(NSString *)userid withData:(NSData *)data;
- (void)userHome:(NSString *)myId;

- (void)getComments:(NSString *)identifier asUser:(NSString *)userid;
- (void)comment:(NSString *)identifier asUser:(NSString *)userid withComment:(NSString *)comment;

- (void)authorizeUser:(NSString *)user asUser:(NSString *)requester;
- (void)unauthorizeUser:(NSString *)user asUser:(NSString *)requester;

- (void)cancel;

/* 
 * This does not return anything or do anything neato; it's just how I'm 
 * learning to send HTTP POST commands through NSURLRequest.
 */
- (void)admin;

@end

@protocol CompletionDelegate
- (void)apihandler:(APIHandler *)apihandler didFail:(enum APICall)type;
@optional
/* probably should be regular array */
- (void)apihandler:(APIHandler *)apihandler didCompleteQuery:(NSMutableArray *)data asUser:(NSString *)theUser;
- (void)apihandler:(APIHandler *)apihandler didCompletePost:(bool)success asUser:(NSString *)theUser;
- (void)apihandler:(APIHandler *)apihandler didCompleteView:(UIImage *)image withPost:(NSString *)postid;
- (void)apihandler:(APIHandler *)apihandler didCompleteThumbnail:(UIImage *)image withPost:(NSString *)postid;
- (void)apihandler:(APIHandler *)apihandler didCompleteUserView:(UIImage *)image withUser:(NSString *)userid;
- (void)apihandler:(APIHandler *)apihandler didCompleteName:(User *)details withAuthor:(NSString *)authorid asUser:(NSString *)theUser;
- (void)apihandler:(APIHandler *)apihandler didCompleteLogin:(NSString *)userid;
- (void)apihandler:(APIHandler *)apihandler didCompleteUserQuery:(NSMutableArray *)data withQuery:(NSString *)query forUser:(NSString *)user asUser:(NSString *)theUser;
- (void)apihandler:(APIHandler *)apihandler didCompleteFavorite:(bool)success forPost:(NSString *)postid asUser:(NSString *)theUser;
- (void)apihandler:(APIHandler *)apihandler didCompleteUnFavorite:(bool)success forPost:(NSString *)postid asUser:(NSString *)theUser;
/* These may lose all meaning if you logout */
- (void)apihandler:(APIHandler *)apihandler didCompleteWatch:(bool)success withUser:(NSString *)userid asUser:(NSString *)theUser;
- (void)apihandler:(APIHandler *)apihandler didCompleteUnWatch:(bool)success withUser:(NSString *)userid asUser:(NSString *)theUser;

- (void)apihandler:(APIHandler *)apihandler didCompleteReport:(bool)success forPost:(NSString *)postid asUser:(NSString *)theUser;

- (void)apihandler:(APIHandler *)apihandler didCompleteJoin:(bool)success forComm:(NSArray *)tags asUser:(NSString *)theUser;
- (void)apihandler:(APIHandler *)apihandler didCompleteLeave:(bool)success forComm:(NSArray *)tags asUser:(NSString *)theUser;

- (void)apihandler:(APIHandler *)apihandler didCompleteUpdate:(bool)success asUser:(NSString *)theUser;

- (void)apihandler:(APIHandler *)apihandler didCompleteComment:(bool)success with:(Comment *)comment asUser:(NSString *)theUser forPost:(NSString *)postId;
- (void)apihandler:(APIHandler *)apihandler didCompleteComments:(NSMutableArray *)data forPost:(NSString *)postId asUser:(NSString *)theUser;

- (void)apihandler:(APIHandler *)apihandler didCompleteAuthorize:(NSString *)user withResult:(bool)success asUser:(NSString *)theUser;
- (void)apihandler:(APIHandler *)apihandler didCompleteUnauthorize:(NSString *)user withResult:(bool)success asUser:(NSString *)theUser;
@end
