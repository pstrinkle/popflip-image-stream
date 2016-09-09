//
//  ImageSpinner.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/23/12.
//
//

#import <UIKit/UIKit.h>

@interface ImageSpinner : UIImageView

/** @brief The whole point of this thing is that it has an activity spinner. */
@property(nonatomic,strong) UIActivityIndicatorView *activity;

/** @brief In case you want to set a key. */
@property(copy) NSString *key;

@end
