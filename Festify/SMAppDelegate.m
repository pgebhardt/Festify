//
//  PGAppDelegate.m
//  Festify
//
//  Created by Patrik Gebhardt on 14/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "SMAppDelegate.h"
#import "SMDiscoveryManager.h"
#import "SMUserDefaults.h"
#import <MediaPlayer/MediaPlayer.h>
#import <Spotify/Spotify.h>
#import "TSMessage.h"
#import "MBProgressHUD.h"
#import "ATConnect.h"

// spotify authentication constants
// TODO: replace with post-beta IDs and adjust the App's URL type
static NSString* const kClientID = @"spotify-ios-sdk-beta";
static NSString * const kCallbackURL = @"spotify-ios-sdk-beta://callback";

@interface SMAppDelegate ()
@property (nonatomic, copy) void (^loginCallback)(NSError* error);
@end

@implementation SMAppDelegate

-(void)remoteControlReceivedWithEvent:(UIEvent *)event {
    // control track player by remote events
    if (event.type == UIEventTypeRemoteControl) {
        if (event.subtype == UIEventSubtypeRemoteControlPlay ||
            event.subtype == UIEventSubtypeRemoteControlPause ||
            event.subtype == UIEventSubtypeRemoteControlTogglePlayPause) {
            [self togglePlaybackState];
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
    __weak typeof(self) weakSelf = self;
    
    // collect all playlists from current user and enable playback
    [self.trackProvider addPlaylistsFromUser:self.session.canonicalUsername session:self.session completion:^(NSError *error) {
        if (!error) {
            // login to track player to Spotify
            [weakSelf.trackPlayer enablePlaybackWithSession:weakSelf.session callback:^(NSError *error) {
                if (!error) {
                    weakSelf.trackPlayer.delegate = weakSelf;
                    [weakSelf.trackPlayer playTrackProvider:weakSelf.trackProvider
                                                  fromIndex:[weakSelf.trackInfo[MPMediaItemPropertyAlbumTrackNumber] integerValue]];
                    [weakSelf.trackPlayer pausePlayback];
                    
                    // start receiving remote control events
                    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
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
    // stop receiving remote control events
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    
    // stop audio playback
    [self.trackPlayer pausePlayback];

    // TODO: As soon as available, really log out of spotify ;)
    self.session = nil;
    
    // clear track provider
    [self.trackProvider clearAllTracks];
    [self.trackInfo removeAllObjects];
    
    // clear user defaults
    [SMUserDefaults clear];
}

-(void)togglePlaybackState {
    // toggle playback state and update playback position and rate to avoid apple tv and lockscreen glitches
    if (self.trackPlayer.paused) {
        [self.trackPlayer resumePlayback];
        self.trackInfo[MPNowPlayingInfoPropertyPlaybackRate] = @1.0;
    }
    else {
        [self.trackPlayer pausePlayback];
        self.trackInfo[MPNowPlayingInfoPropertyPlaybackRate] = @0.0;
    }
    
    self.trackInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = [NSNumber numberWithDouble:self.trackPlayer.currentPlaybackPosition];
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:self.trackInfo];
}

#pragma mark - UIApplicationDelegate

-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.trackPlayer = [[SPTTrackPlayer alloc] initWithCompanyName:[NSBundle mainBundle].bundleIdentifier
                                                           appName:[NSBundle mainBundle].infoDictionary[(NSString*)kCFBundleNameKey]];
    self.trackInfo = [NSMutableDictionary dictionary];
    self.trackProvider = [[SMFestifyTrackProvider alloc] init];
    
    // enable repeat for track player to get an endless playback behaviour
    self.trackPlayer.repeatEnabled = YES;
    
    // set delegates
    [SMDiscoveryManager sharedInstance].delegate = self;
    
    // restore application state
    [SMUserDefaults restoreApplicationState];
    
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
    [SMUserDefaults saveApplicationState];
}

-(void)applicationWillResignActive:(UIApplication *)application {
    // save current application state
    [SMUserDefaults saveApplicationState];    
}

#pragma mark - PGDiscoveryManagerDelegate

-(void)discoveryManager:(SMDiscoveryManager *)discoveryManager didDiscoverDevice:(NSString *)devicename withProperty:(NSData *)property {
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
    
    // notify user
    [self postNotificationWithTitle:[NSString stringWithFormat:@"Discovered %@", username]
                           subtitle:@"All public songs added!"
                               type:TSMessageNotificationTypeSuccess];
}

#pragma mark - Helper

-(void)postNotificationWithTitle:(NSString*)title subtitle:(NSString*)subtitle type:(TSMessageNotificationType)type {
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [TSMessage showNotificationInViewController:self.window.rootViewController title:title
                                               subtitle:subtitle type:type];
        });
    }
    else {
        UILocalNotification* notification = [[UILocalNotification alloc] init];
        notification.alertBody = [NSString stringWithFormat:@"%@\n%@", title, subtitle];
        
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    }
}

#pragma mark - SPTTrackPlayerDelegate

-(void)trackPlayer:(SPTTrackPlayer *)player didStartPlaybackOfTrackAtIndex:(NSInteger)index ofProvider:(id<SPTTrackProvider>)provider {
    NSLog(@"didStartPlaybackOfTrackAtIndex: %ld", (long)index);

    // fill track data dictionary
    self.trackInfo[MPMediaItemPropertyTitle] = [provider.tracks[index] name];
    self.trackInfo[MPMediaItemPropertyArtist] = [[[provider.tracks[index] artists] objectAtIndex:0] name];
    self.trackInfo[MPMediaItemPropertyPlaybackDuration] = [NSNumber numberWithDouble:[(SPTTrack*)provider.tracks[index] duration]];
    self.trackInfo[MPMediaItemPropertyAlbumTrackNumber] = [NSNumber numberWithInteger:index];
    self.trackInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @0.0;
    self.trackInfo[MPNowPlayingInfoPropertyPlaybackRate] = @1.0;
    self.trackInfo[@"spotifyURI"] = [provider.tracks[index] uri];
    
    // request complete album of track
    [SPTRequest requestItemAtURI:[provider.tracks[index] album].uri withSession:self.session callback:^(NSError *error, id object) {
        // download image
        [[[NSURLSession sharedSession] dataTaskWithRequest:[NSURLRequest requestWithURL:[object largestCover].imageURL]
                                         completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (!error) {
                self.coverArtOfCurrentTrack = [UIImage imageWithData:data];
                self.trackInfo[MPMediaItemPropertyArtwork] = [[MPMediaItemArtwork alloc] initWithImage:self.coverArtOfCurrentTrack];
            }
            [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:self.trackInfo];
        }] resume];
    }];
}

-(void)trackPlayer:(SPTTrackPlayer *)player didEndPlaybackOfTrackAtIndex:(NSInteger)index ofProvider:(id<SPTTrackProvider>)provider {
    NSLog(@"didEndPlaybackOfTrackAtIndex: %ld", (long)index);
}

-(void)trackPlayer:(SPTTrackPlayer *)player didEndPlaybackOfProvider:(id<SPTTrackProvider>)provider withReason:(SPTPlaybackEndReason)reason {
    NSLog(@"didEndPlaybackOfProvider: %@ withReason: %u", provider, (unsigned)reason);
    
    if (reason == SPTPlaybackEndReasonLoggedOut) {
        UIBackgroundTaskIdentifier backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
        [MBProgressHUD showHUDAddedTo:self.window.subviews.lastObject animated:YES];
        
        // try to login again
        [self loginToSpotifyAPIWithCompletionHandler:^(NSError *error) {
            // restore trackPlayer state, when woke up in background
            if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
                [self.trackPlayer resumePlayback];
            }
            
            [MBProgressHUD hideAllHUDsForView:self.window.subviews.lastObject animated:YES];
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
        }];
    }
}

-(void)trackPlayer:(SPTTrackPlayer *)player didEndPlaybackOfProvider:(id<SPTTrackProvider>)provider withError:(NSError *)error {
    NSLog(@"didEndPlaybackOfProvider: %@ withError: %@", provider, error);
}

-(void)trackPlayer:(SPTTrackPlayer *)player didDidReceiveMessageForEndUser:(NSString *)message {
    NSLog(@"didDidReceiveMessageForEndUser: %@", message);

    // show message to user
    [self postNotificationWithTitle:@"Message from Spotify:"
                           subtitle:message
                               type:TSMessageNotificationTypeMessage];
}

@end