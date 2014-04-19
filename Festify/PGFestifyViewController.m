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

@property (nonatomic, strong) PGFestifyTrackProvider* trackProvider;

@end

@implementation PGFestifyViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // init properties
    self.trackProvider = [[PGFestifyTrackProvider alloc] init];
    
    // enable banner ads
    self.canDisplayBannerAds = YES;
    
    // set delegates
    [PGDiscoveryManager sharedInstance].delegate = self;

    // check for valid session, or show login screen
    if (!((PGAppDelegate*)[UIApplication sharedApplication].delegate).session) {
        [self performSegueWithIdentifier:@"showLogin" sender:self];
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
    if ([segue.identifier isEqualToString:@"showSettings"]) {
        PGSettingsViewController* viewController = (PGSettingsViewController*)[[segue.destinationViewController viewControllers] objectAtIndex:0];
        
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
            // play track provider, if not already playing
            SPTTrackPlayer* trackPlayer = ((PGAppDelegate*)[UIApplication sharedApplication].delegate).trackPlayer;
            if (trackPlayer.currentProvider == nil || trackPlayer.paused) {
                [trackPlayer playTrackProvider:self.trackProvider];
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
    
    // log out of spotify API
    [(PGAppDelegate*)[UIApplication sharedApplication].delegate logoutOfSpotifyAPI];

    // clear track provider
    [self.trackProvider clearAllTracks];
    
    // show login screen
    [self performSegueWithIdentifier:@"showLogin" sender:self];
}

@end