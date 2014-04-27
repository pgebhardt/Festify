//
//  PGSettingsViewController.h
//  Festify
//
//  Created by Patrik Gebhardt on 15/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PGSettingsViewController;

@protocol PGSettingsViewDelegate <NSObject>

-(void)settingsViewUserDidRequestLogout:(PGSettingsViewController*)settingsView;

@end

@interface PGSettingsViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UISwitch *includeOwnSongsSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *advertisementSwitch;
@property (nonatomic, weak) id<PGSettingsViewDelegate> delegate;

@end
