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
#import "TSMessage.h"

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

                // set advertised playlist to user defaults
                NSInteger indexOfAdvertisedPlaylist = [[[NSUserDefaults standardUserDefaults] valueForKey:@"indexOfAdvertisedPlaylist"] integerValue];
                [self.playlistPicker selectRow:indexOfAdvertisedPlaylist inComponent:0 animated:NO];
                self.playlistLabel.text = [self.playlists.items[indexOfAdvertisedPlaylist] name];
            });
        }
    }];
}

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showAcknowledgements"]) {
        UITextView* textView = (UITextView*)[[[segue.destinationViewController view] subviews] objectAtIndex:0];
        
        // adjust textview
        textView.textContainerInset = UIEdgeInsetsMake(40.0, 10.0, 12.0, 10.0);
        textView.text = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"acknowledgements" ofType:@"txt"]
                                                  encoding:NSUTF8StringEncoding
                                                     error:nil];
        textView.font = [UIFont systemFontOfSize:14.0];
        textView.textColor = [UIColor darkGrayColor];
    }
}

#pragma mark - Switch Actions

-(void)toggleAdvertisementState {
    if (self.advertisementSwitch.isOn) {
        SPTSession* session = ((PGAppDelegate*)[UIApplication sharedApplication].delegate).session;
        [[PGDiscoveryManager sharedInstance] setAdvertisingPlaylist:self.playlists.items[[self.playlistPicker selectedRowInComponent:0]]
                                                        withSession:session];
        if (![[PGDiscoveryManager sharedInstance] startAdvertisingPlaylistWithSession:session]) {
            [TSMessage showNotificationInViewController:self.navigationController
                                                  title:@"Error"
                                               subtitle:@"Turn On Bluetooth!"
                                                   type:TSMessageNotificationTypeError];
            
            [self.advertisementSwitch setOn:NO animated:YES];
        }
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
    self.playlistLabel.text = [self.playlists.items[row] name];
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInteger:row] forKey:@"indexOfAdvertisedPlaylist"];
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
