//
//  PGUserDefaults.h
//  Festify
//
//  Created by Patrik Gebhardt on 22/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Spotify/Spotify.h>

// default application keys
static NSString* const SMUserDefaultsSpotifySessionKey = @"spotifySession";
static NSString* const SMUserDefaultsAdvertisementStateKey = @"advertisementState";
static NSString* const SMUserDefaultsIndicesOfSelectedPlaylistsKey = @"indicesOfSelectedPlaylists";

@interface SMUserDefaults : NSObject

+(void)saveApplicationState;
+(void)clear;

+(SPTSession*)session;
+(void)setSession:(SPTSession*)session;

+(BOOL)advertisementState;
+(void)setAdvertisementState:(BOOL)state;

+(NSArray*)indicesOfSelectedPlaylists;
+(void)setIndicesOfSelectedPlaylists:(NSArray*)indices;

@end
