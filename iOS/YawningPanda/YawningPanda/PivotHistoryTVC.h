//
//  PivotHistoryTVC.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 10/5/12.
//
//

#import <UIKit/UIKit.h>

#import "PivotTableViewController.h"

@interface PivotHistoryTVC : UITableViewController

/* It can't be destroyed while this view is up. */
@property(weak) NSMutableArray *pivotHistory;
@property(nonatomic,unsafe_unretained) id<PivotPopupDelegate> delegate;

@end
