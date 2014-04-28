//
//  PGFestifyViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 16/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "SMFestifyViewController.h"
#import "SMFestifyTrackProvider.h"
#import "SMAppDelegate.h"
#import "SMUserDefaults.h"
#import "TSMessage.h"
#import "MBProgressHUD.h"
#import "ATConnect.h"

@interface SMFestifyViewController ()

@property (nonatomic, strong) NSError* loginError;

@end

@implementation SMFestifyViewController

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
        SMSettingsViewController* viewController = (SMSettingsViewController*)segue.destinationViewController;
        
        viewController.delegate = self;
    }
    else if ([segue.identifier isEqualToString:@"showLogin"]) {
        SMLoginViewController* viewController = (SMLoginViewController*)segue.destinationViewController;
        
        viewController.loginError = self.loginError;
        viewController.underlyingView = self.navigationController.view;
        viewController.delegate = self;
    }
}

#pragma  mark - Actions

- (IBAction)festify:(id)sender {
    // start discovering playlists
    if (![[SMDiscoveryManager sharedInstance] startDiscovering]) {
        [TSMessage showNotificationInViewController:self.navigationController
                                              title:@"Error"
                                           subtitle:@"Turn On Bluetooth!"
                                               type:TSMessageNotificationTypeError];
    }
    else {
        [((SMAppDelegate*)[UIApplication sharedApplication].delegate).trackProvider clearAllTracks];
    }
    
    // apptentive event
    [[ATConnect sharedConnection] engage:@"festifyButtonHit" fromViewController:self.navigationController];
}

- (IBAction)spotifyButton:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.spotify.com"]];
}

#pragma mark - PGLoginViewDelegate

-(void)loginView:(SMLoginViewController *)loginView didCompleteLoginWithError:(NSError *)error {
    self.loginError = error;
    [self loginToSpotifyAPI];
}

#pragma mark - PGSettingsViewDelegate

-(void)settingsViewUserDidRequestLogout:(SMSettingsViewController *)settingsView {
    SMAppDelegate* appDelegate = (SMAppDelegate*)[UIApplication sharedApplication].delegate;

    // stop advertisiement and discovery and return to login screen
    [[SMDiscoveryManager sharedInstance] stopDiscovering];
    [[SMDiscoveryManager sharedInstance] stopAdvertisingProperty];
    
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
    
    __weak SMAppDelegate* appDelegate = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
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