//
//  PGFestifyViewController.h
//  Festify
//
//  Created by Patrik Gebhardt on 16/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PGDiscoveryManager.h"
#import "PGLoginViewController.h"
#import "PGSettingsViewController.h"
#import "PGFestifyTrackProvider.h"

@interface PGFestifyViewController : UIViewController<PGLoginViewDelegate, PGSettingsViewDelegate,
    PGFestifyTrackProviderDelegate>

- (IBAction)festify:(id)sender;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *playButton;

@end
