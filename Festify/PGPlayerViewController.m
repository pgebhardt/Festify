//
//  PGFestifyViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 15/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "PGPlayerViewController.h"
#import "PGAppDelegate.h"
#import <Spotify/Spotify.h>

@interface PGPlayerViewController ()

@property (nonatomic, weak) SPTSession* session;
@property (nonatomic, weak) SPTAudioStreamingController* streamingController;
@property (nonatomic, weak) SPTTrackPlayer* trackPlayer;

@end

@implementation PGPlayerViewController

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // obtain spotify objects
    self.session = ((PGAppDelegate*)[UIApplication sharedApplication].delegate).session;
    self.streamingController = ((PGAppDelegate*)[UIApplication sharedApplication].delegate).streamingController;
    self.trackPlayer = ((PGAppDelegate*)[UIApplication sharedApplication].delegate).trackPlayer;
    
    // observe playback state change and track change to update UI accordingly
    [self addObserver:self forKeyPath:@"streamingController.currentTrackMetadata" options:0 context:nil];
    [self addObserver:self forKeyPath:@"streamingController.isPlaying" options:0 context:nil];
    [self addObserver:self forKeyPath:@"streamingController.currentPlaybackPosition" options:0 context:nil];

    // initialy setup UI correctly
    [self updateTrackInfo:self.streamingController.currentTrackMetadata];
    [self updatePlayButton:self.streamingController.isPlaying];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self removeObserver:self forKeyPath:@"streamingController.currentTrackMetadata"];
    [self removeObserver:self forKeyPath:@"streamingController.isPlaying"];
    [self removeObserver:self forKeyPath:@"streamingController.currentPlaybackPosition"];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"streamingController.currentTrackMetadata"]) {
        [self updateTrackInfo:self.streamingController.currentTrackMetadata];
    }
    else if ([keyPath isEqualToString:@"streamingController.isPlaying"]) {
        [self updatePlayButton:self.streamingController.isPlaying];
    }
    else if ([keyPath isEqualToString:@"streamingController.currentPlaybackPosition"]) {
        [self updatePlaybackPosition:self.streamingController.currentPlaybackPosition
                         andDuration:[self.streamingController.currentTrackMetadata[SPTAudioStreamingMetadataTrackDuration] doubleValue]];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showPlaylist"]) {
        PGPlaylistViewController* viewController = (PGPlaylistViewController*)segue.destinationViewController;
        
        viewController.delegate = self;
    }
}

#pragma mark - Actions

-(IBAction)rewind:(id)sender {
    if (self.trackPlayer.currentProvider != nil) {
        [self.trackPlayer skipToPreviousTrack:NO];
    }
}

-(IBAction)playPause:(id)sender {
    if (self.trackPlayer.currentProvider != nil) {
        if (self.trackPlayer.paused) {
            [self.trackPlayer resumePlayback];
        }
        else {
            [self.trackPlayer pausePlayback];
        }
    }
}

-(IBAction)fastForward:(id)sender {
    if (self.trackPlayer.currentProvider != nil) {
        [self.trackPlayer skipToNextTrack];
    }
}

#pragma mark - Logic

-(void)updatePlayButton:(BOOL)isPlaying {
    if (isPlaying) {
        self.playPauseButton.imageView.image = [UIImage imageNamed:@"Pause"];
    }
    else {
        self.playPauseButton.imageView.image = [UIImage imageNamed:@"Play"];
    }
}

-(void)updatePlaybackPosition:(NSTimeInterval)playbackPosition andDuration:(NSTimeInterval)duration {
    self.trackPosition.progress = playbackPosition / duration;
    self.currentTimeView.text = [NSString stringWithFormat:@"%d:%02d",
                                 (int)playbackPosition / 60, (int)playbackPosition % 60];
    self.remainingTimeView.text = [NSString stringWithFormat:@"%d:%02d",
                                   (int)(playbackPosition - duration) / 60,
                                   (int)(duration - playbackPosition) % 60];
}

-(void)updateTrackInfo:(NSDictionary*)trackMetadata {
    if (trackMetadata) {
        self.titleLabel.text = trackMetadata[SPTAudioStreamingMetadataTrackName];
        self.artistLabel.text = trackMetadata[SPTAudioStreamingMetadataArtistName];
        
        [self loadAlbumCoverArtWithURL:[NSURL URLWithString:trackMetadata[SPTAudioStreamingMetadataAlbumURI]]];
    }
    else {
        self.titleLabel.text = @"Nothing Playing";
        self.trackPosition.progress = 0.0;
        self.artistLabel.text = @"";
        self.coverImage.image = nil;
    }
}

-(void)loadAlbumCoverArtWithURL:(NSURL*)albumURI {
    // request complete album of track
    [SPTRequest requestItemAtURI:albumURI withSession:self.session callback:^(NSError *error, id object) {
        if (!error) {
            // extract image URL
            NSURL* imageURL = [object largestCover].imageURL;
            
            // download image
            [self.spinner startAnimating];
            [[[NSURLSession sharedSession] dataTaskWithRequest:[NSURLRequest requestWithURL:imageURL] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                // show cover image
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.spinner stopAnimating];
                    self.coverImage.image = [UIImage imageWithData:data];
                });
            }] resume];
        }
    }];
}

#pragma mark - PGPlaylistViewDelegate

-(void)playlistView:(PGPlaylistViewController *)playlistView didSelectTrackWithIndex:(NSUInteger)index {
    [self.trackPlayer playTrackProvider:self.trackPlayer.currentProvider fromIndex:index];
}

@end
