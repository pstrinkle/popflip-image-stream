//
//  Post.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface Post : NSObject <MKAnnotation>

@property bool cachingImage;
@property bool cachingUser;
@property bool cachingThumbnail;

/* Native Properties */

@property bool favorite_of_user;

@property(assign) NSInteger num_replies;
@property(assign) NSInteger num_reposts;
@property(assign) NSInteger num_comments;

@property(copy) NSString *reply_to;
@property(copy) NSString *repost_of;

@property(copy) NSString *author;
@property(copy) NSString *created;

@property(copy) NSString *postid;
@property(copy) NSString *location;
@property(copy) NSMutableArray *tags;

/* Derived Properties */
@property(copy) NSDate *createdStamp;
@property(strong) NSMutableArray *communities;

@property(nonatomic,readonly) CLLocationCoordinate2D coordinate;
//@property(nonatomic,readonly,copy) NSString *subtitle;
//@property(nonatomic,readonly,copy) NSString *title;

@property(assign) bool validCoordinates;

/* Sort of Extra Properties */

@property(retain) NSMutableArray *comments;
@property(copy) NSDate *commentsRefreshed; // this is set when comments are downloaded.
@property(copy) UIImage *image; // this should free and copy a new image.
@property(copy) UIImage *thumbnail;
@property(copy) NSString *screen_name;
@property(copy) NSString *display_name;

- (id)init;
- (id)initWithJSONDict:(NSDictionary *)jsonDict;
- (id)copyWithZone:(NSZone *)zone;

@end
