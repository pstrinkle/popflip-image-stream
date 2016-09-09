//
//  UITableCell.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 1/3/13.
//
//

#import <UIKit/UIKit.h>

/*
 * 10px cell 10px
 *
 * within a cell:
 * ---label ----
 * - thumbnail -
 */

/** @brief The height of the labels we're using. */
#define LABEL_HEIGHT 20

/**
 * @brief The square dimensions we're using for the thumbnails, also the label
 * width.  This may prove too narrow for the label at which point we'll use a
 * CELL_WIDTH to define the overall cell width which includes the wider label.
 */
#define THUMBNAIL_SIZE 80

/** @brief The width of the cell, really the width of the label. */
#define CELL_WIDTH 100

/**
 * @brief This is the height of a cell, which has at its top a label, then 10px
 * margin of empty before the thumbnail, and then nothing below the thumbnail.
 */
#define CELL_HEIGHT (THUMBNAIL_SIZE + 10 + LABEL_HEIGHT)

/**
 * @brief The gap you have to the left and right, please keep this to a non-odd
 * value.
 */
#define THUMBNAIL_MARGIN ((CELL_WIDTH - THUMBNAIL_SIZE) / 2)

#import "ImageSpinner.h"

@interface UITableCell : UIView

@property(strong) ImageSpinner *spin;
@property(strong) UILabel *heading;
@property(strong) UILabel *refresh;

/** @brief In case you want to set a key. */
@property(copy) NSString *key;

- (void)setImage:(UIImage *)image;
- (void)setText:(NSString *)text;
- (void)setFont:(UIFont *)font;
- (void)setNumberOfLines:(NSInteger)lines;
/** @brief Setting to zero clears the text. */
- (void)setRefreshCount:(NSInteger)count;

@end
