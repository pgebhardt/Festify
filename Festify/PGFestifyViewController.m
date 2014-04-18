//
//  PGFestifyViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 16/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "PGFestifyViewController.h"
#import "PGFestifyTrackProvider.h"
#import "PGPlayerViewController.h"
#import "PGAppDelegate.h"
#import "TSMessage.h"
#import <iAd/iAd.h>

@interface PGFestifyViewController ()

@property (nonatomic, strong) SPTTrackPlayer* trackPlayer;
@property (nonatomic, strong) PGFestifyTrackProvider* trackProvider;

@end

@implementation PGFestifyViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // enable banner ads
    self.canDisplayBannerAds = YES;
    
    // set delegates
    [PGDiscoveryManager sharedInstance].delegate = self;

    // check for valid session, or show login screen
    if (!((PGAppDelegate*)[UIApplication sharedApplication].delegate).session) {
        [self performSegueWithIdentifier:@"showLogin" sender:self];
    }
    else {
        [self initSpotify];
    }
}

-(void)initSpotify {
    SPTSession* session = ((PGAppDelegate*)[UIApplication sharedApplication].delegate).session;
    SPTAudioStreamingController* streamingController = ((PGAppDelegate*)[UIApplication sharedApplication].delegate).streamingController;
    
    // create festify track provider
    self.trackProvider = [[PGFestifyTrackProvider alloc] initWithSession:session];
    
    // create new streaming controller and track player
    self.trackPlayer = [[SPTTrackPlayer alloc] initWithStreamingController:streamingController];
    self.trackPlayer.repeatEnabled = YES;
    self.trackPlayer.delegate = self;
    
    // enable playback
    [self.trackPlayer enablePlaybackWithSession:session callback:^(NSError *error) {
        if (error) {
			NSLog(@"*** Enabling playback got error: %@", error);
        }
    }];

}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"streamingController.currentTrackMetadata"]) {
        SPTAudioStreamingController* streamingController = ((PGAppDelegate*)[UIApplication sharedApplication].delegate).streamingController;
    
        // notify user
        [TSMessage showNotificationInViewController:self.navigationController
                                              title:@"Now playing"
                                           subtitle:[NSString stringWithFormat:@"%@ - %@",
                                                     streamingController.currentTrackMetadata[SPTAudioStreamingMetadataArtistName],
                                                     streamingController.currentTrackMetadata[SPTAudioStreamingMetadataTrackName]]
                                               type:TSMessageNotificationTypeMessage];

    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma  mark - Actions

- (IBAction)festify:(id)sender {
    // clear content of track provider
    [self.trackProvider clearAllTracks];
    
    // start discovering playlists
    [[PGDiscoveryManager sharedInstance] startDiscoveringPlaylists];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showTrackPlayer"]) {
        PGPlayerViewController* viewController = (PGPlayerViewController*)segue.destinationViewController;
        
        viewController.session = ((PGAppDelegate*)[UIApplication sharedApplication].delegate).session;
        viewController.streamingController = ((PGAppDelegate*)[UIApplication sharedApplication].delegate).streamingController;
        viewController.trackPlayer = self.trackPlayer;
    }
    else if ([segue.identifier isEqualToString:@"showSettings"]) {
        PGSettingsViewController* viewController = (PGSettingsViewController*)[[segue.destinationViewController viewControllers] objectAtIndex:0];
        
        viewController.session = ((PGAppDelegate*)[UIApplication sharedApplication].delegate).session;
        viewController.delegate = self;
    }
    else if ([segue.identifier isEqualToString:@"showLogin"]) {
        PGLoginViewController* viewController = (PGLoginViewController*)segue.destinationViewController;
        
        viewController.delegate = self;
    }
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"showTrackPlayer"] && self.trackProvider.tracks.count == 0) {
        return NO;
    }
    
    return YES;
}

#pragma mark - PGDiscoveryManagerDelegate

-(void)discoveryManager:(PGDiscoveryManager *)discoveryManager didDiscoverPlaylistWithURI:(NSURL *)uri byIdentifier:(NSString *)identifier {
    // request complete playlist and add it to track provider
    [SPTRequest requestItemAtURI:uri
                     withSession:((PGAppDelegate*)[UIApplication sharedApplication].delegate).session
                        callback:^(NSError *error, id object) {
        if (!error && [self.trackProvider addPlaylist:object forIdentifier:identifier]) {
            // start track player
            if (self.trackPlayer.currentProvider == nil) {
                [self.trackPlayer playTrackProvider:self.trackProvider];
            }
            
            // notify user
            [TSMessage showNotificationInViewController:self.navigationController
                                                  title:[NSString stringWithFormat:@"Added: %@", [object name]]
                                               subtitle:[NSString stringWithFormat:@"Creator: %@", [object creator]]
                                                   type:TSMessageNotificationTypeSuccess];
        }
    }];
}

#pragma mark - PGSettingsViewDelegate

-(void)settingsViewUserDidRequestLogout:(PGSettingsViewController *)settingsView {
    // stop advertisiement and discovery and return to login screen
    [[PGDiscoveryManager sharedInstance] stopDiscoveringPlaylists];
    [[PGDiscoveryManager sharedInstance] stopAdvertisingPlaylist];
    
    // cleanup spotify classes
    [self.trackPlayer pausePlayback];
    self.trackPlayer = nil;
    
    // log out of spotify API
    [(PGAppDelegate*)[UIApplication sharedApplication].delegate logoutOfSpotifyAPI];
    
    // show login screen
    [self performSegueWithIdentifier:@"showLogin" sender:self];
}

#pragma mark -PGLoginViewDelegate

-(void)loginViewDidCompleteLogin:(PGLoginViewController *)loginView {
    // show main screen
    [self dismissViewControllerAnimated:YES completion:nil];
    
    // initialize spotify
    [self initSpotify];
}

#pragma mark - SPTTrackPlayerDelegate

-(void)trackPlayer:(SPTTrackPlayer *)player didDidReceiveMessageForEndUser:(NSString *)message {
    [TSMessage showNotificationInViewController:self.navigationController
                                          title:@"Message by Spotify"
                                       subtitle:message
                                           type:TSMessageNotificationTypeMessage];
}

-(void)trackPlayer:(SPTTrackPlayer *)player didEndPlaybackOfProvider:(id<SPTTrackProvider>)provider withError:(NSError *)error {
    [TSMessage showNotificationInViewController:self.navigationController
                                          title:@"Error"
                                       subtitle:error.userInfo[NSLocalizedDescriptionKey]
                                           type:TSMessageNotificationTypeError];
}

-(void)trackPlayer:(SPTTrackPlayer *)player didEndPlaybackOfProvider:(id<SPTTrackProvider>)provider withReason:(SPTPlaybackEndReason)reason {
    NSLog(@"trackPlayer didEndPlaybackOfProvider withReason: %u", (unsigned)reason);
}

-(void)trackPlayer:(SPTTrackPlayer *)player didEndPlaybackOfTrackAtIndex:(NSInteger)index ofProvider:(id<SPTTrackProvider>)provider {
    NSLog(@"trackPlayer didEndPlaybackOfTrackAtIndex: %ld", (long)index);
}

-(void)trackPlayer:(SPTTrackPlayer *)player didStartPlaybackOfTrackAtIndex:(NSInteger)index ofProvider:(id<SPTTrackProvider>)provider {
    NSLog(@"trackPlayer didStartPlaybackOfTrackAtIndex: %ld", (long)index);
}

@end