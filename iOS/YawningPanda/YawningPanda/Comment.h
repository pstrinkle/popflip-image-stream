//
//  Comment.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 10/21/12.
//
//

#import <Foundation/Foundation.h>

@interface Comment : NSObject

@property(copy) NSString *author;
@property(copy) NSString *created;
@property(copy) NSString *comment;

/* Derived Properties */
@property(copy) NSDate *createdStamp;

- (id)init;
- (id)initWithJSONDict:(NSDictionary *)jsonDict;

@end
