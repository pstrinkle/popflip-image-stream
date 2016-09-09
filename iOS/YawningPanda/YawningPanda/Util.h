//
//  Util.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/7/12.
//
//

#import <Foundation/Foundation.h>
#import "APIHandler.h"

@interface Util : NSObject

+ (bool)locationIs2DCoordinate:(NSString *)locationString;
+ (NSString *)timeSinceWhen:(NSDate *)sinceTime;
+ (APIHandler *)getHandler:(id<CompletionDelegate>)delegate;
+ (int)lastIndex:(NSArray *)data;
+ (void)printRectangle:(CGRect)rect;
+ (CGFloat)getArea:(CGSize)size;
+ (CGFloat)getFrameArea:(CGRect)rect;
+ (UIImage *)centerCrop:(UIImage *)source withMax:(CGFloat)max;
+ (UIView *)basicLabelViewWithWidth:(CGFloat)width withHeight:(CGFloat)height;

@end
