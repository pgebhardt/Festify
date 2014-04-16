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
    
    [self updateUI];
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

-(void)updateUI {
	if (self.trackPlayer.indexOfCurrentTrack == NSNotFound) {
		self.titleLabel.text = @"Nothing Playing";
		self.albumLabel.text = @"";
		self.artistLabel.text = @"";
        self.coverImage.image = nil;
	}
    else {
		NSInteger index = self.trackPlayer.indexOfCurrentTrack;
		SPTTrack *track = (SPTTrack*)self.trackPlayer.currentProvider.tracks[index];
		self.titleLabel.text = track.name;
		self.albumLabel.text = track.album.name;
		self.artistLabel.text = [track.artists.firstObject name];
        self.coverImage.image = nil;
        
        [self loadCoverArtForPartialAlbum:track.album];
    }
    
    self.navigationItem.title = [NSString stringWithFormat:@"%ld of %lu", (long)self.trackPlayer.indexOfCurrentTrack + 1, (unsigned long)self.trackPlayer.currentProvider.tracks.count];
}

-(void)loadCoverArtForPartialAlbum:(SPTPartialAlbum*)album {
    // request complete album of track
    [SPTRequest requestItemFromPartialObject:album withSession:self.session callback:^(NSError *error, id object) {
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

#pragma mark - SPTTrackPlayerDelegate

-(void)trackPlayer:(SPTTrackPlayer *)player didDidReceiveMessageForEndUser:(NSString *)message {
    NSLog(@"didDidReceiveMessageForEndUser: %@", message);
}

-(void)trackPlayer:(SPTTrackPlayer *)player didEndPlaybackOfProvider:(id<SPTTrackProvider>)provider withError:(NSError *)error {
    NSLog(@"didEndPlaybackOfProvider: %@ withError: %@", provider, error);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateUI];
    });
}

-(void)trackPlayer:(SPTTrackPlayer *)player didEndPlaybackOfProvider:(id<SPTTrackProvider>)provider withReason:(SPTPlaybackEndReason)reason {
    NSLog(@"didEndPlaybackOfProvider: %@ withReason: %u", provider, reason);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateUI];
    });
}

-(void)trackPlayer:(SPTTrackPlayer *)player didEndPlaybackOfTrackAtIndex:(NSInteger)index ofProvider:(id<SPTTrackProvider>)provider {
    NSLog(@"didEndPlaybackOfTrackAtIndex: %d ofProvider: %@", index, provider);
}

-(void)trackPlayer:(SPTTrackPlayer *)player didStartPlaybackOfTrackAtIndex:(NSInteger)index ofProvider:(id<SPTTrackProvider>)provider {
    NSLog(@"didStartPlaybackOfTrackAtIndex: %d ofProvider: %@", index, provider);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateUI];
    });
}

@end
