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

// spotify authentication constants
// TODO: replace with post-beta IDs and adjust the App's URL type
static NSString* const kClientID = @"spotify-ios-sdk-beta";
static NSString * const kCallbackURL = @"spotify-ios-sdk-beta://callback";

@interface PGAppDelegate ()

@property (nonatomic, copy) void (^loginCallback)(NSError* error);

@end

@implementation PGAppDelegate

-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.trackPlayer = [[SPTTrackPlayer alloc] initWithCompanyName:[NSBundle mainBundle].infoDictionary[(NSString*)kCFBundleIdentifierKey]
                                                           appName:[NSBundle mainBundle].infoDictionary[(NSString*)kCFBundleNameKey]];
    self.trackInfoDictionary = [NSMutableDictionary dictionary];
    self.trackProvider = [[PGFestifyTrackProvider alloc] init];
    
    // enable repeat for track player to get an endless playback behaviour
    self.trackPlayer.repeatEnabled = YES;
    
    // set delegates
    [PGDiscoveryManager sharedInstance].delegate = self;
    
    // restore application state
    [PGUserDefaults restoreApplicationState];
    
    // show white status bar and load spotify color schema for TSMessage
    [application setStatusBarHidden:NO];
    [application setStatusBarStyle:UIStatusBarStyleLightContent];
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
            
            // call callback to inform about completed session request
            if (self.loginCallback) {
                self.loginCallback(error);
            }
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
    [self.trackInfoDictionary removeAllObjects];
    
    // clear user defaults
    [PGUserDefaults clear];
}

#pragma mark - PGDiscoveryManagerDelegate

-(void)discoveryManager:(PGDiscoveryManager *)discoveryManager didDiscoverDevice:(NSString *)devicename withProperty:(NSData *)property {
    // extract spotify username from device property
    NSString* username = [[NSString alloc] initWithData:property encoding:NSUTF8StringEncoding];
    
    // add playlist for discovered user and notify user
    [self.trackProvider addPlaylistsFromUser:username session:self.session];
/*
        if (!error) {
            // start playback, if not already running
            if (weakSelf.trackPlayer.currentProvider == nil || weakSelf.trackPlayer.paused) {
                [weakSelf.trackPlayer playTrackProvider:weakSelf.trackProvider];
            }
            
        }
    }];
*/
}

#pragma mark - SPTTrackPlayerDelegate

-(void)trackPlayer:(SPTTrackPlayer *)player didStartPlaybackOfTrackAtIndex:(NSInteger)index ofProvider:(id<SPTTrackProvider>)provider {
    // fill track data dictionary
    self.trackInfoDictionary[MPMediaItemPropertyTitle] = [provider.tracks[index] name];
    self.trackInfoDictionary[MPMediaItemPropertyArtist] = [[[provider.tracks[index] artists] objectAtIndex:0] name];
    self.trackInfoDictionary[MPMediaItemPropertyPlaybackDuration] = [NSNumber numberWithDouble:[(SPTTrack*)provider.tracks[index] duration]];
    self.trackInfoDictionary[MPMediaItemPropertyAlbumTrackNumber] = [NSNumber numberWithInteger:index];
    self.trackInfoDictionary[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @0.0;
    self.trackInfoDictionary[@"spotifyURI"] = [provider.tracks[index] uri];
    
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

-(void)trackPlayer:(SPTTrackPlayer *)player didEndPlaybackOfTrackAtIndex:(NSInteger)index ofProvider:(id<SPTTrackProvider>)provider {
    NSLog(@"didEndPlaybackOfTrachAtIndex: %ld", (long)index);
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

-(void)trackPlayer:(SPTTrackPlayer *)player didEndPlaybackOfProvider:(id<SPTTrackProvider>)provider withError:(NSError *)error {
    NSLog(@"didEndPlaybackOfProviderWithError: %@", error);
}

-(void)trackPlayer:(SPTTrackPlayer *)player didDidReceiveMessageForEndUser:(NSString *)message {
    // show message to user
    [TSMessage showNotificationInViewController:self.window.rootViewController
                                          title:@"Message from Spotify:"
                                       subtitle:message
                                           type:TSMessageNotificationTypeMessage];
}

@end