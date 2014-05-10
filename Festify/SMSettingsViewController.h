//
//  PGSettingsViewController.h
//  Festify
//
//  Created by Patrik Gebhardt on 15/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <SPotify/Spotify.h>
#import "SMSettingSelectionViewController.h"

@class SMSettingsViewController;

@protocol SMSettingsViewDelegate <NSObject>

-(void)settingsViewDidRequestLogout:(SMSettingsViewController*)settingsView;
-(BOOL)settingsView:(SMSettingsViewController*)settingsView didChangeAdvertisementState:(BOOL)advertising;
-(void)settingsView:(SMSettingsViewController*)settingsView didChangeAdvertisedPlaylistSelection:(NSArray*)selectedPlaylists;
-(void)settingsView:(SMSettingsViewController*)settingsView didChangeUserTimeout:(NSInteger)timeout;

@end

@interface SMSettingsViewController : UITableViewController<SMSettinsSelectionViewDelegate, MFMailComposeViewControllerDelegate>

- (IBAction)done:(id)sender;

@property (weak, nonatomic) IBOutlet UISwitch *advertisementSwitch;
@property (weak, nonatomic) IBOutlet UILabel *playlistNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeoutLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *playlistActivityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *logoutLabel;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

@property (nonatomic, strong) SPTSession* session;
@property (nonatomic, strong) NSArray* advertisedPlaylists;
@property (nonatomic, weak) id<SMSettingsViewDelegate> delegate;

@end
