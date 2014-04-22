//
//  PGFestifyViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 16/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "PGFestifyViewController.h"
#import "PGFestifyTrackProvider.h"
#import "PGLoginViewController.h"
#import "PGAppDelegate.h"
#import "TSMessage.h"
#import "MBProgressHUD.h"

@implementation PGFestifyViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // set delegates
    [PGDiscoveryManager sharedInstance].delegate = self;

    // try to login to spotify api
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [((PGAppDelegate*)[UIApplication sharedApplication].delegate) loginToSpotifyAPIWithCompletionHandler:^(NSError *error) {
        // show login screen
        if (error) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:NO];
                [self performSegueWithIdentifier:@"showLogin" sender:self];
            });
        }
        else {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        }
    }];
}

#pragma  mark - Actions

- (IBAction)festify:(id)sender {
    // start discovering playlists
    if (![[PGDiscoveryManager sharedInstance] startDiscoveringPlaylists]) {
        [TSMessage showNotificationInViewController:self.navigationController
                                              title:@"Error"
                                           subtitle:@"Turn On Bluetooth!"
                                               type:TSMessageNotificationTypeError];
    }
    else {
        // clear content of track provider
        [((PGAppDelegate*)[UIApplication sharedApplication].delegate).trackProvider clearAllTracks];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showSettings"]) {
        PGSettingsViewController* viewController = (PGSettingsViewController*)[[segue.destinationViewController viewControllers] objectAtIndex:0];
        viewController.delegate = self;
    }
    else if ([segue.identifier isEqualToString:@"showLogin"]) {
        PGLoginViewController* viewController = (PGLoginViewController*)segue.destinationViewController;
        viewController.underlyingView = self.navigationController.view;
    }
}

#pragma mark - PGDiscoveryManagerDelegate

-(void)discoveryManager:(PGDiscoveryManager *)discoveryManager didDiscoverPlaylistWithURI:(NSURL *)uri devicename:(NSString *)devicename identifier:(NSString *)identifier {
    // request complete playlist and add it to track provider
    [SPTRequest requestItemAtURI:uri
                     withSession:((PGAppDelegate*)[UIApplication sharedApplication].delegate).session
                        callback:^(NSError *error, id object) {
        if (!error && [((PGAppDelegate*)[UIApplication sharedApplication].delegate).trackProvider addPlaylist:object forIdentifier:identifier]) {
            // play track provider, if not already playing
            SPTTrackPlayer* trackPlayer = ((PGAppDelegate*)[UIApplication sharedApplication].delegate).trackPlayer;
            if (!trackPlayer.currentProvider || trackPlayer.paused) {
                [trackPlayer playTrackProvider:((PGAppDelegate*)[UIApplication sharedApplication].delegate).trackProvider];
            }
            
            // notify user
            self.playButton.enabled = YES;
            [TSMessage showNotificationInViewController:self.navigationController
                                                  title:[NSString stringWithFormat:@"Discovered: %@", devicename]
                                               subtitle:[NSString stringWithFormat:@"Added: %@", [object name]]
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
    self.playButton.enabled = NO;
    [(PGAppDelegate*)[UIApplication sharedApplication].delegate logoutOfSpotifyAPI];

    // show login screen
    [self performSegueWithIdentifier:@"showLogin" sender:self];
}

@end