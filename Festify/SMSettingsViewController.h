//
//  PGSettingsViewController.h
//  Festify
//
//  Created by Patrik Gebhardt on 15/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@class SMSettingsViewController;

@protocol SMSettingsViewDelegate <NSObject>

-(void)settingsViewUserDidRequestLogout:(SMSettingsViewController*)settingsView;

@end

@interface SMSettingsViewController : UITableViewController<MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UISwitch *advertisementSwitch;
@property (nonatomic, weak) id<SMSettingsViewDelegate> delegate;

@end
