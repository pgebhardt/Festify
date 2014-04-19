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
#import "TestFlight.h"
#import <Spotify/Spotify.h>
#import <MediaPlayer/MediaPlayer.h>

// authentication credentials
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

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSDictionary* trackMetadata = self.streamingController.currentTrackMetadata;
    if ([keyPath isEqualToString:@"streamingController.currentTrackMetadata"]) {
        // fill track data dictionary
        NSMutableDictionary* trackInfo = [NSMutableDictionary dictionary];
        trackInfo[MPMediaItemPropertyAlbumTitle] = trackMetadata[SPTAudioStreamingMetadataTrackName];
        trackInfo[MPMediaItemPropertyArtist] = trackMetadata[SPTAudioStreamingMetadataArtistName];
        trackInfo[MPMediaItemPropertyPlaybackDuration] = trackMetadata[SPTAudioStreamingMetadataTrackDuration];
        // trackInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = [NSNumber numberWithDouble:self.streamingController.currentPlaybackPosition];
        
        // request complete album of track
        [SPTRequest requestItemAtURI:[NSURL URLWithString:trackMetadata[SPTAudioStreamingMetadataAlbumURI]] withSession:self.session callback:^(NSError *error, id object) {
            if (!error) {
                // extract image URL
                NSURL* imageURL = [object largestCover].imageURL;
                
                // download image
                [[[NSURLSession sharedSession] dataTaskWithRequest:[NSURLRequest requestWithURL:imageURL] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    if (!error) {
                        trackInfo[MPMediaItemPropertyArtwork] = [[MPMediaItemArtwork alloc] initWithImage:[UIImage imageWithData:data]];
                    }
                    
                    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:trackInfo];
                }] resume];
            }
        }];
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
    NSURL* loginURL = [[SPTAuth defaultInstance] loginURLForClientId:kSpotifyClientId
                                                 declaredRedirectURL:[NSURL URLWithString:kSpotifyCallbackURL]
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
    self.session = session;
    
    // create new streaming controller and observe track changes
    self.streamingController = [[SPTAudioStreamingController alloc] initWithCompanyName:[NSBundle mainBundle].infoDictionary[(NSString*)kCFBundleIdentifierKey]
                                                                                appName:[NSBundle mainBundle].infoDictionary[(NSString*)kCFBundleNameKey]];
    [self addObserver:self forKeyPath:@"streamingController.currentTrackMetadata" options:0 context:nil];
    
    // create track player and enable playback
    self.trackPlayer = [[SPTTrackPlayer alloc] initWithStreamingController:self.streamingController];
    self.trackPlayer.repeatEnabled = YES;
    [self.trackPlayer enablePlaybackWithSession:session callback:nil];
    
    // start handling remote control events
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
}

@end