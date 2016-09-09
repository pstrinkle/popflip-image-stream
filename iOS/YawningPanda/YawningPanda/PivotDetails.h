//
//  PivotDetails.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 11/17/12.
//
//

#import <Foundation/Foundation.h>

@interface PivotDetails : NSObject

@property(copy) NSString *pivot;
@property(copy) NSString *value;
@property(copy) UIImage *thumbnail;

- (id)initWithPivot:(NSString *)spivot
          withValue:(NSString *)svalue
          withImage:(UIImage *)image;

@end
