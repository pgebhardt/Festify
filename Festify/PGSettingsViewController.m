//
//  PGSettingsViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 15/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "PGSettingsViewController.h"
#import "PGDiscoveryManager.h"
#import "PGAppDelegate.h"
#import <Spotify/Spotify.h>

@interface PGSettingsViewController ()

@property (nonatomic, strong) SPTPlaylistList* playlists;
@property (nonatomic, assign) BOOL playlistPickerIsShowing;

@end

@implementation PGSettingsViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    // initially hide picker
    [self hidePlaylistPicker];
    
    // connect switches to event handler
    [self.advertisementSwitch addTarget:self action:@selector(toggleAdvertisementState) forControlEvents:UIControlEventValueChanged];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // set switches to correct states
    [self.advertisementSwitch setOn:[[PGDiscoveryManager sharedInstance] isAdvertisingsPlaylist]];
    
    [self retrievePlaylists];
}

-(void)retrievePlaylists {
    // get the playlists of the current user
    SPTSession* session = ((PGAppDelegate*)[UIApplication sharedApplication].delegate).session;
    [SPTRequest playlistsForUser:session.canonicalUsername withSession:session callback:^(NSError *error, id object) {
        if (error) {
            NSLog(@"Could not retrieve playlists for user: %@", session.canonicalUsername);
        }
        else {
            self.playlists = object;
            
            // set first playlist as default advertisement playlist
            if ([PGDiscoveryManager sharedInstance].advertisingPlaylist == nil) {
                [[PGDiscoveryManager sharedInstance] setAdvertisingPlaylist:self.playlists.items[0] withSession:session];
            }
            
            // update ui
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.playlistPicker reloadAllComponents];

                // selected currently advertised playlist
                for (int i = 0; i < self.playlists.items.count; ++i) {
                    if ([[self.playlists.items[i] uri].absoluteString isEqualToString:[PGDiscoveryManager sharedInstance].advertisingPlaylist.uri.absoluteString]) {
                        [self.playlistPicker selectRow:i inComponent:0 animated:NO];
                        self.playlistLabel.text = [self.playlists.items[i] name];
                    }
                }
            });
        }
    }];
}

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Switch Actions

-(void)toggleAdvertisementState {
    if (self.advertisementSwitch.isOn) {
        SPTSession* session = ((PGAppDelegate*)[UIApplication sharedApplication].delegate).session;
        [[PGDiscoveryManager sharedInstance] startAdvertisingPlaylistWithSession:session];
    }
    else {
        [[PGDiscoveryManager sharedInstance] stopAdvertisingPlaylist];
    }
}

#pragma mark - UIPickerViewDataSource

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.playlists.items.count;
}

#pragma mark - UIPickerViewDelegate

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [self.playlists.items[row] name];
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    SPTSession* session = ((PGAppDelegate*)[UIApplication sharedApplication].delegate).session;
    [[PGDiscoveryManager sharedInstance] setAdvertisingPlaylist:self.playlists.items[row] withSession:session];
    self.playlistLabel.text = [self.playlists.items[row] name];
}

#pragma mark - UITableViewDelegate

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return [NSString stringWithFormat:@"%@ %@ (%@)",
                [NSBundle mainBundle].infoDictionary[(NSString*)kCFBundleNameKey],
                [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"],
                [NSBundle mainBundle].infoDictionary[(NSString*)kCFBundleVersionKey]];
    }
    else {
        return @"";
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // deselect cell
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // handle actions for specific cell
    NSString* reuseIdentifier = [tableView cellForRowAtIndexPath:indexPath].reuseIdentifier;
    if ([reuseIdentifier isEqualToString:@"playlistCell"]) {
        // show or hide playlist picker
        if (!self.playlistPickerIsShowing) {
            [self showPlaylistPicker];
        }
        else {
            [self hidePlaylistPicker];
        }
    }
    else if ([reuseIdentifier isEqualToString:@"logoutCell"]) {
        // inform delegate to logout and dismiss view controller
        [self dismissViewControllerAnimated:YES completion:^{
            if (self.delegate) {
                [self.delegate settingsViewUserDidRequestLogout:self];
            }
        }];
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 1 && !self.playlistPickerIsShowing) {
        return 0.0f;
    }
    
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

#pragma mark - Helper

-(void)showPlaylistPicker {
    self.playlistPickerIsShowing = YES;
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    
    self.playlistPicker.hidden = NO;
    self.playlistPicker.alpha = 0.0f;
    
    [UIView animateWithDuration:0.25 animations:^{
        self.playlistPicker.alpha = 1.0f;
    }];
}

-(void)hidePlaylistPicker {
    self.playlistPickerIsShowing = NO;
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         self.playlistPicker.alpha = 0.0f;
                     }
                     completion:^(BOOL finished){
                         self.playlistPicker.hidden = YES;
                     }];
}

@end
