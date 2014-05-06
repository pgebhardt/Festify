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
    [SPTRequest playlistsForUser:self.session.canonicalUsername withSession:self.session callback:^(NSError *error, id object) {
        if (!error) {
            self.playlists = [object items];
            
            // update UI
            [self.playlistActivityIndicator stopAnimating];
            self.playlistNumberLabel.hidden = NO;
            [self updateVisiblePlaylistsCell];
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
        SMSettingSelectionViewController* settingsView = (SMSettingSelectionViewController*)segue.destinationViewController;
        settingsView.delegate = self;
    
        // adjust settings view to let user select which playlists are broadcasted
        settingsView.data = self.playlists;
        settingsView.indicesOfSelectedItems = [self.playlists indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            return [self.advertisedPlaylists containsObject:[[obj uri] absoluteString]];
        }];
        settingsView.dataAccessor = ^NSString*(id item) {
            return [item name];
        };
        
        settingsView.navigationItem.title = @"Limit Playlists";
        settingsView.allowMultipleSelections = YES;
    }
}

#pragma mark - Actions


- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)toggleAdvertisementState:(id)sender {
    if (self.delegate) {
        if (![self.delegate settingsView:self didChangeAdvertisementState:self.advertisementSwitch.isOn]) {
            [self.advertisementSwitch setOn:NO animated:YES];
            [TSMessage showNotificationInViewController:self.navigationController
                                                  title:@"Error"
                                               subtitle:@"Turn On Bluetooth!"
                                                   type:TSMessageNotificationTypeError];
        }
    }
}

-(void)updateVisiblePlaylistsCell {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.advertisedPlaylists.count == 0) {
            self.playlistNumberLabel.text = @"None";
        }
        else if (self.advertisedPlaylists.count == self.playlists.count){
            self.playlistNumberLabel.text = @"All";
        }
        else {
            self.playlistNumberLabel.text = [NSString stringWithFormat:@"%d", self.advertisedPlaylists.count];
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
    if ([reuseIdentifier isEqualToString:@"clearPlaylistCell"]) {
        if (self.delegate) {
            [self.delegate settingsViewDidRequestPlaylistCleanup:self];
        }
    }
    else if ([reuseIdentifier isEqualToString:@"logoutCell"]) {
        // inform delegate to logout
        if (self.delegate) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.delegate settingsViewDidRequestLogout:self];
            });
        }
    }
    else if ([reuseIdentifier isEqualToString:@"contactCell"]) {
        // add some basic debug information to default message
        NSString* message = [NSString stringWithFormat:@"\n\n-----\nApp: %@ %@ (%@)\nDevice: %@ (%@)",
                             [NSBundle mainBundle].bundleIdentifier,
                             [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"],
                             [NSBundle mainBundle].infoDictionary[(NSString*)kCFBundleVersionKey],
                             [SMSettingsViewController deviceString],
                             [UIDevice currentDevice].systemVersion];
        
        // create mail composer to send feedback to me
        MFMailComposeViewController* mailComposer = [[MFMailComposeViewController alloc] init];
        mailComposer.mailComposeDelegate = self;
        [mailComposer setSubject:@"Support"];
        [mailComposer setToRecipients:@[@"support+festify@schnuffmade.com"]];
        [mailComposer setMessageBody:message isHTML:NO];
        [self presentViewController:mailComposer animated:YES completion:nil];
    }
}

#pragma mark - SMSettingsSelectionViewDelegate

-(void)settingsSelectionView:(SMSettingSelectionViewController *)settingsSelectionView didChangeIndicesOfSelectedItems:(NSIndexSet*)indicesOfSelectedItems {
    self.advertisedPlaylists = [[[self.playlists objectsAtIndexes:indicesOfSelectedItems] valueForKey:@"uri"] valueForKey:@"absoluteString"];
    
    // update UI
    [self updateVisiblePlaylistsCell];
    
    // inform delegate
    if (self.delegate) {
        [self.delegate settingsView:self didChangeAdvertisedPlaylistSelection:self.advertisedPlaylists];
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
