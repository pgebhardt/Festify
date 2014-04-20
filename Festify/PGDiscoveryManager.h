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

@class PGDiscoveryManager;

@protocol PGDiscoveryManagerDelegate<NSObject>

-(void)discoveryManager:(PGDiscoveryManager*)discoveryManager didDiscoverPlaylistWithURI:(NSURL*)uri byIdentifier:(NSString*)identifier;

@end

@interface PGDiscoveryManager : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate>

+(PGDiscoveryManager*)sharedInstance;

-(BOOL)setAdvertisingPlaylist:(SPTPartialPlaylist*)playlist withSession:(SPTSession*)session;
-(BOOL)startAdvertisingPlaylistWithSession:(SPTSession*)session;
-(void)stopAdvertisingPlaylist;
-(BOOL)isAdvertisingsPlaylist;

-(BOOL)startDiscoveringPlaylists;
-(void)stopDiscoveringPlaylists;
-(BOOL)isDiscoveringPlaylists;

@property (nonatomic, weak) id<PGDiscoveryManagerDelegate> delegate;
@property (nonatomic, strong) CBUUID* serviceUUID;
@property (nonatomic, strong, readonly) SPTPartialPlaylist* advertisingPlaylist;

@end
