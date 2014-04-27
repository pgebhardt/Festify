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
#import "ATConnect.h"

// spotify authentication constants
// TODO: replace with post-beta IDs and adjust the App's URL type
static NSString* const kClientID = @"spotify-ios-sdk-beta";
static NSString * const kCallbackURL = @"spotify-ios-sdk-beta://callback";

@interface PGAppDelegate ()

@property (nonatomic, copy) void (^loginCallback)(NSError* error);

@end

@implementation PGAppDelegate

-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.trackPlayer = [[SPTTrackPlayer alloc] initWithCompanyName:[NSBundle mainBundle].bundleIdentifier
                                                           appName:[NSBundle mainBundle].infoDictionary[(NSString*)kCFBundleNameKey]];
    self.trackInfoDictionary = [NSMutableDictionary dictionary];
    self.trackProvider = [[PGFestifyTrackProvider alloc] init];
    
    // enable repeat for track player to get an endless playback behaviour
    self.trackPlayer.repeatEnabled = YES;
    
    // set delegates
    [PGDiscoveryManager sharedInstance].delegate = self;
    
    // restore application state
    [PGUserDefaults restoreApplicationState];
    
    // initialize apptentive feedback system
    [ATConnect sharedConnection].apiKey = @"332a2ed7324aa7465ab10f63cfd79c62784a61ac97a80c83d489502f00a7b103";
    
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
        if (event.subtype == UIEventSubtypeRemoteControlPause ||
            (event.subtype == UIEventSubtypeRemoteControlTogglePlayPause && !self.trackPlayer.paused)) {
            [self pausePlayback];
        }
        else if (event.subtype == UIEventSubtypeRemoteControlPlay ||
            (event.subtype == UIEventSubtypeRemoteControlTogglePlayPause && self.trackPlayer.paused)) {
            [self resumePlayback];
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
            
            // initially add own songs to trackprovider
            __weak typeof(self) weakSelf = self;
            [self.trackProvider addPlaylistsFromUser:self.session.canonicalUsername session:self.session completion:^(NSError *error) {
                if (!error) {
                    [weakSelf.trackPlayer playTrackProvider:weakSelf.trackProvider];
                    [weakSelf.trackPlayer pausePlayback];
                    
                }
                if (completion) {
                    completion(error);
                }
            }];
        }
        else if (completion) {
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

-(void)pausePlayback {
    [self.trackPlayer pausePlayback];
    
    // update playback position and rate to avoid apple tv and lockscreen glitches
    self.trackInfoDictionary[MPNowPlayingInfoPropertyElapsedPlaybackTime] = [NSNumber numberWithDouble:self.trackPlayer.currentPlaybackPosition];
    self.trackInfoDictionary[MPNowPlayingInfoPropertyPlaybackRate] = @0.0;
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:self.trackInfoDictionary];
}

-(void)resumePlayback {
    [self.trackPlayer resumePlayback];
    
    // update playback position and rate to avoid apple tv and lockscreen glitches
    self.trackInfoDictionary[MPNowPlayingInfoPropertyElapsedPlaybackTime] = [NSNumber numberWithDouble:self.trackPlayer.currentPlaybackPosition];
    self.trackInfoDictionary[MPNowPlayingInfoPropertyPlaybackRate] = @1.0;
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:self.trackInfoDictionary];
}

#pragma mark - PGDiscoveryManagerDelegate

-(void)discoveryManager:(PGDiscoveryManager *)discoveryManager didDiscoverDevice:(NSString *)devicename withProperty:(NSData *)property {
    NSLog(@"didDiscoverDevice: %@ withProperty: %@", devicename,
          [[NSString alloc] initWithData:property encoding:NSUTF8StringEncoding]);
    
    // extract spotify username from device property
    NSString* username = [[NSString alloc] initWithData:property encoding:NSUTF8StringEncoding];
    
    // add playlist for discovered user and notify user
    __weak typeof(self) weakSelf = self;
    [self.trackProvider addPlaylistsFromUser:username session:self.session completion:^(NSError *error) {
        if (weakSelf.trackPlayer.paused) {
            [weakSelf.trackPlayer resumePlayback];
        }
    }];
    
    // fire local notification, if in background
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        UILocalNotification* notification = [[UILocalNotification alloc] init];
        notification.alertBody = [NSString stringWithFormat:@"Discovered %@", username];
        
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    }
}

#pragma mark - SPTTrackPlayerDelegate

-(void)trackPlayer:(SPTTrackPlayer *)player didStartPlaybackOfTrackAtIndex:(NSInteger)index ofProvider:(id<SPTTrackProvider>)provider {
    NSLog(@"didStartPlaybackOfTrackAtIndex: %ld", (long)index);

    // fill track data dictionary
    self.trackInfoDictionary[MPMediaItemPropertyTitle] = [provider.tracks[index] name];
    self.trackInfoDictionary[MPMediaItemPropertyArtist] = [[[provider.tracks[index] artists] objectAtIndex:0] name];
    self.trackInfoDictionary[MPMediaItemPropertyPlaybackDuration] = [NSNumber numberWithDouble:[(SPTTrack*)provider.tracks[index] duration]];
    self.trackInfoDictionary[MPMediaItemPropertyAlbumTrackNumber] = [NSNumber numberWithInteger:index];
    self.trackInfoDictionary[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @0.0;
    self.trackInfoDictionary[MPNowPlayingInfoPropertyPlaybackRate] = @0.0;
    self.trackInfoDictionary[@"spotifyURI"] = [provider.tracks[index] uri];
    
    // request complete album of track
    [SPTRequest requestItemAtURI:[provider.tracks[index] album].uri withSession:self.session callback:^(NSError *error, id object) {
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
    NSLog(@"didEndPlaybackOfTrackAtIndex: %ld", (long)index);
}

-(void)trackPlayer:(SPTTrackPlayer *)player didEndPlaybackOfProvider:(id<SPTTrackProvider>)provider withReason:(SPTPlaybackEndReason)reason {
    NSLog(@"didEndPlaybackOfProviderWithReason: %u", (unsigned)reason);

    if (reason == SPTPlaybackEndReasonLoggedOut) {
        // try to login again
        [MBProgressHUD showHUDAddedTo:self.window.subviews.lastObject animated:YES];
        [self.trackPlayer enablePlaybackWithSession:self.session callback:^(NSError *error) {
            [MBProgressHUD hideHUDForView:self.window.subviews.lastObject animated:YES];
            
            // restore trackPlayer state
            if (self.trackPlayer.currentProvider == nil) {
                [self.trackPlayer playTrackProvider:self.trackProvider
                                          fromIndex:[self.trackInfoDictionary[MPMediaItemPropertyAlbumTrackNumber] integerValue]];
                [self.trackPlayer pausePlayback];
            }
        }];
    }
}

-(void)trackPlayer:(SPTTrackPlayer *)player didEndPlaybackOfProvider:(id<SPTTrackProvider>)provider withError:(NSError *)error {
    NSLog(@"didEndPlaybackOfProviderWithError: %@", error);
}

-(void)trackPlayer:(SPTTrackPlayer *)player didDidReceiveMessageForEndUser:(NSString *)message {
    NSLog(@"didDidReceiveMessageForEndUser: %@", message);

    // show message to user
    [TSMessage showNotificationInViewController:self.window.subviews.lastObject
                                          title:@"Message from Spotify:"
                                       subtitle:message
                                           type:TSMessageNotificationTypeMessage];
}

@end