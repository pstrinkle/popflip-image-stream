//
//  APIHandler.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 7/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "APIHandler.h"
#import "Post.h"
#import "Comment.h"
#import "Multipart.h"

#define HTTP_BAD_REQUEST 400

@implementation APIHandler

@synthesize delegate;
@synthesize userQueryType;
@synthesize userIdentifier;
@synthesize providedTags;
@synthesize type;
@synthesize me;
@synthesize lastCode;
@synthesize canceled;
@synthesize callerIdentifier;

+ (NSString *)typeToString:(enum APICall)type
{
    //API_USER_FAVORITED, // not implemented
    switch (type)
    {
        case API_POST_ADMIN:
            return @"admin";
        case API_POST_COMMENT:
            return @"comment";
        case API_POST_COMMENTS:
            return @"comments";
        case API_POST_CREATE:
            return @"create";
        case API_POST_FAVORITE:
            return @"favorite_post";
        case API_POST_UNFAVORITE:
            return @"unfavorite_post";
        case API_POST_QUERY:
            return @"query";
        case API_POST_REPLY:
            return @"reply";
        case API_POST_REPORT:
            return @"report";
        case API_POST_REPOST:
            return @"repost";
        case API_POST_THUMBNAIL:
            return @"thumbnail";
        case API_POST_VIEW:
            return @"view_post";
        case API_USER_AUTHORIZE:
            return @"authorize_user";
        case API_USER_GET:
            return @"get_user";
        case API_USER_JOIN:
            return @"join";
        case API_USER_LEAVE:
            return @"leave";
        case API_USER_LOGIN:
            return @"login";
        case API_USER_QUERY:
            return @"query_user";
        case API_USER_UNAUTHORIZE:
            return @"unauthorize_user";
        case API_USER_UPDATE:
            return @"update_user";
        case API_USER_UNWATCH:
            return @"unwatch_user";
        case API_USER_WATCH:
            return @"watch_user";
        case API_USER_VIEW:
            return @"view_user";
        default:
            return @"";
    }
}

- (id)init
{
    if (self = [super init])
    {
        downloadComplete = NO;
        base = @"http://api.hyperionstorm.com/"; /* change to static */

        self.type = API_POST_QUERY;
        self.canceled = NO;
    }
    
    return self;
}

- (NSString *)encodeFields:(NSDictionary *)fields
{
    NSString *output = nil;
    NSMutableArray *temp = [[NSMutableArray alloc] init];
    
    for (id obj in fields)
    {
        if ([fields[obj] length] == 0)
        {
            [temp addObject:[NSString stringWithFormat:@"%@",
                             [obj stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]];
        }
        else
        {
            [temp addObject:[NSString stringWithFormat:@"%@=%@",
                             [obj stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
                             [fields[obj] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]];
        }
    }

    output = [temp componentsJoinedByString:@"&"];

    return output;
}

/**
 * @brief Cancel the API call in progress.
 */
- (void)cancel
{
    [conn cancel];
    
    NSLog(@"canceled API request");

    conn = nil;
    receivedData = nil;
    
    self.canceled = YES;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"Did receive response of type: %d with code: %d",
          self.type,
          [(NSHTTPURLResponse *)response statusCode]);

    // This method is called when the server has determined that it
    // has enough information to create the NSURLResponse.

    self.lastCode = [(NSHTTPURLResponse *)response statusCode];

    //NSLog(@"Received HTTP Status Code: %d", [(NSHTTPURLResponse *)response statusCode]);

    // It can be called multiple times, for example in the case of a
    // redirect, so each time we reset the data.

    [receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    //NSLog(@"Received data");
    // Append the new data to receivedData.
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // inform the user    
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [error userInfo][NSURLErrorFailingURLStringErrorKey]);

    if (self.canceled)
    {
        conn = nil;
        receivedData = nil;
        return;
    }

    /* I wonder if this is called for a 400 return... */
    /* and if connectionDidFinishLoading is called... */
    /* if not, then I can assume a 200 code on connectionDidFinishLoading... */
    [delegate apihandler:self didFail:self.type];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // do something with the data
    // receivedData is declared as a method instance elsewhere

    /* Calling cancel should work, but doesn't always it seems. */
    if (self.canceled)
    {
        conn = nil;
        receivedData = nil;
        return;
    }

    int length = [receivedData length];

    downloadComplete = YES;

    NSLog(@"Succeeded! Received %d bytes of data, for type: %d",
          length,
          self.type);
    
    /* 
     * if length is 0... could have failed to download thing.
     * but we want to catch this and still call delegate.
     */
        
    /* 
     * So how we handle the finish loading should depend entirely on the
     * query we're running.
     *
     * Are we downloading an image?
     * Are we retrieving a user profile? -- what are we doing?
     */
    NSError *e = nil;
    NSArray *jsonArray = nil;

    switch (self.type)
    {
        case API_POST_QUERY:
        {
            /* handle bad request */
            if (self.lastCode == HTTP_BAD_REQUEST)
            {
                [delegate apihandler:self didCompleteQuery:nil asUser:self.me];
                break;
            }
            
            /* Send them an empty array. */
            if (length == 2) // []
            {
                [delegate apihandler:self didCompleteQuery:[[NSMutableArray alloc] init] asUser:self.me];
                break;
            }
            
            /* handle non-bad request */
            if (length > 2) // []
            {
                jsonArray = \
                    [NSJSONSerialization JSONObjectWithData:receivedData
                                                    options:NSJSONReadingMutableContainers
                                                      error:&e];
            }

            if (!jsonArray)
            {
                NSLog(@"Error parsing JSON: %@", e);
                [delegate apihandler:self didCompleteQuery:nil asUser:self.me];
            }
            else
            {
                // this is released when self.postCache = nil (if autorelease then bad).
                NSMutableArray *items = [[NSMutableArray alloc] init];

                for (NSDictionary *item in jsonArray)
                {
                    Post *newPost = [[Post alloc] initWithJSONDict:item];
                    [items addObject:newPost];
                }

                NSLog(@"Download Complete: %d", [items count]);
                [delegate apihandler:self didCompleteQuery:items asUser:self.me];
            }
            break;
        }
        case API_POST_COMMENTS:
        {
            if (self.lastCode == HTTP_BAD_REQUEST)
            {
                [delegate apihandler:self
                 didCompleteComments:nil
                             forPost:self.postId
                              asUser:self.me];
                break;
            }
            
            /* handle non-bad request */
            if (length > 2) // []
            {
                jsonArray = \
                    [NSJSONSerialization JSONObjectWithData:receivedData
                                                    options:NSJSONReadingMutableContainers
                                                      error:&e];
            }
            
            if (!jsonArray)
            {
                NSLog(@"Error parsing JSON: %@", e);
                [delegate apihandler:self
                 didCompleteComments:nil
                             forPost:self.postId
                              asUser:self.me];
            }
            else
            {
                // this is released when self.postCache = nil (if autorelease then bad).
                NSMutableArray *items = [[NSMutableArray alloc] init];
                
                for (NSDictionary *item in jsonArray)
                {
                    Comment *newPost = [[Comment alloc] initWithJSONDict:item];
                    [items addObject:newPost];
                }
                
                NSLog(@"Download Complete: %d", [items count]);
                [delegate apihandler:self
                 didCompleteComments:items
                             forPost:self.postId
                              asUser:self.me];
            }
            break;
        }
        case API_POST_CREATE: /* if post create, reply, or repost changes what it returns you want these separate. */
        {
            /* handle bad request */
            if (self.lastCode == HTTP_BAD_REQUEST)
            {
                [delegate apihandler:self didCompletePost:NO asUser:self.me];
                break;
            }

            /* handle non-bad request */
            if (length != 0)
            {
                jsonArray = \
                    [NSJSONSerialization JSONObjectWithData:receivedData
                                                    options:NSJSONReadingMutableContainers
                                                      error:&e];
            }
            
            if (!jsonArray)
            {
                NSLog(@"Error parsing JSON: %@", e);
                [delegate apihandler:self didCompletePost:NO asUser:self.me];
            }
            else
            {
                NSLog(@"Bam!: %@", jsonArray);
                [delegate apihandler:self didCompletePost:YES asUser:self.me];
            }
            break;
        }
        case API_POST_REPLY:
        {
            /* handle bad request */
            if (self.lastCode == HTTP_BAD_REQUEST)
            {
                [delegate apihandler:self didCompletePost:NO asUser:self.me];
                break;
            }
            
            /* handle non-bad request */
            if (length != 0)
            {
                jsonArray = \
                    [NSJSONSerialization JSONObjectWithData:receivedData
                                                    options:NSJSONReadingMutableContainers
                                                      error:&e];
            }
            
            if (!jsonArray)
            {
                NSLog(@"Error parsing JSON: %@", e);
                [delegate apihandler:self didCompletePost:NO asUser:self.me];
            }
            else
            {
                NSLog(@"Bam!: %@", jsonArray);
                [delegate apihandler:self didCompletePost:YES asUser:self.me];
            }
            break;
        }
        case API_POST_REPOST:
        {
            /* handle bad request */
            if (self.lastCode == HTTP_BAD_REQUEST)
            {
                [delegate apihandler:self didCompletePost:NO asUser:self.me];
                break;
            }
            
            /* handle non-bad request */
            if (length != 0)
            {
                jsonArray = \
                    [NSJSONSerialization JSONObjectWithData:receivedData
                                                    options:NSJSONReadingMutableContainers
                                                      error:&e];
            }
            
            if (!jsonArray)
            {
                NSLog(@"Error parsing JSON: %@", e);
                [delegate apihandler:self didCompletePost:NO asUser:self.me];
            }
            else
            {
                NSLog(@"Bam!: %@", jsonArray);
                [delegate apihandler:self didCompletePost:YES asUser:self.me];
            }
            break;
        }
        case API_POST_VIEW:
        {
            /* handle bad request */
            if (self.lastCode == HTTP_BAD_REQUEST)
            {
                [delegate apihandler:self
                     didCompleteView:nil
                            withPost:self.postId];
                break;
            }
            
            /* handle non-bad request */
            if (length == 0)
            {
                [delegate apihandler:self
                     didCompleteView:nil
                            withPost:self.postId];
            }
            else
            {
                [delegate apihandler:self
                     didCompleteView:[[UIImage alloc] initWithData:receivedData]
                            withPost:self.postId];
            }
            break;
        }
        case API_POST_THUMBNAIL:
        {
            /* handle bad request */
            if (self.lastCode == HTTP_BAD_REQUEST)
            {
                [delegate apihandler:self
                didCompleteThumbnail:nil
                            withPost:self.postId];
                break;
            }
            
            /* handle non-bad request */
            if (length == 0)
            {
                [delegate apihandler:self
                didCompleteThumbnail:nil
                            withPost:self.postId];
            }
            else
            {
                UIImage *tmpImg = [[UIImage alloc] initWithData:receivedData];
                [delegate apihandler:self
                didCompleteThumbnail:tmpImg
                            withPost:self.postId];
            }
            break;
        }
        case API_POST_ADMIN:
        {
            if (length != 0)
            {
                jsonArray = \
                    [NSJSONSerialization JSONObjectWithData:receivedData
                                                    options:NSJSONReadingMutableContainers
                                                      error:&e];
            }
            
            if (!jsonArray)
            {
                NSLog(@"Error parsing JSON: %@", e);
            }
            else
            {
                NSLog(@"Bam!: %@", jsonArray);
            }
            break;
        }
        case API_POST_REPORT:
        {
            if (self.lastCode == HTTP_BAD_REQUEST)
            {
                [delegate apihandler:self
                   didCompleteReport:NO
                             forPost:self.postId
                              asUser:self.me];
                
                break;
            }
            
            /* handle non-bad request */
            if (length != 0)
            {
                jsonArray = \
                    [NSJSONSerialization JSONObjectWithData:receivedData
                                                    options:NSJSONReadingMutableContainers
                                                      error:&e];
            }
            
            if (!jsonArray)
            {
                NSLog(@"Error parsing JSON: %@", e);
                [delegate apihandler:self
                   didCompleteReport:NO
                             forPost:self.postId
                              asUser:self.me]; /* for error case */
            }
            else
            {
                if (((NSDictionary *)jsonArray)[@"id"] == nil)
                {
                    [delegate apihandler:self
                       didCompleteReport:NO
                                 forPost:self.postId
                                  asUser:self.me];
                }
                else
                {
                    [delegate apihandler:self
                       didCompleteReport:YES
                                 forPost:self.postId
                                  asUser:self.me];
                }
            }
            break;
        }
        case API_POST_FAVORITE:
        {
            /* handle bad request */
            if (self.lastCode == HTTP_BAD_REQUEST)
            {
                [delegate apihandler:self
                 didCompleteFavorite:NO
                             forPost:self.postId
                              asUser:self.me];
                break;
            }
            
            /* handle non-bad request */
            if (length != 0)
            {
                jsonArray = \
                    [NSJSONSerialization JSONObjectWithData:receivedData
                                                    options:NSJSONReadingMutableContainers
                                                      error:&e];
            }
            
            if (!jsonArray)
            {
                NSLog(@"Error parsing JSON: %@", e);
                [delegate apihandler:self
                 didCompleteFavorite:NO
                             forPost:self.postId
                              asUser:self.me]; /* for error case */
            }
            else
            {
                if (((NSDictionary *)jsonArray)[@"id"] == nil)
                {
                    [delegate apihandler:self
                     didCompleteFavorite:NO
                                 forPost:self.postId
                                  asUser:self.me];
                }
                else
                {
                    [delegate apihandler:self
                     didCompleteFavorite:YES
                                 forPost:self.postId
                                  asUser:self.me];
                }
            }
            break;
        }
        case API_POST_UNFAVORITE:
        {
            /* handle bad request */
            if (self.lastCode == HTTP_BAD_REQUEST)
            {
                [delegate apihandler:self
               didCompleteUnFavorite:NO
                             forPost:self.postId
                              asUser:self.me];
                break;
            }
            
            /* handle non-bad request */
            [delegate apihandler:self
           didCompleteUnFavorite:YES
                         forPost:self.postId
                          asUser:self.me];
            break;
        }
        case API_POST_COMMENT:
        {
            if (self.lastCode == HTTP_BAD_REQUEST)
            {
                [delegate apihandler:self
                  didCompleteComment:NO
                                with:nil
                              asUser:self.me
                             forPost:self.postId];
            }

            /* handle non-bad request */
            if (length != 0)
            {
                jsonArray = \
                    [NSJSONSerialization JSONObjectWithData:receivedData
                                                    options:NSJSONReadingMutableContainers
                                                      error:&e];
            }
            
            if (!jsonArray)
            {
                NSLog(@"Error parsing JSON: %@", e);
                [delegate apihandler:self
                  didCompleteComment:NO
                                with:nil
                                asUser:self.me
                             forPost:self.postId]; /* for error case */
            }
            else
            {
                Comment *newPost = [[Comment alloc] initWithJSONDict:(NSDictionary *)jsonArray];
                [delegate apihandler:self
                  didCompleteComment:YES
                                with:newPost
                              asUser:self.me
                             forPost:self.postId];
            }
            break;
        }
        case API_USER_AUTHORIZE:
        {
            if (self.lastCode == HTTP_BAD_REQUEST)
            {
                [delegate apihandler:self
                didCompleteAuthorize:self.userIdentifier
                          withResult:NO
                              asUser:self.me];
            }
            else
            {
                [delegate apihandler:self
                didCompleteAuthorize:self.userIdentifier
                          withResult:YES
                              asUser:self.me];
            }

            break;
        }
        case API_USER_UNAUTHORIZE:
        {
            if (self.lastCode == HTTP_BAD_REQUEST)
            {
                [delegate apihandler:self
              didCompleteUnauthorize:self.userIdentifier
                          withResult:NO
                              asUser:self.me];
            }
            else
            {
                [delegate apihandler:self
              didCompleteUnauthorize:self.userIdentifier
                          withResult:YES
                              asUser:self.me];
            }
            
            break;
        }
        case API_USER_GET:
        {
            /* handle bad request */
            if (self.lastCode == HTTP_BAD_REQUEST)
            {
                [delegate apihandler:self
                     didCompleteName:nil
                          withAuthor:self.userIdentifier
                              asUser:self.me];
                break;
            }
            
            /* handle non-bad request */
            if (length != 0)
            {
                jsonArray = \
                    [NSJSONSerialization JSONObjectWithData:receivedData
                                                    options:NSJSONReadingMutableContainers
                                                      error:&e];
            }
            
            if (!jsonArray)
            {
                NSLog(@"Error parsing JSON: %@", e);
                [delegate apihandler:self
                     didCompleteName:nil
                          withAuthor:self.userIdentifier
                              asUser:self.me]; /* for error case */
            }
            else
            {
                User *userData = \
                    [[User alloc] initWithJSONDict:(NSDictionary *)jsonArray];

                [delegate apihandler:self
                     didCompleteName:userData
                          withAuthor:userData.userid
                              asUser:self.me];
            }
            break;
        }
        case API_USER_VIEW:
        {
            /* handle bad request */
            if (self.lastCode == HTTP_BAD_REQUEST)
            {
                [delegate apihandler:self
                 didCompleteUserView:nil
                            withUser:self.userIdentifier];
                break;
            }
            
            /* handle non-bad request */
            if (length == 0)
            {
                [delegate apihandler:self
                 didCompleteUserView:nil
                            withUser:self.userIdentifier];
            }
            else
            {
                [delegate apihandler:self
                 didCompleteUserView:[[UIImage alloc] initWithData:receivedData]
                            withUser:self.userIdentifier];
            }
            break;
        }
        case API_USER_JOIN:
        {
            /* handle bad request */
            if (self.lastCode == HTTP_BAD_REQUEST)
            {
                [delegate apihandler:self
                     didCompleteJoin:NO
                             forComm:self.providedTags
                              asUser:self.me];
                break;
            }
            
            /* handle non-bad request */
            if (length != 0)
            {
                jsonArray = \
                    [NSJSONSerialization JSONObjectWithData:receivedData
                                                    options:NSJSONReadingMutableContainers
                                                      error:&e];
            }
            
            if (!jsonArray)
            {
                NSLog(@"Error parsing JSON: %@", e);
                [delegate apihandler:self
                     didCompleteJoin:NO
                             forComm:self.providedTags
                              asUser:self.me]; /* for error case */
            }
            else
            {
                [delegate apihandler:self
                     didCompleteJoin:YES
                             forComm:self.providedTags
                              asUser:self.me];
            }
            break;
        }
        case API_USER_LEAVE:
        {
            /* handle bad request */
            if (self.lastCode == HTTP_BAD_REQUEST)
            {
                [delegate apihandler:self
                    didCompleteLeave:NO
                             forComm:self.providedTags
                              asUser:self.me];
                break;
            }
            
            /* handle non-bad request */
            [delegate apihandler:self
                didCompleteLeave:YES
                         forComm:self.providedTags
                          asUser:self.me];
            break;
        }
        case API_USER_LOGIN:
        {
            /* handle bad request */
            if (self.lastCode == HTTP_BAD_REQUEST)
            {
                [delegate apihandler:self didCompleteLogin:nil];
                break;
            }
            
            /* handle non-bad request */
            if (length != 0)
            {                
                jsonArray = \
                    [NSJSONSerialization JSONObjectWithData:receivedData
                                                    options:NSJSONReadingMutableContainers
                                                      error:&e];
            }
            
            if (!jsonArray)
            {
                NSLog(@"Error parsing JSON: %@", e);
                [delegate apihandler:self didCompleteLogin:nil];
            }
            else
            {
                [delegate apihandler:self
                    didCompleteLogin:((NSDictionary *)jsonArray)[@"id"]];
            }
            break;
        }
        case API_USER_QUERY:
        {
            /* handle bad request */
            if (self.lastCode == HTTP_BAD_REQUEST)
            {
                [delegate apihandler:self
                didCompleteUserQuery:nil
                           withQuery:nil
                             forUser:self.userIdentifier
                              asUser:self.me];
                break;
            }
            
            /* handle non-bad request */
            if (length > 2) // "[]"
            {
                jsonArray = \
                    [NSJSONSerialization JSONObjectWithData:receivedData
                                                    options:NSJSONReadingMutableContainers
                                                      error:&e];
            }
            
            if (!jsonArray)
            {
                [delegate apihandler:self
                didCompleteUserQuery:nil
                           withQuery:nil
                             forUser:self.userIdentifier
                              asUser:self.me];
            }
            else
            {
                [delegate apihandler:self
                didCompleteUserQuery:[[NSMutableArray alloc] initWithArray:(NSArray *)jsonArray]
                           withQuery:self.userQueryType
                             forUser:self.userIdentifier
                              asUser:self.me];
            }
            break;
        }
        /* These currently do not return bad. */
        case API_USER_UPDATE:
        {
            /* handle bad request */
            if (self.lastCode == HTTP_BAD_REQUEST)
            {
                [delegate apihandler:self didCompleteUpdate:NO asUser:self.me];
                break;
            }
            
            /* handle non-bad request */
            [delegate apihandler:self didCompleteUpdate:YES asUser:self.me];
            break;
        }
        case API_USER_UNWATCH:
        {
            /* handle bad request */
            if (self.lastCode == HTTP_BAD_REQUEST)
            {
                [delegate apihandler:self
                  didCompleteUnWatch:NO
                            withUser:self.userIdentifier
                              asUser:self.me];
                break;
            }
            
            /* handle non-bad request */
            [delegate apihandler:self
              didCompleteUnWatch:YES
                        withUser:self.userIdentifier
                          asUser:self.me];
            break;
        }
        case API_USER_WATCH:
        {
            /* handle bad request */
            if (self.lastCode == HTTP_BAD_REQUEST)
            {
                [delegate apihandler:self
                    didCompleteWatch:NO
                            withUser:self.userIdentifier
                              asUser:self.me];
                break;
            }
            
            /* handle non-bad request */
            [delegate apihandler:self
                didCompleteWatch:YES
                        withUser:self.userIdentifier
                          asUser:self.me];
            break;
        }
        default:
        {
            break;
        }
    }

    // release the connection, and the data object
    receivedData = nil;
    conn = nil;

    return;
}

/**
 * @brief Report a post.
 *
 * @param identifier the post to mark.
 * @param userid user reporting the post.
 */
- (void)reportPost:(NSString *)identifier asUser:(NSString *)userid
{
    if ([identifier length] == 0 || [userid length] == 0)
    {
        [delegate apihandler:self didCompleteReport:NO forPost:nil asUser:nil];
        return;
    }

    self.type = API_POST_REPORT;
    self.postId = identifier;
    self.me = userid;

    NSDictionary *params = @{@"user" : userid, @"post" : identifier};
    
    NSString *urlStr = [NSString stringWithFormat:@"%@snapshot/report", base];
    NSURL *url = [[NSURL alloc] initWithString:urlStr];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    request.HTTPMethod = @"POST";
    request.HTTPBody = [[self encodeFields:params] dataUsingEncoding:NSUTF8StringEncoding];

    NSURLConnection *theConnection = \
        [[NSURLConnection alloc] initWithRequest:request delegate:self];

    if (theConnection)
    {
        receivedData = [NSMutableData data];
        conn = theConnection;
    }
    else
    {
        NSLog(@"Connection request was NOT successful.");
    }

    return;
}

/**
 * @brief Mark as a post as favorite.
 *
 * @param identifier the post to mark.
 * @param userid user favoriting the post.
 */
- (void)favoritePost:(NSString *)identifier asUser:(NSString *)userid
{
    if ([identifier length] == 0 || [userid length] == 0)
    {
        [delegate apihandler:self didCompleteFavorite:NO forPost:nil asUser:nil];
        return;
    }

    self.type = API_POST_FAVORITE;
    self.postId = identifier;
    self.me = userid;

    NSDictionary *params = @{@"user" : userid, @"post" : identifier};

    NSString *urlStr = [NSString stringWithFormat:@"%@snapshot/favorite", base];
    NSURL *url = [[NSURL alloc] initWithString:urlStr];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    request.HTTPMethod = @"POST";
    [request setHTTPBody:[[self encodeFields:params] dataUsingEncoding:NSUTF8StringEncoding]];

    NSURLConnection *theConnection = \
        [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    if (theConnection)
    {
        receivedData = [NSMutableData data];
        conn = theConnection;
    }
    else
    {
        NSLog(@"Connection request was NOT successful.");
    }

    return;
}

/**
 * @brief Unmark as a post as favorite.
 *
 * @param identifier the post to mark.
 * @param userid user favoriting the post.
 */
- (void)unfavoritePost:(NSString *)identifier asUser:(NSString *)userid
{
    if ([identifier length] == 0 || [userid length] == 0)
    {
        [delegate apihandler:self didCompleteUnFavorite:NO forPost:nil asUser:nil];
        return;
    }

    self.type = API_POST_UNFAVORITE;
    self.postId = identifier;
    self.me = userid;

    NSDictionary *params = @{@"user" : userid, @"post" : identifier};

    NSString *urlStr = [NSString stringWithFormat:@"%@snapshot/unfavorite", base];
    NSURL *url = [[NSURL alloc] initWithString:urlStr];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    request.HTTPMethod = @"POST";
    [request setHTTPBody:[[self encodeFields:params] dataUsingEncoding:NSUTF8StringEncoding]];

    NSURLConnection *theConnection = \
        [[NSURLConnection alloc] initWithRequest:request delegate:self];

    if (theConnection)
    {
        receivedData = [NSMutableData data];
        conn = theConnection;
    }
    else
    {
        NSLog(@"Connection request was NOT successful.");
    }

    return;
}

/**
 * @brief Run the admin query.
 */
- (void)admin
{
    self.type = API_POST_ADMIN;

    NSDictionary *params = @{@"code" : @"58780932341"};

    NSString *urlStr = [NSString stringWithFormat:@"%@snapshot/admin", base];
    NSURL *url = [[NSURL alloc] initWithString:urlStr];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    request.HTTPMethod = @"POST";
    request.HTTPBody = [[self encodeFields:params] dataUsingEncoding:NSUTF8StringEncoding];

    NSURLConnection *theConnection = \
        [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    if (theConnection)
    {
        receivedData = [NSMutableData data];
        conn = theConnection;
    }
    else
    {
        NSLog(@"Connection request was NOT successful.");
    }

    return;
}

/**
 * @brief Create a post.
 *
 * @param author the user creating the post.
 * @param tags the tags to use with the post.
 * @param image the image data.
 * @param point the location data string, optional.
 */
- (void)createPost:(NSString *)author
          withTags:(NSArray *)tags
          withData:(NSData *)image
      withLocation:(NSString *)point
{
    if ([author length] == 0 || [tags count] == 0 || [image length] == 0)
    {
        [delegate apihandler:self didCompletePost:NO asUser:author];
        return;
    }

    self.type = API_POST_CREATE;
    self.me = author;

    NSDictionary *params = \
        @{@"author": author,
          @"code": @"98098098098",
          @"tags": [tags componentsJoinedByString:@","],
          @"location": (point == nil) ? @"" : point};

    NSLog(@"fields: %@", params);

    Multipart *multi = \
        [[Multipart alloc] initWithStuff:params
                           imageContents:image
                                withName:@"data"];
    
    NSLog(@"Multi Created.");
    
    NSString *urlStr = [NSString stringWithFormat:@"%@snapshot/create", base];
    NSURL *url = [[NSURL alloc] initWithString:urlStr];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    NSLog(@"Building Request.");
    
    request.HTTPMethod = @"POST";
    [request setValue:[multi getForm] forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[multi getOutputData]];

    NSLog(@"Request Built.");
    
    NSURLConnection *theConnection = \
        [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    if (theConnection)
    {
        receivedData = [NSMutableData data];
        conn = theConnection;
    }
    else
    {
        NSLog(@"Connection request was NOT successful.");
    }

    return;
}

/**
 * @brief Reply to a post.
 *
 * @param author the user creating the post.
 * @param tags the tags to use with the post.
 * @param image the image data.
 * @param point the location data string, optional.
 * @param replyTo the post identifier to which they are replying.
 */
- (void)replyPost:(NSString *)author
         withTags:(NSArray *)tags
         withData:(NSData *)image
     withLocation:(NSString *)point
          asReply:(NSString *)replyTo
{
    if ([author length] == 0 || [tags count] == 0 || [replyTo length] == 0)
    {
        [delegate apihandler:self didCompletePost:NO asUser:nil];
        return;
    }

    self.type = API_POST_REPLY;
    self.me = author;

    NSDictionary *params = \
        @{@"author": author,
          @"code": @"98098098098",
          @"tags": [tags componentsJoinedByString:@","],
          @"location": (point == nil) ? @"" : point,
          @"reply_to": replyTo};

    NSLog(@"fields: %@", params);
    
    Multipart *multi = \
        [[Multipart alloc] initWithStuff:params
                           imageContents:image
                                withName:@"data"];

    NSString *urlStr = [NSString stringWithFormat:@"%@snapshot/reply", base];
    NSURL *url = [[NSURL alloc] initWithString:urlStr];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    request.HTTPMethod = @"POST";
    [request setValue:[multi getForm] forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[multi getOutputData]];

    NSURLConnection *theConnection = \
        [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    if (theConnection)
    {
        receivedData = [NSMutableData data];
        conn = theConnection;
    }
    else
    {
        NSLog(@"Connection request was NOT successful.");
    }

    return;
}

/**
 * @brief Repost to a post.
 *
 * @param author the user creating the post.
 * @param tags the tags to use with the post.
 * @param repostOf the post identifier for the post they are re-posting.
 */
- (void)repostPost:(NSString *)author
          withTags:(NSArray *)tags
          asRepost:(NSString *)repostOf
{
    if ([author length] == 0 || [tags count] == 0 || [repostOf length] == 0)
    {
        [delegate apihandler:self didCompletePost:NO asUser:nil];
        return;
    }

    self.type = API_POST_REPOST;
    self.me = author;

    NSDictionary *params = \
        @{@"author": author,
          @"repost_of": repostOf,
          @"code": @"98098098098",
          @"tags": [tags componentsJoinedByString:@","]};

    NSString *urlStr = [NSString stringWithFormat:@"%@snapshot/repost", base];
    NSURL *url = [[NSURL alloc] initWithString:urlStr];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    request.HTTPMethod = @"POST";
    [request setHTTPBody:[[self encodeFields:params] dataUsingEncoding:NSUTF8StringEncoding]];

    NSURLConnection *theConnection = \
        [[NSURLConnection alloc] initWithRequest:request delegate:self];

    if (theConnection)
    {
        receivedData = [NSMutableData data];
        conn = theConnection;
    }
    else
    {
        NSLog(@"Connection request was NOT successful.");
    }

    return;
}

/**
 * @brief Watch the user.
 *
 * @param me Your user identifier.
 * @param userid The identifier you wish to watch.
 *
 * @todo If this succeeds we'll want that indicated.
 */
- (void)watchUser:(NSString *)myId watchesUser:(NSString *)userid
{
    if ([myId length] == 0 || [userid length] == 0)
    {
        [delegate apihandler:self
            didCompleteWatch:NO
                    withUser:userid
                      asUser:myId];
        return;
    }

    self.type = API_USER_WATCH;
    self.userIdentifier = userid;
    self.me = myId;

    NSDictionary *params = \
        @{@"author": myId, @"watched": userid, @"code": @"98098098098"};

    NSString *urlStr = [NSString stringWithFormat:@"%@user/watch", base];
    NSURL *url = [[NSURL alloc] initWithString:urlStr];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    request.HTTPMethod = @"POST";
    request.HTTPBody = [[self encodeFields:params] dataUsingEncoding:NSUTF8StringEncoding];

    NSURLConnection *theConnection = \
        [[NSURLConnection alloc] initWithRequest:request delegate:self];

    if (theConnection)
    {
        receivedData = [NSMutableData data];
        conn = theConnection;
    }
    else
    {
        NSLog(@"Connection request was NOT successful.");
    }

    return;
}

/**
 * @brief Unwatch the user.
 *
 * @param me Your user identifier.
 * @param userid The identifier you wish to stop watching.
 *
 * @todo If this succeeds we'll want that indicated.
 */
- (void)unwatchUser:(NSString *)myId unwatchesUser:(NSString *)userid
{
    if ([myId length] == 0 || [userid length] == 0)
    {
        [delegate apihandler:self didCompleteUnWatch:NO withUser:nil asUser:nil];
        return;
    }

    self.type = API_USER_UNWATCH;
    self.userIdentifier = userid;
    self.me = myId;

    NSDictionary *params = @{@"author" : myId,
    @"watched" : userid,
    @"code" : @"98098098098"};

    NSString *urlStr = [NSString stringWithFormat:@"%@user/unwatch", base];
    NSURL *url = [[NSURL alloc] initWithString:urlStr];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    request.HTTPMethod = @"POST";
    request.HTTPBody = [[self encodeFields:params] dataUsingEncoding:NSUTF8StringEncoding];

    NSURLConnection *theConnection = \
        [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    if (theConnection)
    {
        receivedData = [NSMutableData data];
        conn = theConnection;
    }
    else
    {
        NSLog(@"Connection request was NOT successful.");
    }

    return;
}

/**
 * @brief "Join" the community.
 *
 * @param myId
 * @param tags
 */
- (void)joinCommunity:(NSString *)myId withTags:(NSArray *)tags
{
    if ([myId length] == 0 || [tags count] == 0)
    {
        NSLog(@"joinCommunity invalid input.");
        [delegate apihandler:self didCompleteJoin:NO forComm:nil asUser:nil];
        return;
    }

    self.type = API_USER_JOIN;
    self.providedTags = tags;
    self.me = myId;

    NSDictionary *params = \
        @{@"user" : myId,
          @"community" : [tags componentsJoinedByString:@","]};

    NSString *urlStr = [NSString stringWithFormat:@"%@user/join", base];
    NSURL *url = [[NSURL alloc] initWithString:urlStr];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    request.HTTPMethod = @"POST";
    request.HTTPBody = [[self encodeFields:params] dataUsingEncoding:NSUTF8StringEncoding];

    NSURLConnection *theConnection = \
        [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    if (theConnection)
    {
        receivedData = [NSMutableData data];
        conn = theConnection;
    }
    else
    {
        NSLog(@"Connection request was NOT successful.");
    }

    return;
}

/**
 * @brief "Leave" the community.
 *
 * @param myId
 * @param tags
 */
- (void)leaveCommunity:(NSString *)myId withTags:(NSArray *)tags
{
    if ([myId length] == 0 || [tags count] == 0)
    {
        [delegate apihandler:self didCompleteLeave:NO forComm:nil asUser:nil];
        return;
    }

    self.type = API_USER_LEAVE;
    self.providedTags = tags;
    self.me = myId;

    NSDictionary *params = \
        @{@"user" : myId,
          @"community" : [tags componentsJoinedByString:@","]};

    NSString *urlStr = [NSString stringWithFormat:@"%@user/leave", base];
    NSURL *url = [[NSURL alloc] initWithString:urlStr];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    request.HTTPMethod = @"POST";
    request.HTTPBody = [[self encodeFields:params] dataUsingEncoding:NSUTF8StringEncoding];

    NSURLConnection *theConnection = \
        [[NSURLConnection alloc] initWithRequest:request delegate:self];

    if (theConnection)
    {
        receivedData = [NSMutableData data];
        conn = theConnection;
    }
    else
    {
        NSLog(@"Connection request was NOT successful.");
    }

    return;
}

/**
 * @brief Download the comments for the specified post.
 *
 * @param identifier the post we're checking.
 * @param userid the user requesting the comments.
 */
- (void)getComments:(NSString *)identifier asUser:(NSString *)userid
{
    if ([identifier length] == 0 || [userid length] == 0)
    {
        [delegate apihandler:self didCompleteComments:nil forPost:nil asUser:nil];
        return;
    }

    self.type = API_POST_COMMENTS;
    self.me = userid;
    self.postId = identifier;

    NSDictionary *params = @{@"user" : userid, @"post" : identifier};

    NSString *urlStr = [NSString stringWithFormat:@"%@snapshot/comments", base];
    NSURL *url = [[NSURL alloc] initWithString:urlStr];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    request.HTTPMethod = @"POST";
    request.HTTPBody = [[self encodeFields:params] dataUsingEncoding:NSUTF8StringEncoding];

    NSURLConnection *theConnection = \
        [[NSURLConnection alloc] initWithRequest:request delegate:self];

    if (theConnection)
    {
        receivedData = [NSMutableData data];
        conn = theConnection;
    }
    else
    {
        NSLog(@"Connection request was NOT successful.");
    }

    return;
}

/**
 * @brief Comment the specified post.
 *
 * @param identifier the post specified.
 * @param userid the person commenting.
 * @param comment the comment value.
 *
 * @warning Currently, the comment isn't length restricted.
 */
- (void)comment:(NSString *)identifier
         asUser:(NSString *)userid
    withComment:(NSString *)comment
{
    if ([identifier length] == 0 || [userid length] == 0 || [comment length] == 0)
    {
        [delegate apihandler:self didCompleteComment:NO with:nil asUser:nil forPost:nil];
        return;
    }

    self.type = API_POST_COMMENT;
    self.me = userid;
    self.postId = identifier;

    NSDictionary *params = @{@"user" : userid,
                             @"post" : identifier,
                             @"comment" : comment};

    NSString *urlStr = [NSString stringWithFormat:@"%@snapshot/comment", base];
    NSURL *url = [[NSURL alloc] initWithString:urlStr];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    request.HTTPMethod = @"POST";
    request.HTTPBody = [[self encodeFields:params] dataUsingEncoding:NSUTF8StringEncoding];

    NSURLConnection *theConnection = \
        [[NSURLConnection alloc] initWithRequest:request delegate:self];

    if (theConnection)
    {
        receivedData = [NSMutableData data];
        conn = theConnection;
    }
    else
    {
        NSLog(@"Connection request was NOT successful.");
    }

    return;
}

/**
 * @brief Authorize the user specified to comment on your posts.
 *
 * @param user (authorized) parameter.
 * @param requester (authorizer) parameter.
 */
- (void)authorizeUser:(NSString *)user asUser:(NSString *)requester
{
    if ([user length] == 0 || [requester length] == 0)
    {
        [delegate apihandler:self didCompleteAuthorize:nil withResult:NO asUser:nil];
        return;
    }

    self.type = API_USER_AUTHORIZE;
    self.me = requester;
    self.userIdentifier = user;

    NSDictionary *params = @{@"authorized" : user,
                             @"authorizer" : requester};

    NSString *urlStr = [NSString stringWithFormat:@"%@user/authorize", base];
    NSURL *url = [[NSURL alloc] initWithString:urlStr];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    request.HTTPMethod = @"POST";
    request.HTTPBody = [[self encodeFields:params] dataUsingEncoding:NSUTF8StringEncoding];

    NSURLConnection *theConnection = \
        [[NSURLConnection alloc] initWithRequest:request delegate:self];

    if (theConnection)
    {
        receivedData = [NSMutableData data];
        conn = theConnection;
    }
    else
    {
        NSLog(@"Connection request was NOT successful.");
    }

    return;
}

/**
 * @brief Unauthorize the user specified to comment on your posts.
 *
 * @param user (authorized) parameter.
 * @param requester (authorizer) parameter.
 */
- (void)unauthorizeUser:(NSString *)user asUser:(NSString *)requester
{
    if ([user length] == 0 || [requester length] == 0)
    {
        [delegate apihandler:self didCompleteUnauthorize:nil withResult:NO asUser:nil];
        return;
    }
    
    self.type = API_USER_UNAUTHORIZE;
    self.me = requester;
    self.userIdentifier = user;
    
    NSDictionary *params = @{@"authorized" : user,
                             @"authorizer" : requester};
    
    NSString *urlStr = [NSString stringWithFormat:@"%@user/authorize", base];
    NSURL *url = [[NSURL alloc] initWithString:urlStr];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    request.HTTPMethod = @"POST";
    request.HTTPBody = [[self encodeFields:params] dataUsingEncoding:NSUTF8StringEncoding];
    
    NSURLConnection *theConnection = \
        [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    if (theConnection)
    {
        /* XXX: Need to update this code if we switch to using these repeatedly. */
        receivedData = [NSMutableData data];
        conn = theConnection;
    }
    else
    {
        NSLog(@"Connection request was NOT successful.");
    }
    
    return;
}

/**
 * @brief Download the post metadata.
 *
 * @param identifier the post we're trying to download.
 * @param querierid who I am.
 */
- (void)getPost:(NSString *)identifier asUser:(NSString *)querierid
{
    if ([identifier length] == 0 || [querierid length] == 0)
    {
        [delegate apihandler:self didCompleteQuery:nil asUser:nil];
        return;
    }

    self.type = API_POST_QUERY;
    self.postId = identifier;
    self.me = querierid;

    NSDictionary *params = @{@"id" : identifier, @"user" : querierid}; // 

    NSString *urlStr = \
        [NSString stringWithFormat:@"%@snapshot/get?%@", base, [self encodeFields:params]];

    NSLog(@"URL: %@", urlStr);

    NSURLRequest *theRequest = \
        [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]
                         cachePolicy:NSURLRequestUseProtocolCachePolicy
                     timeoutInterval:60.0];

    NSURLConnection *theConnection = \
        [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];

    if (theConnection)
    {
        receivedData = [NSMutableData data];
        conn = theConnection;
    }
    else
    {
        NSLog(@"Connection request was NOT successful.");
    }

    return;
}

/**
 * @brief Download the post contents (the data).
 *
 * @param identifier the post we're trying to download.
 */
- (void)viewPost:(NSString *)identifier asLarge:(bool)large
{
    if ([identifier length] == 0)
    {
        [delegate apihandler:self didCompleteView:nil withPost:nil];
        return;
    }

    self.type = API_POST_VIEW;
    self.postId = identifier;

    NSDictionary *params = nil;
    if (large)
    {
        params = @{@"id" : identifier, @"large" : @""};
    }
    else
    {
        params = @{@"id" : identifier};
    }

    NSString *urlStr = \
        [NSString stringWithFormat:@"%@snapshot/view?%@", base, [self encodeFields:params]];

    NSLog(@"URL: %@", urlStr);

    NSURLRequest *theRequest = \
        [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]
                         cachePolicy:NSURLRequestUseProtocolCachePolicy
                     timeoutInterval:60.0];

    NSURLConnection *theConnection = \
        [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];

    if (theConnection)
    {
        receivedData = [NSMutableData data];
        conn = theConnection;
    }
    else
    {
        NSLog(@"Connection request was NOT successful.");
    }

    return;
}

/**
 * @brief Download the post contents thumbnail (the data).
 *
 * @param identifier the post we're trying to download.
 */
- (void)viewThumbnail:(NSString *)identifier
{
    if ([identifier length] == 0)
    {
        [delegate apihandler:self didCompleteThumbnail:nil withPost:nil];
        return;
    }

    self.type = API_POST_THUMBNAIL;
    self.postId = identifier;

    NSDictionary *params = @{@"id" : identifier, @"thumbnail" : @""};

    NSString *urlStr = \
        [NSString stringWithFormat:@"%@snapshot/view?%@", base, [self encodeFields:params]];

    NSLog(@"URL: %@", urlStr);

    NSURLRequest *theRequest = \
        [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]
                         cachePolicy:NSURLRequestUseProtocolCachePolicy
                     timeoutInterval:60.0];

    NSURLConnection *theConnection = \
        [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];

    if (theConnection)
    {
        receivedData = [NSMutableData data];
        conn = theConnection;
    }
    else
    {
        NSLog(@"Connection request was NOT successful.");
    }
    
    return;
}

/**
 * @brief Get the userid for the specified screen name.
 *
 * @param screenName
 */
- (void)loginUser:(NSString *)screenName
{
    if ([screenName length] == 0)
    {
        [delegate apihandler:self didCompleteLogin:nil];
        return;
    }

    self.type = API_USER_LOGIN;

    NSDictionary *params = @{@"screen_name" : [screenName lowercaseString]};

    NSString *urlStr = \
        [NSString stringWithFormat:@"%@user/login?%@", base, [self encodeFields:params]];

    NSLog(@"URL: %@", urlStr);

    NSURLRequest *theRequest = \
        [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]
                         cachePolicy:NSURLRequestUseProtocolCachePolicy
                     timeoutInterval:60.0];

    NSURLConnection *theConnection = \
        [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];

    if (theConnection)
    {
        receivedData = [NSMutableData data];
        conn = theConnection;
    }
    else
    {
        NSLog(@"Connection request was NOT successful.");
    }

    return;
}

/**
 * @brief Get user information as me.
 *
 * @param user the user to get.
 * @param me who is running query.
 */
- (void)getAuthor:(NSString *)user asUser:(NSString *)myId
{
    if ([user length] == 0 || [myId length] == 0)
    {
        [delegate apihandler:self didCompleteName:nil withAuthor:nil asUser:nil];
        return;
    }

    self.type = API_USER_GET;
    self.me = myId;
    self.userIdentifier = user;

    NSDictionary *params = @{@"id" : user, @"requester" : myId};

    NSString *urlStr = [NSString stringWithFormat:@"%@user/get", base];
    NSURL *url = [[NSURL alloc] initWithString:urlStr];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    request.HTTPMethod = @"POST";
    request.HTTPBody = [[self encodeFields:params] dataUsingEncoding:NSUTF8StringEncoding];

    NSURLConnection *theConnection = \
        [[NSURLConnection alloc] initWithRequest:request delegate:self];

    if (theConnection)
    {
        receivedData = [NSMutableData data];
        conn = theConnection;
    }
    else
    {
        NSLog(@"Connection request was NOT successful.");
    }

    return;
}

/**
 * @brief Run the user query against userid as user me, right now the me field 
 * is disregarded by the API; but later it will likely make sense to make sure
 * you have permissions to get the information; you should be able to read other
 * users' communities, etc via this interface.
 *
 * @param userid the user you're querying
 * @param query the query you're running
 * @param myId who is running the query
 */
- (void)userQuery:(NSString *)userid
      withRequest:(NSString *)query
           asUser:(NSString *)myId
{
    if ([userid length] == 0 || [query length] == 0 || [myId length] == 0)
    {
        [delegate apihandler:self
        didCompleteUserQuery:nil
                   withQuery:nil
                     forUser:nil
                      asUser:nil];
        return;
    }

    NSArray *valid = @[@"community", @"watchlist", @"favorites"];

    if (![valid containsObject:query])
    {
        [delegate apihandler:self
        didCompleteUserQuery:nil
                   withQuery:nil
                     forUser:nil
                      asUser:nil];
        return;
    }

    self.type = API_USER_QUERY;
    self.userIdentifier = userid;
    self.me = myId;             // Save it off for later reference.
    self.userQueryType = query; // Save it off for later reference.

    NSDictionary *params = @{@"id" : userid, @"query" : query};

    NSString *urlStr = \
        [NSString stringWithFormat:@"%@user/query?%@", base, [self encodeFields:params]];

    NSLog(@"URL: %@", urlStr);

    NSURLRequest *theRequest = \
        [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]
                         cachePolicy:NSURLRequestUseProtocolCachePolicy
                     timeoutInterval:60.0];

    NSURLConnection *theConnection = \
        [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];

    if (theConnection)
    {
        receivedData = [NSMutableData data];
        conn = theConnection;
    }
    else
    {
        NSLog(@"Connection request was NOT successful.");
    }

    return;
}

/**
 * @brief Run the snapshot API home call, as the user.
 * 
 * @param myId
 *
 * @note I think this makes perfect sense to callback as a query... for now.
 */
- (void)userHome:(NSString *)myId
{
    if ([myId length] == 0)
    {
        [delegate apihandler:self didCompleteQuery:nil asUser:nil];
        return;
    }
    
    self.type = API_POST_QUERY;
    self.me = myId;

    NSDictionary *params = @{@"id" : myId};

    NSString *urlStr = \
        [NSString stringWithFormat:@"%@snapshot/home?%@", base, [self encodeFields:params]];

    NSLog(@"URL: %@", urlStr);

    NSURLRequest *theRequest = \
        [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]
                         cachePolicy:NSURLRequestUseProtocolCachePolicy
                     timeoutInterval:60.0];

    NSURLConnection *theConnection = \
        [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];

    if (theConnection)
    {
        receivedData = [NSMutableData data];
        conn = theConnection;
    }
    else
    {
        NSLog(@"Connection request was NOT successful.");
    }

    return;
}

/**
 * @brief Run snapshot/public as the specified user; this'll provide extra neato
 * details about the posts returned.
 *
 * @param user the user identifier value.
 */
- (void)publicStream:(NSString *)user
{
    if ([user length] == 0)
    {
        [delegate apihandler:self didCompleteQuery:nil asUser:nil];
        return;
    }
    
    self.type = API_POST_QUERY;
    self.me = user;

    NSDictionary *params = @{@"user" : user};

    NSString *urlStr = \
        [NSString stringWithFormat:@"%@snapshot/public?%@", base, [self encodeFields:params]];

    NSLog(@"URL: %@", urlStr);

    NSURLRequest *theRequest = \
        [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]
                         cachePolicy:NSURLRequestUseProtocolCachePolicy
                     timeoutInterval:60.0];

    NSURLConnection *theConnection = \
        [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];

    if (theConnection)
    {
        receivedData = [NSMutableData data];
        conn = theConnection;
    }
    else
    {
        NSLog(@"Connection request was NOT successful.");
    }

    return;
}

/**
 * @brief Download the user's avatar.  There's no guarantee there is an avatar.
 *
 * @param userid the user you wish to view.
 */
- (void)userView:(NSString *)userid
{
    if ([userid length] == 0)
    {
        [delegate apihandler:self didCompleteUserView:nil withUser:nil];
        return;
    }

    self.type = API_USER_VIEW;
    self.userIdentifier = userid;

    NSDictionary *params = @{@"id" : userid};

    NSString *urlStr = \
        [NSString stringWithFormat:@"%@user/view?%@", base, [self encodeFields:params]];

    NSLog(@"URL: %@", urlStr);

    NSURLRequest *theRequest = \
        [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]
                         cachePolicy:NSURLRequestUseProtocolCachePolicy
                     timeoutInterval:60.0];

    NSURLConnection *theConnection = \
        [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];

    if (theConnection)
    {
        receivedData = [NSMutableData data];
        conn = theConnection;
    }
    else
    {
        NSLog(@"Connection request was NOT successful.");
    }

    return;

}

/**
 * @brief Update the user's field with the specified value.
 *
 * @param userid the user
 * @param field the field to update
 * @param value the value for the update
 */
- (void)userUpdate:(NSString *)userid
          forField:(NSString *)field
         withValue:(NSString *)value
{
    if ([userid length] == 0 || [field length] == 0 || [value length] == 0)
    {
        [delegate apihandler:self didCompleteUpdate:NO asUser:nil];
        return;
    }

    NSArray *valid = \
        @[@"bio", @"realish_name", @"home", @"location", @"display_name"];
    
    if (![valid containsObject:field])
    {
        [delegate apihandler:self didCompleteUpdate:NO asUser:nil];
        return;
    }
    
    self.type = API_USER_UPDATE;
    self.me = userid;

    NSDictionary *params = @{@"user" : userid, field : value};

    NSString *urlStr = [NSString stringWithFormat:@"%@user/update", base];
    NSURL *url = [[NSURL alloc] initWithString:urlStr];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    request.HTTPMethod = @"POST";
    request.HTTPBody = [[self encodeFields:params] dataUsingEncoding:NSUTF8StringEncoding];

    NSURLConnection *theConnection = \
        [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    if (theConnection)
    {
        receivedData = [NSMutableData data];
        conn = theConnection;
    }
    else
    {
        NSLog(@"Connection request was NOT successful.");
    }

    return;
}

/**
 * @brief Update the user's field with the specified value.
 *
 * @param userid the user
 * @param data the value for the avatar
 */
- (void)userUpdate:(NSString *)userid withData:(NSData *)data
{
    if ([userid length] == 0 || [data length] == 0)
    {
        [delegate apihandler:self didCompleteUpdate:NO asUser:nil];
        return;
    }

    self.type = API_USER_UPDATE;
    self.me = userid;

    NSDictionary *params = @{@"user" : userid};

    Multipart *multi = \
        [[Multipart alloc] initWithStuff:params
                           imageContents:data
                                withName:@"avatar"];
    
    NSLog(@"Multi Created.");
    
    NSString *urlStr = [NSString stringWithFormat:@"%@user/update", base];
    NSURL *url = [[NSURL alloc] initWithString:urlStr];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    NSLog(@"Building Request.");
    
    request.HTTPMethod = @"POST";
    [request setValue:[multi getForm] forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[multi getOutputData]];
    
    NSLog(@"Request Built.");
    
    NSURLConnection *theConnection = \
        [[NSURLConnection alloc] initWithRequest:request delegate:self];

    if (theConnection)
    {
        receivedData = [NSMutableData data];
        conn = theConnection;
    }
    else
    {
        NSLog(@"Connection request was NOT successful.");
    }

    return;
}

/**
 * @brief Query the snapshot API with the specified query for the value, as the
 * user.
 *
 * @param query the query you want to run.
 * @param value the value to use for the query.
 * @param querierid the user running the query.
 * @param sinceId the latest value you have (optional).
 */
- (void)queryPosts:(NSString *)query
         withValue:(NSString *)value
            asUser:(NSString *)querierid
             since:(NSString *)sinceId
{
    NSDictionary *params = nil;

    if ([query length] == 0 || [value length] == 0 || [querierid length] == 0)
    {
        NSLog(@"queryPosts invalid input");
        [delegate apihandler:self didCompleteQuery:nil asUser:nil];
        return;
    }
    
    NSArray *valid = \
        @[@"screen_name", @"author", @"tag", @"reply_to", @"repost_of", @"community"];
    
    if (![valid containsObject:query])
    {
        [delegate apihandler:self didCompleteQuery:nil asUser:nil];
        return;
    }
    
    if ([query isEqualToString:@"screen_name"])
    {
        value = [value lowercaseString];
    }
    
    self.type = API_POST_QUERY;
    self.me = querierid;

    if (sinceId == nil)
    {
        params = @{query : value, @"user" : querierid};
    }
    else
    {
        params = @{query : value, @"user" : querierid, @"since" : sinceId};
    }

    NSString *urlStr = \
        [NSString stringWithFormat:@"%@snapshot/query?%@", base, [self encodeFields:params]];
    
    NSLog(@"URL: %@", urlStr);
    
    NSURLRequest *theRequest = \
        [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]
                         cachePolicy:NSURLRequestUseProtocolCachePolicy
                     timeoutInterval:60.0];
    
    NSURLConnection *theConnection = \
        [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    
    if (theConnection)
    {
        receivedData = [NSMutableData data];
        conn = theConnection;
    }
    else
    {
        NSLog(@"Connection request was NOT successful.");
    }
    
    return;
}

/**
 * @brief Query the snapshot API with the specified query for the value, as the
 * user.
 *
 * @param query the query you want to run.
 * @param value the value to use for the query.
 * @param querierid the user running the query.
 */
- (void)queryPosts:(NSString *)query
         withValue:(NSString *)value
            asUser:(NSString *)querierid
{
    [self queryPosts:query withValue:value asUser:querierid since:nil];
    
    return;
}

@end
