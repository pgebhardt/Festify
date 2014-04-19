//
//  PGAppDelegate.m
//  Festify
//
//  Created by Patrik Gebhardt on 14/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "PGAppDelegate.h"
#import "PGDiscoveryManager.h"
#import "PGFestifyViewController.h"
#import <Spotify/Spotify.h>
#import "TestFlight.h"

// Spotify authentication credentials
static NSString* const kSpotifyClientId = @"spotify-ios-sdk-beta";
static NSString* const kSpotifyCallbackURL = @"spotify-ios-sdk-beta://callback";
static NSString* const kSessionUserDefaultsKey = @"SpotifySession";

@interface PGAppDelegate ()

@property (nonatomic, copy) void (^loginCallback)(NSError* error);

@end

@implementation PGAppDelegate

-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // update discovery manager service UUID
    [PGDiscoveryManager sharedInstance].serviceUUID = [CBUUID UUIDWithString:@"313752b1-f55b-4769-9387-61ce9fd7a840"];
    
    // enable test flight
    [TestFlight takeOff:@"53842477-fe12-4f61-ba55-aa1bb1eebba0"];
    
    // try to load session from NSUserDefaults
    SPTSession* session = [self loadSpotifySessionFromNSUserDefaults:kSessionUserDefaultsKey];;
    
    // check for valid session
    if (session.credential.length > 0) {
        [self initSpotifyWithSession:session];
    }
    
    return YES;
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // this is the return point for the spotify authentication,
    // so completion happens here
    if ([[SPTAuth defaultInstance] canHandleURL:url withDeclaredRedirectURL:[NSURL URLWithString:kSpotifyCallbackURL]]) {
        [[SPTAuth defaultInstance] handleAuthCallbackWithTriggeredAuthURL:url tokenSwapServiceEndpointAtURL:[NSURL URLWithString:@"http://patrik-macbook:1234/swap"] callback:^(NSError *error, SPTSession *session) {
            if (!error) {
                // save session to user defaults
                [[NSUserDefaults standardUserDefaults] setValue:[session propertyListRepresentation]
                                                         forKey:kSessionUserDefaultsKey];
                [[NSUserDefaults standardUserDefaults] synchronize];

                [self initSpotifyWithSession:session];
            }
            
            // call completion handler
            if (self.loginCallback) {
                self.loginCallback(error);
            }
        }];
        
        return YES;
    }
    
    return NO;
}

-(void)loginToSpotifyAPI:(void (^)(NSError *))completion {
    // set login callback
    self.loginCallback = completion;
    
    // get login url
    NSURL* loginURL = [[SPTAuth defaultInstance] loginURLForClientId:kSpotifyClientId
                                                 declaredRedirectURL:[NSURL URLWithString:kSpotifyCallbackURL]
                                                              scopes:@[@"login"]];
    
    // open url in safari to login to spotify api
    [[UIApplication sharedApplication] openURL:loginURL];
}

-(void)logoutOfSpotifyAPI {
    if (!self.trackPlayer.paused) {
        [self.trackPlayer pausePlayback];
    }
    
    __weak typeof(self) weakSelf = self;
    [self.streamingController setIsPlaying:NO callback:^(NSError *error) {
        weakSelf.trackPlayer = nil;
        weakSelf.streamingController = nil;
        weakSelf.session = nil;
    }];
    
    // clear NSUserDefault session storage
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSessionUserDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Helper

-(SPTSession*)loadSpotifySessionFromNSUserDefaults:(NSString*)spotifySessionKey {
    // load session from NSUserDefaults
    id plistRepresentation = [[NSUserDefaults standardUserDefaults] valueForKey:spotifySessionKey];
    return [[SPTSession alloc] initWithPropertyListRepresentation:plistRepresentation];
}

-(void)initSpotifyWithSession:(SPTSession*)session {
    self.session = session;
    
    // create new streaming controller and track player
    self.streamingController = [[SPTAudioStreamingController alloc] initWithCompanyName:@"Patrik Gebhardt"
                                                                                appName:@"Festify"];
    self.trackPlayer = [[SPTTrackPlayer alloc] initWithStreamingController:self.streamingController];
    self.trackPlayer.repeatEnabled = YES;
    
    // enable playback
    [self.trackPlayer enablePlaybackWithSession:session callback:^(NSError *error) {
        if (error) {
            NSLog(@"*** Enabling playback got error: %@", error);
        }
    }];
}

@end
