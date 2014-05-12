//
//  PGFestifyViewController.h
//  Festify
//
//  Created by Patrik Gebhardt on 16/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SMDiscoveryManager.h"
#import "SMTrackProvider.h"
#import "SMLoginViewController.h"
#import "SMSettingsViewController.h"

// notification center strings
static NSString* const SMFestifyViewControllerRestoreApplicationState = @"SMFestifyViewControllerRestoreApplicationState";

@interface SMFestifyViewController : UIViewController<SMDiscoveryManagerDelegate,
    SMTrackProviderDelegate, SMLoginViewDelegate, SMSettingsViewDelegate>

- (IBAction)spotifyButton:(id)sender;
- (IBAction)festify:(id)sender;

@property (weak, nonatomic) IBOutlet UIImageView *festifyButtonOverlay;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *trackPlayerBarPosition;

@end
