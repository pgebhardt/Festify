//
//  PGSettingsViewController.h
//  Festify
//
//  Created by Patrik Gebhardt on 15/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Spotify/Spotify.h>

@interface PGSettingsViewController : UITableViewController<UIPickerViewDelegate, UIPickerViewDataSource>

- (IBAction)done:(id)sender;

@property (weak, nonatomic) IBOutlet UISwitch *advertisementSwitch;
@property (weak, nonatomic) IBOutlet UILabel *playlistLabel;
@property (weak, nonatomic) IBOutlet UIPickerView *playlistPicker;

@property (nonatomic, strong) SPTSession* session;

@end
