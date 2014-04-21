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

@implementation PGFestifyViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // set delegates
    [PGDiscoveryManager sharedInstance].delegate = self;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // init streaming controller when session valid, or show login screen
    if (!((PGAppDelegate*)[UIApplication sharedApplication].delegate).session) {
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
        [((PGAppDelegate*)[UIApplication sharedApplication].delegate).trackProvider clearAllTracks];
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
        image = [image applyBlurWithRadius:5
                                 tintColor:[UIColor colorWithRed:130.0/255.0 green:130.0/255.0 blue:130.0/255.0 alpha:0.4]
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
        if (!error && [((PGAppDelegate*)[UIApplication sharedApplication].delegate).trackProvider addPlaylist:object forIdentifier:identifier]) {
            // play track provider, if not already playing
            SPTAudioStreamingController* streamingController = ((PGAppDelegate*)[UIApplication sharedApplication].delegate).streamingController;
            SPTTrackPlayer* trackPlayer = ((PGAppDelegate*)[UIApplication sharedApplication].delegate).trackPlayer;
            if (!streamingController.isPlaying) {
                [trackPlayer playTrackProvider:((PGAppDelegate*)[UIApplication sharedApplication].delegate).trackProvider];
            }
            
            // notify user
            self.playButton.enabled = YES;
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
    self.playButton.enabled = NO;
    [(PGAppDelegate*)[UIApplication sharedApplication].delegate logoutOfSpotifyAPI];

    // show login screen
    [self performSegueWithIdentifier:@"showLogin" sender:self];
}

@end