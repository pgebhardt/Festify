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
#import "UIView+ConvertToImage.h"
#import "UIImage+ImageEffects.h"
#import "TSMessage.h"
#import "MBProgressHud.h"

@interface PGFestifyViewController ()

@property (nonatomic, strong) PGFestifyTrackProvider* trackProvider;

@end

@implementation PGFestifyViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // init properties
    self.trackProvider = [[PGFestifyTrackProvider alloc] init];
    
    // set delegates
    [PGDiscoveryManager sharedInstance].delegate = self;
    self.adBanner.delegate = self;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // init streaming controller when session valid, or show login screen
    if (((PGAppDelegate*)[UIApplication sharedApplication].delegate).session) {
        if (!((PGAppDelegate*)[UIApplication sharedApplication].delegate).streamingController) {
            [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
            [(PGAppDelegate*)[UIApplication sharedApplication].delegate initStreamingControllerWithCompletionHandler:^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
                    if (error) {
                        [self performSegueWithIdentifier:@"showLogin" sender:self];
                    }
                });
            }];
        }
    }
    else {
        [self performSegueWithIdentifier:@"showLogin" sender:self];
    }
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
        [self.trackProvider clearAllTracks];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showSettings"]) {
        PGSettingsViewController* viewController = (PGSettingsViewController*)[[segue.destinationViewController viewControllers] objectAtIndex:0];
        
        viewController.delegate = self;
    }
    else if ([segue.identifier isEqualToString:@"showLogin"]) {
        UIView* view = [segue.destinationViewController view];
        
        // create image view containing a blured image of the current view controller.
        // This makes the effect of a transparent playlist view
        UIImage* image = [self.navigationController.view convertToImage];
        image = [image applyBlurWithRadius:20
                                 tintColor:[UIColor colorWithRed:130.0/255.0 green:130.0/255.0 blue:130.0/255.0 alpha:0.7]
                     saturationDeltaFactor:1.3
                                 maskImage:nil];
        
        UIImageView* backgroundView = [[UIImageView alloc] initWithFrame:view.frame];
        backgroundView.image = image;
        
        [view addSubview:backgroundView];
        [view sendSubviewToBack:backgroundView];
    }
}

#pragma mark - PGDiscoveryManagerDelegate

-(void)discoveryManager:(PGDiscoveryManager *)discoveryManager didDiscoverPlaylistWithURI:(NSURL *)uri byIdentifier:(NSString *)identifier {
    // request complete playlist and add it to track provider
    [SPTRequest requestItemAtURI:uri
                     withSession:((PGAppDelegate*)[UIApplication sharedApplication].delegate).session
                        callback:^(NSError *error, id object) {
        if (!error && [self.trackProvider addPlaylist:object forIdentifier:identifier]) {
            // play track provider, if not already playing
            SPTAudioStreamingController* streaminController = ((PGAppDelegate*)[UIApplication sharedApplication].delegate).streamingController;
            SPTTrackPlayer* trackPlayer = ((PGAppDelegate*)[UIApplication sharedApplication].delegate).trackPlayer;
            if (!streaminController.isPlaying) {
                [trackPlayer playTrackProvider:self.trackProvider];
            }
            
            // notify user
            [TSMessage showNotificationInViewController:self.navigationController
                                                  title:@"Playlist discovered!"
                                               subtitle:[object name]
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

#pragma mark - ADBannerViewDelegate

-(void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
    if (error) {
        self.adBanner.hidden = YES;
    }
}

-(void)bannerViewDidLoadAd:(ADBannerView *)banner {
    if (self.adBanner.hidden) {
        self.adBanner.hidden = NO;
    }
}

@end