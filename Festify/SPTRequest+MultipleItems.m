//
//  SPTRequest+MultipleItems.m
//  Festify
//
//  Created by Patrik Gebhardt on 16/05/14.
//  Copyright (c) 2014 SchnuffMade. All rights reserved.
//

#import "SPTRequest+MultipleItems.h"

@implementation SPTRequest (MultipleItems)

+(void)requestItemsAtURIs:(NSArray *)uris withSession:(SPTSession *)session callback:(SPTRequestCallback)block {
    __block NSInteger requestCompleteCount = 0;
    __block NSMutableArray* items = [NSMutableArray array];
    for (NSURL* uri in uris) {
        [SPTRequest requestItemAtURI:uri withSession:session callback:^(NSError *error, id object) {
            requestCompleteCount += 1;
            if (!error) {
                [items addObject:object];
            }
            
            // when all items are requested, call completion block
            if (requestCompleteCount == uris.count && block) {
                block(nil, items);
            }
        }];
    }
}

@end
