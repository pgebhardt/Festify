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

+(void)restoreApplicationState {
    SMAppDelegate* appDelegate = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
    
    // load spotify session
    id plistRepresentation = [[NSUserDefaults standardUserDefaults] valueForKey:SMUserDefaultsSpotifySessionKey];
    appDelegate.session = [[SPTSession alloc] initWithPropertyListRepresentation:plistRepresentation];
    
    // load advertisement state of discovery manager
    NSNumber* advertisementState = [[NSUserDefaults standardUserDefaults] valueForKeyPath:SMUserDefaultsAdvertisementStateKey];
    if ([advertisementState boolValue]) {
        [[SMDiscoveryManager sharedInstance] advertiseProperty:[appDelegate.session.canonicalUsername dataUsingEncoding:NSUTF8StringEncoding]];
    }
    else {
        [[SMDiscoveryManager sharedInstance] stopAdvertisingProperty];
    }
}

+(void)saveApplicationState {
    SMAppDelegate* appDelegate = (SMAppDelegate*)[UIApplication sharedApplication].delegate;

    // save current spotify session
    [[NSUserDefaults standardUserDefaults] setValue:appDelegate.session.propertyListRepresentation
                                         forKeyPath:SMUserDefaultsSpotifySessionKey];
    
    // save current discovery manager state
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:[SMDiscoveryManager sharedInstance].isAdvertisingProperty]
                                         forKeyPath:SMUserDefaultsAdvertisementStateKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(void)clear {
    // clear NSUserDefault storage
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:SMUserDefaultsAdvertisementStateKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:SMUserDefaultsSpotifySessionKey];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(void)setValue:(id)value forKey:(NSString *)key {
    [[NSUserDefaults standardUserDefaults] setValue:value forKey:key];
}

+(id)valueForKey:(NSString *)key {
    return [[NSUserDefaults standardUserDefaults] valueForKey:key];
}

@end
