//
//  PGUserDefaults.h
//  Festify
//
//  Created by Patrik Gebhardt on 22/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <Foundation/Foundation.h>

// default application keys
static NSString* const PGUserDefaultsSpotifySessionKey = @"spotifySession";
static NSString* const PGUserDefaultsIndexOfAdvertisedPlaylistKey = @"indexOfAdvertisedPlaylist";
static NSString* const PGUserDefaultsAdvertisementStateKey = @"AdvertisementState";

@interface PGUserDefaults : NSObject

+(void)restoreApplicationState;
+(void)saveApplicationState;
+(void)clear;

+(id)valueForKey:(NSString*)key;
+(void)setValue:(id)value forKey:(NSString*)key;

@end
