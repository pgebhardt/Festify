//
//  PGFestifyViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 15/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "SMPlayerViewController.h"
#import "SMAppDelegate.h"
#import "SMTrackPlayer.h"
#import <MediaPlayer/MediaPlayer.h>
#import "ATConnect.h"

@interface SMPlayerViewController ()

@property (nonatomic, weak) SMTrackPlayer* trackPlayer;

@end

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
    self.trackPlayer = ((SMAppDelegate*)[UIApplication sharedApplication].delegate).trackPlayer;
    [self.trackPlayer addObserver:self forKeyPath:@"playing" options:0 context:nil];
    [self.trackPlayer addObserver:self forKeyPath:@"currentPlaybackPosition" options:0 context:nil];
    [self.trackPlayer addObserver:self forKeyPath:@"currentTrack" options:0 context:nil];
    if (!self.delegate) {
        [self.trackPlayer addObserver:self forKeyPath:@"coverArtOfCurrentTrack" options:0 context:nil];
    }
    
    // initialy setup UI correctly
    [self updateTrackInfo:self.trackPlayer.currentTrack];
    [self updateCoverArt:self.trackPlayer.coverArtOfCurrentTrack];
    [self updatePlayButton:self.trackPlayer.playing];
    [self updatePlaybackPosition:self.trackPlayer.currentPlaybackPosition
                     andDuration:self.trackPlayer.currentTrack.duration];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // apptentive event
    [[ATConnect sharedConnection] engage:@"playerViewDidAppear" fromViewController:self.navigationController];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // remove observers
    [self.trackPlayer removeObserver:self forKeyPath:@"playing"];
    [self.trackPlayer removeObserver:self forKeyPath:@"currentPlaybackPosition"];
    [self.trackPlayer removeObserver:self forKeyPath:@"currentTrack"];
    if (!self.delegate) {
        [self.trackPlayer removeObserver:self forKeyPath:@"coverArtOfCurrentTrack"];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"coverArtOfCurrentTrack"]) {
        [self updateCoverArt:self.trackPlayer.coverArtOfCurrentTrack];
        
        if (self.delegate) {
            [self.delegate playerViewDidUpdateTrackInfo:self];
        }
    }
    else if ([keyPath isEqualToString:@"currentTrack"]) {
        [self updateTrackInfo:self.trackPlayer.currentTrack];
    }
    else if ([keyPath isEqualToString:@"playing"]) {
        [self updatePlayButton:self.trackPlayer.playing];
    }
    else if ([keyPath isEqualToString:@"currentPlaybackPosition"]) {
        [self updatePlaybackPosition:self.trackPlayer.currentPlaybackPosition
                         andDuration:self.trackPlayer.currentTrack.duration];
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
        NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"spotify://%@",
                                           self.trackPlayer.currentTrack.uri.absoluteString]];
        
        [self.trackPlayer pause];
        [[UIApplication sharedApplication] openURL:url];
    }
}

-(IBAction)rewind:(id)sender {
    [self.trackPlayer skipBackward];
}

-(IBAction)playPause:(id)sender {
    if (self.trackPlayer.playing) {
        [self.trackPlayer pause];
    }
    else {
        [self.trackPlayer play];
    }
}

-(IBAction)fastForward:(id)sender {
    [self.trackPlayer skipForward];
}

#pragma mark - Logic

-(void)updatePlayButton:(BOOL)playing {
    if (playing) {
        [self.playPauseButton setImage:[UIImage imageNamed:@"Pause"] forState:UIControlStateNormal];
    }
    else {
        [self.playPauseButton setImage:[UIImage imageNamed:@"Play"] forState:UIControlStateNormal];
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

-(void)updateTrackInfo:(SPTTrack*)track {
    self.titleLabel.text = track.name;
    self.artistLabel.text = [track.artists[0] name];
}

-(void)updateCoverArt:(UIImage*)coverArt {
    if (coverArt) {
        self.coverImage.image = coverArt;
    }
    else {
        self.coverImage.image = [UIImage imageNamed:@"DefaultCoverArt"];
    }
}

#pragma mark - PGPlaylistViewDelegate

-(void)playlistViewDidEndShowing:(SMPlaylistViewController *)playlistView {
    playlistView.delegate = nil;
    self.delegate = nil;
}

@end