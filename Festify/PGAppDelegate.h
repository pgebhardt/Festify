//
//  PGAppDelegate.h
//  Festify
//
//  Created by Patrik Gebhardt on 14/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Spotify/Spotify.h>
#import "PGFestifyTrackProvider.h"

@interface PGAppDelegate : UIResponder <UIApplicationDelegate, SPTTrackPlayerDelegate>

-(void)requestSpotifySessionWithCompletionHandler:(void (^)(NSError* error))completion;
-(void)loginToSpotifyAPIWithCompletionHandler:(void (^)(NSError* error))completion;
-(void)logoutOfSpotifyAPI;

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) SPTSession* session;
@property (nonatomic, strong) SPTTrackPlayer* trackPlayer;
@property (nonatomic, strong) PGFestifyTrackProvider* trackProvider;
@property (nonatomic, strong) NSMutableDictionary* trackInfoDictionary;
@property (nonatomic, strong) UIImage* coverArtOfCurrentTrack;

@end
