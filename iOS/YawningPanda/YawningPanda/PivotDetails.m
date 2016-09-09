//
//  PivotDetails.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 11/17/12.
//
//

#import "PivotDetails.h"
#import "Util.h"

@implementation PivotDetails

@synthesize pivot, value, thumbnail;

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.pivot forKey:@"pivot"];
    [coder encodeObject:self.value forKey:@"value"];
    [coder encodeObject:self.thumbnail forKey:@"thumbnail"];
    
//    NSLog(@"encoding pivot history item.");

    return;
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [super init])
    {
        self.pivot = [coder decodeObjectForKey:@"pivot"];
        self.value = [coder decodeObjectForKey:@"value"];
        self.thumbnail = [coder decodeObjectForKey:@"thumbnail"];
    }
    
    return self;
}

- (id)init
{
    if (self = [super init])
    {
    }
    
    return self;
}

- (id)initWithPivot:(NSString *)spivot
          withValue:(NSString *)svalue
          withImage:(UIImage *)image
{
    if (self = [super init])
    {
        self.pivot = spivot;
        self.value = svalue;
        self.thumbnail = nil;
        
        if (image != nil)
        {
            CGSize uploadSize;
            CGSize x = [image size];

            if (x.width > 256 || x.height > 256)
            {
                /* not a great method. */
                if (x.width > 2048 || x.height > 2048)
                {
                    uploadSize = CGSizeMake(x.width / 8, x.height / 8);
                }
                else if (x.width > 1024 || x.height > 1024)
                {
                    uploadSize = CGSizeMake(x.width / 4, x.height / 4);
                }
                else
                {
                    uploadSize = CGSizeMake(x.width / 2, x.height / 2);
                }
                
                NSLog(@"uploadSize: (%f, %f)", uploadSize.width, uploadSize.height);

                UIGraphicsBeginImageContext(uploadSize);
                [image drawInRect:CGRectMake(0, 0, uploadSize.width, uploadSize.height)];
                UIImage *uploadImage = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                
                self.thumbnail = [Util centerCrop:uploadImage withMax:120];
            }
            else
            {
                NSLog(@"cropping without shrinking.");
                self.thumbnail = [Util centerCrop:image withMax:120];
            }
        }
    }

    return self;
}

@end
