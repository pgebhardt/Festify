//
//  PGFestifyViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 16/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "SMFestifyViewController.h"
#import "SMTrackPlayerBarViewController.h"
#import "SMUsersViewController.h"
#import "SMAppDelegate.h"
#import "SMUserDefaults.h"
#import "SMTrackPlayer.h"
#import "MBProgressHUD.h"
#import "MWLogging.h"

@interface SMFestifyViewController ()
@property (nonatomic, strong) SPTSession* session;
@property (nonatomic, strong) SMTrackPlayer* trackPlayer;
@property (nonatomic, strong) SMTrackProvider* trackProvider;
@property (nonatomic, strong) SMTrackPlayerBarViewController* trackPlayerBar;
@property (nonatomic, strong) NSArray* advertisedPlaylists;
@end

@implementation SMFestifyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [SMDiscoveryManager sharedInstance].delegate = self;
    
    // listen to notifications to update application state correctly
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(discoveryManagerDidUpdateState:) name:SMDiscoveryManagerDidUpdateAdvertisementState object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(discoveryManagerDidUpdateState:) name:SMDiscoveryManagerDidUpdateDiscoveryState object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackProviderDidUpdateTracks:) name:SMTrackProviderDidUpdateTracksArray object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    // init properties
    self.trackPlayer = ((SMAppDelegate*)[UIApplication sharedApplication].delegate).trackPlayer;
    self.trackPlayerBar.trackPlayer = self.trackPlayer;
    self.trackProvider = [[SMTrackProvider alloc] init];
    self.trackProvider.delegate = self;
    
    // initialize users bar button item
    self.usersBarButtonItem = [self.usersBarButtonItem initWithCustomUIButton:self.usersButton];
    self.usersBarButtonItem.badgeOriginX = [self.usersButton imageForState:UIControlStateNormal].size.width / 2.0;
    self.usersBarButtonItem.enabled = NO;

    [self restoreApplicationState];
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
        self.usersBarButtonItem.badgeValue = @"";
    }
    else if ([segue.identifier isEqualToString:@"loadPlayerBar"]) {
        self.trackPlayerBar = (SMTrackPlayerBarViewController*)segue.destinationViewController;
    }
}

#pragma  mark - Actions

- (IBAction)spotifyButton:(id)sender {
    NSURL* url = [NSURL URLWithString:@"http://www.spotify.com"];
    if ([SPTAuth defaultInstance].spotifyApplicationIsInstalled) {
        url = [NSURL URLWithString:@"spotify://open"];
    }
    
    [[UIApplication sharedApplication] openURL:url];
}

#pragma mark - Notification Hanlder

-(void)discoveryManagerDidUpdateState:(id)notification {
    // add all currently advertised songs, if festify and advertisement modes are active
    if ([SMDiscoveryManager sharedInstance].isDiscovering &&
        [SMDiscoveryManager sharedInstance].isAdvertising) {
        MWLogDebug(@"TODO: replace user name with correct one, this is only for debug");
        [self setPlaylists:self.advertisedPlaylists forUser:@"self" withTimeout:0];
    }
}

-(void)trackProviderDidUpdateTracks:(id)notification {
    // init track player, if neccessary, and inform user,
    // when playback cannot be enabled due to its account status,
    // and update UI accordingly
    if (self.trackProvider.tracks.count != 0) {
        if (self.trackPlayer.session) {
            if (!self.trackPlayer.currentProvider) {
                [self.trackPlayer playTrackProvider:self.trackProvider];
            }
        }
        else {
            [[[UIAlertView alloc] initWithTitle:@"Music playback requires a Spotify Premium account!"
                                       message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    }
    else {
        [self.trackPlayer clear];
        [self dismissViewControllerAnimated:YES completion:nil];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }

    // update UI
    dispatch_async(dispatch_get_main_queue(), ^{
        self.usersButton.enabled = (self.trackProvider.users.count != 0);
        if (self.trackProvider.tracks.count == 0) {
            self.usersBarButtonItem.badgeValue = @"";
        }
        
        // show or hide track player bar
        self.trackPlayerBarPosition.constant = self.trackPlayer.currentProvider ? 0.0 : -44.0;
        [UIView animateWithDuration:0.4 animations:^{
            [self.view layoutIfNeeded];
        }];
    });
}

-(void)applicationWillEnterForeground:(id)notification {
    // assume spotify did logout when player is not playing
    if (!self.trackPlayer.playing && self.trackPlayer.session) {
        [self restoreApplicationState];
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
                if ([SMDiscoveryManager sharedInstance].isAdvertising != [SMUserDefaults advertisementState]) {
                    [self setAdvertisementState:[SMUserDefaults advertisementState]];
                }
                
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
    if (advertising) {
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
                        NSInteger value = [self.usersBarButtonItem.badgeValue integerValue] + 1;
                        self.usersBarButtonItem.badgeValue = [NSString stringWithFormat:@"%ld", (long)value];
                    });
                }
                
                [self.trackProvider setPlaylists:playlists forUser:username withTimeoutInterval:timeout];
            }
        }];
    }
}

@end