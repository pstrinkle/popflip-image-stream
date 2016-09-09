//
//  Util.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 9/7/12.
//
//

#import "Util.h"

@implementation Util

/**
 * @brief Given a location string, check to see if it's actually a latlong
 * coordinate point.
 *
 * @param locationString the location string.
 */
+ (bool)locationIs2DCoordinate:(NSString *)locationString
{
    float tmpFloat;
    NSScanner *floatScanner;
    
    if ([locationString length] == 0)
    {
        return NO;
    }
    
    NSArray *points = [locationString componentsSeparatedByString:@", "];
    
    if ([points count] != 2)
    {
        return NO;
    }
    
    floatScanner = [NSScanner scannerWithString:points[0]];
    if (NO == [floatScanner scanFloat:&tmpFloat])
    {
        return NO;
    }
    
    floatScanner = [NSScanner scannerWithString:points[1]];
    if (NO == [floatScanner scanFloat:&tmpFloat])
    {
        return NO;
    }
    
    return YES;
}

/**
 * @brief Return a time comparison string.
 *
 * @param sinceDateTime (in UTC/GMT)
 */
+ (NSString *)timeSinceWhen:(NSDate *)sinceTime
{
    NSDate *today = [NSDate date];
    
    //NSLog(@"Now: %@: Then: %@", today, sinceTime);
    
    double interval = [today timeIntervalSinceDate:sinceTime];
    
    //NSLog(@"%f", interval);
    
    /* Come up with a cleaner way to do this. */
    int days = interval / (3600 * 24); // can just pull the modulus...
    interval -= (days * 3600 * 24);
    
    int hours = interval / (3600);
    interval -= (hours * 3600);
    
    int minutes = interval / 60;

    NSMutableArray *timeUnits = [[NSMutableArray alloc] init];
    
    if (days > 0)
    {
        [timeUnits addObject:[NSString stringWithFormat:@"%d %@", days, (days > 1) ? @"days" : @"day"]];
    }

    if (hours > 0)
    {
        [timeUnits addObject:[NSString stringWithFormat:@"%d %@", hours, (hours > 1) ? @"hours" : @"hour"]];
    }

    if (minutes > 0)
    {
        [timeUnits addObject:[NSString stringWithFormat:@"%d %@", minutes, (minutes > 1) ? @"minutes" : @"minute"]];
    }
    
    if (days == 0 && hours == 0 && minutes == 0)
    {
        return @"now";
    }

    return [timeUnits componentsJoinedByString:@", "];
}

+ (APIHandler *)getHandler:(id<CompletionDelegate>)delegate
{
    APIHandler *api = [[APIHandler alloc] init];
    /* this sets up the callback function required for the viewPost call */
    api.delegate = delegate;
    
    return api;
}

/**
 * @brief Convenience method.
 *
 * @param array.
 */
+ (int)lastIndex:(NSArray *)data
{
    return [data count] - 1;
}

+ (void)printRectangle:(CGRect)rect
{
    NSLog(@"origin: %f, %f, size: %f, %f",
          rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    
    return;
}

+ (CGFloat)getArea:(CGSize)size
{
    return (size.width * size.height);
}

+ (CGFloat)getFrameArea:(CGRect)rect
{
    return (rect.size.width - rect.origin.x) * (rect.size.height - rect.origin.y);
}

+ (UIImage *)centerCrop:(UIImage *)source withMax:(CGFloat)max
{
    float sourceH, sourceW;
    sourceH = source.size.height;
    sourceW = source.size.width;
    
    float excess;
    CGRect subArea;
    float smaller = fminf(sourceH, sourceW);
    
    if (smaller > max)
    {
        //NSLog(@"smaller side is greater than max"); // should work for all shapes.
        
        float horiz = sourceW - max;
        float vert = sourceH - max;
        
        subArea = CGRectMake(horiz / 2, vert / 2, max, max);
    }
    else
    {
        if (sourceH > sourceW) // it's tall.
        {
            excess = sourceH - sourceW;
            subArea = CGRectMake(0, excess / 2.0, sourceW, sourceW);
        }
        else if (sourceW > sourceH) // it's wide
        {
            excess = sourceW - sourceH;
            subArea = CGRectMake(excess / 2.0, 0, sourceH, sourceH);
        }
        else // square if it needed shrinking, would have been caught already.
        {
            return source;
        }
    }
    
    CGImageRef subImage = CGImageCreateWithImageInRect(source.CGImage, subArea);
    UIImage *returnImage = [UIImage imageWithCGImage:subImage];
    CGImageRelease(subImage);
    
    return returnImage;
}

+ (UIView *)basicLabelViewWithWidth:(CGFloat)width withHeight:(CGFloat)height
{
    UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    
    customView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UILabel *sectionHeader = [[UILabel alloc] initWithFrame:CGRectZero];
    
    sectionHeader.textAlignment = UITextAlignmentLeft;
    sectionHeader.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    sectionHeader.backgroundColor = [UIColor clearColor];
    sectionHeader.textColor = [UIColor darkGrayColor];
    sectionHeader.font = [UIFont boldSystemFontOfSize:18];
    sectionHeader.tag = 900;
    sectionHeader.frame = CGRectMake(20, 5, width - 40, 20);
    sectionHeader.contentMode = UIViewContentModeBottom;
    
    customView.contentMode = UIViewContentModeBottom;
    
    [customView addSubview:sectionHeader];
    
    return customView;
}

@end
