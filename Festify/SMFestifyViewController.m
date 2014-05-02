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
@property (nonatomic, strong) NSError* loginError;
@property (nonatomic, strong) NSMutableArray* indicesOfSelectedPlaylists;
@property (nonatomic, strong) SPTSession* session;
@property (nonatomic, strong) SMTrackPlayer* trackPlayer;
@property (nonatomic, strong) SMTrackProvider* trackProvider;
@end

@implementation SMFestifyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [SMDiscoveryManager sharedInstance].delegate = self;
    
    // obtain track handling objects from app delegate
    SMAppDelegate* appDelegate = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
    self.trackPlayer = appDelegate.trackPlayer;
    self.trackProvider = appDelegate.trackProvider;
    
    // observe currently played track provider, to activate play button
    [self.trackPlayer addObserver:self forKeyPath:@"currentProvider" options:0 context:nil];
    
    // load session from user defaults and try to login, but wait a bit to avoid UI glitches
    appDelegate.session = [SMUserDefaults session];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self loginToSpotifyAPI];
    });
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showSettings"]) {
        SMSettingsViewController* viewController = (SMSettingsViewController*)segue.destinationViewController;
        
        viewController.indicesOfSelectedPlaylists = self.indicesOfSelectedPlaylists;
        viewController.delegate = self;
    }
    else if ([segue.identifier isEqualToString:@"showLogin"]) {
        SMLoginViewController* viewController = (SMLoginViewController*)segue.destinationViewController;
        
        viewController.loginError = self.loginError;
        viewController.underlyingView = self.navigationController.view;
        viewController.delegate = self;
    }
    else if ([segue.identifier isEqualToString:@"showTrackPlayer"]) {
        SMPlayerViewController* viewController = (SMPlayerViewController*)segue.destinationViewController;
        
        viewController.trackPlayer = self.trackPlayer;
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"currentProvider"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.playButton.enabled = (self.trackPlayer.currentProvider != nil);
        });
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
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
        // add own selected songs, if advertising is turned on
        if ([SMDiscoveryManager sharedInstance].isAdvertisingProperty) {
            [self addPlaylistsForUser:self.session.canonicalUsername indicesOfSelectedPlaylists:self.indicesOfSelectedPlaylists callback:^(NSError *error) {
                if (error) {
                    MWLogWarning(@"%@", error);
                }
            }];
        }
    }
}

- (IBAction)spotifyButton:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.spotify.com"]];
}

#pragma mark - PGDiscoveryManagerDelegate

-(void)discoveryManager:(SMDiscoveryManager *)discoveryManager didDiscoverDevice:(NSString *)devicename withProperty:(NSData *)property {
    // extract spotify username and indicesOfSelectedPlaylists from device property
    NSDictionary* advertisedData = [NSJSONSerialization JSONObjectWithData:property options:0 error:nil];
    
    // add playlist for discovered user and notify user
    __weak typeof(self) weakSelf = self;
    [self addPlaylistsForUser:advertisedData[@"username"] indicesOfSelectedPlaylists:advertisedData[@"indicesOfSelectedPlaylists"] callback:^(NSError *error) {
        if (!error) {
            // notify user
            dispatch_async(dispatch_get_main_queue(), ^{
                [TSMessage showNotificationInViewController:weakSelf
                                                      title:[NSString stringWithFormat:@"Discovered %@!", advertisedData[@"username"]]
                                                   subtitle:@"All public songs added!"
                                                       type:TSMessageNotificationTypeSuccess];
            });
        }
        else {
            MWLogWarning(@"%@", error);
        }
    }];
}

#pragma mark - PGLoginViewDelegate

-(void)loginView:(SMLoginViewController *)loginView didCompleteLoginWithError:(NSError *)error {
    // save current error object for possible handling by loginView and try to login to API
    self.loginError = error;
    [self loginToSpotifyAPI];

    // initially fill indicesOfSelectedPlaylists list with all playlists
    if (!error) {
        [SPTRequest playlistsForUser:self.session.canonicalUsername withSession:self.session callback:^(NSError *error, id object) {
            if (!error) {
                self.indicesOfSelectedPlaylists = [NSMutableArray arrayWithCapacity:[object items].count];
                for (NSUInteger i = 0; i < [object items].count; ++i) {
                    self.indicesOfSelectedPlaylists[i] = [NSNumber numberWithInteger:i];
                }
                [SMUserDefaults setIndicesOfSelectedPlaylists:self.indicesOfSelectedPlaylists];
            }
            else {
                MWLogWarning(@"%@", error);
            }
        }];
    }
    else {
        MWLogWarning(@"%@", error);
    }
}

#pragma mark - PGSettingsViewDelegate

-(void)settingsViewDidRequestLogout:(SMSettingsViewController *)settingsView {
    SMAppDelegate* appDelegate = (SMAppDelegate*)[UIApplication sharedApplication].delegate;

    // stop advertisiement and discovery and clear all settings
    [[SMDiscoveryManager sharedInstance] stopDiscovering];
    [[SMDiscoveryManager sharedInstance] stopAdvertisingProperty];
    [SMUserDefaults clear];
    
    // log out of spotify API and show login screen
    [appDelegate logoutOfSpotifyAPI];
    [self performSegueWithIdentifier:@"showLogin" sender:self];
}

-(void)settingsView:(SMSettingsViewController *)settingsView didChangeAdvertisementState:(BOOL)advertising {
    if (![self setAdvertisementState:advertising]) {
        [TSMessage showNotificationInViewController:settingsView
                                              title:@"Error"
                                           subtitle:@"Turn On Bluetooth!"
                                               type:TSMessageNotificationTypeError];
        
        [settingsView.advertisementSwitch setOn:NO animated:YES];
    }
    else if ([SMDiscoveryManager sharedInstance].isDiscovering) {
        // add own selected songs, if discovering is turned on
        [self addPlaylistsForUser:self.session.canonicalUsername indicesOfSelectedPlaylists:self.indicesOfSelectedPlaylists callback:^(NSError *error) {
            if (error) {
                MWLogWarning(@"%@", error);
            }
        }];
    }
}

-(void)settingsView:(SMSettingsViewController *)settingsView didChangeAdvertisedPlaylistSelection:(NSArray *)indicesOfSelectedPlaylists {
    self.indicesOfSelectedPlaylists = [indicesOfSelectedPlaylists mutableCopy];
    [SMUserDefaults setIndicesOfSelectedPlaylists:self.indicesOfSelectedPlaylists];
    
    // restart adverisement
    [self setAdvertisementState:[SMDiscoveryManager sharedInstance].isAdvertisingProperty];
}

-(void)settingsViewDidRequestPlaylistCleanup:(SMSettingsViewController *)settingsView {
    [self.trackPlayer clear];
    [self.trackProvider clearAllTracks];
}

#pragma mark - Helper

-(void)loginToSpotifyAPI {
    [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    
    __weak SMAppDelegate* appDelegate = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
    [appDelegate loginToSpotifyAPIWithCompletionHandler:^(NSError *error) {
        [MBProgressHUD hideAllHUDsForView:self.navigationController.view animated:YES];
        
        if (error) {
            MWLogWarning(@"%@", error);
            [self performSegueWithIdentifier:@"showLogin" sender:self];
        }
        else {
            // save new session
            [SMUserDefaults setSession:appDelegate.session];
            self.session = appDelegate.session;

            // restore saved user settings
            self.indicesOfSelectedPlaylists = [[SMUserDefaults indicesOfSelectedPlaylists] mutableCopy];
            [self setAdvertisementState:[SMUserDefaults advertisementState]];
        }
    }];
}

-(BOOL)setAdvertisementState:(BOOL)advertising {
    BOOL success = YES;
    
    if (advertising) {
        // create dictionary with advertisement data
        NSDictionary* advertisedData = @{
            @"username": ((SMAppDelegate*)[UIApplication sharedApplication].delegate).session.canonicalUsername,
            @"indicesOfSelectedPlaylists": self.indicesOfSelectedPlaylists
            };
        
        // broadcast data
        NSData* jsonString = [NSJSONSerialization dataWithJSONObject:advertisedData options:0 error:nil];
        success = [[SMDiscoveryManager sharedInstance] advertiseProperty:jsonString];
    }
    else {
        [[SMDiscoveryManager sharedInstance] stopAdvertisingProperty];
    }
    
    // store advertisement state
    [SMUserDefaults setAdvertisementState:(advertising && success)];
    
    return success;
}

-(void)addPlaylistsForUser:(NSString*)username indicesOfSelectedPlaylists:(NSArray*)indices callback:(void (^)(NSError* error))callback {
    // download list of playlists from given user and add all selected playlists to track provider
    [SPTRequest playlistsForUser:username withSession:self.session callback:^(NSError *error, id object) {
        if (!error) {
            SPTPlaylistList* playlists = object;
            
            for (NSNumber* playlistIndex in indices) {
                [SPTRequest requestItemFromPartialObject:playlists.items[[playlistIndex integerValue]] withSession:self.session callback:^(NSError *error, id object) {
                    if (!error) {
                        [self.trackProvider addPlaylist:object];
                    }
                    else {
                        MWLogDebug(@"%@", error);
                    }
                    
                    // set track provider, if not already set and provider not empty
                    if (self.trackPlayer.currentProvider == nil &&
                        self.trackProvider.tracks.count != 0 &&
                        [playlistIndex integerValue] == [indices.lastObject integerValue]) {
                        [self.trackPlayer playTrackProvider:self.trackProvider];
                    }
                }];
            }
        }
        
        if (callback) {
            callback(error);
        }
    }];
}

@end