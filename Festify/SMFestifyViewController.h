//
//  PGFestifyViewController.h
//  Festify
//
//  Created by Patrik Gebhardt on 16/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SMDiscoveryManager.h"
#import "SMTrackPlayer.h"
#import "SMTrackProvider.h"
#import "SMLoginViewController.h"
#import "SMSettingsViewController.h"
#import "BBBadgeBarButtonItem.h"

@interface SMFestifyViewController : UIViewController<SMDiscoveryManagerDelegate,
    SMTrackProviderDelegate, SMLoginViewDelegate, SMSettingsViewDelegate, SMTrackPlayerDelegate>

- (IBAction)spotifyButton:(id)sender;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *trackPlayerBarPosition;
@property (strong, nonatomic) IBOutlet BBBadgeBarButtonItem *usersBarButtonItem;
@property (weak, nonatomic) IBOutlet UIButton *usersButton;

@end
