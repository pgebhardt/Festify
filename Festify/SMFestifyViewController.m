//
//  PGFestifyViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 16/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "SMFestifyViewController.h"
#import "SMPlayerViewController.h"
#import "SMAppDelegate.h"
#import "SMUserDefaults.h"
#import "SMTrackPlayer.h"
#import "SMTrackProvider.h"
#import "TSMessage.h"
#import "MBProgressHUD.h"
#import "MWLogging.h"

@interface SMFestifyViewController ()
@property (nonatomic, strong) SPTSession* session;
@property (nonatomic, strong) SMTrackPlayer* trackPlayer;
@property (nonatomic, strong) SMTrackProvider* trackProvider;
@property (nonatomic, strong) NSArray* advertisedPlaylists;
@end

@implementation SMFestifyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [SMDiscoveryManager sharedInstance].delegate = self;
    
    // init properties
    SMAppDelegate* appDelegate = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
    self.trackPlayer = appDelegate.trackPlayer;
    self.trackProvider = [[SMTrackProvider alloc] init];
    
    // listen to notifications to update UI correctly
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFestifyButton:) name:SMDiscoveryManagerDidStartDiscovering object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFestifyButton:) name:SMDiscoveryManagerDidStopDiscovering object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTrackPlayer:) name:SMTrackProviderDidAddPlaylist object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTrackPlayer:) name:SMTrackProviderDidClearAllTracks object:nil];
    
    // load saved user defaults, but wait a bit to avoid bluetooth glitches
    self.session = [SMUserDefaults session];
    self.advertisedPlaylists = [SMUserDefaults advertisedPlaylists];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setAdvertisementState:[SMUserDefaults advertisementState]];
    });

    // try to login, if a stored session is available
    if (self.session) {
        [self loginToSpotifyAPI];
    }
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
        SMPlayerViewController* viewController = (SMPlayerViewController*)segue.destinationViewController;
        
        viewController.trackPlayer = self.trackPlayer;
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
        else {
            [TSMessage showNotificationInViewController:self.navigationController
                                                  title:@"Error"
                                               subtitle:@"Turn On Bluetooth!"
                                                   type:TSMessageNotificationTypeError];
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

-(void)updateFestifyButton:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([SMDiscoveryManager sharedInstance].isDiscovering) {
            [self.festifyButton setTitleColor:[UIColor colorWithRed:206.0/255.0 green:0.0 blue:0.0 alpha:1.0]
                                     forState:UIControlStateNormal];
        }
        else {
            [self.festifyButton setTitleColor:[UIColor colorWithRed:132.0/255.0 green:189.0/255.0 blue:0.0 alpha:1.0]
                                     forState:UIControlStateNormal];
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
    
    // notify user
    dispatch_async(dispatch_get_main_queue(), ^{
        [TSMessage showNotificationInViewController:self
                                              title:[NSString stringWithFormat:@"Discovered %@!", advertisedData[@"username"]]
                                           subtitle:@"All public songs added!"
                                               type:TSMessageNotificationTypeSuccess];
    });
}

#pragma mark - PGLoginViewDelegate

-(void)loginView:(SMLoginViewController *)loginView didCompleteLoginWithSession:(SPTSession *)session error:(NSError *)error {
    if (!error) {
        // save session object to user defaults
        self.session = session;
        [SMUserDefaults setSession:session];

        [loginView dismissViewControllerAnimated:YES completion:^{
            [self loginToSpotifyAPI];
        }];
    }
}

#pragma mark - PGSettingsViewDelegate

-(void)settingsViewDidRequestLogout:(SMSettingsViewController *)settingsView {
    // stop advertisiement and discovery and clear all settings
    [[SMDiscoveryManager sharedInstance] stopDiscovering];
    [[SMDiscoveryManager sharedInstance] stopAdvertising];
    [SMUserDefaults clear];
    
    // cleanup Spotify objects
    self.session = nil;
    self.advertisedPlaylists = @[];
    [self.trackPlayer clear];
    [self.trackProvider clearAllTracks];

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

-(void)settingsViewDidRequestPlaylistCleanup:(SMSettingsViewController *)settingsView {
    [self.trackPlayer clear];
    [self.trackProvider clearAllTracks];
}

#pragma mark - Helper

-(void)loginToSpotifyAPI {
    [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    [self.trackPlayer enablePlaybackWithSession:self.session callback:^(NSError *error) {
        [MBProgressHUD hideAllHUDsForView:self.navigationController.view animated:YES];

        if (error) {
            [self performSegueWithIdentifier:@"showLogin" sender:self];
        }
    }];
}

-(BOOL)setAdvertisementState:(BOOL)advertising {
    BOOL success = NO;
    
    if (advertising && self.advertisedPlaylists) {
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