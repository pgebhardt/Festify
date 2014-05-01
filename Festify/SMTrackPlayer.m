//
//  SMTrackPlayer.m
//  Festify
//
//  Created by Patrik Gebhardt on 28/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "SMTrackPlayer.h"
#import <MediaPlayer/MediaPlayer.h>

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
    [self.trackPlayer enablePlaybackWithSession:session callback:^(NSError *error) {
        if (!error) {
            self.session = session;
        }

        // restore trackPlayer state
        [self.trackPlayer setCurrentProvider:self.currentProvider];
        [self.trackPlayer setIndexOfCurrentTrack:self.indexOfCurrentTrack];
        self.currentTrack = self.currentProvider.tracks[self.indexOfCurrentTrack];
        
        if (block) {
            block(error);
        }
    }];
}

-(void)playTrackProvider:(id<SPTTrackProvider>)provider {
    [self playTrackProvider:provider fromIndex:0];
}

-(void)playTrackProvider:(id<SPTTrackProvider>)provider fromIndex:(NSInteger)index {
    [self.trackPlayer playTrackProvider:provider fromIndex:index];
    [self.trackPlayer pausePlayback];
    
    self.indexOfCurrentTrack = index;
    self.currentProvider = provider;
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

-(void)handleRemoteEvent:(UIEvent *)event {
    void (^handler)(void) = ^{
        // control track player by remote events
        if (event.type == UIEventTypeRemoteControl) {
            if (event.subtype == UIEventSubtypeRemoteControlPlay ||
                event.subtype == UIEventSubtypeRemoteControlPause ||
                event.subtype == UIEventSubtypeRemoteControlTogglePlayPause) {
                if (self.playing) {
                    [self pause];
                }
                else {
                    [self play];
                }
            }
            else if (event.subtype == UIEventSubtypeRemoteControlNextTrack) {
                [self skipForward];
            }
            else if (event.subtype == UIEventSubtypeRemoteControlPreviousTrack) {
                [self skipBackward];
            }
        }
    };
    
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive
        && !self.playing) {
        [self enablePlaybackWithSession:self.session callback:^(NSError *error) {
            handler();
        }];
    }
    else {
        handler();
    }
}

#pragma mark - playback contols

-(void)play {
    if (self.currentProvider) {
        [self.trackPlayer resumePlayback];
        self.playing = YES;

        // update playback position and rate to avoid apple tv and lockscreen glitches
        self.trackInfo[MPNowPlayingInfoPropertyPlaybackRate] = @1.0;
        self.trackInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = [NSNumber numberWithDouble:self.trackPlayer.currentPlaybackPosition];
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:self.trackInfo];
    }
}

-(void)pause {
    if (self.currentProvider) {
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
        [self.trackPlayer playTrackProvider:self.currentProvider fromIndex:index];
        [self play];
    }
}

-(void)skipForward {
    if (self.currentProvider) {
        [self.trackPlayer skipToNextTrack];
        [self play];
    }
}

-(void)skipBackward {
    if (self.currentProvider) {
        [self.trackPlayer skipToPreviousTrack:NO];
        [self play];
    }
}

#pragma mark - SPTTrackPlayerDelegate

-(void)trackPlayer:(SPTTrackPlayer *)player didStartPlaybackOfTrackAtIndex:(NSInteger)index ofProvider:(id<SPTTrackProvider>)provider {
    NSLog(@"trackPlayer:%@ didStartPlaybackOfTrackAtIndex:%ld ofProvider:%@", player, (long)index, provider);

    // update properties
    self.currentTrack = provider.tracks[index];
    self.indexOfCurrentTrack = index;
    
    // update track info dictionary and NowPlayingCenter
    self.trackInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @0.0;
    self.trackInfo[MPNowPlayingInfoPropertyPlaybackRate] = @1.0;
    self.trackInfo[MPMediaItemPropertyTitle] = self.currentTrack.name;
    self.trackInfo[MPMediaItemPropertyAlbumTitle] = self.currentTrack.album.name;
    self.trackInfo[MPMediaItemPropertyArtist] = [self.currentTrack.artists[0] name];
    self.trackInfo[MPMediaItemPropertyPlaybackDuration] = [NSNumber numberWithDouble:self.currentTrack.duration];
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:self.trackInfo];
    
    // request complete album of track
    [SPTRequest requestItemFromPartialObject:self.currentTrack.album withSession:self.session callback:^(NSError *error, id object) {
        // download image
        [[[NSURLSession sharedSession] dataTaskWithRequest:[NSURLRequest requestWithURL:[object largestCover].imageURL]
                                         completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            self.coverArtOfCurrentTrack = [UIImage imageWithData:data];
            
            if (!error) {
                self.trackInfo[MPMediaItemPropertyArtwork] = [[MPMediaItemArtwork alloc] initWithImage:self.coverArtOfCurrentTrack];
                [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:self.trackInfo];
            }
        }] resume];
    }];
}

-(void)trackPlayer:(SPTTrackPlayer *)player didEndPlaybackOfTrackAtIndex:(NSInteger)index ofProvider:(id<SPTTrackProvider>)provider {
    NSLog(@"trackPlayer:%@ didEndPlaybackOfTrackAtIndex:%ld ofProvider:%@", player, (long)index, provider);
}

-(void)trackPlayer:(SPTTrackPlayer *)player didEndPlaybackOfProvider:(id<SPTTrackProvider>)provider withReason:(SPTPlaybackEndReason)reason {
    NSLog(@"trackPlayer:%@ didEndPlaybackOfProvider:%@ withReason:%u", player, provider, (unsigned)reason);
}

-(void)trackPlayer:(SPTTrackPlayer *)player didEndPlaybackOfProvider:(id<SPTTrackProvider>)provider withError:(NSError *)error {
    NSLog(@"trackPlayer:%@ didEndPlaybackOfProvider:%@ withError:%@", player, provider, error);
}

-(void)trackPlayer:(SPTTrackPlayer *)player didDidReceiveMessageForEndUser:(NSString *)message {
    NSLog(@"trackPlayer:%@ didDidReceiveMessageForEndUser: %@", player, message);
}

@end
