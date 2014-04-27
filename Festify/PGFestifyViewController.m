//
//  PGFestifyViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 16/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "PGFestifyViewController.h"
#import "PGFestifyTrackProvider.h"
#import "PGAppDelegate.h"
#import "PGUserDefaults.h"
#import "TSMessage.h"
#import "MBProgressHUD.h"
#import "ATConnect.h"

@interface PGFestifyViewController ()

@property (nonatomic, strong) NSError* loginError;

@end

@implementation PGFestifyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // try to login to spotify api
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self loginToSpotifyAPI];
    });
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // apptentive event
    [[ATConnect sharedConnection] engage:@"festifyViewDidAppear" fromViewController:self.navigationController];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showSettings"]) {
        PGSettingsViewController* viewController = (PGSettingsViewController*)segue.destinationViewController;
        
        viewController.delegate = self;
    }
    else if ([segue.identifier isEqualToString:@"showLogin"]) {
        PGLoginViewController* viewController = (PGLoginViewController*)segue.destinationViewController;
        
        viewController.loginError = self.loginError;
        viewController.underlyingView = self.navigationController.view;
        viewController.delegate = self;
    }
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
        [((PGAppDelegate*)[UIApplication sharedApplication].delegate).trackProvider clearAllTracks];
    }
    
    // apptentive event
    [[ATConnect sharedConnection] engage:@"festifyButtonHit" fromViewController:self.navigationController];
}

- (IBAction)spotifyButton:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.spotify.com"]];
}

#pragma mark - PGLoginViewDelegate

-(void)loginView:(PGLoginViewController *)loginView didCompleteLoginWithError:(NSError *)error {
    self.loginError = error;
    [self loginToSpotifyAPI];
}

#pragma mark - PGSettingsViewDelegate

-(void)settingsViewUserDidRequestLogout:(PGSettingsViewController *)settingsView {
    PGAppDelegate* appDelegate = (PGAppDelegate*)[UIApplication sharedApplication].delegate;

    // stop advertisiement and discovery and return to login screen
    [[PGDiscoveryManager sharedInstance] stopDiscovering];
    [[PGDiscoveryManager sharedInstance] stopAdvertisingProperty];
    
    // log out of spotify API
    [appDelegate logoutOfSpotifyAPI];
    
    // apptentive event
    [[ATConnect sharedConnection] engage:@"didLogOut" fromViewController:self.navigationController];
    
    // show login screen
    [self performSegueWithIdentifier:@"showLogin" sender:self];
}

#pragma mark - Helper

-(void)loginToSpotifyAPI {
    [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    
    __weak PGAppDelegate* appDelegate = (PGAppDelegate*)[UIApplication sharedApplication].delegate;
    [appDelegate loginToSpotifyAPIWithCompletionHandler:^(NSError *error) {
        if (error) {
            [self performSegueWithIdentifier:@"showLogin" sender:self];
        }
        else {
            [MBProgressHUD hideAllHUDsForView:self.navigationController.view animated:YES];
            
            // apptentive event
            [[ATConnect sharedConnection] engage:@"didLogIn" fromViewController:self.navigationController];
        }
    }];
}

@end