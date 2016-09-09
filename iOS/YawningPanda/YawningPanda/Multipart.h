//
//  Multipart.h
//  YawningPanda
//
//  Created by Patrick Trinkle on 7/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Multipart : NSObject {
    
    NSMutableData *output;
    NSString *boundary;
}

- (id)init;
- (id)initWithStuff:(NSDictionary *)fields imageContents:(NSData *)data withName:(NSString *)name;

//- (NSString *)getOutput;
- (NSMutableData *)getOutputData;

- (NSString *)getForm;

@end
