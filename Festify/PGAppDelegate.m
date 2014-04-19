//
//  PGAppDelegate.m
//  Festify
//
//  Created by Patrik Gebhardt on 14/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "PGAppDelegate.h"
#import "PGDiscoveryManager.h"
#import "TestFlight.h"
#import <Spotify/Spotify.h>
#import <MediaPlayer/MediaPlayer.h>
#import "TSMessage.h"

// authentication IDs
static NSString* const kPGDiscoveryManagerUUID = @"313752b1-f55b-4769-9387-61ce9fd7a840";
static NSString* const kTestFlightAppToken = @"64c2e34b-5362-4a6f-8d64-644887b84b52";

// spotify authentication constants
// TODO: replace with post-beta IDs and adjust the App's URL type
static NSString* const kClientID = @"spotify-ios-sdk-beta";
static NSString * const kCallbackURL = @"spotify-ios-sdk-beta://callback";
static NSString * const kSessionUserDefaultsKey = @"SpotifySession";

@interface PGAppDelegate ()

@property (nonatomic, copy) void (^loginCallback)(NSError* error);
@property (nonatomic, strong) NSMutableDictionary* trackInfoDictionary;

@end

@implementation PGAppDelegate

-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.trackInfoDictionary = [NSMutableDictionary dictionary];
    
    // initialize services
    [PGDiscoveryManager sharedInstance].serviceUUID = [CBUUID UUIDWithString:kPGDiscoveryManagerUUID];
    [TestFlight takeOff:kTestFlightAppToken];
    [self initSpotifyWithSession:[self loadSpotifySessionFromNSUserDefaults:kSessionUserDefaultsKey]];
    
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
                                            tokenSwapServiceEndpointAtURL:[NSURL URLWithString:@"http://patrik-macbook:1234/swap"]
                                                                 callback:^(NSError *error, SPTSession *session) {
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

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSDictionary* trackMetadata = [self.streamingController.currentTrackMetadata copy];
    if ([keyPath isEqualToString:@"streamingController.currentTrackMetadata"]) {
        // fill track data dictionary
        self.trackInfoDictionary[MPMediaItemPropertyAlbumTitle] = trackMetadata[SPTAudioStreamingMetadataTrackName];
        self.trackInfoDictionary[MPMediaItemPropertyArtist] = trackMetadata[SPTAudioStreamingMetadataArtistName];
        self.trackInfoDictionary[MPMediaItemPropertyPlaybackDuration] = trackMetadata[SPTAudioStreamingMetadataTrackDuration];
        self.trackInfoDictionary[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @0.0;
        
        // request complete album of track
        [SPTRequest requestItemAtURI:[NSURL URLWithString:trackMetadata[SPTAudioStreamingMetadataAlbumURI]]
                         withSession:self.session
                            callback:^(NSError *error, id object) {
            if (!error) {
                // extract image URL
                NSURL* imageURL = [object largestCover].imageURL;
                
                // download image
                [[[NSURLSession sharedSession] dataTaskWithRequest:[NSURLRequest requestWithURL:imageURL]
                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    if (!error) {
                        self.trackInfoDictionary[MPMediaItemPropertyArtwork] = [[MPMediaItemArtwork alloc] initWithImage:[UIImage imageWithData:data]];
                    }
                    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:self.trackInfoDictionary];
                }] resume];
            }
        }];
    }
    else if ([keyPath isEqualToString:@"trackPlayer.paused"]) {
        if (!self.trackPlayer.paused) {
            self.trackInfoDictionary[MPNowPlayingInfoPropertyElapsedPlaybackTime] = [NSNumber numberWithDouble:self.streamingController.currentPlaybackPosition];
            [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:self.trackInfoDictionary];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
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

-(void)loginToSpotifyAPI:(void (^)(NSError *))completion {
    // set login callback
    self.loginCallback = completion;
    
    // get login url
    NSURL* loginURL = [[SPTAuth defaultInstance] loginURLForClientId:kClientID
                                                 declaredRedirectURL:[NSURL URLWithString:kCallbackURL]
                                                              scopes:@[@"login"]];
    
    // open url in safari to login to spotify api
    [[UIApplication sharedApplication] openURL:loginURL];
}

-(void)logoutOfSpotifyAPI {
    // stop receiving remot control events
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    
    // cleanup spotify api
    __weak typeof(self) weakSelf = self;
    [self removeObserver:self forKeyPath:@"streamingController.currentTrackMetadata"];
    [self removeObserver:self forKeyPath:@"trackPlayer.paused"];
    if (!self.trackPlayer.paused) {
        [self.trackPlayer pausePlayback];
    }
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
    if (session.credential.length == 0) {
        return;
    }
    
    self.session = session;
    
    // create new streaming controller and observe track changes
    self.streamingController = [[SPTAudioStreamingController alloc] initWithCompanyName:[NSBundle mainBundle].infoDictionary[(NSString*)kCFBundleIdentifierKey]
                                                                                appName:[NSBundle mainBundle].infoDictionary[(NSString*)kCFBundleNameKey]];
    [self addObserver:self forKeyPath:@"streamingController.currentTrackMetadata" options:0 context:nil];
    
    // create track player and enable playback
    self.trackPlayer = [[SPTTrackPlayer alloc] initWithStreamingController:self.streamingController];
    self.trackPlayer.repeatEnabled = YES;
    [self addObserver:self forKeyPath:@"trackPlayer.paused" options:0 context:nil];
    [self.trackPlayer enablePlaybackWithSession:session callback:nil];
    
    // start handling remote control events
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
}

@end