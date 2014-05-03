//
//  PGFestifyViewController.h
//  Festify
//
//  Created by Patrik Gebhardt on 16/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SMDiscoveryManager.h"
#import "SMLoginViewController.h"
#import "SMSettingsViewController.h"

@interface SMFestifyViewController : UIViewController<SMDiscoveryManagerDelegate,
    SMLoginViewDelegate, SMSettingsViewDelegate>

- (IBAction)spotifyButton:(id)sender;
- (IBAction)festify:(id)sender;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *playButton;
@property (weak, nonatomic) IBOutlet UIButton *festifyButton;

@end
