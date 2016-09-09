//
//  RowButton.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 11/21/12.
//
//

#import <UIKit/UIKit.h>

@interface RowButton : UIButton

@property(copy) NSString *value;
@property(copy) NSString *pivot;

+ (id)buttonWithType:(UIButtonType)buttonType;

@end
