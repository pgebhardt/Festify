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
#import "TSMessage.h"
#import <iAd/iAd.h>

@interface PGFestifyViewController ()

@property (nonatomic, strong) SPTSession* session;
@property (nonatomic, strong) SPTTrackPlayer* trackPlayer;
@property (nonatomic, strong) SPTAudioStreamingController* streamingController;
@property (nonatomic, strong) PGFestifyTrackProvider* trackProvider;

@end

@implementation PGFestifyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // set delegates
    [PGDiscoveryManager sharedInstance].delegate = self;
    
    // enable banner ads
    self.canDisplayBannerAds = YES;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // observe current track to inform user of track changes
    [self addObserver:self forKeyPath:@"streamingController.currentTrackMetadata" options:0 context:nil];
}

-(void)dealloc {
    // cleanup observer
    [self removeObserver:self forKeyPath:@"streamingController.currentTrackMetadata"];
}

-(void)handleNewSession:(SPTSession *)session {
    self.session = session;
    self.trackProvider = [[PGFestifyTrackProvider alloc] initWithSession:session];
    
    // create new streaming controller and track player
    self.streamingController = [[SPTAudioStreamingController alloc] initWithCompanyName:@"Patrik Gebhardt" appName:@"Festify"];
    self.trackPlayer = [[SPTTrackPlayer alloc] initWithStreamingController:self.streamingController];
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
        // notify user
        [TSMessage showNotificationInViewController:self.navigationController
                                              title:@"Now playing"
                                           subtitle:[NSString stringWithFormat:@"%@ - %@",
                                                     self.streamingController.currentTrackMetadata[SPTAudioStreamingMetadataArtistName],
                                                     self.streamingController.currentTrackMetadata[SPTAudioStreamingMetadataTrackName]]
                                               type:TSMessageNotificationTypeMessage];

    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma  mark - Actions

- (IBAction)festify:(id)sender {
    // stop playback
    if (self.streamingController.isPlaying) {
        [self.trackPlayer pausePlayback];
    }
    
    // clear content of track provider
    [self.trackProvider clearAllTracks];
    
    // start discovering playlists
    [[PGDiscoveryManager sharedInstance] startDiscoveringPlaylists];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showTrackPlayer"]) {
        PGPlayerViewController* viewController = (PGPlayerViewController*)segue.destinationViewController;
        
        viewController.streamingController = self.streamingController;
        viewController.trackPlayer = self.trackPlayer;
        viewController.session = self.session;
    }
    else if ([segue.identifier isEqualToString:@"showSettings"]) {
        PGSettingsViewController* viewController = (PGSettingsViewController*)[[segue.destinationViewController viewControllers] objectAtIndex:0];
        
        viewController.session = self.session;
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
    [SPTRequest requestItemAtURI:uri withSession:self.session callback:^(NSError *error, id object) {
        if (!error && [self.trackProvider addPlaylist:object forIdentifier:identifier]) {
            // restart track player
            if (self.trackPlayer.currentProvider == nil || self.trackPlayer.paused == YES) {
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
    // stop playback, advertisiement and discovery and return to login screen
    [[PGDiscoveryManager sharedInstance] stopDiscoveringPlaylists];
    [[PGDiscoveryManager sharedInstance] stopAdvertisingPlaylist];

    // use a weak copy of self to avoid retain cycles
    __weak typeof(self) weakSelf = self;
    [self.streamingController setIsPlaying:NO callback:^(NSError *error) {
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
    }];
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
