//
//  SMTrackPlayerBarViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 12/05/14.
//  Copyright (c) 2014 SchnuffMade. All rights reserved.
//

#import "SMTrackPlayerBarViewController.h"
#import "SMPlayerViewController.h"

@implementation SMTrackPlayerBarViewController

-(void)setTrackPlayer:(SMTrackPlayer *)trackPlayer {
    // cleanup all observations
    if (trackPlayer) {
        [self.trackPlayer removeObserver:self forKeyPath:@"playing"];
        [self.trackPlayer removeObserver:self forKeyPath:@"currentTrack"];
        [self.trackPlayer removeObserver:self forKeyPath:@"coverArtOfCurrentTrack"];
    }
    
    // set new track player
    _trackPlayer = trackPlayer;
    
    // observe properties of new track player
    if (trackPlayer) {
        // observe playback state change and track change to update UI accordingly
        [self.trackPlayer addObserver:self forKeyPath:@"playing" options:0 context:nil];
        [self.trackPlayer addObserver:self forKeyPath:@"currentTrack" options:0 context:nil];
        [self.trackPlayer addObserver:self forKeyPath:@"coverArtOfCurrentTrack" options:0 context:nil];
        
        // initialy setup UI correctly
        [self updateTrackInfo:self.trackPlayer.currentTrack];
        [self updateCoverArt:self.trackPlayer.coverArtOfCurrentTrack];
        [self updatePlayButton:self.trackPlayer.playing];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"coverArtOfCurrentTrack"]) {
        [self updateCoverArt:self.trackPlayer.coverArtOfCurrentTrack];
    }
    else if ([keyPath isEqualToString:@"currentTrack"]) {
        [self updateTrackInfo:self.trackPlayer.currentTrack];
    }
    else if ([keyPath isEqualToString:@"playing"]) {
        [self updatePlayButton:self.trackPlayer.playing];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showTrackPlayer"]) {
        UINavigationController* navController = (UINavigationController*)segue.destinationViewController;
        ((SMPlayerViewController*)navController.viewControllers[0]).trackPlayer = self.trackPlayer;
    }
}

#pragma mark - Actions

- (IBAction)playButtonPressed:(id)sender {
    if (self.trackPlayer.playing) {
        [self.trackPlayer pause];
    }
    else {
        [self.trackPlayer play];
    }
}

#pragma mark - Logic

-(void)updatePlayButton:(BOOL)playing {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (playing) {
            [self.playButton setImage:[UIImage imageNamed:@"Pause"] forState:UIControlStateNormal];
        }
        else {
            [self.playButton setImage:[UIImage imageNamed:@"Play"] forState:UIControlStateNormal];
        }
    });
}

-(void)updateTrackInfo:(SPTTrack*)track {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.trackLabel.text = track.name;
        self.artistLabel.text = [track.artists[0] name];
    });
}

-(void)updateCoverArt:(UIImage*)coverArt {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (coverArt) {
            self.coverArtImageView.image = coverArt;
        }
        else {
            self.coverArtImageView.image = [UIImage imageNamed:@"DefaultCoverArt"];
        }
    });
}

@end
