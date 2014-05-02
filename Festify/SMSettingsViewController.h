//
//  PGSettingsViewController.h
//  Festify
//
//  Created by Patrik Gebhardt on 15/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "SMSettingSelectionViewController.h"

@class SMSettingsViewController;

@protocol SMSettingsViewDelegate <NSObject>

-(void)settingsViewUserDidRequestLogout:(SMSettingsViewController*)settingsView;
-(void)settingsView:(SMSettingsViewController*)settingsView didChangeAdvertisedPlaylistSelection:(NSArray*)indicesOfSelectedPlaylists;
-(void)settingsView:(SMSettingsViewController*)settingsView didChangeAdvertisementState:(BOOL)advertising;

@end

@interface SMSettingsViewController : UITableViewController<SMSettinsSelectionViewDelegate ,MFMailComposeViewControllerDelegate>

- (IBAction)done:(id)sender;

@property (weak, nonatomic) IBOutlet UISwitch *advertisementSwitch;
@property (nonatomic, strong) NSMutableArray* indicesOfSelectedPlaylists;
@property (nonatomic, weak) id<SMSettingsViewDelegate> delegate;

@end
