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
        SPTSession* session = ((PGAppDelegate*)[UIApplication sharedApplication].delegate).session;
        __weak PGFestifyTrackProvider* trackProvider = ((PGAppDelegate*)[UIApplication sharedApplication].delegate).trackProvider;
        SPTTrackPlayer* trackPlayer = ((PGAppDelegate*)[UIApplication sharedApplication].delegate).trackPlayer;
        
        [trackProvider clearAllTracks];
        [trackProvider addPlaylistsFromUser:session.canonicalUsername session:session completion:^(NSError *error) {
            if (!error) {
                [trackPlayer playTrackProvider:trackProvider];
            }
        }];
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
    SPTSession* session = ((PGAppDelegate*)[UIApplication sharedApplication].delegate).session;
    PGFestifyTrackProvider* trackProvider = ((PGAppDelegate*)[UIApplication sharedApplication].delegate).trackProvider;
    
    // extract spotify username from device property
    NSString* username = [[NSString alloc] initWithData:property encoding:NSUTF8StringEncoding];
    
    // add playlist for discovered user and notify user
    [trackProvider addPlaylistsFromUser:username session:session completion:^(NSError *error) {
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [TSMessage showNotificationInViewController:self.navigationController
                                                      title:[NSString stringWithFormat:@"Discovered %@", devicename]
                                                   subtitle:[NSString stringWithFormat:@"Added tracks for user %@", username]
                                                       type:TSMessageNotificationTypeSuccess];
            });
        }
    }];
}

#pragma mark - PGSettingsViewDelegate

-(void)settingsViewUserDidRequestLogout:(PGSettingsViewController *)settingsView {
    // stop advertisiement and discovery and return to login screen
    [[PGDiscoveryManager sharedInstance] stopDiscovering];
    [[PGDiscoveryManager sharedInstance] stopAdvertisingProperty];
    
    // log out of spotify API
    [(PGAppDelegate*)[UIApplication sharedApplication].delegate logoutOfSpotifyAPI];

    // show login screen
    [self performSegueWithIdentifier:@"showLogin" sender:self];
}

@end