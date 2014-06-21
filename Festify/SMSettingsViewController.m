//
//  PGSettingsViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 15/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#include <sys/types.h>
#include <sys/sysctl.h>
#import "SMSettingsViewController.h"
#import "SMDiscoveryManager.h"
#import "SMUserDefaults.h"
#import "MWLogging.h"

@interface SMSettingsViewController ()
@property (nonatomic, strong) NSArray* playlists;
@property (nonatomic, strong) NSArray* advertisedPlaylists;
@property (nonatomic, assign) NSInteger indexOfSelectedUserTimout;
@property (nonatomic, strong) NSArray* usersTimeoutSelection;
@end

@implementation SMSettingsViewController

-(void)viewDidLoad {
    [super viewDidLoad];

    // init properties
    self.usersTimeoutSelection =  @[@{@"name": @"After 30 min", @"value": @30},
                                    @{@"name": @"After 1 h", @"value": @60},
                                    @{@"name": @"After 2 h", @"value": @120},
                                    @{@"name": @"After 4 h", @"value": @240},
                                    @{@"name": @"After 6 h", @"value": @360},
                                    @{@"name": @"Never", @"value": @0}];
    
    // connect switches to event handler and set them to correct state
    [self.advertisementSwitch addTarget:self action:@selector(toggleAdvertisementState:) forControlEvents:UIControlEventValueChanged];
    [self updateAdvertisiementSwitch];

    // collect playlists from currently logged in user to pass to playlist selection screen
    self.advertisedPlaylists = [[NSUserDefaults standardUserDefaults] valueForKey:SMUserDefaultsAdvertisedPlaylistsKey];
    [SPTRequest playlistsForUserInSession:self.session callback:^(NSError *error, id object) {
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
    
    // update UI
    NSInteger usersTimeout = [[[NSUserDefaults standardUserDefaults] valueForKey:SMUserDefaultsUserTimeoutKey] integerValue];
    self.indexOfSelectedUserTimout = [self.usersTimeoutSelection indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [[obj objectForKey:@"value"] doubleValue] == usersTimeout;
    }];
    
    self.timeoutLabel.text = self.usersTimeoutSelection[self.indexOfSelectedUserTimout][@"name"];
    self.logoutLabel.text = [NSString stringWithFormat:@"Log Out %@", self.session.canonicalUsername];
    self.versionLabel.text = [NSString stringWithFormat:@"%@ (%@)",
                              [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"],
                              [NSBundle mainBundle].infoDictionary[(NSString*)kCFBundleVersionKey]];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // observe changes in advertisement state
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAdvertisiementSwitch) name:SMDiscoveryManagerDidUpdateAdvertisementState object:nil];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // remove observations
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showVisiblePlaylists"]) {
        SMSettingSelectionViewController* settingsView = (SMSettingSelectionViewController*)segue.destinationViewController;
        settingsView.delegate = self;
    
        // adjust settings view to let user select which playlists are broadcasted
        settingsView.data = self.playlists;
        settingsView.allowMultipleSelections = YES;
        settingsView.indicesOfSelectedItems = [self.playlists indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            return [self.advertisedPlaylists containsObject:[[obj uri] absoluteString]];
        }];
        settingsView.dataAccessor = ^NSString*(id item) {
            return [item name];
        };
        
        settingsView.navigationItem.title = @"Visible Playlists";
        settingsView.subtitle = @"Selected playlists are visible to nearby users. Only playlists publicy visible in your spotify profile can be made available.";
    }
    else if ([segue.identifier isEqualToString:@"showUserTimeout"]) {
        SMSettingSelectionViewController* settingsView = (SMSettingSelectionViewController*)segue.destinationViewController;
        settingsView.delegate = self;
        
        // adjust settings view to let user select which playlists are broadcasted
        settingsView.data = self.usersTimeoutSelection;
        settingsView.dataAccessor = ^NSString*(id item) {
            return [item objectForKey:@"name"];
        };
        settingsView.indexOfSelectedItem = self.indexOfSelectedUserTimout;
        settingsView.allowMultipleSelections = NO;
        
        settingsView.navigationItem.title = @"Delete Users";
        settingsView.subtitle = @"When a user is not available for the selcted time interval, it's songs are deleted from the playlist.";        
    }
    else if ([segue.identifier isEqualToString:@"showAcknowledgements"]) {
        UIViewController* viewController = (UIViewController*)segue.destinationViewController;
        UITextView* textView = (UITextView*)viewController.view.subviews[0];
        
        // load acknowledgements from plist file
        NSString* path = [[NSBundle mainBundle] pathForResource:@"Pods-acknowledgements" ofType:@"plist"];
        NSDictionary* acknowledgements = [NSDictionary dictionaryWithContentsOfFile:path][@"PreferenceSpecifiers"];
        
        // read out all acknowledgements and add them to one continious string
        NSMutableString* acknowledgementsText = [NSMutableString stringWithString:textView.text];
        for (NSDictionary *acknowledgement in acknowledgements) {
            [acknowledgementsText appendFormat:@"\n\n%@\n%@", acknowledgement[@"Title"], acknowledgement[@"FooterText"]];
        }

        textView.text = acknowledgementsText;
        textView.textContainerInset = UIEdgeInsetsMake(12.0, 10.0, 12.0, 10.0);
    }
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if (self.playlistActivityIndicator.isAnimating &&
        [identifier isEqualToString:@"showVisiblePlaylists"]) {
        return NO;
    }
    return YES;
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)toggleAdvertisementState:(id)sender {
    if (self.delegate) {
        [self.delegate settingsView:self didChangeAdvertisementState:self.advertisementSwitch.isOn];
    }

    // check if advertisement was not enabled and update UI accordingly 
    if (![SMDiscoveryManager sharedInstance].isAdvertising) {
        [self.advertisementSwitch setOn:NO animated:YES];
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
            self.playlistNumberLabel.text = @"Limited";
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

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // deselect cell
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    // handle actions for specific cell
    NSString* reuseIdentifier = [tableView cellForRowAtIndexPath:indexPath].reuseIdentifier;
    if ([reuseIdentifier isEqualToString:@"logoutCell"]) {
        [self dismissViewControllerAnimated:YES completion:^{
            // inform delegate to logout
            if (self.delegate) {
                [self.delegate settingsViewDidRequestLogout:self];
            }
        }];
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
    if ([settingsSelectionView.navigationItem.title isEqualToString:@"Visible Playlists"]) {
        self.advertisedPlaylists = [[[self.playlists objectsAtIndexes:indicesOfSelectedItems] valueForKey:@"uri"] valueForKey:@"absoluteString"];
        
        // update UI
        [self updateVisiblePlaylistsCell];
        
        // inform delegate
        if (self.delegate) {
            [self.delegate settingsView:self didChangeAdvertisedPlaylistSelection:self.advertisedPlaylists];
        }
    }
    else if ([settingsSelectionView.navigationItem.title isEqualToString:@"Delete Users"]) {
        // update UI
        NSNumber* timeout = self.usersTimeoutSelection[indicesOfSelectedItems.firstIndex][@"value"];
        self.timeoutLabel.text = self.usersTimeoutSelection[indicesOfSelectedItems.firstIndex][@"name"];
        self.indexOfSelectedUserTimout = [self.usersTimeoutSelection indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            return [[obj objectForKey:@"value"] doubleValue] == [timeout integerValue];
        }];
        
        // inform delegate
        if (self.delegate) {
            [self.delegate settingsView:self didChangeUsersTimeout:[timeout integerValue]];
        }
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
