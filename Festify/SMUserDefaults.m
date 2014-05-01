//
//  PGUserDefaults.m
//  Festify
//
//  Created by Patrik Gebhardt on 22/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "SMUserDefaults.h"
#import "SMDiscoveryManager.h"
#import "SMAppDelegate.h"
#import <Spotify/Spotify.h>

@implementation SMUserDefaults

+(void)saveApplicationState {
    // force synchronization
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(void)clear {
    // clear NSUserDefault storage
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:SMUserDefaultsAdvertisementStateKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:SMUserDefaultsSpotifySessionKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:SMUserDefaultsIndicesOfSelectedPlaylistsKey];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(SPTSession *)session {
    id plistRepresentation = [[NSUserDefaults standardUserDefaults] valueForKey:SMUserDefaultsSpotifySessionKey];
    return [[SPTSession alloc] initWithPropertyListRepresentation:plistRepresentation];
}

+(void)setSession:(SPTSession *)session {
    [[NSUserDefaults standardUserDefaults] setValue:session.propertyListRepresentation
                                             forKey:SMUserDefaultsSpotifySessionKey];
}

+(BOOL)advertisementState {
    return [[[NSUserDefaults standardUserDefaults] valueForKeyPath:SMUserDefaultsAdvertisementStateKey] boolValue];
}

+(void)setAdvertisementState:(BOOL)state {
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:state]
                                             forKey:SMUserDefaultsAdvertisementStateKey];
}

+(NSArray *)indicesOfSelectedPlaylists {
    return [[NSUserDefaults standardUserDefaults] valueForKey:SMUserDefaultsIndicesOfSelectedPlaylistsKey];
}

+(void)setIndicesOfSelectedPlaylists:(NSArray *)indices {
    [[NSUserDefaults standardUserDefaults] setValue:indices forKey:SMUserDefaultsIndicesOfSelectedPlaylistsKey];
}

@end