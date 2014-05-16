//
//  SPTRequest+MultipleItems.h
//  Festify
//
//  Created by Patrik Gebhardt on 16/05/14.
//  Copyright (c) 2014 SchnuffMade. All rights reserved.
//

#import <Spotify/Spotify.h>

@interface SPTRequest (MultipleItems)

+(void)requestItemsAtURIs:(NSArray*)uris withSession:(SPTSession *)session callback:(SPTRequestCallback)block;

@end
