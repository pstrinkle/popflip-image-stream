//
//  User.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 7/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface User : NSObject

@property(copy) NSString *realish_name;
@property(copy) NSString *screen_name;
@property(copy) NSString *display_name;

@property(copy) NSString *userid;
@property(copy) NSString *bio;
@property(copy) NSString *created;
@property(copy) NSString *email;
@property(copy) NSString *home;
@property(copy) NSString *location;
@property(strong) NSMutableArray *badges;
/** @brief An array of the user Ids they watch. */
@property(strong) NSMutableArray *watches;


@property(assign) NSInteger watching;
@property(assign) NSInteger watched;

@property(copy) NSDate *createdStamp;
@property(copy) UIImage *image; // this should free and copy a new image.
@property(assign) bool authorized;
@property(assign) bool authorized_back;

@property(nonatomic,readonly) CLLocationCoordinate2D coordinate;
//@property(nonatomic,readonly,copy) NSString *subtitle;
//@property(nonatomic,readonly,copy) NSString *title;

@property(assign) bool validCoordinates;

- (id)init;
- (id)initWithJSONDict:(NSDictionary *)jsonDict;
- (id)copyWithZone:(NSZone *)zone;
- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate;

@end
