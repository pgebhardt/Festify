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
static NSString* const SMUserDefaultsSpotifySessionKey = @"SMUserDefaultsSpotifySessionKey";
static NSString* const SMUserDefaultsAdvertisementStateKey = @"SMUserDefaultsAdvertisementStateKey";
static NSString* const SMUserDefaultsAdvertisedPlaylistsKey = @"SMUserDefaultsAdvertisedPlaylistsKey";
static NSString* const SMUserDefaultsUserTimeoutKey = @"SMUserDefaultsUserTimeoutKey";

@interface SMUserDefaults : NSObject

+(void)saveApplicationState;
+(void)clear;

+(SPTSession*)session;
+(void)setSession:(SPTSession*)session;

+(BOOL)advertisementState;
+(void)setAdvertisementState:(BOOL)state;

+(void)advertisedPlaylists:(void (^)(NSArray* advertisedPlaylists))completion;
+(void)setAdvertisedPlaylists:(NSArray*)advertisedPlaylists;

+(NSInteger)userTimeout;
+(void)setUserTimeout:(NSInteger)timeout;
+(NSArray*)userTimeoutSelections;

@end
