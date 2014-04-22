//
//  PGAppDelegate.m
//  Festify
//
//  Created by Patrik Gebhardt on 14/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "PGAppDelegate.h"
#import "PGDiscoveryManager.h"
#import "PGUserDefaults.h"
#import <MediaPlayer/MediaPlayer.h>
#import <Spotify/Spotify.h>
#import "TSMessage.h"
#import "MBProgressHUD.h"

// authentication IDs
static NSString* const kPGDiscoveryManagerUUID = @"313752b1-f55b-4769-9387-61ce9fd7a840";
static NSString* const kTestFlightAppToken = @"64c2e34b-5362-4a6f-8d64-644887b84b52";

// spotify authentication constants
// TODO: replace with post-beta IDs and adjust the App's URL type
static NSString* const kClientID = @"spotify-ios-sdk-beta";
static NSString * const kCallbackURL = @"spotify-ios-sdk-beta://callback";

@interface PGAppDelegate ()

@property (nonatomic, copy) void (^loginCallback)(NSError* error);

@end

@implementation PGAppDelegate

-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.trackInfoDictionary = [NSMutableDictionary dictionary];
    self.trackProvider = [[PGFestifyTrackProvider alloc] init];
    
    // restore application state
    [PGUserDefaults restoreApplicationState];
    
    // init spotify objects
    self.trackPlayer = [[SPTTrackPlayer alloc] initWithCompanyName:[NSBundle mainBundle].infoDictionary[(NSString*)kCFBundleIdentifierKey]
                                                           appName:[NSBundle mainBundle].infoDictionary[(NSString*)kCFBundleNameKey]];
    self.trackPlayer.repeatEnabled = YES;
    
    // initialize services
    [PGDiscoveryManager sharedInstance].serviceUUID = [CBUUID UUIDWithString:kPGDiscoveryManagerUUID];
    
    // adjust default colors to match spotify color schema
    [application setStatusBarHidden:NO];
    [application setStatusBarStyle:UIStatusBarStyleLightContent];
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:130.0/255.0 green:130.0/255.0 blue:130.0/255.0 alpha:1.0]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName: [UIColor whiteColor]}];
    [[UIButton appearance] setTintColor:[UIColor colorWithRed:132.0/255.0 green:189.0/255.0 blue:0.0 alpha:1.0]];
    [[UIProgressView appearance] setTintColor:[UIColor colorWithRed:132.0/255.0 green:189.0/255.0 blue:0.0 alpha:1.0]];
    [TSMessage addCustomDesignFromFileWithName:@"spotifymessagedesign.json"];
    
    return YES;
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // this is the return point for the spotify authentication,
    // so completion happens here
    if ([[SPTAuth defaultInstance] canHandleURL:url withDeclaredRedirectURL:[NSURL URLWithString:kCallbackURL]]) {
        [[SPTAuth defaultInstance] handleAuthCallbackWithTriggeredAuthURL:url
                                            tokenSwapServiceEndpointAtURL:[NSURL URLWithString:@"http://192.168.178.28:1234/swap"]
                                                                 callback:^(NSError *error, SPTSession *session) {
            if (!error) {
                self.session = session;
            }
            
            // init track player
            [self loginToSpotifyAPIWithCompletionHandler:self.loginCallback];
        }];
        
        return YES;
    }
    
    return NO;
}

-(void)applicationWillTerminate:(UIApplication *)application {
    // save current application state
    [PGUserDefaults saveApplicationState];
}

-(void)applicationWillResignActive:(UIApplication *)application {
    // save current application state
    [PGUserDefaults saveApplicationState];    
}

-(void)remoteControlReceivedWithEvent:(UIEvent *)event {
    // control track player by remote events
    if (event.type == UIEventTypeRemoteControl) {
        if (event.subtype == UIEventSubtypeRemoteControlPause) {
            [self.trackPlayer pausePlayback];
        }
        else if (event.subtype == UIEventSubtypeRemoteControlPlay) {
            [self.trackPlayer resumePlayback];
        }
        else if (event.subtype == UIEventSubtypeRemoteControlTogglePlayPause) {
            if (self.trackPlayer.paused) {
                [self.trackPlayer resumePlayback];
            }
            else {
                [self.trackPlayer pausePlayback];
            }
        }
        else if (event.subtype == UIEventSubtypeRemoteControlNextTrack) {
            [self.trackPlayer skipToNextTrack];
        }
        else if (event.subtype == UIEventSubtypeRemoteControlPreviousTrack) {
            [self.trackPlayer skipToPreviousTrack:NO];
        }
    }
}

-(void)requestSpotifySessionWithCompletionHandler:(void (^)(NSError *))completion {
    // set login callback
    self.loginCallback = completion;
    
    // get login url
    NSURL* loginURL = [[SPTAuth defaultInstance] loginURLForClientId:kClientID
                                                 declaredRedirectURL:[NSURL URLWithString:kCallbackURL]
                                                              scopes:@[@"login"]];
    
    // open url in safari to login to spotify api
    [[UIApplication sharedApplication] openURL:loginURL];
}

-(void)loginToSpotifyAPIWithCompletionHandler:(void (^)(NSError *))completion {
    // login to Spotify with track player
    [self.trackPlayer enablePlaybackWithSession:self.session callback:^(NSError *error) {
        if (!error) {
            // start receiving remote control events and delegate messages
            [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
            self.trackPlayer.delegate = self;
        }
        
        if (completion) {
            completion(error);
        }
    }];
}

-(void)logoutOfSpotifyAPI {
    // stop receiving remote control events and delegate messages
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    self.trackPlayer.delegate = nil;
    
    // stop audio playback
    [self.trackPlayer pausePlayback];

    // TODO: As soon as available, really log out of spotify ;)
    self.session = nil;
    
    // clear track provider
    [self.trackProvider clearAllTracks];
    
    // clear user defaults
    [PGUserDefaults clear];
}

#pragma mark - SPTTrackPlayerDelegate

-(void)trackPlayer:(SPTTrackPlayer *)player didStartPlaybackOfTrackAtIndex:(NSInteger)index ofProvider:(id<SPTTrackProvider>)provider {
    // fill track data dictionary
    self.trackInfoDictionary[MPMediaItemPropertyTitle] = [provider.tracks[index] name];
    self.trackInfoDictionary[MPMediaItemPropertyArtist] = [[[provider.tracks[index] artists] objectAtIndex:0] name];
    self.trackInfoDictionary[MPMediaItemPropertyPlaybackDuration] = [NSNumber numberWithDouble:[(SPTTrack*)provider.tracks[index] duration]];
    self.trackInfoDictionary[MPMediaItemPropertyAlbumTrackNumber] = [NSNumber numberWithInteger:index];
    self.trackInfoDictionary[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @0.0;
    
    // request complete album of track
    [SPTRequest requestItemAtURI:[[provider.tracks[index] album] uri] withSession:self.session callback:^(NSError *error, id object) {
        if (!error) {
            // download image
            [[[NSURLSession sharedSession] dataTaskWithRequest:[NSURLRequest requestWithURL:[object largestCover].imageURL]
                                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                if (!error) {
                    self.coverArtOfCurrentTrack = [UIImage imageWithData:data];
                    self.trackInfoDictionary[MPMediaItemPropertyArtwork] = [[MPMediaItemArtwork alloc] initWithImage:self.coverArtOfCurrentTrack];
                }
                [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:self.trackInfoDictionary];
            }] resume];
        }
    }];
}

-(void)trackPlayer:(SPTTrackPlayer *)player didEndPlaybackOfProvider:(id<SPTTrackProvider>)provider withReason:(SPTPlaybackEndReason)reason {
    if (reason == SPTPlaybackEndReasonLoggedOut) {
        // try to login again
        [MBProgressHUD showHUDAddedTo:self.window.subviews.lastObject animated:YES];
        [self loginToSpotifyAPIWithCompletionHandler:^(NSError *error) {
            [MBProgressHUD hideHUDForView:self.window.subviews.lastObject animated:YES];
            
            // restore trackPlayer state
            [self.trackPlayer playTrackProvider:self.trackProvider
                                      fromIndex:[self.trackInfoDictionary[MPMediaItemPropertyAlbumTrackNumber] integerValue]];
            [self.trackPlayer pausePlayback];
        }];
    }
}

@end