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
#import "SMFestifyTrackProvider.h"

@interface SMAppDelegate : UIResponder <UIApplicationDelegate, SPTTrackPlayerDelegate,
    SMDiscoveryManagerDelegate>

-(void)requestSpotifySessionWithCompletionHandler:(void (^)(NSError* error))completion;
-(void)loginToSpotifyAPIWithCompletionHandler:(void (^)(NSError* error))completion;
-(void)logoutOfSpotifyAPI;
-(void)togglePlaybackState;

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) SPTSession* session;
@property (nonatomic, strong) SPTTrackPlayer* trackPlayer;
@property (nonatomic, strong) SMFestifyTrackProvider* trackProvider;
@property (nonatomic, strong) NSMutableDictionary* trackInfo;
@property (nonatomic, strong) UIImage* coverArtOfCurrentTrack;

@end
