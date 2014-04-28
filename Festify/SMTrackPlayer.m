//
//  SMTrackPlayer.m
//  Festify
//
//  Created by Patrik Gebhardt on 28/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "SMTrackPlayer.h"
#import <MediaPlayer/MediaPlayer.h>

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

-(void)skipForward {
    if (self.currentProvider) {
        [self.trackPlayer skipToNextTrack];
    }
}

-(void)skipBackward {
    if (self.currentProvider) {
        [self.trackPlayer skipToPreviousTrack:NO];
    }
}

#pragma mark - SPTTrackPlayerDelegate

-(void)trackPlayer:(SPTTrackPlayer *)player didStartPlaybackOfTrackAtIndex:(NSInteger)index ofProvider:(id<SPTTrackProvider>)provider {
    // update properties
    self.currentTrack = provider.tracks[index];
    self.indexOfCurrentTrack = index;
    
    // fill track data dictionary
    self.trackInfo[MPMediaItemPropertyTitle] = self.currentTrack.name;
    self.trackInfo[MPMediaItemPropertyAlbumTitle] = self.currentTrack.album.name;
    self.trackInfo[MPMediaItemPropertyArtist] = [self.currentTrack.artists[0] name];
    self.trackInfo[MPMediaItemPropertyPlaybackDuration] = [NSNumber numberWithDouble:self.currentTrack.duration];
    self.trackInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @0.0;
    self.trackInfo[MPNowPlayingInfoPropertyPlaybackRate] = @1.0;
    
    // request complete album of track
    [SPTRequest requestItemAtURI:self.currentTrack.album.uri withSession:self.session callback:^(NSError *error, id object) {
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
}

-(void)trackPlayer:(SPTTrackPlayer *)player didEndPlaybackOfProvider:(id<SPTTrackProvider>)provider withReason:(SPTPlaybackEndReason)reason {
    if (reason == SPTPlaybackEndReasonLoggedOut) {
        // try to login again
        UIBackgroundTaskIdentifier backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
        [player enablePlaybackWithSession:self.session callback:^(NSError *error) {
            // do a little vodoo to get the track player right again
            [player performSelector:NSSelectorFromString(@"setCurrentProvider:") withObject:provider];
            
            NSMethodSignature* signature = [[SPTTrackPlayer class] instanceMethodSignatureForSelector:NSSelectorFromString(@"setIndexOfCurrentTrack:")];
            NSInvocation* invokation = [NSInvocation invocationWithMethodSignature:signature];
            invokation.target = self.trackPlayer;
            invokation.selector = NSSelectorFromString(@"setIndexOfCurrentTrack:");
            [invokation setArgument:&_indexOfCurrentTrack atIndex:2];
            [invokation invoke];
            
            // restore trackPlayer state, when woke up in background
            if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
                [self play];
            }
            
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
        }];
    }
}

-(void)trackPlayer:(SPTTrackPlayer *)player didEndPlaybackOfProvider:(id<SPTTrackProvider>)provider withError:(NSError *)error {
}

-(void)trackPlayer:(SPTTrackPlayer *)player didDidReceiveMessageForEndUser:(NSString *)message {
    NSLog(@"didDidReceiveMessageForEndUser: %@", message);
}

@end
