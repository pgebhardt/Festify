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
    if (![[PGDiscoveryManager sharedInstance] startDiscovering]) {
        [TSMessage showNotificationInViewController:self.navigationController
                                              title:@"Error"
                                           subtitle:@"Turn On Bluetooth!"
                                               type:TSMessageNotificationTypeError];
    }
    else {
        // clear content of track provider and add own playlists
        [((PGAppDelegate*)[UIApplication sharedApplication].delegate).trackProvider clearAllTracks];
        [self addPlaylistsForUser:((PGAppDelegate*)[UIApplication sharedApplication].delegate).session.canonicalUsername];
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

-(void)discoveryManager:(PGDiscoveryManager *)discoveryManager didDiscoverDevice:(NSString *)devicename withProperty:(NSData *)property {
    // extract spotify username from device property
    NSString* username = [[NSString alloc] initWithData:property encoding:NSUTF8StringEncoding];
    
    [self addPlaylistsForUser:username];
}

#pragma mark - PGSettingsViewDelegate

-(void)settingsViewUserDidRequestLogout:(PGSettingsViewController *)settingsView {
    // stop advertisiement and discovery and return to login screen
    [[PGDiscoveryManager sharedInstance] stopDiscovering];
    [[PGDiscoveryManager sharedInstance] stopAdvertisingProperty];
    
    // log out of spotify API
    self.playButton.enabled = NO;
    [(PGAppDelegate*)[UIApplication sharedApplication].delegate logoutOfSpotifyAPI];

    // show login screen
    [self performSegueWithIdentifier:@"showLogin" sender:self];
}

#pragma mark - Helper

-(void)addPlaylistsForUser:(NSString*)username {
    SPTSession* session = ((PGAppDelegate*)[UIApplication sharedApplication].delegate).session;
    SPTTrackPlayer* trackPlayer = ((PGAppDelegate*)[UIApplication sharedApplication].delegate).trackPlayer;
    PGFestifyTrackProvider* trackProvider = ((PGAppDelegate*)[UIApplication sharedApplication].delegate).trackProvider;
    
    // reguest and add all playlists of the given user
    [SPTRequest playlistsForUser:username withSession:session callback:^(NSError *error, id object) {
        if (!error) {
            SPTPlaylistList* playlists = object;
            for (NSUInteger i = 0; i < playlists.items.count; ++i) {
                [SPTRequest requestItemFromPartialObject:playlists.items[i] withSession:session callback:^(NSError *error, id object) {
                    if (!error) {
                        [trackProvider addPlaylist:object];
                    }
                    
                    if (i == playlists.items.count - 1 && trackProvider.tracks.count != 0 &&
                        (trackPlayer.currentProvider == nil || trackPlayer.paused)) {
                        [trackPlayer playTrackProvider:trackProvider];
                    }
                }];
            }
            
            // notify user
            self.playButton.enabled = YES;
            [TSMessage showNotificationInViewController:self.navigationController
                                                  title:@"Tracks added!"
                                               subtitle:[NSString stringWithFormat:@"Username: %@", username]
                                                   type:TSMessageNotificationTypeSuccess];
        }
    }];
}

@end