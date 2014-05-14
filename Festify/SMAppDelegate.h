//
//  PGAppDelegate.h
//  Festify
//
//  Created by Patrik Gebhardt on 14/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Spotify/Spotify.h>

@class SMTrackPlayer;

@interface SMAppDelegate : UIResponder <UIApplicationDelegate>

-(void)requestSpotifySessionWithCompletionHandler:(void (^)(SPTSession* session, NSError* error))completion;
@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) SMTrackPlayer* trackPlayer;

@end
