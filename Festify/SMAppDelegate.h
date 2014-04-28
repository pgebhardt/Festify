//
//  PGAppDelegate.h
//  Festify
//
//  Created by Patrik Gebhardt on 14/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Spotify/Spotify.h>
#import "SMDiscoveryManager.h"
#import "SMTrackPlayer.h"
#import "SMFestifyTrackProvider.h"

@interface SMAppDelegate : UIResponder <UIApplicationDelegate, SMDiscoveryManagerDelegate>

-(void)requestSpotifySessionWithCompletionHandler:(void (^)(NSError* error))completion;
-(void)loginToSpotifyAPIWithCompletionHandler:(void (^)(NSError* error))completion;
-(void)logoutOfSpotifyAPI;

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) SPTSession* session;
@property (nonatomic, strong) SMTrackPlayer* trackPlayer;
@property (nonatomic, strong) SMFestifyTrackProvider* trackProvider;

@end
