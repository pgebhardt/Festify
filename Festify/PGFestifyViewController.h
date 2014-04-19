//
//  PGFestifyViewController.h
//  Festify
//
//  Created by Patrik Gebhardt on 16/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>
#import "PGDiscoveryManager.h"
#import "PGSettingsViewController.h"

@interface PGFestifyViewController : UIViewController<PGDiscoveryManagerDelegate,
    PGSettingsViewDelegate, ADBannerViewDelegate>

- (IBAction)festify:(id)sender;
@property (weak, nonatomic) IBOutlet ADBannerView *adBanner;

@end
