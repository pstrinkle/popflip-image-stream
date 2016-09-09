//
//  PivotTableViewController.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 8/26/12.
//
//

#import <UIKit/UIKit.h>

@protocol PivotPopupDelegate
/*
 * pivot types (should use enum):
 * - tag
 * - author
 * - screen_name
 * - reply_to
 */
- (void)handlePivot:(NSString *)pivot withValue:(NSString *)value;
@end

@interface PivotTableViewController : UITableViewController

@property(copy) NSDictionary *details;

@property(nonatomic,unsafe_unretained) id<PivotPopupDelegate> delegate;

- (id)initWithStyle:(UITableViewStyle)style withDetails:(NSDictionary *)details withDelegate:(id<PivotPopupDelegate>)delegate;

@end
