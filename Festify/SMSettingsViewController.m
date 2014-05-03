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
#import "MWLogging.h"

@interface SMSettingsViewController ()
@property (nonatomic, strong) NSArray* playlists;
@end

@implementation SMSettingsViewController

-(void)viewDidLoad {
    [super viewDidLoad];

    // connect switches to event handler and set them to correct state
    [self.advertisementSwitch addTarget:self action:@selector(toggleAdvertisementState:) forControlEvents:UIControlEventValueChanged];
    [self updateAdvertisiementSwitch];
    
    // collect all playlists
    SPTSession* session = ((SMAppDelegate*)[UIApplication sharedApplication].delegate).session;
    [SPTRequest playlistsForUser:session.canonicalUsername withSession:session callback:^(NSError *error, id object) {
        if (!error) {
            self.playlists = [object items];
            
            // update UI
            [self updateLimitPlaylistsCell];
        }
        else {
            MWLogWarning(@"%@", error);
        }
    }];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // observe changes in advertisement state
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAdvertisiementSwitch) name:SMDiscoveryManagerDidStartAdvertising object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAdvertisiementSwitch) name:SMDiscoveryManagerDidStopAdvertising object:nil];    
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // remove observations
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showLimitPlaylists"]) {
        UINavigationController* navigationController = (UINavigationController*)segue.destinationViewController;
        SMSettingSelectionViewController* viewController = (SMSettingSelectionViewController*)navigationController.viewControllers[0];
        
        viewController.underlyingView = self.navigationController.view;
        viewController.data = self.playlists;
        viewController.indicesOfSelectedItems = self.indicesOfSelectedPlaylists;
        viewController.dataAccessor = ^NSString*(id item) {
            return [item name];
        };
        viewController.delegate = self;
    }
}

#pragma mark - Actions

-(void)toggleAdvertisementState:(id)sender {
    if (self.delegate) {
        [self.delegate settingsView:self didChangeAdvertisementState:self.advertisementSwitch.isOn];
    }
}

-(void)updateLimitPlaylistsCell {
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

-(void)updateAdvertisiementSwitch {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([SMDiscoveryManager sharedInstance].isAdvertising) {
            [self.advertisementSwitch setOn:YES animated:YES];
        }
        else {
            [self.advertisementSwitch setOn:NO animated:YES];
        }
    });
}

#pragma mark - UITableViewDelegate

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == self.tableView.numberOfSections - 1) {
        return [NSString stringWithFormat:@"©2014 SchnuffMade. %@ %@",
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
        MFMailComposeViewController* mailComposer = [[MFMailComposeViewController alloc] init];
        mailComposer.mailComposeDelegate = self;
        
        // show mail composer with some debug infos included
        [mailComposer setSubject:@"Support"];
        [mailComposer setToRecipients:@[@"support+festify@schnuffmade.com"]];
        [mailComposer setMessageBody:[NSString stringWithFormat:@"\n\n-----\nApp: %@ %@ (%@)\nDevice: %@ (%@)",
                                      [NSBundle mainBundle].bundleIdentifier,
                                      [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"],
                                      [NSBundle mainBundle].infoDictionary[(NSString*)kCFBundleVersionKey],
                                      [SMSettingsViewController deviceString],
                                      [UIDevice currentDevice].systemVersion] isHTML:NO];
        
        // apply missing style properties and show mail composer
        [self presentViewController:mailComposer animated:YES completion:nil];
    }
    else if ([reuseIdentifier isEqualToString:@"logoutCell"]) {
        // inform delegate to logout
        if (self.delegate) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.delegate settingsViewDidRequestLogout:self];
            });
        }
    }
    else if ([reuseIdentifier isEqualToString:@"clearPlaylistCell"]) {
        if (self.delegate) {
            [self.delegate settingsViewDidRequestPlaylistCleanup:self];
        }
    }
}

#pragma mark - SMSettingsSelectionViewDelegate

-(void)settingsSelectionView:(SMSettingSelectionViewController *)settingsSelectionView didChangeIndicesOfSelectedItems:(NSArray *)indicesOfSelectedItems {
    self.indicesOfSelectedPlaylists = [indicesOfSelectedItems mutableCopy];
    
    // update UI
    [self updateLimitPlaylistsCell];
    
    // inform delegate
    if (self.delegate) {
        [self.delegate settingsView:self didChangeAdvertisedPlaylistSelection:self.indicesOfSelectedPlaylists];
    }
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
