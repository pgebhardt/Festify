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

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

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
            
            // start advertising default playlist
            [[PGDiscoveryManager sharedInstance] startAdvertisingPlaylist:self.playlists.items[0] withSession:self.session];
            
            // update ui
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.playlistPicker reloadAllComponents];
            });
        }
    }];
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
    [[PGDiscoveryManager sharedInstance] stopAdvertisingPlaylists];
    [[PGDiscoveryManager sharedInstance] startAdvertisingPlaylist:self.playlists.items[row] withSession:self.session];
}

@end
