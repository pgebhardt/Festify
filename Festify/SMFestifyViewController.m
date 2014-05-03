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
    
    // init properties
    SMAppDelegate* appDelegate = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
    self.trackPlayer = appDelegate.trackPlayer;
    self.trackProvider = [[SMTrackProvider alloc] init];
    
    // observe currently played track provider, to activate play button
    [self.trackPlayer addObserver:self forKeyPath:@"currentProvider" options:0 context:nil];
    
    // listen to discovery manager notifications to update UI correctly
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFestifyButton:) name:SMDiscoveryManagerDidStartDiscovering object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFestifyButton:) name:SMDiscoveryManagerDidStopDiscovering object:nil];
    
    // load saved user defaults
    self.session = [SMUserDefaults session];
    self.indicesOfSelectedPlaylists = [[SMUserDefaults indicesOfSelectedPlaylists] mutableCopy];
    // restore advertisement state and try to login, but wait a bit to avoid UI and bluetooth glitches
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setAdvertisementState:[SMUserDefaults advertisementState]];
        [self loginToSpotifyAPI];
    });
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showSettings"]) {
        SMSettingsViewController* viewController = (SMSettingsViewController*)segue.destinationViewController;
        
        viewController.session = self.session;
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
    // start or stop discovering mode
    if ([SMDiscoveryManager sharedInstance].isDiscovering) {
        [[SMDiscoveryManager sharedInstance] stopDiscovering];
    }
    else {
        if ([[SMDiscoveryManager sharedInstance] startDiscovering]) {
            // add own selected songs, if advertising is turned on
            if ([SMDiscoveryManager sharedInstance].isAdvertising) {
                [self addPlaylistsForUser:self.session.canonicalUsername indicesOfSelectedPlaylists:self.indicesOfSelectedPlaylists callback:^(NSError *error) {
                    if (error) {
                        MWLogWarning(@"%@", error);
                    }
                }];
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

-(void)loginView:(SMLoginViewController *)loginView didCompleteLoginWithSession:(SPTSession *)session error:(NSError *)error {
    if (!error) {
        // save session object to user defaults
        self.session = session;
        [SMUserDefaults setSession:session];

        // initialize indices list to all playlists are selected
        self.indicesOfSelectedPlaylists = [NSMutableArray array];
        [SPTRequest playlistsForUser:self.session.canonicalUsername withSession:self.session callback:^(NSError *error, id object) {
            if (!error) {
                for (NSUInteger i = 0; i < [object items].count; ++i) {
                    [self.indicesOfSelectedPlaylists addObject:[NSNumber numberWithInteger:i]];
                }
                [SMUserDefaults setIndicesOfSelectedPlaylists:self.indicesOfSelectedPlaylists];
            }
            else {
                MWLogWarning(@"%@", error);
            }
        }];
    }

    // try to login with new session
    self.loginError = error;
    [self loginToSpotifyAPI];
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
    [self.trackProvider clearAllTracks];
    
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
    
    if (advertising && self.indicesOfSelectedPlaylists) {
        // broadcast username and indices of selected playlists
        NSData* jsonString = [NSJSONSerialization dataWithJSONObject:@{@"username": self.session.canonicalUsername,
                                                                       @"indicesOfSelectedPlaylists": self.indicesOfSelectedPlaylists}
                                                             options:0 error:nil];
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