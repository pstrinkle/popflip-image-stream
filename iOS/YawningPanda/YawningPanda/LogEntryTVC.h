//
//  LogEntryTVC.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/20/12.
//
//

#import "EventLogEntry.h"
#import <UIKit/UIKit.h>

@interface LogEntryTVC : UITableViewController

@property(copy) NSDictionary *details; /* maybe just use assign and don't free.. and hope nothing in the background can kill the data. */

@property(assign) enum EventType event;

@end
