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

@interface PGFestifyViewController : UIViewController<PGDiscoveryManagerDelegate, PGSettingsViewDelegate, SPTTrackPlayerDelegate>

-(void)handleNewSession:(SPTSession*)session;
-(void)handleLoginError:(NSError*)error;
- (IBAction)festify:(id)sender;

@property (nonatomic, strong) SPTSession* session;

@end
