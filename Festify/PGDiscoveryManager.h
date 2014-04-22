//
//  PGDiscoveryManager.h
//  Festify
//
//  Created by Patrik Gebhardt on 14/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <Spotify/Spotify.h>

// bluetooth uuid strings
static NSString* const PGDiscoveryManagerServiceUUIDString = @"313752b1-f55b-4769-9387-61ce9fd7a840";
static NSString* const PGDiscoveryManagerPlaylistUUIDString = @"be1e3455-4ca0-488a-809c-bd82e094ebaa";
static NSString* const PGDiscoveryManagerNameUUIDString = @"bebf2065-a207-4f21-a048-85e84dd34a7f";

@class PGDiscoveryManager;

@protocol PGDiscoveryManagerDelegate<NSObject>

-(void)discoveryManager:(PGDiscoveryManager*)discoveryManager didDiscoverPlaylistWithURI:(NSURL*)uri devicename:(NSString*)devicename identifier:(NSString*)identifier;

@end

@interface PGDiscoveryManager : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate>

+(PGDiscoveryManager*)sharedInstance;

-(BOOL)setAdvertisingPlaylist:(SPTPartialPlaylist*)playlist;
-(BOOL)startAdvertisingPlaylist;;
-(void)stopAdvertisingPlaylist;
-(BOOL)isAdvertisingsPlaylist;

-(BOOL)startDiscoveringPlaylists;
-(void)stopDiscoveringPlaylists;
-(BOOL)isDiscoveringPlaylists;

@property (nonatomic, weak) id<PGDiscoveryManagerDelegate> delegate;
@property (nonatomic, strong, readonly) SPTPartialPlaylist* advertisingPlaylist;

@end
