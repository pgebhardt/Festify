//
//  PGFestifyTrackProvider.h
//  Festify
//
//  Created by Patrik Gebhardt on 15/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Spotify/Spotify.h>
#import "PGDiscoveryManager.h"

@interface PGFestifyTrackProvider : NSObject<SPTTrackProvider, PGDiscoveryManagerDelegate>

-(id)initWithSession:(SPTSession*)session;
-(void)clearAllTracks;

@end
