//
//  PGFestifyViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 15/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "PGPlayerViewController.h"
#import <iAd/iAd.h>

@interface PGPlayerViewController ()

@end

@implementation PGPlayerViewController

-(void)viewDidLoad {
    [super viewDidLoad];

    // enable iAd
    self.canDisplayBannerAds = YES;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.streamingController.playbackDelegate = self;
    [self updateUI:self.streamingController.currentTrackMetadata];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.streamingController.playbackDelegate = nil;
}

#pragma mark - Actions

-(IBAction)rewind:(id)sender {
    if (self.trackPlayer.currentProvider != nil) {
        [self.trackPlayer skipToPreviousTrack:NO];
    }
}

-(IBAction)playPause:(id)sender {
    if (self.trackPlayer.currentProvider != nil) {
        if (self.streamingController.isPlaying) {
            [self.streamingController setIsPlaying:NO callback:nil];
        }
        else {
            [self.streamingController setIsPlaying:YES callback:nil];
        }
    }
}

-(IBAction)fastForward:(id)sender {
    if (self.trackPlayer.currentProvider != nil) {
        [self.trackPlayer skipToNextTrack];
    }
}

#pragma mark - Logic

-(void)updateUI:(NSDictionary*)trackMetadata {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (trackMetadata) {
            self.titleLabel.text = trackMetadata[SPTAudioStreamingMetadataTrackName];
            self.albumLabel.text = trackMetadata[SPTAudioStreamingMetadataAlbumName];
            self.artistLabel.text = trackMetadata[SPTAudioStreamingMetadataArtistName];
            
            [self loadCoverArtForPartialAlbum:[NSURL URLWithString:trackMetadata[SPTAudioStreamingMetadataAlbumURI]]];
        }
        else {
            self.titleLabel.text = @"Nothing Playing";
            self.albumLabel.text = @"";
            self.artistLabel.text = @"";
            self.coverImage.image = nil;
        }
    });
}

-(void)loadCoverArtForPartialAlbum:(NSURL*)albumURI {
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

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showSettings"]) {
        [segue.destinationViewController setSession:self.session];
    }
}

#pragma mark - SPTAudioStreamingControllerPlaybackDelegate

-(void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangePlaybackStatus:(BOOL)isPlaying {
    NSLog(@"audioStreming didChangePlaybackStatus:%d", isPlaying);
    
    if (!isPlaying) {
        [self updateUI:nil];
    }
}

-(void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangeRepeatStatus:(BOOL)isRepeated {
    NSLog(@"audioStreming didChangeRepeatStatus:%d", isRepeated);
}

-(void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangeShuffleStatus:(BOOL)isShuffled {
    NSLog(@"audioStreming didChangeShuffleStatus:%d", isShuffled);
}

-(void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangeToTrack:(NSDictionary *)trackMetadata {
    NSLog(@"audioStreming didChangeToTrack:%@", trackMetadata);

    [self updateUI:trackMetadata];
}

-(void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangeVolume:(SPVolume)volume {
    NSLog(@"audioStreming didChangeVolume:%f", volume);
}

-(void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didSeekToOffset:(NSTimeInterval)offset {
    NSLog(@"audioStreming didSeekToOffset:%f", offset);
}

-(void)audioStreamingDidBecomeActivePlaybackDevice:(SPTAudioStreamingController *)audioStreaming {
    NSLog(@"audioStremingDidBecomeActivePlaybackDevice");
}

-(void)audioStreamingDidBecomeInactivePlaybackDevice:(SPTAudioStreamingController *)audioStreaming {
    NSLog(@"audioStremingDidBecomeInactivePlaybackDevice");
}

-(void)audioStreamingDidLosePermissionForPlayback:(SPTAudioStreamingController *)audioStreaming {
    NSLog(@"audioStremingDidLosePermissionForPlayback");
}

-(void)audioStreamingDidSkipToPreviousTrack:(SPTAudioStreamingController *)audioStreaming {
    NSLog(@"audioStremingDidSkipToPreviousTrack");
}

-(void)audioStreamingDidSkipToNextTrack:(SPTAudioStreamingController *)audioStreaming {
    NSLog(@"audioStremingDidSkipToNextTrack");
}

@end
