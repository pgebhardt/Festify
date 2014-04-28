//
//  PGFestifyViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 15/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "SMPlayerViewController.h"
#import "SMAppDelegate.h"
#import <Spotify/Spotify.h>
#import <MediaPlayer/MediaPlayer.h>
#import "ATConnect.h"

@implementation SMPlayerViewController

-(void)viewDidLoad {
    [super viewDidLoad];

    // set button with spotify logo as title view
    UIButton* titleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [titleButton setImage:[UIImage imageNamed:@"SpotifyLogoWhite"] forState:UIControlStateNormal];
    [titleButton addTarget:self action:@selector(openInSpotify:) forControlEvents:UIControlEventTouchUpInside];
    [titleButton sizeToFit];
    
    self.navigationItem.titleView = titleButton;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // observe playback state change and track change to update UI accordingly
    SMAppDelegate* appDelegate = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
    [appDelegate addObserver:self forKeyPath:@"trackPlayer.paused" options:0 context:nil];
    [appDelegate addObserver:self forKeyPath:@"trackPlayer.currentPlaybackPosition" options:0 context:nil];
    if (!self.delegate) {
        [appDelegate addObserver:self forKeyPath:@"coverArtOfCurrentTrack" options:0 context:nil];
    }
    
    // initialy setup UI correctly
    [self updateTrackInfo:appDelegate.trackInfo andCoverArt:appDelegate.coverArtOfCurrentTrack];
    [self updatePlayButton:appDelegate.trackPlayer.paused];
    [self updatePlaybackPosition:appDelegate.trackPlayer.currentPlaybackPosition
                     andDuration:[appDelegate.trackInfo[MPMediaItemPropertyPlaybackDuration] doubleValue]];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // apptentive event
    [[ATConnect sharedConnection] engage:@"playerViewDidAppear" fromViewController:self.navigationController];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    SMAppDelegate* appDelegate = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
    [appDelegate removeObserver:self forKeyPath:@"trackPlayer.paused"];
    [appDelegate removeObserver:self forKeyPath:@"trackPlayer.currentPlaybackPosition"];
    if (!self.delegate) {
        [appDelegate removeObserver:self forKeyPath:@"coverArtOfCurrentTrack"];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    SMAppDelegate* appDelegate = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
    if ([keyPath isEqualToString:@"coverArtOfCurrentTrack"]) {
        [self updateTrackInfo:appDelegate.trackInfo andCoverArt:appDelegate.coverArtOfCurrentTrack];
        
        if (self.delegate) {
            [self.delegate playerView:self didUpdateTrackInfo:appDelegate.trackInfo];
        }
    }
    else if ([keyPath isEqualToString:@"trackPlayer.paused"]) {
        [self updatePlayButton:appDelegate.trackPlayer.paused];
    }
    else if ([keyPath isEqualToString:@"trackPlayer.currentPlaybackPosition"]) {
        [self updatePlaybackPosition:appDelegate.trackPlayer.currentPlaybackPosition
                         andDuration:[appDelegate.trackInfo[MPMediaItemPropertyPlaybackDuration] doubleValue]];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showPlaylist"]) {
        UINavigationController* navigationController = (UINavigationController*)segue.destinationViewController;
        SMPlaylistViewController* viewController = (SMPlaylistViewController*)navigationController.viewControllers[0];
        
        viewController.underlyingView = self.navigationController.view;
        self.delegate = viewController;
        viewController.delegate = self;
    }
}

#pragma mark - Actions

-(void)openInSpotify:(id)sender {
    // open currently played track in spotify app, if available
    if ([SPTAuth defaultInstance].spotifyApplicationIsInstalled) {
        SMAppDelegate* appDelegate = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
        NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"spotify://%@",
                                           [appDelegate.trackInfo[@"spotifyURI"] absoluteString]]];
        
        if (!appDelegate.trackPlayer.paused) {
            [appDelegate togglePlaybackState];
        }
        [[UIApplication sharedApplication] openURL:url];
    }
}

-(IBAction)rewind:(id)sender {
    SMAppDelegate* appDelegate = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
    [appDelegate.trackPlayer skipToPreviousTrack:NO];
}

-(IBAction)playPause:(id)sender {
    SMAppDelegate* appDelegate = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
    [appDelegate togglePlaybackState];
}

-(IBAction)fastForward:(id)sender {
    SMAppDelegate* appDelegate = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
    [appDelegate.trackPlayer skipToNextTrack];
}

#pragma mark - Logic

-(void)updatePlayButton:(BOOL)paused {
    if (paused) {
        self.playPauseButton.imageView.image = [UIImage imageNamed:@"Play"];
    }
    else {
        self.playPauseButton.imageView.image = [UIImage imageNamed:@"Pause"];
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

-(void)updateTrackInfo:(NSDictionary*)trackInfoDictionary andCoverArt:(UIImage*)coverArt {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (trackInfoDictionary) {
            self.titleLabel.text = trackInfoDictionary[MPMediaItemPropertyTitle];
            self.trackPosition.progress = 0.0;
            self.artistLabel.text = trackInfoDictionary[MPMediaItemPropertyArtist];
            self.coverImage.image = coverArt;
        }
        else {
            self.titleLabel.text = @"Nothing Playing";
            self.trackPosition.progress = 0.0;
            self.artistLabel.text = @"";
            self.coverImage.image = nil;
        }
    });
}

#pragma mark - PGPlaylistViewDelegate

-(void)playlistViewDidEndShowing:(SMPlaylistViewController *)playlistView {
    playlistView.delegate = nil;
    self.delegate = nil;
}

@end