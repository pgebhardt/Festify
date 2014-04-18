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
#import "PGLoginViewController.h"
#import "TSMessage.h"
#import <iAd/iAd.h>

static NSString* const kSessionUserDefaultsKey = @"SpotifySession";

@interface PGFestifyViewController ()

@property (nonatomic, strong) SPTTrackPlayer* trackPlayer;
@property (nonatomic, strong) SPTAudioStreamingController* streamingController;
@property (nonatomic, strong) PGFestifyTrackProvider* trackProvider;
@property (nonatomic, strong) NSError* loginError;

@end

@implementation PGFestifyViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // enable banner ads
    self.canDisplayBannerAds = YES;
    
    // set delegates
    [PGDiscoveryManager sharedInstance].delegate = self;

    // check for valid session, or show login screen
    if (!self.session) {
        [self performSegueWithIdentifier:@"showLogin" sender:self];
    }
}

-(void)dealloc {
    // cleanup observer
    [self removeObserver:self forKeyPath:@"streamingController.currentTrackMetadata"];
}

-(void)handleNewSession:(SPTSession *)session {
    self.session = session;
    
    // create festify track provider
    self.trackProvider = [[PGFestifyTrackProvider alloc] initWithSession:session];
    
    // create new streaming controller and track player
    self.streamingController = [[SPTAudioStreamingController alloc] initWithCompanyName:@"Patrik Gebhardt" appName:@"Festify"];
    self.trackPlayer = [[SPTTrackPlayer alloc] initWithStreamingController:self.streamingController];
    self.trackPlayer.repeatEnabled = YES;
    self.trackPlayer.delegate = self;
    
    // observe current track to inform user of track changes
    [self addObserver:self forKeyPath:@"streamingController.currentTrackMetadata" options:0 context:nil];

    // enable playback
    [self.trackPlayer enablePlaybackWithSession:session callback:^(NSError *error) {
        if (error) {
			NSLog(@"*** Enabling playback got error: %@", error);
        }
    }];

}

-(void)handleLoginError:(NSError *)error {
    // show login screen with error message
    self.loginError = error;
    [self performSegueWithIdentifier:@"showLogin" sender:self];
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
    else if ([segue.identifier isEqualToString:@"showLogin"]) {
        PGLoginViewController* viewController = (PGLoginViewController*)[[segue.destinationViewController viewControllers] objectAtIndex:0];
        
        viewController.error = self.loginError;
        self.loginError = nil;
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
    // stop advertisiement and discovery and return to login screen
    [[PGDiscoveryManager sharedInstance] stopDiscoveringPlaylists];
    [[PGDiscoveryManager sharedInstance] stopAdvertisingPlaylist];
    
    // cleanup spotify classes
    [self.trackPlayer pausePlayback];
    [self removeObserver:self forKeyPath:@"streamingController.currentTrackMetadata"];

    __weak typeof(self) weakSelf = self;
    [self.streamingController setIsPlaying:NO callback:^(NSError *error) {
        weakSelf.trackPlayer = nil;
        weakSelf.streamingController = nil;
        weakSelf.session = nil;
    }];
    
    // clear NSUserDefault session storage
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSessionUserDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // show login screen
    [self performSegueWithIdentifier:@"showLogin" sender:self];
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
