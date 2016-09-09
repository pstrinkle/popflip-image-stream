//
//  Multipart.m
//  YawningPanda
//
//  Created by Patrick Trinkle on 7/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Multipart.h"

@implementation Multipart

- (id)init
{
    if (self = [super init])
    {
        output = nil;
        boundary = nil;
    }
    
    return self;
}

/**
 * @brief This does not URL encode the parameters in fields.
 *
 * @param fields a dictionary of key-value pairs to use.
 * @param data the image data
 * @param name what you want to call the image data.
 */
- (id)initWithStuff:(NSDictionary *)fields imageContents:(NSData *)data withName:(NSString *)name
{
    if (self = [super init])
    {
        // fields has the key/value pairs for the form data
        // data has the image contents, assumes your key name is data.
        
        output = [[NSMutableData alloc] init];
        boundary = @"-condition-unlikely-03902920d9d09sd";
        
        NSString *disposition = @"Content-Disposition: form-data; name=\"%@\"\r\n";
        NSString *boringContent = @"Content-Type: text/plain; charset=utf-8";

        NSString *imgDisp = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"photo.jpg\"", name];
        NSString *jpegContent = @"Content-Type: image/jpeg";

        for (id obj in fields)
        {
//            NSLog(@"obj: %@", obj);
            [output appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] \
                                dataUsingEncoding:NSUTF8StringEncoding]];

            // ascii url encode
            [output appendData:[[NSString stringWithFormat:disposition, [obj stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]] \
                                dataUsingEncoding:NSUTF8StringEncoding]];

            [output appendData:[[NSString stringWithFormat:@"%@\r\n\r\n", boringContent] \
                                dataUsingEncoding:NSUTF8StringEncoding]];

            // ascii url encode
            [output appendData:[[NSString stringWithFormat:@"%@\r\n",
                                 [[fields valueForKey:obj] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]] \
                                dataUsingEncoding:NSUTF8StringEncoding]];
        }
        
        [output appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] \
                            dataUsingEncoding:NSUTF8StringEncoding]];
        [output appendData:[[NSString stringWithFormat:@"%@\r\n", imgDisp] \
                            dataUsingEncoding:NSUTF8StringEncoding]];
        [output appendData:[[NSString stringWithFormat:@"%@\r\n\r\n", jpegContent] \
                            dataUsingEncoding:NSUTF8StringEncoding]];
        [output appendData:data];
        [output appendData:[[NSString stringWithFormat:@"\r\n"] \
                            dataUsingEncoding:NSUTF8StringEncoding]];
        
        [output appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] \
                            dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    return self;
}

- (NSMutableData *)getOutputData
{
    return output;
}

- (NSString *)getForm
{
    return [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
}

- (void)dealloc
{
    NSLog(@"dealloc Multipart");
    
    
}


@end
