//
//  PGFestifyViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 15/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "PGPlayerViewController.h"

@implementation PGPlayerViewController

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self addObserver:self forKeyPath:@"streamingController.currentTrackMetadata" options:0 context:nil];
    [self updateUI:self.streamingController.currentTrackMetadata];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self removeObserver:self forKeyPath:@"streamingController.currentTrackMetadata"];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"streamingController.currentTrackMetadata"]) {
        [self updateUI:self.streamingController.currentTrackMetadata];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
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
            
            [self loadAlbumCoverArtWithURL:[NSURL URLWithString:trackMetadata[SPTAudioStreamingMetadataAlbumURI]]];
        }
        else {
            self.titleLabel.text = @"Nothing Playing";
            self.albumLabel.text = @"";
            self.artistLabel.text = @"";
            self.coverImage.image = nil;
        }
    });
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

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showSettings"]) {
        [segue.destinationViewController setSession:self.session];
    }
}

@end
