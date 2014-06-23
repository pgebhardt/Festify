//
//  SMTrackPlayer.m
//  Festify
//
//  Created by Patrik Gebhardt on 28/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "SMTrackPlayer.h"
#import "MWLogging.h"

// define private api accessors for SPTTrackPlayer to restore its state correctly
@interface SPTTrackPlayer ()

-(void)setCurrentProvider:(id<SPTTrackProvider>)provider;
-(void)setIndexOfCurrentTrack:(NSInteger)index;

@end

@interface SMTrackPlayer ()

@property (nonatomic, strong) id<SPTTrackProvider> currentProvider;
@property (nonatomic, assign) NSInteger indexOfCurrentTrack;
@property (nonatomic, assign) NSTimeInterval currentPlaybackPosition;
@property (nonatomic, assign) BOOL playing;
@property (nonatomic, strong) SPTTrack* currentTrack;
@property (nonatomic, strong) UIImage* coverArtOfCurrentTrack;

@property (nonatomic, strong) SPTTrackPlayer* trackPlayer;
@property (nonatomic, strong) SPTSession* session;
@property (nonatomic, strong) NSMutableDictionary* trackInfo;

@end

@implementation SMTrackPlayer

+(instancetype)trackPlayerWithCompanyName:(NSString *)companyName appName:(NSString *)appName {
    return [[SMTrackPlayer alloc] initWithCompanyName:companyName appName:appName];
}

-(id)initWithCompanyName:(NSString *)companyName appName:(NSString *)appName {
    if (self = [super init]) {
        // init properties
        self.trackPlayer = [[SPTTrackPlayer alloc] initWithCompanyName:companyName appName:appName];
        self.trackPlayer.repeatEnabled = YES;
        self.trackPlayer.delegate = self;
        self.trackInfo = [NSMutableDictionary dictionary];
        
        // observe playback position
        [self.trackPlayer addObserver:self forKeyPath:@"currentPlaybackPosition" options:0 context:nil];
    }
    
    return self;
}

-(void)enablePlaybackWithSession:(SPTSession *)session callback:(SPTErrorableOperationCallback)block {
    if (self.delegate) {
        [self.delegate trackPlayer:self willEnablePlaybackWithSession:session];
    }
    
    [self.trackPlayer enablePlaybackWithSession:session callback:^(NSError *error) {
        // save login session for relogin purpose
        self.session = session;
        
        // restore trackPlayer state
        [self.trackPlayer setCurrentProvider:self.currentProvider];
        [self.trackPlayer setIndexOfCurrentTrack:self.indexOfCurrentTrack];
        
        // call completion block
        if (block) {
            block(error);
        }

        // inform delegate
        if (self.delegate) {
            if (!error) {
                [self.delegate trackPlayer:self didEnablePlaybackWithSession:session];
            }
            else {
                [self.delegate trackPlayer:self couldNotEnablePlaybackWithSession:session error:error];
            }
        }
    }];
}

-(void)playTrackProvider:(id<SPTTrackProvider>)provider {
    [self playTrackProvider:provider fromIndex:0];
}

-(void)playTrackProvider:(id<SPTTrackProvider>)provider fromIndex:(NSInteger)index {
    [self performActionWithConnectivityCheck:^{
        self.indexOfCurrentTrack = index;
        self.currentProvider = provider;
        
        [self.trackPlayer playTrackProvider:provider fromIndex:index];
    }];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"currentPlaybackPosition"]) {
        self.currentPlaybackPosition = self.trackPlayer.currentPlaybackPosition;
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)dealloc {
    // cleanup observers
    [self.trackPlayer removeObserver:self forKeyPath:@"currentPlaybackPosition"];
}

-(void)clear {
    // stop playback and cleanup track provider
    [self pause];
    
    self.currentProvider = nil;
    self.currentTrack = nil;
    self.indexOfCurrentTrack = -1;
    self.currentPlaybackPosition = 0.0;
}

-(void)logout {
    self.session = nil;
    [self clear];
}

#pragma mark - playback contols

-(void)play {
    if (self.currentProvider && !self.playing) {
        [self performActionWithConnectivityCheck:^{
            [self.trackPlayer resumePlayback];
            self.playing = YES;
            
            // update playback position and rate to avoid apple tv and lockscreen glitches
            self.trackInfo[MPNowPlayingInfoPropertyPlaybackRate] = @1.0;
            self.trackInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = [NSNumber numberWithDouble:self.trackPlayer.currentPlaybackPosition];
            [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:self.trackInfo];
        }];
    }
}

-(void)pause {
    if (self.currentProvider && self.playing) {
        [self.trackPlayer pausePlayback];
        self.playing = NO;
        
        // update playback position and rate to avoid apple tv and lockscreen glitches
        self.trackInfo[MPNowPlayingInfoPropertyPlaybackRate] = @0.0;
        self.trackInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = [NSNumber numberWithDouble:self.trackPlayer.currentPlaybackPosition];
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:self.trackInfo];
    }
}

-(void)skipToTrack:(NSInteger)index {
    if (self.currentProvider) {
        [self performActionWithConnectivityCheck:^{
            [self.trackPlayer playTrackProvider:self.currentProvider fromIndex:index];
            [self play];
        }];
    }
}

-(void)skipForward {
    if (self.currentProvider) {
        [self performActionWithConnectivityCheck:^{
            [self.trackPlayer skipToNextTrack];
            [self play];
        }];
    }
}

-(void)skipBackward {
    if (self.currentProvider) {
        [self performActionWithConnectivityCheck:^{
            [self.trackPlayer skipToPreviousTrack:NO];
            [self play];
        }];
    }
}

#pragma mark - SPTTrackPlayerDelegate

-(void)trackPlayer:(SPTTrackPlayer *)player didStartPlaybackOfTrackAtIndex:(NSInteger)index ofProvider:(id<SPTTrackProvider>)provider {
    // update properties
    self.currentTrack = provider.tracksForPlayback[index];
    self.indexOfCurrentTrack = index;
    self.playing = YES;
    
    // update track info dictionary and NowPlayingCenter
    self.trackInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @0.0;
    self.trackInfo[MPNowPlayingInfoPropertyPlaybackRate] = @1.0;
    self.trackInfo[MPMediaItemPropertyTitle] = self.currentTrack.name;
    self.trackInfo[MPMediaItemPropertyAlbumTitle] = self.currentTrack.album.name;
    self.trackInfo[MPMediaItemPropertyArtist] = [self.currentTrack.artists[0] name];
    self.trackInfo[MPMediaItemPropertyPlaybackDuration] = [NSNumber numberWithDouble:self.currentTrack.duration];
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:self.trackInfo];
    
    // download image album cover for current track
    [[[NSURLSession sharedSession] dataTaskWithRequest:[NSURLRequest requestWithURL:self.currentTrack.album.largestCover.imageURL]
                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        self.coverArtOfCurrentTrack = [UIImage imageWithData:data];
        if (!error) {
            self.trackInfo[MPMediaItemPropertyArtwork] = [[MPMediaItemArtwork alloc] initWithImage:self.coverArtOfCurrentTrack];
            [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:self.trackInfo];
        }
        else {
            MWLogWarning(@"%@", error);
        }
    }] resume];
}

-(void)trackPlayer:(SPTTrackPlayer *)player didEndPlaybackOfProvider:(id<SPTTrackProvider>)provider withError:(NSError *)error {
    MWLogWarning(@"%@", error);
}

-(void)trackPlayer:(SPTTrackPlayer *)player didDidReceiveMessageForEndUser:(NSString *)message {
    MWLogDebug(@"%@", message);
}

#pragma mark - Helper

-(void)performActionWithConnectivityCheck:(void (^)(void))action {
    if (action) {
        if (!self.trackPlayer.playbackIsAvailable ||
            ([UIApplication sharedApplication].applicationState != UIApplicationStateActive && !self.playing)) {
            UIBackgroundTaskIdentifier backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
            
            [self enablePlaybackWithSession:self.session callback:^(NSError *error) {
                if (!error) {
                    action();
                }
                else {
                    MWLogError(@"%@", error);
                }
                
                [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
            }];
        }
        else {
            action();
        }
    }
}

@end
