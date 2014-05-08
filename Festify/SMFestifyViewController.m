//
//  PGFestifyViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 16/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "SMFestifyViewController.h"
#import "SMPlayerViewController.h"
#import "SMSettingSelectionViewController.h"
#import "SMAppDelegate.h"
#import "SMUserDefaults.h"
#import "SMTrackPlayer.h"
#import "SMTrackProvider.h"
#import "MBProgressHUD.h"
#import "MWLogging.h"
#import "BBBadgeBarButtonItem.h"

@interface SMFestifyViewController ()
@property (nonatomic, strong) SPTSession* session;
@property (nonatomic, strong) SMTrackPlayer* trackPlayer;
@property (nonatomic, strong) SMTrackProvider* trackProvider;
@property (nonatomic, strong) NSArray* advertisedPlaylists;
@property (nonatomic, strong) NSMutableArray* discoveredUsers;
@property (nonatomic, strong) BBBadgeBarButtonItem* usersButton;
@end

@implementation SMFestifyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [SMDiscoveryManager sharedInstance].delegate = self;
    
    // listen to notifications to update application state correctly
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFestifyButton:) name:SMDiscoveryManagerDidStartDiscovering object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFestifyButton:) name:SMDiscoveryManagerDidStopDiscovering object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTrackPlayer:) name:SMTrackProviderDidAddPlaylist object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTrackPlayer:) name:SMTrackProviderDidClearAllTracks object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restoreApplicationState) name:SMFestifyViewControllerRestoreApplicationState object:nil];

    // init properties
    self.trackPlayer = ((SMAppDelegate*)[UIApplication sharedApplication].delegate).trackPlayer;
    self.trackProvider = [[SMTrackProvider alloc] init];
    self.discoveredUsers = [NSMutableArray array];
    
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

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // show login screen, if no valid session is available
    if (!self.session) {
        [self performSegueWithIdentifier:@"showLogin" sender:self];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showSettings"]) {
        UINavigationController* navController = (UINavigationController*)segue.destinationViewController;
        SMSettingsViewController* viewController = (SMSettingsViewController*)navController.viewControllers[0];
        
        viewController.session = self.session;
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
        SMSettingSelectionViewController* viewController = (SMSettingSelectionViewController*)navController.viewControllers[0];
        
        viewController.data = self.discoveredUsers;
        viewController.selectionAction = ^(id item) { };
        viewController.accessoryAction = ^(id item) {
            if ([SPTAuth defaultInstance].spotifyApplicationIsInstalled) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"spotify://spotify:user:%@", item]]];
            }
        };
        viewController.subtitle = @"All visible playlists of these users are currently include in Festify`s playlist.";
        self.usersButton.badgeValue = @"";
    }
}

#pragma  mark - Actions

- (IBAction)festify:(id)sender {
    // start or stop discovering mode
    if ([SMDiscoveryManager sharedInstance].isDiscovering) {
        [[SMDiscoveryManager sharedInstance] stopDiscovering];
    }
    else {
        if ([[SMDiscoveryManager sharedInstance] startDiscovering]) {
            // add own selected songs, if advertising is turned on
            if ([SMDiscoveryManager sharedInstance].isAdvertising) {
                [self addPlaylistsToTrackProvider:self.advertisedPlaylists];
            }
        }
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

    // update UI
    dispatch_async(dispatch_get_main_queue(), ^{
        self.playButton.enabled = (self.trackPlayer.currentProvider != nil);
    });
}

#pragma mark - PGDiscoveryManagerDelegate

-(void)discoveryManager:(SMDiscoveryManager *)discoveryManager didDiscoverDevice:(NSString *)devicename withProperty:(NSData *)property {
    // extract spotify username and indicesOfSelectedPlaylists from device property
    NSDictionary* advertisedData = [NSJSONSerialization JSONObjectWithData:property options:0 error:nil];
    
    // add playlist for discovered user and notify user
    [self addPlaylistsToTrackProvider:advertisedData[@"playlists"]];
    
    // update discovered user array and show animation indicating new user
    if (![self.discoveredUsers containsObject:advertisedData[@"username"]]) {
        [self.discoveredUsers insertObject:advertisedData[@"username"] atIndex:0];

        dispatch_async(dispatch_get_main_queue(), ^{
            NSInteger value = [self.usersButton.badgeValue integerValue];
            value += 1;
            self.usersButton.badgeValue = [NSString stringWithFormat:@"%ld", (long)value];
            self.usersButton.enabled = YES;
        });
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
    
    [self settingsViewDidRequestReset:settingsView];
    [settingsView dismissViewControllerAnimated:YES completion:nil];
}

-(BOOL)settingsView:(SMSettingsViewController *)settingsView didChangeAdvertisementState:(BOOL)advertising {
    BOOL success = [self setAdvertisementState:advertising];
    
    // add all currently advertised songs, if festify and advertisement modes are active
    if ([SMDiscoveryManager sharedInstance].isDiscovering &&
        [SMDiscoveryManager sharedInstance].isAdvertising) {
        [self addPlaylistsToTrackProvider:self.advertisedPlaylists];
    }
    
    return success;
}

-(void)settingsView:(SMSettingsViewController *)settingsView didChangeAdvertisedPlaylistSelection:(NSArray *)selectedPlaylists {
    self.advertisedPlaylists = selectedPlaylists;
    [SMUserDefaults setAdvertisedPlaylists:self.advertisedPlaylists];
    
    // restart advertisement
    [self setAdvertisementState:[SMDiscoveryManager sharedInstance].isAdvertising];
}

-(void)settingsViewDidRequestReset:(SMSettingsViewController *)settingsView {
    [self.trackPlayer clear];
    [self.trackProvider clearAllTracks];
    [self.discoveredUsers removeAllObjects];
    
    // update UI
    self.usersButton.badgeValue = @"";
    self.usersButton.enabled = NO;
}

#pragma mark - Helper

-(void)restoreApplicationState {
    [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    
    // load stored spotify session and try to enable playback
    self.session = [SMUserDefaults session];
    [self.trackPlayer enablePlaybackWithSession:self.session callback:^(NSError *error) {
        if (!error) {
            // load user settings
            [SMUserDefaults advertisedPlaylists:^(NSArray *advertisedPlaylists) {
                [MBProgressHUD hideAllHUDsForView:self.navigationController.view animated:YES];
                
                self.advertisedPlaylists = advertisedPlaylists;
                [self setAdvertisementState:[SMUserDefaults advertisementState]];
            }];
        }
        else {
            [MBProgressHUD hideAllHUDsForView:self.navigationController.view animated:YES];
            
            // cleanup stored application state and show login screen
            [SMUserDefaults clear];
            [self performSegueWithIdentifier:@"showLogin" sender:self];
        }
    }];
}

-(BOOL)setAdvertisementState:(BOOL)advertising {
    BOOL success = NO;
    
    if (advertising && self.advertisedPlaylists && self.session) {
        // create broadcast dictionary with username and all playlists
        NSDictionary* broadcastData = @{@"username": self.session.canonicalUsername,
                                        @"playlists": self.advertisedPlaylists};
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

-(void)addPlaylistsToTrackProvider:(NSArray*)playlistURIs {
    for (NSString* playlist in playlistURIs) {
        [SPTRequest requestItemAtURI:[NSURL URLWithString:playlist] withSession:self.session callback:^(NSError *error, id object) {
            if (!error) {
                [self.trackProvider addPlaylist:object];
            }
            else {
                MWLogWarning(@"%@", error);
            }
        }];
    }
}

@end