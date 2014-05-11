//
//  PGFestifyViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 16/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "SMFestifyViewController.h"
#import "SMPlayerViewController.h"
#import "SMUsersViewController.h"
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
@end

@implementation SMFestifyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [SMDiscoveryManager sharedInstance].delegate = self;
    
    // listen to notifications to update application state correctly
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFestifyButton:) name:SMDiscoveryManagerDidStartDiscovering object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFestifyButton:) name:SMDiscoveryManagerDidStopDiscovering object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTrackPlayer:) name:SMTrackProviderDidUpdateTracksArray object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restoreApplicationState) name:SMFestifyViewControllerRestoreApplicationState object:nil];

    // init properties
    self.trackPlayer = ((SMAppDelegate*)[UIApplication sharedApplication].delegate).trackPlayer;
    self.trackProvider = [[SMTrackProvider alloc] init];
    self.trackProvider.delegate = self;
    
    [self initializeUI];
    [self restoreApplicationState];
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
    
    UIBarButtonItem* settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Cog"]
                                                                       style:UIBarButtonItemStylePlain target:self
                                                                      action:@selector(settingsButtonPressed:)];
    
    self.navigationItem.leftBarButtonItems = @[settingsButton, self.usersButton];
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
    else if ([segue.identifier isEqualToString:@"showTrackPlayer"]) {
        ((SMPlayerViewController*)segue.destinationViewController).trackPlayer = self.trackPlayer;
    }
    else if ([segue.identifier isEqualToString:@"showUsers"]) {
        UINavigationController* navController = (UINavigationController*)segue.destinationViewController;
        SMUsersViewController* viewController = (SMUsersViewController*)navController.viewControllers[0];
        
        viewController.trackProvider = self.trackProvider;
        self.usersButton.badgeValue = @"";
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
            if ([[SMDiscoveryManager sharedInstance] startDiscovering] &&
                [SMDiscoveryManager sharedInstance].isAdvertising) {
                // add own selected songs, if advertising is turned on
                MWLogDebug(@"TODO: replace user name with correct one, this is only for debug");
                [self setPlaylists:self.advertisedPlaylists forUser:@"self" withTimeout:-1];
            }
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

-(void)settingsButtonPressed:(id)sender {
    [self performSegueWithIdentifier:@"showSettings" sender:self];
}

-(void)usersButtonPressed:(id)sender {
    [self performSegueWithIdentifier:@"showUsers" sender:self];
}

-(void)updateFestifyButton:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([SMDiscoveryManager sharedInstance].isDiscovering) {
            [self.festifyButton setTitleColor:SMAlertColor forState:UIControlStateNormal];
        }
        else {
            [self.festifyButton setTitleColor:SMTintColor forState:UIControlStateNormal];
        }
    });
}

-(void)updateTrackPlayer:(id)sender {
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
        self.playButton.enabled = (self.trackProvider.users.count != 0);
        self.usersButton.enabled = (self.trackProvider.users.count != 0);
        if (self.trackProvider.tracks.count == 0) {
            self.usersButton.badgeValue = @"";
        }
    });
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
    // stop advertisiement and discovery and clear all settings
    [[SMDiscoveryManager sharedInstance] stopDiscovering];
    [[SMDiscoveryManager sharedInstance] stopAdvertising];
    [SMUserDefaults clear];
    
    // cleanup Spotify objects
    self.session = nil;
    [self.trackPlayer clear];
    [self.trackProvider clear];
    
    [settingsView dismissViewControllerAnimated:YES completion:^{
        [self performSegueWithIdentifier:@"showLogin" sender:self];
    }];
}

-(BOOL)settingsView:(SMSettingsViewController *)settingsView didChangeAdvertisementState:(BOOL)advertising {
    BOOL success = [self setAdvertisementState:advertising];
    
    // add all currently advertised songs, if festify and advertisement modes are active
    if ([SMDiscoveryManager sharedInstance].isDiscovering &&
        [SMDiscoveryManager sharedInstance].isAdvertising) {
        MWLogDebug(@"TODO: replace user name with correct one, this is only for debug");
        [self setPlaylists:self.advertisedPlaylists forUser:@"self" withTimeout:-1];
    }
    
    return success;
}

-(void)settingsView:(SMSettingsViewController *)settingsView didChangeAdvertisedPlaylistSelection:(NSArray *)selectedPlaylists {
    self.advertisedPlaylists = selectedPlaylists;
    [SMUserDefaults setAdvertisedPlaylists:self.advertisedPlaylists];
    
    // reset user playlists and restart advertisement
    MWLogDebug(@"TODO: replace user name with correct one, this is only for debug");
    if ([self.trackProvider.users.allKeys containsObject:@"self"]) {
        [self setPlaylists:self.advertisedPlaylists forUser:@"self" withTimeout:-1];
    }

    [self setAdvertisementState:[SMDiscoveryManager sharedInstance].isAdvertising];
}

#pragma mark - Helper

-(void)restoreApplicationState {
    [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    
    // load stored session and advertised playlists, and try to enable playback,
    // if possible
    self.session = [SMUserDefaults session];
    [SMUserDefaults advertisedPlaylists:^(NSArray *advertisedPlaylists) {
        if (advertisedPlaylists) {
            self.advertisedPlaylists = advertisedPlaylists;
            
            [self.trackPlayer enablePlaybackWithSession:self.session callback:^(NSError *error) {
                [MBProgressHUD hideAllHUDsForView:self.navigationController.view animated:YES];
            }];
        }
        else {
            [MBProgressHUD hideAllHUDsForView:self.navigationController.view animated:YES];
            
            // cleanup stored application state and show login screen
            [SMUserDefaults clear];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self performSegueWithIdentifier:@"showLogin" sender:self];
            });
        }
    }];
}

-(BOOL)setAdvertisementState:(BOOL)advertising {
    BOOL success = NO;
    
    if (advertising && self.advertisedPlaylists && self.session) {
        // create broadcast dictionary with username and all playlists
        NSDictionary* broadcastData = @{@"username": self.session.canonicalUsername,
                                        @"playlists": self.advertisedPlaylists };
        NSData* jsonString = [NSJSONSerialization dataWithJSONObject:broadcastData options:0 error:nil];
        success = [[SMDiscoveryManager sharedInstance] advertiseProperty:jsonString];
    }
    else if (!advertising) {
        [[SMDiscoveryManager sharedInstance] stopAdvertising];
        success = YES;
    }
    
    // store advertisement state
    [SMUserDefaults setAdvertisementState:[SMDiscoveryManager sharedInstance].isAdvertising];
    
    return success;
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