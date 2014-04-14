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

-(void)discoveryManager:(PGDiscoveryManager*)discoveryManager didDiscoverUsers:(NSArray*)users andPlaylists:(NSArray*)playlists;

@end

@interface PGDiscoveryManager : NSObject<CBCentralManagerDelegate, CBPeripheralManagerDelegate, CBPeripheralDelegate>

+(PGDiscoveryManager*)sharedInstance;

-(void)startAdvertisingPlaylist:(SPTPartialPlaylist*)playlist withSession:(SPTSession*)session;
-(void)stopAdvertising;
-(void)discoverPlaylists;

@property (nonatomic, weak) id<PGDiscoveryManagerDelegate> delegate;
@property (nonatomic, strong) NSString* appId;

@end
