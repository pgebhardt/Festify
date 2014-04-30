//
//  PGSettingsViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 15/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "SMSettingsViewController.h"
#import "SMDiscoveryManager.h"
#import "SMAppDelegate.h"
#import "SMUserDefaults.h"
#import <Spotify/Spotify.h>
#import "TSMessage.h"

@implementation SMSettingsViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    // connect switches to event handler
    [self.advertisementSwitch addTarget:self action:@selector(toggleAdvertisementState) forControlEvents:UIControlEventValueChanged];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // set switches to correct states
    [self.advertisementSwitch setOn:[SMDiscoveryManager sharedInstance].isAdvertisingProperty];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showAcknowledgements"]) {
        // load acknowledgements text from resource file
        UITextView* textView = (UITextView*)[[[segue.destinationViewController view] subviews] objectAtIndex:0];
        textView.text = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"acknowledgements" ofType:@"txt"]
                                                  encoding:NSUTF8StringEncoding
                                                     error:nil];
        
        // adjust style of text view to match iOS settings app
        textView.textContainerInset = UIEdgeInsetsMake(40.0, 10.0, 12.0, 10.0);
        textView.font = [UIFont systemFontOfSize:14.0];
        textView.textColor = [UIColor darkGrayColor];
    }
}

#pragma mark - Actions

-(void)toggleAdvertisementState {
    if (self.advertisementSwitch.isOn) {
        NSString* username = ((SMAppDelegate*)[UIApplication sharedApplication].delegate).session.canonicalUsername;
        if (![[SMDiscoveryManager sharedInstance] advertiseProperty:[username dataUsingEncoding:NSUTF8StringEncoding]]) {
            [TSMessage showNotificationInViewController:self.navigationController
                                                  title:@"Error"
                                               subtitle:@"Turn On Bluetooth!"
                                                   type:TSMessageNotificationTypeError];
            
            [self.advertisementSwitch setOn:NO animated:YES];
        }
    }
    else {
        [[SMDiscoveryManager sharedInstance] stopAdvertisingProperty];
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
}

@end
