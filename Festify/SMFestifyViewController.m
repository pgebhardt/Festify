//
//  PGFestifyViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 16/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "Festify-Bridging-Header.h"
#import "Festify-Swift.h"
#import "SMFestifyViewController.h"
#import "SMTrackPlayerBarViewController.h"
#import "SMUsersViewController.h"
#import "SMUserDefaults.h"
#import "MBProgressHUD.h"
#import "MWLogging.h"
#import "SPTRequest+MultipleItems.h"

@interface SMFestifyViewController ()
@property (nonatomic, strong) SPTSession* session;
@property (nonatomic, strong) SMTrackPlayer* trackPlayer;
@property (nonatomic, strong) SMTrackProvider* trackProvider;
@property (nonatomic, strong) SMTrackPlayerBarViewController* trackPlayerBar;
@property (nonatomic, strong) NSArray* advertisedPlaylists;
@property (nonatomic, assign) BOOL updateUsersBadgeValue;
@property (nonatomic, assign) NSInteger usersTimeout;
@property (nonatomic, strong) MBProgressHUD* progressHUD;
@property (nonatomic, strong) NSString* username;
@end

@implementation SMFestifyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [SMDiscoveryManager sharedInstance].delegate = self;
    
    // listen to notifications to update application state correctly
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(discoveryManagerDidUpdateState:) name:SMDiscoveryManagerDidUpdateAdvertisementState object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(discoveryManagerDidUpdateState:) name:SMDiscoveryManagerDidUpdateDiscoveryState object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackProviderDidUpdateTracks:) name:SMTrackProviderDidUpdateTracksArray object:nil];
    
    // init properties
    self.trackPlayer = ((AppDelegate*)[UIApplication sharedApplication].delegate).trackPlayer;
    self.trackPlayerBar.trackPlayer = self.trackPlayer;
    self.trackPlayer.delegate = self;
    
    self.trackProvider = [[SMTrackProvider alloc] init];
    self.trackProvider.delegate = self;
    
    // initialize users bar button item
    self.usersBarButtonItem = [self.usersBarButtonItem initWithCustomUIButton:self.usersButton];
    self.usersBarButtonItem.badgeOriginX = [self.usersButton imageForState:UIControlStateNormal].size.width / 2.0;
    self.usersBarButtonItem.enabled = NO;

    // load spotify session from userdefaults and restore application state,
    // or show login screen if no session is available
    id sessionData = [[NSUserDefaults standardUserDefaults] valueForKey:SMUserDefaultsSpotifySessionKey];
    self.session = sessionData ? [NSKeyedUnarchiver unarchiveObjectWithData:sessionData] : nil;
    if (self.session) {
        void (^initSession)() = ^{
            // try to enable playback
            [self.trackPlayer enablePlaybackWithSession:self.session callback:nil];
            [self getUsernameWithSession:self.session completion:^(NSString *username) {
                self.username = username;
                
                self.advertisedPlaylists = [[NSUserDefaults standardUserDefaults] valueForKey:SMUserDefaultsAdvertisedPlaylistsKey];
                [self setAdvertisementState:[[[NSUserDefaults standardUserDefaults] valueForKey:SMUserDefaultsAdvertisementStateKey] boolValue]];
                self.usersTimeout = [[[NSUserDefaults standardUserDefaults] valueForKey:SMUserDefaultsUserTimeoutKey] integerValue];
            }];
        };
        
        if (self.session.isValid) {
            initSession();
        }
        else {
            [LoginViewController renewSpotifySession:self.session withCompletionHandler:^(SPTSession* session, NSError* error) {
                // store new session to users defaults, initialize user defaults and try to enable playback
                self.session = session;
                [[NSUserDefaults standardUserDefaults] setValue:[NSKeyedArchiver archivedDataWithRootObject:self.session] forKey:SMUserDefaultsSpotifySessionKey];

                initSession();
            }];
        }
    }
    else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:@"showLogin" sender:self];
        });
    }
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // reenable update of users badge value
    self.updateUsersBadgeValue = YES;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showSettings"]) {
        UINavigationController* navController = (UINavigationController*)segue.destinationViewController;
        SMSettingsViewController* viewController = (SMSettingsViewController*)navController.viewControllers[0];
        
        viewController.session = self.session;
        viewController.delegate = self;
    }
    else if ([segue.identifier isEqualToString:@"showLogin"]) {
        LoginViewController* viewController = (LoginViewController*)segue.destinationViewController;
        
        viewController.delegate = self;
        viewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    else if ([segue.identifier isEqualToString:@"showUsers"]) {
        UINavigationController* navController = (UINavigationController*)segue.destinationViewController;
        SMUsersViewController* viewController = (SMUsersViewController*)navController.viewControllers[0];
        
        // navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        viewController.trackProvider = self.trackProvider;
        self.usersBarButtonItem.badgeValue = @"";
        self.updateUsersBadgeValue = NO;
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
        [self setPlaylists:self.advertisedPlaylists forUser:self.username withTimeout:0];
    }
}

-(void)trackProviderDidUpdateTracks:(id)notification {
    // init track player, if neccessary, and inform user,
    // when playback cannot be enabled due to its account status,
    // and update UI accordingly
    if (self.trackProvider.tracksForPlayback.count != 0) {
        if (!self.trackPlayer.currentProvider) {
            [self.trackPlayer playTrackProvider:self.trackProvider];
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
        if (self.trackProvider.tracksForPlayback.count == 0) {
            self.usersBarButtonItem.badgeValue = @"";
        }
        
        // show or hide track player bar
        self.trackPlayerBarPosition.constant = self.trackPlayer.currentProvider ? 0.0 : -44.0;
        [UIView animateWithDuration:0.4 animations:^{
            [self.view layoutIfNeeded];
        }];
    });
}

#pragma mark - PGDiscoveryManagerDelegate

-(void)discoveryManager:(SMDiscoveryManager *)discoveryManager didDiscoverDevice:(NSString *)devicename withProperty:(NSData *)property {
    // extract spotify username and indicesOfSelectedPlaylists from device property
    NSDictionary* advertisedData = [NSJSONSerialization JSONObjectWithData:property options:0 error:nil];
    [self setPlaylists:advertisedData[@"playlists"] forUser:advertisedData[@"username"] withTimeout:self.usersTimeout];
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

-(void)loginViewDidReturnFromExternalSignUp:(LoginViewController *)loginView {
    // hide login view and block UI with progress HUD
    [loginView dismissViewControllerAnimated:NO completion:nil];
    self.progressHUD = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    self.progressHUD.labelText = @"Logging in ...";
}

-(void)loginView:(LoginViewController *)loginView didCompleteLoginWithSession:(SPTSession *)session {
    // store new session to users defaults, initialize user defaults and try to enable playback
    self.session = session;
    [[NSUserDefaults standardUserDefaults] setValue:[NSKeyedArchiver archivedDataWithRootObject:self.session] forKey:SMUserDefaultsSpotifySessionKey];
    [self getUsernameWithSession:self.session completion:^(NSString *username) {
        self.username = username;
        [self initStandardUserDefaults:^{
            [self.trackPlayer enablePlaybackWithSession:session callback:^(NSError *error) {
                if (error) {
                    [[[UIAlertView alloc] initWithTitle:@"Music playback requires a Spotify Premium account!"
                                                message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                }
            }];
        }];
    }];
}

-(void)loginView:(LoginViewController *)loginView didCompleteLoginWithError:(NSError *)error {
    // show error to user, if login failed and return user to login screen
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Login Failed" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        // hide progress HUD and show login view
        [self.progressHUD hide:YES];
        self.progressHUD = nil;
        [self performSegueWithIdentifier:@"showLogin" sender:self];
    }]];
     
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - PGSettingsViewDelegate

-(void)settingsViewDidRequestLogout:(SMSettingsViewController *)settingsView {
    [self logoutOfSpotify];
}

-(void)settingsView:(SMSettingsViewController *)settingsView didChangeAdvertisementState:(BOOL)advertising {
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:advertising] forKey:SMUserDefaultsAdvertisementStateKey];
    [self setAdvertisementState:advertising];
}

-(void)settingsView:(SMSettingsViewController *)settingsView didChangeAdvertisedPlaylistSelection:(NSArray *)selectedPlaylists {
    [[NSUserDefaults standardUserDefaults] setValue:selectedPlaylists forKeyPath:SMUserDefaultsAdvertisedPlaylistsKey];
    self.advertisedPlaylists = selectedPlaylists;

    // reset advertisement state to update advertised playlist selection
    [self setAdvertisementState:[SMDiscoveryManager sharedInstance].isAdvertising];
}

-(void)settingsView:(SMSettingsViewController *)settingsView didChangeUsersTimeout:(NSInteger)usersTimeout {
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInteger:usersTimeout] forKeyPath:SMUserDefaultsUserTimeoutKey];
    self.usersTimeout = usersTimeout;
    
    // update timeout value for all users in track provider
    for (NSString* username in self.trackProvider.users.allKeys) {
        [self.trackProvider updateTimeoutInterval:usersTimeout forUser:username];
    }
}

#pragma mark - SMTrackPlayerDelegate

-(void)trackPlayer:(SMTrackPlayer *)trackPlayer couldNotEnablePlaybackWithSession:(SPTSession *)session error:(NSError *)error {
    // hide progress hud
    [self.progressHUD hide:YES];
    self.progressHUD = nil;
    
    // logout, when error is not related to a missing premium subscription
    if (error.code != 9) {
        [self logoutOfSpotify];
    }
}

-(void)trackPlayer:(SMTrackPlayer *)trackPlayer didEnablePlaybackWithSession:(SPTSession *)session {
    // hide progress hud
    [self.progressHUD hide:YES];
    self.progressHUD = nil;
}

-(void)trackPlayer:(SMTrackPlayer *)trackPlayer willEnablePlaybackWithSession:(SPTSession *)session {
    // show progress hud on top of the window to indicate connection status
    if (!self.progressHUD) {
        UIWindow* window = ((AppDelegate*)[UIApplication sharedApplication].delegate).window;
        self.progressHUD = [MBProgressHUD showHUDAddedTo:window.subviews[0] animated:YES];
        self.progressHUD.labelText = @"Connecting ...";
    }
}

#pragma mark - Helper

-(void)initStandardUserDefaults:(void (^)(void))completion {
    // initialize user defaults to common standard values
    [SPTRequest playlistsForUserInSession:self.session callback:^(NSError *error, id object) {
        self.advertisedPlaylists = [[[object items] valueForKey:@"uri"] valueForKey:@"absoluteString"];
        [[NSUserDefaults standardUserDefaults] setValue:self.advertisedPlaylists forKey:SMUserDefaultsAdvertisedPlaylistsKey];
        
        self.usersTimeout = 120;
        [[NSUserDefaults standardUserDefaults] setValue:@120 forKeyPath:SMUserDefaultsUserTimeoutKey];
        
        [self setAdvertisementState:YES];
        [[NSUserDefaults standardUserDefaults] setValue:@YES forKey:SMUserDefaultsAdvertisementStateKey];
        
        if (completion) {
            completion();
        }
    }];
}

-(void)logoutOfSpotify {
    // stop advertisiement and discovery and clear all settings
    [[SMDiscoveryManager sharedInstance] stopDiscovering];
    [[SMDiscoveryManager sharedInstance] stopAdvertising];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:[NSBundle mainBundle].bundleIdentifier];
    
    // cleanup Spotify objects
    self.session = nil;
    [self.trackPlayer logout];
    [self.trackProvider clear];
    
    [self performSegueWithIdentifier:@"showLogin" sender:self];
}

-(void)setAdvertisementState:(BOOL)advertising {
    if (advertising) {
        // create broadcast dictionary with username and all playlists
        NSDictionary* broadcastData = @{@"username": self.username,
                                        @"playlists": self.advertisedPlaylists };
        NSData* jsonString = [NSJSONSerialization dataWithJSONObject:broadcastData options:0 error:nil];
        [[SMDiscoveryManager sharedInstance] advertiseProperty:jsonString];
    }
    else if (!advertising) {
        [[SMDiscoveryManager sharedInstance] stopAdvertising];
    }
}

-(void)setPlaylists:(NSArray*)playlistURIs forUser:(NSString*)username withTimeout:(NSInteger)timeout {
    // convert url strings to array of NSURL objects
    __block NSMutableArray* URLs = [NSMutableArray array];
    [playlistURIs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [URLs addObject:[NSURL URLWithString:obj]];
    }];
    
    // request all playlists and add them to the track provider
    [SPTRequest requestItemsAtURIs:URLs withSession:self.session callback:^(NSError *error, id object) {
        // increase badge value, if user is not already known
        if (!self.trackProvider.users[username] && self.updateUsersBadgeValue) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSInteger value = [self.usersBarButtonItem.badgeValue integerValue] + 1;
                self.usersBarButtonItem.badgeValue = [NSString stringWithFormat:@"%ld", (long)value];
            });
        }
        
        [self.trackProvider setPlaylists:object forUser:username withTimeoutInterval:timeout session:self.session];
    }];
}

-(void)getUsernameWithSession:(SPTSession*)session completion:(void (^)(NSString* username))completion {
    [SPTRequest userInformationForUserInSession:session callback:^(NSError *error, id object) {
        if (!error && completion) {
            completion([object displayName] ? [object displayName] : [object canonicalUserName]);
        }
    }];
}
@end