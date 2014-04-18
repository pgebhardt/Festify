//
//  PGFestifyViewController.h
//  Festify
//
//  Created by Patrik Gebhardt on 16/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Spotify/Spotify.h>
#import "PGDiscoveryManager.h"
#import "PGSettingsViewController.h"
#import "PGLoginViewController.h"

@interface PGFestifyViewController : UIViewController<PGDiscoveryManagerDelegate,
    PGSettingsViewDelegate, SPTTrackPlayerDelegate, PGLoginViewDelegate>

- (IBAction)festify:(id)sender;

@end
