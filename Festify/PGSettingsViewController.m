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
#import "PGUserDefaults.h"
#import <Spotify/Spotify.h>
#import "TSMessage.h"
#import "ATConnect.h"

@implementation PGSettingsViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    // connect switches to event handler
    [self.advertisementSwitch addTarget:self action:@selector(toggleAdvertisementState) forControlEvents:UIControlEventValueChanged];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // set switches to correct states
    [self.advertisementSwitch setOn:[PGDiscoveryManager sharedInstance].isAdvertisingProperty];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // apptentive event
    [[ATConnect sharedConnection] engage:@"settingsViewDidAppear" fromViewController:self.navigationController];
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

#pragma mark - Actions

-(void)toggleAdvertisementState {
    if (self.advertisementSwitch.isOn) {
        NSString* username = ((PGAppDelegate*)[UIApplication sharedApplication].delegate).session.canonicalUsername;
        if (![[PGDiscoveryManager sharedInstance] advertiseProperty:[username dataUsingEncoding:NSUTF8StringEncoding]]) {
            [TSMessage showNotificationInViewController:self.navigationController
                                                  title:@"Error"
                                               subtitle:@"Turn On Bluetooth!"
                                                   type:TSMessageNotificationTypeError];
            
            [self.advertisementSwitch setOn:NO animated:YES];
        }
    }
    else {
        [[PGDiscoveryManager sharedInstance] stopAdvertisingProperty];
    }
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
    if ([reuseIdentifier isEqualToString:@"logoutCell"]) {
        // inform delegate to logout
        if (self.delegate) {
            [self.delegate settingsViewUserDidRequestLogout:self];
        }
    }
    else if ([reuseIdentifier isEqualToString:@"sendFeedbackCell"]) {
        [[ATConnect sharedConnection] presentMessageCenterFromViewController:self.navigationController];
    }
}

@end
