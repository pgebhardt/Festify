//
//  PGSettingsViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 15/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "PGSettingsViewController.h"
#import "PGDiscoveryManager.h"

@interface PGSettingsViewController ()

@property (nonatomic, strong) SPTPlaylistList* playlists;

@end

@implementation PGSettingsViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    // connect switches to event handler
    [self.festifySwitch addTarget:self action:@selector(toggleFestifyState) forControlEvents:UIControlEventValueChanged];
    [self.advertisementSwitch addTarget:self action:@selector(toggleAdvertisementState) forControlEvents:UIControlEventValueChanged];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // set switches to correct states
    [self.festifySwitch setOn:[[PGDiscoveryManager sharedInstance] isDiscoveringPlaylists]];
    [self.advertisementSwitch setOn:[[PGDiscoveryManager sharedInstance] isAdvertisingsPlaylist]];
    
    [self retrievePlaylists];
}

-(void)retrievePlaylists {
    // get the playlists of the current user
    [SPTRequest playlistsForUser:self.session.canonicalUsername withSession:self.session callback:^(NSError *error, id object) {
        if (error) {
            NSLog(@"Could not retrieve playlists for user: %@", self.session.canonicalUsername);
        }
        else {
            self.playlists = object;
            
            // update ui
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.playlistPicker reloadAllComponents];
            });
        }
    }];
}

#pragma mark - Switch Actions

-(void)toggleFestifyState {
    if (self.festifySwitch.isOn) {
        [[PGDiscoveryManager sharedInstance] startDiscoveringPlaylists];
    }
    else {
        [[PGDiscoveryManager sharedInstance] stopDiscoveringPlaylists];
    }
}

-(void)toggleAdvertisementState {
    if (self.advertisementSwitch.isOn) {
        [[PGDiscoveryManager sharedInstance] startAdvertisingPlaylist:self.playlists.items[[self.playlistPicker selectedRowInComponent:0]] withSession:self.session];
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
    // advertise newly picked playlist
    if ([[PGDiscoveryManager sharedInstance] isAdvertisingsPlaylist]) {
        [[PGDiscoveryManager sharedInstance] stopAdvertisingPlaylist];
        [[PGDiscoveryManager sharedInstance] startAdvertisingPlaylist:self.playlists.items[row] withSession:self.session];
    }
}

#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end
