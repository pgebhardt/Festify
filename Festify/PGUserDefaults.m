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
    
    // load advertisement state of discovery manager
    NSNumber* advertisementState = [[NSUserDefaults standardUserDefaults] valueForKeyPath:PGUserDefaultsAdvertisementStateKey];
    if ([advertisementState boolValue]) {
        [[PGDiscoveryManager sharedInstance] advertiseProperty:[appDelegate.session.canonicalUsername dataUsingEncoding:NSUTF8StringEncoding]];
    }
    else {
        [[PGDiscoveryManager sharedInstance] stopAdvertisingProperty];
    }
}

+(void)saveApplicationState {
    PGAppDelegate* appDelegate = (PGAppDelegate*)[UIApplication sharedApplication].delegate;

    // save current spotify session
    [[NSUserDefaults standardUserDefaults] setValue:appDelegate.session.propertyListRepresentation
                                         forKeyPath:PGUserDefaultsSpotifySessionKey];
    
    // save current discovery manager state
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:[PGDiscoveryManager sharedInstance].isAdvertisingProperty]
                                         forKeyPath:PGUserDefaultsAdvertisementStateKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(void)clear {
    // clear NSUserDefault storage
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:PGUserDefaultsAdvertisementStateKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:PGUserDefaultsSpotifySessionKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:PGUserDefaultsIncludeOwnSongsKey];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(void)setValue:(id)value forKey:(NSString *)key {
    [[NSUserDefaults standardUserDefaults] setValue:value forKey:key];
}

+(id)valueForKey:(NSString *)key {
    return [[NSUserDefaults standardUserDefaults] valueForKey:key];
}

@end
