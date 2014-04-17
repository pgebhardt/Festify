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
#import "PGSettingsViewController.h"
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

    // set as discovery manager delegate
    [PGDiscoveryManager sharedInstance].delegate = self;

    // enable iAd
    self.canDisplayBannerAds = YES;
}

-(void)handleNewSession:(SPTSession *)session {
    self.session = session;
    self.trackProvider = [[PGFestifyTrackProvider alloc] initWithSession:session];
    
    // create new streaming controller and track player
    self.streamingController = [[SPTAudioStreamingController alloc] initWithCompanyName:@"Patrik Gebhardt" appName:@"Festify"];
    self.trackPlayer = [[SPTTrackPlayer alloc] initWithStreamingController:self.streamingController];
    
    // enable playback
    [self.trackPlayer enablePlaybackWithSession:session callback:^(NSError *error) {
        if (error) {
			NSLog(@"*** Enabling playback got error: %@", error);
        }
    }];

}

- (IBAction)festify:(id)sender {
    // clear content of track provider
    [self.trackProvider clearAllTracks];
    
    // stop playback
    [self.trackPlayer pausePlayback];
    
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
    }
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"showTrackPlayer"] && self.trackProvider.tracks.count == 0) {
        return NO;
    }
    
    return YES;
}

#pragma mark - PGDiscoveryManagerDelegate

-(void)discoveryManager:(PGDiscoveryManager *)discoveryManager didDiscoverPlaylistWithURI:(NSURL *)uri fromIdentifier:(NSString *)identifier {
    // request complete playlist and add it to track provider
    [SPTRequest requestItemAtURI:uri withSession:self.session callback:^(NSError *error, id object) {
        if (!error) {
            [self.trackProvider addPlaylist:object forIdentifier:identifier];
            
            // restart track player
            if (self.trackPlayer.currentProvider == nil || self.trackPlayer.paused == YES) {
                [self.trackPlayer playTrackProvider:self.trackProvider];
            }
         }
    }];
}


@end
