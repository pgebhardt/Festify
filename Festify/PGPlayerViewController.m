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
#import <MediaPlayer/MediaPlayer.h>
#import <Social/Social.h>

@implementation PGPlayerViewController

-(void)viewDidLoad {
    [super viewDidLoad];

    // add bar buttons to navigation bar
    UIBarButtonItem* activityButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Upload"]
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(showActivityView:)];
    UIBarButtonItem* playlistButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"List"]
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(showPlaylistView:)];
    
    self.navigationItem.rightBarButtonItems = @[playlistButton, activityButton];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // observe playback state change and track change to update UI accordingly
    PGAppDelegate* appDelegate = (PGAppDelegate*)[UIApplication sharedApplication].delegate;
    [appDelegate addObserver:self forKeyPath:@"trackPlayer.paused" options:0 context:nil];
    [appDelegate addObserver:self forKeyPath:@"trackPlayer.currentPlaybackPosition" options:0 context:nil];
    if (!self.delegate) {
        [appDelegate addObserver:self forKeyPath:@"coverArtOfCurrentTrack" options:0 context:nil];
    }
    
    // initialy setup UI correctly
    [self updateTrackInfo:appDelegate.trackInfoDictionary andCoverArt:appDelegate.coverArtOfCurrentTrack];
    [self updatePlayButton:appDelegate.trackPlayer.paused];
    [self updatePlaybackPosition:appDelegate.trackPlayer.currentPlaybackPosition
                     andDuration:[appDelegate.trackInfoDictionary[MPMediaItemPropertyPlaybackDuration] doubleValue]];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    PGAppDelegate* appDelegate = (PGAppDelegate*)[UIApplication sharedApplication].delegate;
    [appDelegate removeObserver:self forKeyPath:@"trackPlayer.paused"];
    [appDelegate removeObserver:self forKeyPath:@"trackPlayer.currentPlaybackPosition"];
    if (!self.delegate) {
        [appDelegate removeObserver:self forKeyPath:@"coverArtOfCurrentTrack"];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    PGAppDelegate* appDelegate = (PGAppDelegate*)[UIApplication sharedApplication].delegate;
    if ([keyPath isEqualToString:@"coverArtOfCurrentTrack"]) {
        [self updateTrackInfo:appDelegate.trackInfoDictionary andCoverArt:appDelegate.coverArtOfCurrentTrack];
        
        if (self.delegate) {
            [self.delegate playerView:self didUpdateTrackInfo:appDelegate.trackInfoDictionary];
        }
    }
    else if ([keyPath isEqualToString:@"trackPlayer.paused"]) {
        [self updatePlayButton:appDelegate.trackPlayer.paused];
    }
    else if ([keyPath isEqualToString:@"trackPlayer.currentPlaybackPosition"]) {
        [self updatePlaybackPosition:appDelegate.trackPlayer.currentPlaybackPosition
                         andDuration:[appDelegate.trackInfoDictionary[MPMediaItemPropertyPlaybackDuration] doubleValue]];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showPlaylist"]) {
        UINavigationController* navigationController = (UINavigationController*)segue.destinationViewController;
        PGPlaylistViewController* viewController = (PGPlaylistViewController*)navigationController.viewControllers[0];
        
        viewController.underlyingView = self.navigationController.view;
        self.delegate = viewController;
        viewController.delegate = self;
    }
}

#pragma mark - Actions

-(void)showActivityView:(id)sender {
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"%@ - %@", self.artistLabel.text, self.titleLabel.text]
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Compose Tweet", @"Open in Spotify", @"Copy URL", @"Email URL", nil];
    [actionSheet showInView:self.navigationController.view];
}

-(void)showPlaylistView:(id)sender {
    [self performSegueWithIdentifier:@"showPlaylist" sender:self];
}

-(IBAction)rewind:(id)sender {
    PGAppDelegate* appDelegate = (PGAppDelegate*)[UIApplication sharedApplication].delegate;
    [appDelegate.trackPlayer skipToPreviousTrack:NO];
}

-(IBAction)playPause:(id)sender {
    PGAppDelegate* appDelegate = (PGAppDelegate*)[UIApplication sharedApplication].delegate;
    if (appDelegate.trackPlayer.paused) {
        [appDelegate.trackPlayer resumePlayback];
    }
    else {
        [appDelegate.trackPlayer pausePlayback];
    }
}

-(IBAction)fastForward:(id)sender {
    PGAppDelegate* appDelegate = (PGAppDelegate*)[UIApplication sharedApplication].delegate;
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

-(void)playlistViewDidEndShowing:(PGPlaylistViewController *)playlistView {
    playlistView.delegate = nil;
    self.delegate = nil;
}

#pragma mark - UIActionSheetDelegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString* buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    PGAppDelegate* appDelegate = (PGAppDelegate*)[UIApplication sharedApplication].delegate;

    // request complete track object and call correct handler for selected button
    [SPTRequest requestItemAtURI:appDelegate.trackInfoDictionary[@"spotifyURI"] withSession:appDelegate.session callback:^(NSError *error, id object) {
        if (!error) {
            if ([buttonTitle isEqualToString:@"Compose Tweet"]) {
                SLComposeViewController* composer = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
                [composer addURL:[object sharingURL]];
                [self.navigationController presentViewController:composer animated:YES completion:nil];
            }
            else if ([buttonTitle isEqualToString:@"Open in Spotify"]) {
                [appDelegate.trackPlayer pausePlayback];
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"spotify://%@", [object uri].absoluteString]]];
            }
            else if ([buttonTitle isEqualToString:@"Copy URL"]) {
                [[UIPasteboard generalPasteboard] setURL:[object sharingURL]];
            }
            else if ([buttonTitle isEqualToString:@"Email URL"]) {
                MFMailComposeViewController* mailComposer = [[MFMailComposeViewController alloc] init];
                [mailComposer setMessageBody:[object sharingURL].absoluteString isHTML:NO];
                [mailComposer setSubject:[NSString stringWithFormat:@"%@ - %@", self.artistLabel.text, self.titleLabel.text]];
                mailComposer.mailComposeDelegate = self;
                
                [self.navigationController presentViewController:mailComposer animated:YES completion:nil];
            }
        }
    }];
}

#pragma mark - MFMailComposeViewControllerDelegate

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end