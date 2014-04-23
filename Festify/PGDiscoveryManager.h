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
static NSString* const PGDiscoveryManagerSpotifyUserUUIDString = @"be1e3455-4ca0-488a-809c-bd82e094ebaa";
static NSString* const PGDiscoveryManagerDevicenameUUIDString = @"bebf2065-a207-4f21-a048-85e84dd34a7f";

@class PGDiscoveryManager;

@protocol PGDiscoveryManagerDelegate<NSObject>

-(void)discoveryManager:(PGDiscoveryManager*)discoveryManager didDiscoverUser:(NSString*)username devicename:(NSString*)devicename;

@end

@interface PGDiscoveryManager : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate>

+(PGDiscoveryManager*)sharedInstance;

-(BOOL)startAdvertisingUser:(NSString*)canonicalUserName;
-(void)stopAdvertising;
-(BOOL)isAdvertising;

-(BOOL)startDiscovering;
-(void)stopDiscovering;
-(BOOL)isDiscovering;

@property (nonatomic, weak) id<PGDiscoveryManagerDelegate> delegate;

@end
