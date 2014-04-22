//
//  PGUserDefaults.m
//  Festify
//
//  Created by Patrik Gebhardt on 22/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "PGUserDefaults.h"
#import "PGDiscoveryManager.h"
#import "PGAppDelegate.h"
#import <Spotify/Spotify.h>

@implementation PGUserDefaults

+(void)restoreApplicationState {
    PGAppDelegate* appDelegate = (PGAppDelegate*)[UIApplication sharedApplication].delegate;
    
    // load spotify session
    id plistRepresentation = [[NSUserDefaults standardUserDefaults] valueForKey:PGUserDefaultsSpotifySessionKey];
    appDelegate.session = [[SPTSession alloc] initWithPropertyListRepresentation:plistRepresentation];
    
    // load advertised playlist and advertisement state of discovery manager
    NSNumber* indexOfAdvertisedPlaylist = [[NSUserDefaults standardUserDefaults] valueForKey:PGUserDefaultsIndexOfAdvertisedPlaylistKey];
    NSNumber* advertisementState = [[NSUserDefaults standardUserDefaults] valueForKeyPath:PGUserDefaultsAdvertisementStateKey];
    
    // set discovery manager
    [SPTRequest playlistsForUser:appDelegate.session.canonicalUsername withSession:appDelegate.session callback:^(NSError *error, id object) {
        if (!error) {
            SPTPlaylistList* playlists = (SPTPlaylistList*)object;
            
            [[PGDiscoveryManager sharedInstance] setAdvertisingPlaylist:playlists.items[[indexOfAdvertisedPlaylist integerValue]]];
            if ([advertisementState boolValue]) {
                [[PGDiscoveryManager sharedInstance] startAdvertisingPlaylist];
            }
            else {
                [[PGDiscoveryManager sharedInstance] stopAdvertisingPlaylist];
            }
        }
    }];
}

+(void)saveApplicationState {
    PGAppDelegate* appDelegate = (PGAppDelegate*)[UIApplication sharedApplication].delegate;

    // save current spotify session
    [[NSUserDefaults standardUserDefaults] setValue:appDelegate.session.propertyListRepresentation
                                         forKeyPath:PGUserDefaultsSpotifySessionKey];
    
    // save current discovery manager state
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:[PGDiscoveryManager sharedInstance].isAdvertisingsPlaylist]
                                         forKeyPath:PGUserDefaultsAdvertisementStateKey];
    
    // determine index of advertised playlist
    [SPTRequest playlistsForUser:appDelegate.session.canonicalUsername withSession:appDelegate.session callback:^(NSError *error, id object) {
        if (!error) {
            SPTPlaylistList* playlists = (SPTPlaylistList*)object;
            
            for (int i = 0; i < playlists.items.count; ++i) {
                if ([[playlists.items[i] uri].absoluteString isEqualToString:[PGDiscoveryManager sharedInstance].advertisingPlaylist.uri.absoluteString]) {
                    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:i] forKeyPath:PGUserDefaultsIndexOfAdvertisedPlaylistKey];
                    break;
                }
            }
        }
        
        [[NSUserDefaults standardUserDefaults] synchronize];
    }];
}

+(void)clear {
    // clear NSUserDefault storage
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:[NSBundle mainBundle].bundleIdentifier];;
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(void)setValue:(id)value forKey:(NSString *)key {
    [[NSUserDefaults standardUserDefaults] setValue:value forKey:key];
}

+(id)valueForKey:(NSString *)key {
    return [[NSUserDefaults standardUserDefaults] valueForKey:key];
}

@end
