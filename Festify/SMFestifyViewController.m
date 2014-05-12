//
//  PGFestifyViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 16/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "SMFestifyViewController.h"
#import "SMUsersViewController.h"
#import "SMTrackPlayerBarViewController.h"
#import "SMAppDelegate.h"
#import "SMUserDefaults.h"
#import "SMTrackPlayer.h"
#import "MBProgressHUD.h"
#import "MWLogging.h"
#import "BBBadgeBarButtonItem.h"

@interface SMFestifyViewController ()
@property (nonatomic, strong) SPTSession* session;
@property (nonatomic, strong) SMTrackPlayer* trackPlayer;
@property (nonatomic, strong) SMTrackProvider* trackProvider;
@property (nonatomic, strong) NSArray* advertisedPlaylists;
@property (nonatomic, strong) BBBadgeBarButtonItem* usersButton;
@property (nonatomic, strong) SMTrackPlayerBarViewController* trackPlayerBar;
@end

@implementation SMFestifyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [SMDiscoveryManager sharedInstance].delegate = self;
    
    // listen to notifications to update application state correctly
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(discoveryManagerDidUpdateState:) name:SMDiscoveryManagerDidUpdateAdvertisementState object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(discoveryManagerDidUpdateState:) name:SMDiscoveryManagerDidUpdateDiscoveryState object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackProviderDidUpdateTracks:) name:SMTrackProviderDidUpdateTracksArray object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restoreApplicationState) name:SMFestifyViewControllerRestoreApplicationState object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(animateFestifyButton:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    // init properties
    self.trackPlayer = ((SMAppDelegate*)[UIApplication sharedApplication].delegate).trackPlayer;
    self.trackPlayerBar.trackPlayer = self.trackPlayer;
    self.trackProvider = [[SMTrackProvider alloc] init];
    self.trackProvider.delegate = self;
    
    [self initializeUI];
    [self restoreApplicationState];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self animateFestifyButton:self];
}

-(void)initializeUI {
    // create bar button item with badge to indicate newly discovered users
    UIButton* userButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [userButton addTarget:self action:@selector(usersButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [userButton setImage:[UIImage imageNamed:@"Group"] forState:UIControlStateNormal];
    [userButton sizeToFit];
    userButton.tintColor = SMTintColor;
    
    self.usersButton = [[BBBadgeBarButtonItem alloc] initWithCustomUIButton:userButton];
    self.usersButton.badgeOriginX = [userButton imageForState:UIControlStateNormal].size.width / 2.0;
    self.usersButton.enabled = NO;
    
    self.navigationItem.rightBarButtonItem = self.usersButton;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showSettings"]) {
        UINavigationController* navController = (UINavigationController*)segue.destinationViewController;
        SMSettingsViewController* viewController = (SMSettingsViewController*)navController.viewControllers[0];
        
        viewController.session = self.session;
        viewController.trackProvider = self.trackProvider;
        viewController.advertisedPlaylists = self.advertisedPlaylists;
        viewController.delegate = self;
    }
    else if ([segue.identifier isEqualToString:@"showLogin"]) {
        SMLoginViewController* viewController = (SMLoginViewController*)segue.destinationViewController;
        
        viewController.delegate = self;
        viewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    else if ([segue.identifier isEqualToString:@"showUsers"]) {
        UINavigationController* navController = (UINavigationController*)segue.destinationViewController;
        SMUsersViewController* viewController = (SMUsersViewController*)navController.viewControllers[0];
        
        viewController.trackProvider = self.trackProvider;
        self.usersButton.badgeValue = @"";
    }
    else if ([segue.identifier isEqualToString:@"loadPlayerBar"]) {
        self.trackPlayerBar = (SMTrackPlayerBarViewController*)segue.destinationViewController;
    }
}

#pragma  mark - Actions

- (IBAction)festify:(id)sender {
    // only enable festify mode, if user has a premium spotify account
    if (self.trackPlayer.session) {
        // start or stop discovering mode
        if ([SMDiscoveryManager sharedInstance].isDiscovering) {
            [[SMDiscoveryManager sharedInstance] stopDiscovering];
        }
        else {
            [[SMDiscoveryManager sharedInstance] startDiscovering];
        }
    }
    else {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Discovering other users requires a Spotify Premium account."
                                                            message:nil
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (IBAction)spotifyButton:(id)sender {
    NSURL* url = nil;
    if ([SPTAuth defaultInstance].spotifyApplicationIsInstalled) {
        url = [NSURL URLWithString:@"spotify://open"];
    }
    else {
        url = [NSURL URLWithString:@"http://www.spotify.com"];
    }
    
    [[UIApplication sharedApplication] openURL:url];
}

-(void)usersButtonPressed:(id)sender {
    [self performSegueWithIdentifier:@"showUsers" sender:self];
}

-(void)discoveryManagerDidUpdateState:(NSNotification*)notification {
    // add all currently advertised songs, if festify and advertisement modes are active
    if ([SMDiscoveryManager sharedInstance].isDiscovering &&
        [SMDiscoveryManager sharedInstance].isAdvertising) {
        MWLogDebug(@"TODO: replace user name with correct one, this is only for debug");
        [self setPlaylists:self.advertisedPlaylists forUser:@"self" withTimeout:0];
    }
    
    // update UI
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([notification.name isEqualToString:SMDiscoveryManagerDidUpdateDiscoveryState]) {
            [self animateFestifyButton:self];
        }
    });
}

-(void)trackProviderDidUpdateTracks:(id)sender {
    // init track player, if neccessary
    if (!self.trackPlayer.currentProvider &&
        self.trackProvider.tracks.count != 0) {
        [self.trackPlayer playTrackProvider:self.trackProvider];
    }
    else if (self.trackProvider.tracks.count == 0) {
        [self.trackPlayer clear];
        [self dismissViewControllerAnimated:YES completion:nil];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }

    // update UI
    dispatch_async(dispatch_get_main_queue(), ^{
        self.usersButton.enabled = (self.trackProvider.users.count != 0);
        if (self.trackProvider.tracks.count == 0) {
            self.usersButton.badgeValue = @"";
        }
        
        // show or hide track player bar
        [self.view layoutIfNeeded];
        self.trackPlayerBarPosition.constant = self.trackProvider.users.count != 0 ? 0.0 : -44.0;
        [UIView animateWithDuration:0.4 animations:^{
            [self.view layoutIfNeeded];
        }];
    });
}

-(void)animateFestifyButton:(id)notification {
    // animate festify button, to indicate discovering mode
    [self.festifyButtonOverlay.layer removeAllAnimations];
    if ([SMDiscoveryManager sharedInstance].isDiscovering) {
        self.festifyButtonOverlay.transform = CGAffineTransformMakeRotation(0.0);
        [UIView animateWithDuration:0.6 delay:0.0
                            options:UIViewAnimationOptionAutoreverse | UIViewAnimationCurveEaseInOut |
            UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionRepeat
                         animations:^{
                             self.festifyButtonOverlay.transform = CGAffineTransformMakeRotation(-60.0 * M_PI / 180.0);
                         } completion:nil];
    }
    else {
        self.festifyButtonOverlay.transform = [self.festifyButtonOverlay.layer.presentationLayer affineTransform];
        [UIView animateWithDuration:0.6 delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.festifyButtonOverlay.transform = CGAffineTransformMakeRotation(0.0);
                         } completion:nil];
    }
}

#pragma mark - PGDiscoveryManagerDelegate

-(void)discoveryManager:(SMDiscoveryManager *)discoveryManager didDiscoverDevice:(NSString *)devicename withProperty:(NSData *)property {
    // extract spotify username and indicesOfSelectedPlaylists from device property
    NSDictionary* advertisedData = [NSJSONSerialization JSONObjectWithData:property options:0 error:nil];

    [self setPlaylists:advertisedData[@"playlists"] forUser:advertisedData[@"username"] withTimeout:[SMUserDefaults userTimeout]];
}

#pragma mark - SMTrackProviderDelegate

-(void)trackProvider:(SMTrackProvider *)trackProvider willDeleteUser:(NSString *)username {
    // restart discovery manager to rescan for all available devices to possibly prevent
    // track provider from deleting the user
    if ([SMDiscoveryManager sharedInstance].isDiscovering) {
        [[SMDiscoveryManager sharedInstance] startDiscovering];
    }
}

#pragma mark - PGLoginViewDelegate

-(void)loginView:(SMLoginViewController *)loginView didCompleteLoginWithSession:(SPTSession *)session {
    [loginView dismissViewControllerAnimated:YES completion:^{
        // store new session to users defaults and restore application state
        [SMUserDefaults setSession:session];
        [self restoreApplicationState];
    }];
}

#pragma mark - PGSettingsViewDelegate

-(void)settingsViewDidRequestLogout:(SMSettingsViewController *)settingsView {
    [self logoutOfSpotify];
}

-(void)settingsView:(SMSettingsViewController *)settingsView didChangeAdvertisementState:(BOOL)advertising {
    [self setAdvertisementState:advertising];
}

-(void)settingsView:(SMSettingsViewController *)settingsView didChangeAdvertisedPlaylistSelection:(NSArray *)selectedPlaylists {
    self.advertisedPlaylists = selectedPlaylists;
    [SMUserDefaults setAdvertisedPlaylists:self.advertisedPlaylists];

    // reset advertisement state to update advertised playlist selection
    [self setAdvertisementState:[SMDiscoveryManager sharedInstance].isAdvertising];
}

#pragma mark - Helper

-(void)restoreApplicationState {
    [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    
    // load stored session and check, if session is valid with simple API call,
    // otherwise show login screen
    self.session = [SMUserDefaults session];
    [SPTRequest playlistsForUser:self.session.canonicalUsername withSession:self.session callback:^(NSError *error, id object) {
        if (!error) {
            [SMUserDefaults advertisedPlaylists:^(NSArray *advertisedPlaylists) {
                // load remaining user sessings and try to enable playback
                self.advertisedPlaylists = advertisedPlaylists;
                [self setAdvertisementState:[SMUserDefaults advertisementState]];
                
                [self.trackPlayer enablePlaybackWithSession:self.session callback:^(NSError *error) {
                    [MBProgressHUD hideAllHUDsForView:self.navigationController.view animated:YES];
                }];
            }];
        }
        else {
            [MBProgressHUD hideAllHUDsForView:self.navigationController.view animated:YES];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.navigationController popToRootViewControllerAnimated:YES];
                [self logoutOfSpotify];
            });
        }
    }];
}

-(void)logoutOfSpotify {
    // stop advertisiement and discovery and clear all settings
    [[SMDiscoveryManager sharedInstance] stopDiscovering];
    [[SMDiscoveryManager sharedInstance] stopAdvertising];
    [SMUserDefaults clear];
    
    // cleanup Spotify objects
    self.session = nil;
    [self.trackPlayer logout];
    [self.trackProvider clear];
    
    [self performSegueWithIdentifier:@"showLogin" sender:self];
}

-(void)setAdvertisementState:(BOOL)advertising {
    if (advertising && self.advertisedPlaylists && self.session) {
        // create broadcast dictionary with username and all playlists
        NSDictionary* broadcastData = @{@"username": self.session.canonicalUsername,
                                        @"playlists": self.advertisedPlaylists };
        NSData* jsonString = [NSJSONSerialization dataWithJSONObject:broadcastData options:0 error:nil];
        [[SMDiscoveryManager sharedInstance] advertiseProperty:jsonString];
    }
    else if (!advertising) {
        [[SMDiscoveryManager sharedInstance] stopAdvertising];
    }
}

-(void)setPlaylists:(NSArray*)playlistURIs forUser:(NSString*)username withTimeout:(NSInteger)timeout {
    __block NSInteger requestCompletCount = 0;
    __block NSMutableArray* playlists = [NSMutableArray array];
    for (NSString* playlistURI in playlistURIs) {
        [SPTRequest requestItemAtURI:[NSURL URLWithString:playlistURI] withSession:self.session callback:^(NSError *error, id object) {
            requestCompletCount += 1;
            if (!error) {
                [playlists addObject:object];
            }
            
            // when all playlists are requested, add them to track provider
            if (requestCompletCount == playlistURIs.count) {
                // increase badge value, if user is not already known
                if (!self.trackProvider.users[username]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSInteger value = [self.usersButton.badgeValue integerValue] + 1;
                        self.usersButton.badgeValue = [NSString stringWithFormat:@"%ld", (long)value];
                    });
                }
                
                [self.trackProvider setPlaylists:playlists forUser:username withTimeoutInterval:timeout];
            }
        }];
    }
}

@end