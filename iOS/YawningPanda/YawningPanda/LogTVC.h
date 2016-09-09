//
//  LogTVC.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/20/12.
//
//

#import <UIKit/UIKit.h>

@protocol EventLogDelegate
- (void)handlePurgeEvents;
@end

@interface LogTVC : UITableViewController

/* Maybe later just have a pointer, instead of copying the entire thing */
@property(copy) NSArray *events;

@property(nonatomic,unsafe_unretained) id<EventLogDelegate> delegate;

@end
