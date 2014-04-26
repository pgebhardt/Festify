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

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // check if playback is available and adjust play button accordingly
    PGAppDelegate* appDelegate = (PGAppDelegate*)[UIApplication sharedApplication].delegate;
    [appDelegate addObserver:self forKeyPath:@"trackPlayer.currentProvider" options:0 context:nil];
    self.playButton.enabled = appDelegate.trackPlayer.currentProvider != nil;
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // remove all observations
    PGAppDelegate* appDelegate = (PGAppDelegate*)[UIApplication sharedApplication].delegate;
    [appDelegate removeObserver:self forKeyPath:@"trackPlayer.currentProvider"];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    PGAppDelegate* appDelegate = (PGAppDelegate*)[UIApplication sharedApplication].delegate;
    if ([keyPath isEqualToString:@"trackPlayer.currentProvider"]) {
        self.playButton.enabled = appDelegate.trackPlayer.currentProvider != nil;
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
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
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showSettings"]) {
        PGSettingsViewController* viewController = (PGSettingsViewController*)[[segue.destinationViewController viewControllers] objectAtIndex:0];
        viewController.delegate = self;
    }
    else if ([segue.identifier isEqualToString:@"showLogin"]) {
        PGLoginViewController* viewController = (PGLoginViewController*)segue.destinationViewController;

        viewController.loginError = self.loginError;
        viewController.underlyingView = self.navigationController.view;
        viewController.delegate = self;
    }
}

#pragma mark - PGLoginViewDelegate

-(void)loginView:(PGLoginViewController *)loginView didCompleteLoginWithError:(NSError *)error {
    self.loginError = error;
    [self loginToSpotifyAPI];
}

#pragma mark - PGSettingsViewDelegate

-(void)settingsViewUserDidRequestLogout:(PGSettingsViewController *)settingsView {
    PGAppDelegate* appDelegate = (PGAppDelegate*)[UIApplication sharedApplication].delegate;
    
    // cleanup UI
    self.playButton.enabled = NO;
    
    // clear delegations
    appDelegate.trackProvider.delegate = nil;
    
    // stop advertisiement and discovery and return to login screen
    [[PGDiscoveryManager sharedInstance] stopDiscovering];
    [[PGDiscoveryManager sharedInstance] stopAdvertisingProperty];
    
    // log out of spotify API
    [appDelegate logoutOfSpotifyAPI];

    // show login screen
    [self performSegueWithIdentifier:@"showLogin" sender:self];
}

#pragma mark - PGFestifyTrackProviderDelegate

-(void)trackProvider:(PGFestifyTrackProvider *)trackProvider didAddPlaylistsFromUser:(NSString *)username withError:(NSError *)error {
    if (!error) {
        SPTTrackPlayer* trackPlayer = ((PGAppDelegate*)[UIApplication sharedApplication].delegate).trackPlayer;
        
        // start playback, if not allready playing
        if (trackPlayer.currentProvider == nil || trackPlayer.paused) {
            [trackPlayer playTrackProvider:trackProvider];
        }
        
        // notify user about success
        dispatch_async(dispatch_get_main_queue(), ^{
            [TSMessage showNotificationInViewController:self.navigationController
                                                  title:[NSString stringWithFormat:@"Discovered %@", username]
                                               subtitle:@"All public songs added!"
                                                   type:TSMessageNotificationTypeSuccess];
        });
    }
}

-(void)trackProviderDidClearAllTracks:(PGFestifyTrackProvider *)trackProvider {
    // add all songs from the current user to track provider
    if ([[PGUserDefaults valueForKey:PGUserDefaultsIncludeOwnSongsKey] boolValue]) {
        SPTSession* session = ((PGAppDelegate*)[UIApplication sharedApplication].delegate).session;
        [trackProvider addPlaylistsFromUser:session.canonicalUsername session:session];
     };
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

            appDelegate.trackProvider.delegate = self;
        }
    }];
}

@end