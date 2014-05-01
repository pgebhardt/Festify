//
//  PGSettingsViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 15/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#include <sys/types.h>
#include <sys/sysctl.h>
#import <Spotify/Spotify.h>
#import "SMSettingsViewController.h"
#import "SMDiscoveryManager.h"
#import "SMAppDelegate.h"
#import "SMUserDefaults.h"
#import "TSMessage.h"

@interface SMSettingsViewController ()
@property (nonatomic, strong) MFMailComposeViewController* mailComposer;
@property (nonatomic, strong) NSArray* playlists;
@end

@implementation SMSettingsViewController

-(void)viewDidLoad {
    [super viewDidLoad];

    // init properties
    self.mailComposer = [[MFMailComposeViewController alloc] init];
    self.mailComposer.mailComposeDelegate = self;
    
    // connect switches to event handler
    [self.advertisementSwitch addTarget:self action:@selector(toggleAdvertisementState) forControlEvents:UIControlEventValueChanged];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // collect all playlists
    SPTSession* session = ((SMAppDelegate*)[UIApplication sharedApplication].delegate).session;
    [SPTRequest playlistsForUser:session.canonicalUsername withSession:session callback:^(NSError *error, id object) {
        if (!error) {
            self.playlists = [object items];
            
            // update UI
            dispatch_async(dispatch_get_main_queue(), ^{
                UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
                if (self.playlists.count != self.indicesOfSelectedPlaylists.count) {
                    cell.detailTextLabel.text = @"On";
                }
                else {
                    cell.detailTextLabel.text = @"Off";
                }
            });
        }
    }];
    
    // set switches to correct states
    [self.advertisementSwitch setOn:[SMDiscoveryManager sharedInstance].isAdvertisingProperty];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showLimitPlaylists"]) {
        SMSettingSelectionViewController* viewController = (SMSettingSelectionViewController*)segue.destinationViewController;
        
        viewController.data = self.playlists;
        viewController.indicesOfSelectedItems = self.indicesOfSelectedPlaylists;
        viewController.dataAccessor = ^NSString*(id item) {
            return [item name];
        };
        viewController.delegate = self;
    }
}

#pragma mark - Actions

-(void)toggleAdvertisementState {
    if (self.delegate) {
        [self.delegate settingsView:self didChangeAdvertisementState:self.advertisementSwitch.isOn];
    }
}

#pragma mark - UITableViewDelegate

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 2) {
        return [NSString stringWithFormat:@"©2014 Schnuffmade. %@ %@",
                [NSBundle mainBundle].infoDictionary[(NSString*)kCFBundleNameKey],
                [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"]];
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
    if ([reuseIdentifier isEqualToString:@"contactCell"]) {
        // show mail composer with some debug infos included
        [self.mailComposer setSubject:@"Support"];
        [self.mailComposer setToRecipients:@[@"support+festify@schnuffmade.com"]];
        [self.mailComposer setMessageBody:[NSString stringWithFormat:@"\n\n-----\nApp: %@ %@ (%@)\nDevice: %@ (%@)",
                                           [NSBundle mainBundle].bundleIdentifier,
                                           [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"],
                                           [NSBundle mainBundle].infoDictionary[(NSString*)kCFBundleVersionKey],
                                           [SMSettingsViewController deviceString],
                                           [UIDevice currentDevice].systemVersion] isHTML:NO];
        
        // apply missing style properties and show mail composer
        self.mailComposer.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
        [self presentViewController:self.mailComposer animated:YES completion:^{
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
        }];
    }
    else if ([reuseIdentifier isEqualToString:@"logoutCell"]) {
        // inform delegate to logout
        if (self.delegate) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.delegate settingsViewUserDidRequestLogout:self];
            });
        }
    }
}

#pragma mark - SMSettingsSelectionViewDelegate

-(void)settingsSelectionView:(SMSettingSelectionViewController *)settingsSelectionView didChangeIndicesOfSelectedItems:(NSArray *)indicesOfSelectedItems {
    self.indicesOfSelectedPlaylists = [indicesOfSelectedItems mutableCopy];
    if (self.delegate) {
        [self.delegate settingsView:self didChangeAdvertisedPlaylistSelection:self.indicesOfSelectedPlaylists];
    }
    
    // update UI
    dispatch_async(dispatch_get_main_queue(), ^{
        UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
        if (self.playlists.count != self.indicesOfSelectedPlaylists.count) {
            cell.detailTextLabel.text = @"On";
        }
        else {
            cell.detailTextLabel.text = @"Off";
        }
    });
}

#pragma mark - MFMailComposeViewControllerDelegate

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Helper

+(NSString*)deviceString {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

@end
